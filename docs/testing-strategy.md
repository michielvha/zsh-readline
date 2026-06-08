# Testing Strategy — zsh-readline

**Status:** spec / proposal. Nothing here is built yet. This document is the plan
we agree on *before* writing any test code.

## Why

The plugin has **zero automated tests**. "Does it render correctly?" is currently
answered by one person looking at one terminal — which is exactly how the display
bug behind [PR #4](pr-4-review.md) shipped (it clobbered the theme's
`zle-line-init` hook and nobody noticed until a contributor on a different
theme/terminal hit it).

We want to answer two questions mechanically and repeatably:

1. **Logic:** given a history, does prediction matching produce the right list?
2. **Rendering:** across a matrix of themes × co-plugins × zsh versions, does the
   list draw in the right place, mark the right row, leave the prompt intact, and
   clean up — *without* corrupting the display?

A concrete near-term use: run the matrix against **current `main`** and against
**the PR #4 branch** to settle the open questions in the review — does the
`add-zle-hook-widget` fix actually restore theme hooks, and does the A2 padding
mechanism change anything observable, or is it a no-op we can drop?

## Non-goals

- Not testing zsh's own ZLE/`zle -M` internals — we trust the shell.
- Not pixel/font/color-accurate rendering — we assert on the **text grid** (cells,
  positions, the `>` marker), not on truecolor output.
- Not a benchmark suite (performance is tracked separately).

---

## Layer 0 — Prerequisites & provisioning

The dev box this was scoped on runs **zsh 5.9** but has **no tmux**, **no
oh-my-zsh**, and **no powerlevel10k**. The harness must therefore *provision its
own* dependencies into a throwaway location rather than assume a configured
machine, so it runs identically locally and in CI.

- **tmux** — required for Layer 2 (primary render method). Install via the
  platform package manager (`brew install tmux` / `apt-get install tmux`). If
  absent, Layer 2 skips with a clear message and Layer 1 + the zpty fallback
  still run.
- **Themes** — do **not** depend on a user's `~/.oh-my-zsh`. Vendor the few
  prompt definitions we test into `tests/fixtures/prompts/` (a `.zsh-theme` is
  just a file that sets `PROMPT`/`precmd`/hooks). This keeps tests hermetic and
  lets us include a "theme that installs its own `zle-line-init`" — the exact
  shape that reproduces the PR #4 bug — without pulling in all of oh-my-zsh.
- **Co-plugins** (`zsh-autosuggestions`, `zsh-syntax-highlighting`) — pin to a
  commit and clone into a cached `tests/.vendor/` dir on first run; never read
  the developer's installed copy.
- Everything runs under `zsh -f` (no user `.zshrc`/`.zshenv`) with a generated rc,
  so the developer's real environment can never leak into or break a test.

---

## Layer 1 — Unit tests (pure logic, no TTY)

Fast, deterministic, run on every commit. Target functions that don't need a live
line editor:

