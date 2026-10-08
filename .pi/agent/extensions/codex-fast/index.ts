import type {
  ExtensionAPI,
  ExtensionContext,
} from '@earendil-works/pi-coding-agent';

const STATE_KEY = 'codex-fast';

function supportsFast(ctx: ExtensionContext) {
  return (
    ctx.model?.provider === 'openai-codex' &&
    ctx.model.api === 'openai-codex-responses'
  );
}

export default function (pi: ExtensionAPI) {
  let enabled = false;

  const updateStatus = (ctx: ExtensionContext) => {
    if (ctx.hasUI) {
      ctx.ui.setStatus(
        STATE_KEY,
        enabled ? (supportsFast(ctx) ? 'fast: on' : 'fast: paused') : undefined,
      );
    }
  };

  const restore = (ctx: ExtensionContext) => {
    enabled = false;
    for (const entry of ctx.sessionManager.getBranch()) {
      if (
        entry.type === 'custom' &&
        entry.customType === STATE_KEY &&
        typeof entry.data === 'boolean'
      ) {
        enabled = entry.data;
      }
    }
    updateStatus(ctx);
  };

  pi.on('session_start', (_event, ctx) => restore(ctx));
  pi.on('session_tree', (_event, ctx) => restore(ctx));
  pi.on('model_select', (_event, ctx) => updateStatus(ctx));

  pi.on('before_provider_request', (event, ctx) => {
    if (
      !enabled ||
      !supportsFast(ctx) ||
      !event.payload ||
      typeof event.payload !== 'object' ||
      Array.isArray(event.payload) ||
      !('model' in event.payload) ||
      event.payload.model !== ctx.model?.id
    ) {
      return;
    }
    return { ...event.payload, service_tier: 'priority' };
  });

  pi.registerCommand('fast', {
    description: 'Toggle Codex priority processing: /fast [on|off|status]',
    handler: async (args, ctx) => {
      const action = args.trim().toLowerCase();
      if (!['', 'on', 'off', 'status'].includes(action)) {
        ctx.ui.notify('Usage: /fast [on|off|status]', 'error');
        return;
      }

      if (action !== 'status') {
        const next = action === '' ? !enabled : action === 'on';
        if (next && !supportsFast(ctx)) {
          ctx.ui.notify('Fast mode requires an openai-codex model.', 'error');
          return;
        }
        if (next !== enabled) {
          pi.appendEntry(STATE_KEY, next);
          enabled = next;
        }
      }

      updateStatus(ctx);
      ctx.ui.notify(
        !enabled
          ? 'Fast mode off.'
          : !supportsFast(ctx)
            ? 'Fast mode paused: select an openai-codex model.'
            : 'Fast mode on: priority requested; higher cost or quota usage may apply.',
        'info',
      );
    },
  });
}
