# Acheron

> *"The sun has set, and the river flows. Welcome to the deep hours."*

## Status
✅ Deployed and Running via systemd

## Quick Links
- **Repo:** `daddyclint82/acheron`
- **Location:** `/home/daddyclint82/.openclaw/workspace/acheron/`
- **Started:** 2026-05-12 (as *DaddyClintBot*; rebranded to *Acheron* on 2026-09-15)

## Description

**Acheron** is a locally-hosted Discord bot: the official terminal of **The No Sleep Zone**, named after the underworld's river of shadows. When the rest of the world goes dark, Acheron keeps the mainframe alive — watching the server, reading the room, and helping lost members find their way through the deep hours.

In its own words:

> 🌌 **SYSTEM STATUS: INSOMNIA ENFORCED** · ⚡ **NOCTURNAL PROTOCOLS ACTIVE**
> I monitor the server when the rest of the world goes dark.
> *Guardian of the Deep Hours // Keeping the mainframe alive while you outrun sleep.*

## What Acheron Does

| Capability | What it looks like |
|---|---|
| **Server Help** | Asks in chat → Acheron points to the right channel, quotes the rules, knows who's a mod. |
| **Proactive Watch** | Quietly scores channel activity. Jumps into a thread when someone is frustrated, celebrating, or vulnerable — but with cooldowns and a dry-run mode so it never spams. |
| **Catch-up / News** | `!news` → grouped, channel-by-channel digest of what you missed, written in voice. |
| **Vibe Report** | `!vibe` → aggregate mood per channel; owner gets the full picture (names, quotes, watch-outs). |
| **Stats** | `!stats` → hard numbers: messages, active channels, joins, busiest channels, top contributors (owner-only). |
| **On-Demand Snapshot** | `!snapshot` → pull-only server awareness with an AI-written read of the room. Privacy-respecting: aggregates only, never stores message content. |
| **Memory** | Remembers traits and unresolved threads per user. `!forgetme` wipes everything Acheron knows about you. |
| **Local LLM** | Runs against an **Ollama** server — local or remote. Default model is `minimax-m3:cloud` (reasoning-capable, 196k context). The `Modelfile` defines `qwen3.5:4b` as an alternative. Configure via `OLLAMA_HOST` and `OLLAMA_MODEL` in `.env`. |

## Architecture

### Components

| Component | Purpose |
|---|---|
| **Discord Client** | `discord.py` wrapper. Listens for messages, reactions, guild events. Handles proactive-engagement scoring, command dispatch, and four background tasks (presence refresh, server-intel refresh, daily DB prune, Ollama watchdog). |
| **Engagement Engine** | `agent.py`: SQLite memory + VADER sentiment + regex intent router (`chat` / `help` / `news` / `vibe`) + hardened async Ollama client with retries and in-character fallbacks. |
| **Snapshot Engine** | `src/snapshot/`: on-demand server awareness — collects per-channel activity + sentiment, renders an embed, summarizes with the local model. Cached for 5 min, owner-gated for high-detail views. |
| **Prompt Builder** | Compact, intent-aware system prompts sized for small models. Owner gets a different scope than regulars on vibe reports. |
| **Response Humanizer** | Texting-style post-processing: trims trailing periods, injects one sentiment-matched emoji, occasionally swaps adjacent characters for realism. |
| **Data Persistence** | SQLite (WAL mode). Auto-pruned: channel activity 72h, message log 30d. |

### Data Flow

1. Discord event triggers (message, reaction, join, command).
2. Engine classifies intent (`chat` / `help` / `news` / `vibe`) and runs sentiment analysis.
3. Compact system prompt + recent history + user message → local Ollama.
4. Response humanized, sent back to Discord.
5. Activity logged to SQLite for `!news` / `!vibe` / `!stats` / `!snapshot`.

### Resilience

- Ollama client runs sync `client.chat()` in a `ThreadPoolExecutor` with a hard `asyncio.wait_for` timeout. Retries with exponential backoff. Returns a randomized in-character fallback if the LLM is down — **never raises**.
- One broken event handler cannot kill the loop (`on_error` swallows everything).
- Fatal errors rebuild the bot instance and reconnect with capped backoff (a closed `Client` can't be reused).
- SIGTERM handled for clean systemd stops.
- Ollama up/down transitions are logged by a watchdog so outages are visible.
- An Ollama outage means Acheron uses fallback replies until the model returns.

### Key Design Decisions

- **Local LLM:** No external API calls. Privacy and zero-cost inference.
- **Systemd service:** Runs as persistent background service.
- **SQLite (WAL):** Zero-config local persistence; crash-safe under load.
- **Small-model-aware prompts:** Long instruction-dump prompts confuse small models; prompts are short, concrete, and lead with the persona.
- **Privacy boundary:** `!snapshot` aggregates only. Message content is scored and immediately discarded. `!vibe` differentiates owner scope (names + quotes) from public scope (aggregates only).

### Tech Stack

- Python 3.12 / `discord.py` 2.7
- Ollama (local or remote LLM server; default model `minimax-m3:cloud`)
- `vaderSentiment` (sentiment scoring)
- `aiohttp` (async HTTP), `numpy` (Poisson delays, CLI mode only)
- SQLite (data persistence, WAL mode)
- Systemd (service management)

## Owner Mode — `#thinkhard`

Per-user override of LLM `num_predict` (token budget). Owner-only opt-in.

- `#thinkhard` → 1000 tokens for this user
- `#thinkhard 1500` → custom budget (100–4000)
- `#thinkhard off` → reset to owner default

State is per-user, lives in memory, resets on bot restart. Use when you want the full direct answer instead of the usual short reply.

## Commands

| Command | Aliases | What it does |
|---|---|---|
| `!status` | — | Bot status (engine, latency, guilds). |
| `!health` | — | Deep health: Ollama, DB, uptime, gen counts, last latency, 24h activity. |
| `!news` | `!catchup`, `!recap` | Catch-up digest of recent server activity. |
| `!vibe` | `!vibecheck`, `!vibereport`, `!pulse` | Vibe report. Owner gets the full picture; regulars get a light aggregate. |
| `!stats` | — | Hard numbers: messages, busiest channels, top contributors (owner-only). |
| `!snapshot` | `!snap`, `!whatsgoingon` | On-demand server awareness. `!snapshot hours:24`, `!snapshot channels:general`, `!snapshot detail:high`, `!snap fresh`. |
| `!channels` | — | Server channel map. |
| `!persona` | — | Who Acheron is. |
| `!forgetme` | — | Wipe everything Acheron remembers about you. |
| `!reloadknowledge` | — | Owner only. Reload server guide + re-gather rules/pins from Discord. |
| `!proactive` | — | Show proactive engagement status (threshold, cooldowns, allow/block lists). |

## Getting Started

```bash
# Start the bot
sudo systemctl start acheron

# Check status
sudo systemctl status acheron
```

---

*Project details maintained by Clint. Last updated: 2026-09-15 (rebranded from DaddyClintBot).*
