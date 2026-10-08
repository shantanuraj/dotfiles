# Codex fast mode

Personal Pi extension that requests `service_tier: "priority"` for the active
`openai-codex` model. Priority availability depends on the endpoint and account;
it can cost more or consume quota faster. This does not change reasoning effort,
and Pi's displayed cost estimate may not reflect the priority surcharge.

Install via the dotfiles `symlink.sh`, or link this directory into
`~/.pi/agent/extensions/codex-fast`. In Pi, run `/reload`, then `/fast on`.

- `/fast`: toggle priority requests.
- `/fast on` or `/fast off`: explicitly enable or disable.
- `/fast status`: report the current setting without changing it.

New sessions default to off. State follows the active session branch and survives
reloads and resumes. Switching away from the Codex provider pauses the setting;
switching back restores it. The extension leaves other providers and models
untouched and does not override another extension's priority setting when off.

Test without making provider requests:

```sh
node --test ~/.pi/agent/extensions/codex-fast/index.test.mjs
```
