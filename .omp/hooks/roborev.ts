import type { HookAPI } from "@oh-my-pi/pi-coding-agent/extensibility/hooks";
import { spawnSync } from "child_process";

const ROBOREV = process.env.ROBOREV_BIN ?? "roborev";
const TIMEOUT = 8_000;

function runHook(payload: object): { triggered: boolean; reason?: string } | null {
  const result = spawnSync(ROBOREV, ["agent-hook", "run"], {
    input: JSON.stringify(payload),
    encoding: "utf8",
    timeout: TIMEOUT,
  });
  if (result.status !== 0 || !result.stdout?.trim()) return null;
  try {
    return JSON.parse(result.stdout);
  } catch {
    return null;
  }
}

export default function (pi: HookAPI): void {
  // ponytail: module-level state for pending stop-hook reminder; single-session lifecycle
  let pendingReminder: string | null = null;

  // Inject any pending stop-hook reminder on the next LLM context call
  pi.on("context", async (event) => {
    if (!pendingReminder) return;
    const reminder = pendingReminder;
    pendingReminder = null;
    return {
      messages: [
        ...event.messages,
        { role: "user", content: [{ type: "text", text: reminder }] },
      ],
    };
  });

  // Stop hook: fires at end of each turn
  pi.on("turn_end", async (_event, ctx) => {
    const sessionId = ctx.sessionManager?.getSessionFile() ?? "";
    const cwd = ctx.cwd ?? process.cwd();
    const resp = runHook({
      hook_event_name: "Stop",
      session_id: sessionId,
      cwd,
      stop_hook_active: true,
    });
    if (resp?.triggered && resp.reason) {
      pendingReminder = resp.reason;
    }
  });

  // PostToolUse hook: fires after each tool execution
  pi.on("tool_result", async (event, ctx) => {
    if (event.isError) return;
    const sessionId = ctx.sessionManager?.getSessionFile() ?? "";
    const cwd = ctx.cwd ?? process.cwd();
    const resp = runHook({
      hook_event_name: "PostToolUse",
      session_id: sessionId,
      cwd,
      tool_name: event.toolName,
      tool_use_id: event.toolCallId,
      tool_input: event.input,
      tool_response: event.content,
    });
    if (!resp?.triggered || !resp.reason) return;
    // Append roborev's additional context to the tool result so the model sees it
    return {
      content: [
        ...event.content,
        { type: "text", text: `\n\n---\n${resp.reason}` },
      ],
    };
  });
}
