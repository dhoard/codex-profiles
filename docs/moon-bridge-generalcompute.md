# Moon Bridge General Compute Configuration

Codex sends General Compute requests to a local Moon Bridge endpoint because Codex uses the Responses API:

```toml
base_url = "http://127.0.0.1:38440/v1"
wire_api = "responses"
```

General Compute exposes an OpenAI-compatible Chat Completions API at `https://api.generalcompute.com/v1`. Moon Bridge translates Codex Responses API calls to General Compute chat-completions requests and routes by model name.

> Do not commit real API keys. Keep `GENERALCOMPUTE_API_KEY` in your shell environment, substitute it into a private generated Moon Bridge config before startup, or put the secret directly only in your private Moon Bridge config file.

## Minimal General Compute example

Merge this shape with your existing Moon Bridge `config.yml`. Keep any existing DeepSeek or Z.AI fields that already work for you.

```yaml
mode: "Transform"

server:
  addr: "127.0.0.1:38440"

defaults:
  model: "generalcompute-minimax-m2.7"
  max_tokens: 65536

models:
  generalcompute-minimax-m2.7:
    context_window: 160000
    max_output_tokens: 65536
    display_name: "MiniMax M2.7 (General Compute)"
    default_reasoning_level: "low"
    supported_reasoning_levels:
      - effort: "low"
        description: "Fast general-purpose responses"
    supports_reasoning_summaries: false
    input_modalities:
      - "text"

  generalcompute-deepseek-v3.2:
    context_window: 32000
    max_output_tokens: 65536
    display_name: "DeepSeek V3.2 (General Compute)"
    default_reasoning_level: "medium"
    supported_reasoning_levels:
      - effort: "low"
        description: "Light reasoning"
      - effort: "medium"
        description: "Balanced reasoning"
      - effort: "high"
        description: "More reasoning"
      - effort: "xhigh"
        description: "Maximum reasoning"
    supports_reasoning_summaries: true
    input_modalities:
      - "text"

  generalcompute-deepseek-v3.1:
    context_window: 128000
    max_output_tokens: 65536
    display_name: "DeepSeek V3.1 (General Compute)"
    default_reasoning_level: "medium"
    supported_reasoning_levels:
      - effort: "low"
        description: "Light reasoning"
      - effort: "medium"
        description: "Balanced reasoning"
      - effort: "high"
        description: "More reasoning"
      - effort: "xhigh"
        description: "Maximum reasoning"
    supports_reasoning_summaries: true
    input_modalities:
      - "text"

providers:
  generalcompute:
    base_url: "https://api.generalcompute.com/v1"
    api_key: "replace-with-generalcompute-api-key"
    protocol: "openai-chat"
    user_agent: "moonbridge/1.0"
    offers:
      - model: minimax-m2.7
      - model: deepseek-v3.2
      - model: deepseek-v3.1

routes:
  generalcompute-minimax-m2.7:
    model: minimax-m2.7
    provider: generalcompute
  generalcompute-deepseek-v3.2:
    model: deepseek-v3.2
    provider: generalcompute
  generalcompute-deepseek-v3.1:
    model: deepseek-v3.1
    provider: generalcompute
```

## Restart and smoke test

After changing `config.yml`, restart Moon Bridge, then run:

```bash
codex --profile generalcompute-minimax-m2-7
codex --profile generalcompute-deepseek-v3-2
codex --profile generalcompute-deepseek-v3-1
```

Test a simple prompt first, then test streaming and tool-call behavior. Mark `docs/model-capabilities.md` runtime statuses only after an end-to-end Codex run succeeds.
