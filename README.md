# Codex Configuration

This repository builds a portable Codex CLI home directory for OpenAI GPT-5.5, GPT-5.4, GPT-5.3-Codex, and GPT-5.2 plus selected Ollama Cloud coding models.

Configured profiles:

- `gpt-5.5`
- `gpt-5.4`
- `gpt-5.3-codex`
- `gpt-5.2`
- `ollama-cloud-glm-5.1`
- `ollama-cloud-glm-5`
- `ollama-cloud-minimax-m2.7`
- `ollama-cloud-minimax-m2.5`
- `ollama-cloud-kimi-k2.6`
- `ollama-cloud-kimi-k2.5`
- `ollama-cloud-qwen3-coder-next`

## Requirements

- Codex CLI
- Bash
- `jq`

## Authentication

For OpenAI GPT-5.2, run:

```bash
codex login
```

For Ollama Cloud models, create an API key from ollama.com and set:

```bash
export OLLAMA_API_KEY="..."
```

This configuration talks directly to Ollama Cloud at `https://ollama.com/v1`; it does not require a local Ollama server proxy.

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
codex --profile gpt-5.5
codex --profile gpt-5.4
codex --profile gpt-5.3-codex
codex --profile gpt-5.2
codex --profile ollama-cloud-glm-5.1
codex --profile ollama-cloud-glm-5
codex --profile ollama-cloud-minimax-m2.7
codex --profile ollama-cloud-minimax-m2.5
codex --profile ollama-cloud-kimi-k2.6
codex --profile ollama-cloud-kimi-k2.5
codex --profile ollama-cloud-qwen3-coder-next
```

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
