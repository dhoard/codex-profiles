# Model Capabilities

Capability status values:

- `source-verified`: documented by the linked model/provider source.
- `runtime-verified`: confirmed through local Codex/Ollama execution.
- `not-supported`: explicitly not supported or intentionally disabled.
- `pending-runtime`: source-backed but still needs an end-to-end Codex smoke test.

## Summary

| Codex slug | Provider model id | Provider | Context | Input | Tools | Thinking | Cloud |
|---|---|---|---:|---|---|---|---|
| `gpt-5.5` | `gpt-5.5` | OpenAI | 1.0M | Text, Image | Yes | Yes | No |
| `gpt-5.4` | `gpt-5.4` | OpenAI | 1.05M | Text, Image | Yes | Yes | No |
| `gpt-5.3-codex` | `gpt-5.3-codex` | OpenAI | 272K | Text, Image | Yes | Yes | No |
| `gpt-5.2` | `gpt-5.2` | OpenAI | 272K | Text, Image | Yes | Yes | No |
| `glm-5.1:cloud` | `glm-5.1:cloud` | Ollama | 198K | Text | Yes | Yes | Yes |
| `glm-5:cloud` | `glm-5:cloud` | Ollama | 198K | Text | Yes | Yes | Yes |
| `minimax-m2.7:cloud` | `minimax-m2.7:cloud` | Ollama | 200K | Text | Yes | Yes | Yes |
| `minimax-m2.5:cloud` | `minimax-m2.5:cloud` | Ollama | 200K | Text | Yes | Yes | Yes |
| `kimi-k2.6:cloud` | `kimi-k2.6:cloud` | Ollama | 256K | Text, Image | Yes | Yes | Yes |
| `kimi-k2.5:cloud` | `kimi-k2.5:cloud` | Ollama | 256K | Text, Image | Yes | Yes | Yes |
| `qwen3-coder-next:cloud` | `qwen3-coder-next:cloud` | Ollama | 256K | Text | Yes | No | Yes |

## GPT-5.5

- Source: OpenAI models docs and the OpenAI developer docs home page latest-model guidance.
- Provider model id: `gpt-5.5`.
- Context window: 1.0M, `source-verified`.
- Input modalities: text and image, `source-verified` (image is input-only per model docs).
- Tool/function calling: supported, `source-verified`.
- Thinking/reasoning: `low`, `medium`, `high`, and `xhigh` (plus `none` in the API model docs), `source-verified`.
- Notes: This repo configures `gpt-5.5` as a direct OpenAI profile with the same Codex CLI baseline fields used for `gpt-5.4`.

## GPT-5.4

- Source: OpenAI model docs for GPT-5.4 and the GPT-5.4 release post.
- Provider model id: `gpt-5.4`.
- Context window: 1.05M, `source-verified` (Codex may require explicit configuration to use >272K).
- Input modalities: text and image, `source-verified` (image is input-only per model docs).
- Tool/function calling: supported, `source-verified`.
- Thinking/reasoning: `low`, `medium`, `high`, and `xhigh` (plus `none` as default in the API), `source-verified`.
- Notes: This repo keeps the same Codex CLI baseline fields as `gpt-5.2` while updating context window metadata.

## GPT-5.3-Codex

- Source: local Codex model catalog cache at `~/.codex/models_cache.json`.
- Provider model id: `gpt-5.3-codex`.
- Context window: 272K, `pending-runtime` (mirror of `gpt-5.2` until source-verified).
- Input modalities: text and image, `pending-runtime` (mirror of `gpt-5.2` until source-verified).
- Tool/function calling: enabled through Codex model catalog fields, `pending-runtime`.
- Thinking/reasoning: `low`, `medium`, `high`, and `xhigh`, `pending-runtime`.
- Notes: Configure identically to `gpt-5.2` for Codex CLI, but with the `gpt-5.3-codex` provider model id.

## GPT-5.2

- Source: local Codex model catalog cache at `~/.codex/models_cache.json`.
- Provider model id: `gpt-5.2`.
- Context window: 272K, `source-verified`.
- Input modalities: text and image, `source-verified`.
- Tool/function calling: enabled through Codex model catalog fields, `source-verified`.
- Thinking/reasoning: `low`, `medium`, `high`, and `xhigh`, `source-verified`.
- Notes: This entry preserves standard Codex access alongside the custom Ollama Cloud entries.

## GLM 5.1

- Source: `https://ollama.com/library/glm-5.1%3Acloud` and `https://ollama.com/library/glm-5.1/tags`.
- Provider model id: `glm-5.1:cloud`.
- Codex provider: direct Ollama Cloud OpenAI-compatible endpoint at `https://ollama.com/v1` with `OLLAMA_API_KEY`, `pending-runtime`.
- Context window: 198K, `source-verified`.
- Input modalities: text, `source-verified`.
- Tool/function calling: Ollama tags the model with `tools`, `source-verified`, `pending-runtime` for Codex.
- Thinking/reasoning: Ollama tags the model with `thinking`, `source-verified`, `pending-runtime` for Codex reasoning levels.
- Cloud: Ollama tags the model with `cloud`, `source-verified`.
- Codex web search: enabled to match the `gpt-5.2` baseline, `pending-runtime`.
- Notes: Configure as text-only until image support is documented and runtime verified.

## GLM 5