| Function | What we assert |
|----------|----------------|
| `_zsh_readline_get_predictions` | prefix match; case-insensitivity; de-duplication; `ZSH_READLINE_MAX_PREDICTIONS` cap; exact-match exclusion; empty / below-`MIN_INPUT` input returns nothing; whitespace handling |
| `_zsh_readline__count_lines` *(PR #4)* | 0 for empty, N for N-line strings, trailing-newline edge case |
| `_zsh_readline__set_message` padding math *(PR #4)* | shrinking list pads to previous height; growing list doesn't over-pad; pins the intended behavior of the `cur_lines` assignment (the masked `$`-missing bug from the review) |

**History fixture:** a fixed `tests/fixtures/history.txt` loaded into a private
`HISTFILE` via `fc -p` so `fc -l` returns a known, ordered set. No dependence on
the developer's real history.

**Runner:** plain `zsh` assertion scripts to start (a tiny `assert_eq` helper).
Adopt [zunit](https://github.com/zunit-zsh/zunit) only if the suite grows enough
to justify it — it itself wraps `zpty`, so it's compatible with Layer 2.

---

## Layer 2 — Headless render snapshots (the core of "renders correctly")

Drive a **real interactive zsh** and snapshot the **rendered screen**, then diff
against a committed golden file. This is the layer that catches display
corruption — the class of bug PR #4 is about.

**Primary method — tmux `capture-pane`:**

1. Start a detached tmux session at a **fixed size** (80×24) so snapshots are
   stable.
2. Inside it, launch `zsh -f` with a **generated rc** that sources: the plugin
   under test, one vendored prompt/theme, the selected co-plugins, and the seeded
   history fixture.
3. `tmux send-keys` types a **scripted sequence** per scenario, e.g.
   `git ` → wait → `Down` `Down` → capture → `Enter` → capture.
4. `tmux capture-pane -p` dumps the visible cell grid as plain text → compare to
   `tests/render/golden/<scenario>.txt`.

tmux is the primary because it *is* a terminal emulator: it resolves all the
escape sequences for us and yields clean, human-diffable text. A failing
snapshot shows a readable before/after diff.

**Assertions per scenario:**
- the prediction list appears below the command line (right row range);
- the `>` marker sits on the expected row after each navigation key;
- the prompt / theme line is **intact** — not duplicated, not overwritten, no
  leftover fragments;
- after `Enter`, the list is **gone** and no blank-line residue remains
  (the direct test of whether A2 padding helps or hurts);
- typing then deleting back to a shorter list leaves no stale rows.

**Secondary method — `zpty` (zsh built-in, zero deps):** spawn zsh in a
pseudo-terminal and capture the **raw** byte stream. Used (a) where tmux isn't
available, and (b) to assert the plugin emits *no* stray escape sequences of its
own (it shouldn't — it's pure `zle -M`). Assertions here are on raw bytes, so it's
a complement to, not a replacement for, the tmux snapshots.

### The matrix ("mock against multiple things")

Each cell = one generated rc + one keystroke script + one golden file.

- **Prompts/themes:** single-line (robbyrussell-style) · multi-line · a prompt
  that **installs its own `zle-line-init`/`line-finish`** (PR #4 repro) ·
  powerlevel10k (vendored).
- **Co-plugins:** none · `zsh-autosuggestions` · `zsh-syntax-highlighting` · both.
- **Plugin version under test:** `main` vs the **PR #4 branch** — same scenarios,
  two checkouts, diff the goldens. This is how we make the merge decision with
  evidence instead of opinion.

Not every combination needs a golden; we curate a representative set (~8–12
scenarios) rather than the full cartesian product, and `log`/note which
combinations are intentionally skipped.

---

## Layer 3 — CI matrix (GitHub Actions)

Run Layers 1–2 in CI so regressions can't merge.

- **zsh versions:** 5.3 (the `add-zle-hook-widget` floor), 5.8, 5.9 — via Docker
  images or `setup` actions.
- **OS:** ubuntu-latest + macos-latest (the plugin's two real audiences;
  iTerm2/macOS is where PR #4 surfaced).
- Snapshot mismatches **fail the build**. Updating a golden is a deliberate,
  reviewed commit (`UPDATE_GOLDENS=1` regenerates them locally).
- tmux/zsh/co-plugins are installed in the job; nothing depends on a preconfigured
  developer machine (see Layer 0).

---

## Proposed repo layout

```
tests/
  lib/assert.zsh                 # tiny assertion + harness helpers
  fixtures/
    history.txt                  # seeded, deterministic history
    prompts/                     # vendored theme/prompt defs (incl. the zle-hook repro)
  rc/                            # generated per-scenario rc files (or a generator)
  unit/                          # Layer 1 specs
  render/
    driver.zsh                   # tmux send-keys + capture-pane driver
    scenarios/                   # keystroke scripts + scenario manifest
    golden/                      # committed snapshots
  .vendor/                       # cloned, pinned co-plugins (gitignored)
.github/workflows/test.yml       # Layer 3
```

---

## Open questions this framework will answer

1. Does `zle -M` already clear a shrinking message, making PR #4's A2 padding a
   no-op (drop it) — or is there a real residue artifact it fixes (keep a
   corrected version)?
2. Does the `add-zle-hook-widget` change (A1) demonstrably preserve a theme's own
   `zle-line-init` hook where the current `zle -N` approach destroys it?
3. Any difference in behavior between zsh 5.3 and 5.9 worth documenting as a
   minimum-version note in the README?

## Sequencing (once this spec is approved)

1. Layer 1 + the history fixture (fastest payoff, no provisioning).
2. Layer 0 provisioning + Layer 2 driver with **one** scenario end-to-end.
3. Expand the Layer 2 matrix; capture `main`-vs-PR#4 goldens.
4. Wire up Layer 3 CI.
5. Use the results to finalize the PR #4 review and the response to the
   contributor.
