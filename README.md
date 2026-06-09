# Codex Configuration

This repository builds a portable Codex CLI home directory for OpenAI GPT-5.5 plus DeepSeek and selected Ollama Cloud coding models.

**Requires Codex CLI 0.134.0 or later** (profiles use the `<name>.config.toml` format introduced in 0.134.0).

Configured profiles:

- `gpt-5-5`
- `deepseek-v4-pro`
- `deepseek-v4-flash`
- `ollama-cloud-deepseek-v4-pro`
- `ollama-cloud-deepseek-v4-flash`
- `ollama-cloud-glm-5-1`
- `ollama-cloud-glm-5`
- `ollama-cloud-minimax-m2-7`
- `ollama-cloud-minimax-m2-5`
- `ollama-cloud-kimi-k2-6`
- `ollama-cloud-kimi-k2-5`
- `ollama-cloud-qwen3-coder-next`

## Requirements

- Codex CLI >= 0.134.0
- Bash
- `jq`

## Authentication

For OpenAI GPT-5.5, run:

```bash
codex login
```

### DeepSeek

DeepSeek models require [Moon Bridge](https://github.com/ZhiYi-R/moon-bridge) running locally. Codex uses the Responses API exclusively; Moon Bridge translates to DeepSeek's Chat Completions API.

1. Install and start Moon Bridge (default: `http://127.0.0.1:38440`)
2. Configure your DeepSeek API key in Moon Bridge's `config.yml`
3. Run:

```bash
codex --profile deepseek-v4-pro
codex --profile deepseek-v4-flash
```

### Ollama Cloud

For Ollama Cloud models, create an API key from ollama.com and set:

```bash
export OLLAMA_API_KEY="..."
```

This configuration talks directly to Ollama Cloud at `https://ollama.com/v1`; it does not require a local Ollama server proxy.

## Wire API Compatibility

Codex CLI uses the **Responses API** (`/v1/responses`) exclusively. The older Chat Completions API (`/v1/chat/completions`) is no longer supported.

| Provider | API supported | Works with Codex? | Bridge required? |
|---|---|---|---|
| OpenAI | Responses | Yes | No |
| Ollama Cloud | Responses (v0.13.3+) | Yes | No |
| DeepSeek | Chat Completions only | **No** | Yes — use [Moon Bridge](https://github.com/ZhiYi-R/moon-bridge) |

Moon Bridge is a Go-based proxy that translates Codex Responses API calls into DeepSeek Chat Completions API calls.

## Validate

```bash
scripts/validate.sh
```

## Install

The installer deletes and recreates `~/.codex`. It backs up the existing directory by default.

Preview changes:

```bash
./install.sh --dry-run
```

Install:

```bash
./install.sh
```

Skip the confirmation prompt:

```bash
./install.sh --yes
```

Skip the backup only when you intentionally do not need the current `~/.codex`:

```bash
./install.sh --yes --no-backup
```

## Usage

```bash
codex --profile gpt-5-5
codex --profile deepseek-v4-pro
codex --profile deepseek-v4-flash
codex --profile ollama-cloud-deepseek-v4-pro
codex --profile ollama-cloud-deepseek-v4-flash
codex --profile ollama-cloud-glm-5-1
codex --profile ollama-cloud-glm-5
codex --profile ollama-cloud-minimax-m2-7
codex --profile ollama-cloud-minimax-m2-5
codex --profile ollama-cloud-kimi-k2-6
codex --profile ollama-cloud-kimi-k2-5
codex --profile ollama-cloud-qwen3-coder-next
```

## Profile Files

Each profile is a separate `<name>.config.toml` file in the `profiles/` directory. These are copied to `~/.codex/<name>.config.toml` during installation. Profile files only contain values that differ from the base `config.toml`.

## Restore Backup

If install created a backup such as `~/.codex.backup.20260421-153000`, restore it with:

```bash
rm -rf ~/.codex
mv ~/.codex.backup.20260421-153000 ~/.codex
```

## Model Capabilities

Model capability sources and runtime verification status are tracked in `docs/model-capabilities.md`.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

Copyright (c) 2026-present Douglas Hoard