- Source: `https://ollama.com/library/glm-5%3Acloud` and `https://ollama.com/library/glm-5/tags`.
- Provider model id: `glm-5:cloud`.
- Codex provider: direct Ollama Cloud OpenAI-compatible endpoint at `https://ollama.com/v1` with `OLLAMA_API_KEY`, `pending-runtime`.
- Context window: 198K, `source-verified`.
- Input modalities: text, `source-verified`.
- Tool/function calling: Ollama tags the model with `tools`, `source-verified`, `pending-runtime` for Codex.
- Thinking/reasoning: Ollama tags the model with `thinking`, `source-verified`, `pending-runtime` for Codex reasoning levels.
- Cloud: Ollama tags the model with `cloud`, `source-verified`.
- Codex web search: enabled to match the `gpt-5.2` baseline, `pending-runtime`.
- Notes: Configure as text-only until image support is documented and runtime verified.

## MiniMax M2.7

- Source: `https://ollama.com/library/minimax-m2.7` and `https://ollama.com/library/minimax-m2.7%3Acloud`.
- Provider model id: `minimax-m2.7:cloud`.
- Codex provider: direct Ollama Cloud OpenAI-compatible endpoint at `https://ollama.com/v1` with `OLLAMA_API_KEY`, `pending-runtime`.
- Context window: 200K, `source-verified`.
- Input modalities: text, `source-verified`.
- Tool/function calling: Ollama tags the model with `tools`, `source-verified`, `pending-runtime` for Codex.
- Thinking/reasoning: Ollama tags the model with `thinking`, `source-verified`, `pending-runtime` for Codex reasoning levels.
- Cloud: Ollama tags the model with `cloud`, `source-verified`.
- Codex web search: enabled to match the `gpt-5.2` baseline, `pending-runtime`.
- Notes: Configure as text-only.

## MiniMax M2.5

- Source: `https://ollama.com/library/minimax-m2.5` and `https://ollama.com/library/minimax-m2.5%3Acloud`.
- Provider model id: `minimax-m2.5:cloud`.
- Codex provider: direct Ollama Cloud OpenAI-compatible endpoint at `https://ollama.com/v1` with `OLLAMA_API_KEY`, `pending-runtime`.
- Context window: 200K, `source-verified`.
- Input modalities: text, `source-verified`.
- Tool/function calling: Ollama tags the model with `tools`, `source-verified`, `pending-runtime` for Codex.
- Thinking/reasoning: Ollama tags the model with `thinking`, `source-verified`, `pending-runtime` for Codex reasoning levels.
- Cloud: Ollama tags the model with `cloud`, `source-verified`.
- Codex web search: enabled to match the `gpt-5.2` baseline, `pending-runtime`.
- Notes: Configure as text-only.

## Kimi K2.6

- Source: `https://ollama.com/library/kimi-k2.6`.
- Provider model id: `kimi-k2.6:cloud`.
- Codex provider: direct Ollama Cloud OpenAI-compatible endpoint at `https://ollama.com/v1` with `OLLAMA_API_KEY`, `pending-runtime`.
- Context window: 256K, `source-verified`.
- Input modalities: text and image, `source-verified`, `pending-runtime` for Codex image transport.
- Tool/function calling: Ollama tags the model with `tools`, `source-verified`, `pending-runtime` for Codex.
- Thinking/reasoning: Ollama tags the model with `thinking`, `source-verified`, `pending-runtime` for Codex reasoning levels.
- Cloud: Ollama tags the model with `cloud`, `source-verified`.
- Codex web search: enabled to match the `gpt-5.2` baseline, `pending-runtime`.
- Notes: This is the correct Kimi Ollama Cloud target for this configuration.

## Kimi K2.5

- Source: `https://ollama.com/library/kimi-k2.5`.
- Provider model id: `kimi-k2.5:cloud`.
- Codex provider: direct Ollama Cloud OpenAI-compatible endpoint at `https://ollama.com/v1` with `OLLAMA_API_KEY`, `pending-runtime`.
- Context window: 256K, `source-verified`.
- Input modalities: text and image, `source-verified`, `pending-runtime` for Codex image transport.
- Tool/function calling: Ollama tags the model with `tools`, `source-verified`, `pending-runtime` for Codex.
- Thinking/reasoning: Ollama tags the model with `thinking`, `source-verified`, `pending-runtime` for Codex reasoning levels.
- Cloud: Ollama tags the model with `cloud`, `source-verified`.
- Codex web search: enabled to match the `gpt-5.2` baseline, `pending-runtime`.
- Notes: Configure similarly to K2.6.

## Qwen3-Coder-Next

- Source: `https://ollama.com/library/qwen3-coder-next` and `https://ollama.com/library/qwen3-coder-next%3Acloud`.
- Provider model id: `qwen3-coder-next:cloud`.
- Codex provider: direct Ollama Cloud OpenAI-compatible endpoint at `https://ollama.com/v1` with `OLLAMA_API_KEY`, `pending-runtime`.
- Context window: 256K, `source-verified`.
- Input modalities: text, `source-verified`.
- Tool/function calling: Ollama says tool calling works with coding agents, `source-verified`, `pending-runtime` for Codex.
- Thinking/reasoning: not supported; Ollama describes the model as non-thinking mode only, `source-verified`.
- Cloud: Ollama tags the model with `cloud`, `source-verified`.
- Codex web search: enabled to match the `gpt-5.2` baseline, `pending-runtime`.
- Notes: Do not configure thinking behavior for this model.
