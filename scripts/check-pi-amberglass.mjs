// Run with the source checkout's tsx (see README.md). No Pi session is launched.
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { resolve, dirname } from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const source = resolve(process.argv[2] ?? `${homedir()}/dev/earendil-works/pi`);
const themeDir = `${source}/packages/coding-agent/src/modes/interactive/theme`;
const themePath = `${root}/.pi/agent/themes/amberglass.json`;
const readJson = (path) => JSON.parse(readFileSync(path, "utf8"));
const json = readJson(themePath);
const schema = readJson(`${themeDir}/theme-schema.json`);

// Validate both the published JSON schema and the actual runtime validator.
const require = createRequire(`${source}/packages/coding-agent/package.json`);
const { Compile } = await import(
  pathToFileURL(require.resolve("typebox/compile"))
);
const compiled = Compile(schema);
assert(
  compiled.Check(json),
  JSON.stringify([...compiled.Errors(json)], null, 2),
);
assert.deepEqual(
  Object.keys(json.colors).sort(),
  Object.keys(schema.properties.colors.properties).sort(),
);
const { validateThemeJson } = await import(
  pathToFileURL(`${themeDir}/theme-json.ts`)
);
validateThemeJson("amberglass", json);

const api = await import(pathToFileURL(`${themeDir}/theme.ts`));
api.setThemeJsonValidator(validateThemeJson);
const backgrounds = new Set([
  "selectedBg",
  "searchMatchBg",
  "userMessageBg",
  "customMessageBg",
  "toolPendingBg",
  "toolSuccessBg",
  "toolErrorBg",
]);
const resolveColor = (value) => {
  const hex = json.vars[value] ?? value;
  assert.match(hex, /^#[0-9a-f]{6}$/i);
  return hex;
};
for (const mode of ["truecolor", "256color"]) {
  const theme = api.loadThemeFromPath(themePath, mode);
  assert.equal(theme.name, "amberglass");
  for (const [token, value] of Object.entries(json.colors)) {
    const hex = resolveColor(value);
    const prefix = backgrounds.has(token) ? 48 : 38;
    const ansi = backgrounds.has(token)
      ? theme.getBgAnsi(token)
      : theme.getFgAnsi(token);
    if (mode === "truecolor") {
      const rgb = hex
        .slice(1)
        .match(/../g)
        .map((part) => parseInt(part, 16));
      assert.equal(ansi, `\x1b[${prefix};2;${rgb.join(";")}m`, token);
    } else {
      assert.match(ansi, new RegExp(`^\\x1b\\[${prefix};5;\\d+m$`), token);
    }
  }
  for (const level of [
    "off",
    "minimal",
    "low",
    "medium",
    "high",
    "xhigh",
    "max",
  ]) {
    assert(theme.getThinkingBorderColor(level)("border").includes("border"));
  }
}

// HTML exports use registered theme paths; exercise that route, not only JSON parsing.
api.setRegisteredThemes([api.loadThemeFromPath(themePath, "truecolor")]);
assert.deepEqual(api.getThemeExportColors("amberglass"), {
  pageBg: "#15120D",
  cardBg: "#100E0A",
  infoBg: "#211B12",
});
assert.equal(api.getResolvedThemeColors("amberglass").text, "#D9AA63");
assert.equal(readJson(`${root}/.pi/agent/settings.json`).theme, "amberglass");
console.log(
  `Amberglass: ${Object.keys(json.colors).length} tokens, schema, runtime loading, truecolor/256-color, thinking borders and exports passed`,
);
