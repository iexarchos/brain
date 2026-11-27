You are reviewing the brain system (this engine repo; the owner's notes are in `data/`) for ways to improve it. Read `ARCHITECTURE.md`
and `infra/` first, so you know the current design and why it was chosen. Then answer the three
questions below, using the host facts at the end of this prompt and current sources from the web.

## Questions

1. **Models.** Are the agents (Claude Code, Codex, Hindsight's fact extraction, the council) on the
   latest models, or is anything obsolete, deprecated, or scheduled for retirement? Compare the
   models that are pinned and the models seen in recent sessions with the vendors' current
   lineups (Anthropic's models overview, OpenAI's Codex models page). Are any of the installed
   CLIs or Hindsight behind their latest release, and does the newer release matter here?
2. **Memory and context management.** Has anything appeared recently (releases, papers,
   benchmarks, features built into Claude Code, Codex or Hindsight) that suggests the current
   design should change? The current design is Markdown notes in git as the source of truth, plus
   Hindsight as a derived index with recall injected per session. Judge the evidence on its
   merits: vendor benchmarks and single preprints count as weak evidence. "Still current, nothing
   to change" is a valid answer.
3. **Efficiency.** Are there features, flags or settings (CLI options, Hindsight settings, host
   or service configuration) that would save RAM, time, tokens or subscription quota and aren't
   used yet? Do the host facts show waste or risk (swap pressure, OOM kills, restarts, auth
   warnings, failed runs)?

## Constraints any recommendation must respect

- No pay-per-token APIs: all model use goes through subscription CLIs.
- The host has 1 vCPU and 1 GB RAM with 2 GB swap; no local LLMs or heavy runtimes.
- Self-hosted and private: no new cloud services that receive personal data.
- Markdown notes stay the source of truth.

## Rules

- Verify before claiming: every version, model name, release, or paper you cite must come from a
  source you actually opened this run, linked inline. If you couldn't verify something, say so.
- Check facts about this host against the host facts or the repo, not memory.
- Read-only: don't edit files, run services, or make commits. Just write the report.
- Last week's report is included below (if there is one). Report what is **new or changed** since
  then, and recommendations from it that are still open and still matter. Don't repeat settled
  items at length.

## Output

Markdown only, no preamble. If there is nothing new and nothing open worth action, output exactly
`NO_CHANGES` as the first line, followed by one sentence saying what you checked.

Otherwise:

```
## Summary
One to three sentences: the most important finding and what to do about it.

## Recommendations
A table ranked by value: # | Recommendation | Why (evidence, with links) | Effort (S/M/L) | Risk.
At most 7 rows. Each recommendation is a concrete action (a command, a config line, a file to change).

## 1. Models
## 2. Memory and context management
## 3. Efficiency
Short findings for each, with links. Mark each item **new**, **still open**, or **resolved**.

## Sources
```
