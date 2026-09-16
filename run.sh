#!/usr/bin/env bash
# Launch Acheron with DISCORD_TOKEN sourced from OpenClaw's env-kind store.
# The bot's load_dotenv() will not find DISCORD_TOKEN in .env because we
# zero it out there; this wrapper puts the value into the process
# environment before exec'ing Python.
set -euo pipefail

cd "$(dirname "$0")"

TOKEN_VALUE="$(PATH="$HOME/.openclaw/tmp/agent-cli:$PATH" openclaw secrets store get DISCORD_TOKEN --plain)"

if [[ -z "${TOKEN_VALUE:-}" ]]; then
  echo "run.sh: DISCORD_TOKEN missing from OpenClaw store" >&2
  exit 1
fi

export DISCORD_TOKEN="${TOKEN_VALUE}"
unset TOKEN_VALUE

exec ./venv/bin/python src/discord_bot.py
