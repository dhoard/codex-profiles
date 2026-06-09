# Moon Bridge Multi-Provider Configuration

Codex sends both DeepSeek and Z.AI Coding Plan requests to the same local Moon Bridge endpoint:

```toml
base_url = "http://127.0.0.1:38440/v1"
wire_api = "responses"
```

Moon Bridge must then route by the requested model name. If Moon Bridge only has DeepSeek models in `config.yml`, Z.AI profiles fail with an error like:

```text
The supported API model names are deepseek-v4-pro or deepseek-v4-flash, but you passed glm-5.1.
```

Add Z.AI models, a Z.AI provider, and routes to your private Moon Bridge `config.yml`, then restart Moon Bridge.

> Do not commit real API keys. If you keep `ZHIPU_API_KEY` in your shell environment, either substitute it into a private generated Moon Bridge config before startup or put the secret directly only in your private Moon Bridge config file.

## Minimal combined example

Merge this shape with your existing DeepSeek Moon Bridge config. Keep any existing DeepSeek fields that already work for you.

```yaml
mode: "Transform"

server:
  addr: "127.0.0.1:38440"

defaults:
  model: "deepseek-v4-pro"
  max_tokens: 65536

models:
  deepseek-v4-pro:
    context_window: 1000000
    max_output_tokens: 384000
    default_reasoning_level: "high"
    supported_reasoning_levels:
      - effort: "high"
        description: "High reasoning effort"
      - effort: "xhigh"
        description: "Extra high reasoning effort"
    supports_reasoning_summaries: true

  deepseek-v4-flash:
    context_window: 1000000
    max_output_tokens: 384000
    default_reasoning_level: "high"
    supported_reasoning_levels:
      - effort: "high"
        description: "High reasoning effort"
      - effort: "xhigh"
        description: "Extra high reasoning effort"
    supports_reasoning_summaries: true

  glm-5.1:
    context_window: 200000
    max_output_tokens: 65536
    display_name: "GLM 5.1"
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

  glm-4.7:
    context_window: 200000
    max_output_tokens: 65536
    display_name: "GLM 4.7"
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
  deepseek:
    base_url: "https://api.deepseek.com/anthropic"
    api_key: "replace-with-deepseek-api-key"
    version: "2023-06-01"
    user_agent: "moonbridge/1.0"
    offers:
      - model: deepseek-v4-pro
      - model: deepseek-v4-flash

  zai-coding:
    base_url: "https://api.z.ai/api/coding/paas/v4"
    api_key: "replace-with-zhipu-api-key"
    protocol: "openai-chat"
    user_agent: "moonbridge/1.0"
    offers:
      - model: glm-5.1
      - model: glm-4.7

routes:
  deepseek-v4-pro:
    model: deepseek-v4-pro
    provider: deepseek
  deepseek-v4-flash:
    model: deepseek-v4-flash
    provider: deepseek
  glm-5.1:
    model: glm-5.1
    provider: zai-coding
  glm-4.7:
    model: glm-4.7
    provider: zai-coding
```

## Restart and smoke test

After changing `config.yml`, restart Moon Bridge, then run:

```bash
codex --profile zai-coding-glm-5-1
codex --profile zai-coding-glm-4-7
```
