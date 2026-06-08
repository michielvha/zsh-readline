# zsh-readline tests

Three layers, per [docs/testing-strategy.md](../docs/testing-strategy.md):

| Layer | What | Needs |
|-------|------|-------|
| 1 — unit | prediction logic + (PR #4) message helpers | zsh only |
| 2 — render | real interactive zsh in tmux, screen snapshots | tmux, git |
| 3 — CI | runs 1+2 on Ubuntu/macOS | GitHub Actions |

## Run

```sh
# unit tests (fast, no deps) against the repo plugin
zsh tests/run.zsh unit

# provision tmux + vendored co-plugins (once)
zsh tests/bootstrap.zsh

# render snapshot tests
zsh tests/run.zsh render

# everything
zsh tests/run.zsh all
```

### Test a different build (e.g. a PR)

```sh
git fetch origin pull/4/head:pr-4
git show pr-4:zsh-readline.plugin.zsh > /tmp/pr4.zsh

ZSH_READLINE_PLUGIN=/tmp/pr4.zsh zsh tests/run.zsh unit
RENDER_TAG=pr4 ZSH_READLINE_PLUGIN=/tmp/pr4.zsh zsh tests/run.zsh render
```

Render snapshots are written to `tests/render/snapshots/<tag>/` for diffing.

## Layout

```
tests/
  lib/assert.zsh          # assertions + summary
  lib/history_mock.zsh    # shadows `fc` with a fixed fixture (unit only)
  fixtures/history.txt    # deterministic history
  fixtures/prompts/       # vendored prompts incl. hooky.zsh-theme (bug repro)
  unit/                   # Layer 1
  render/lib.zsh          # tmux driver helpers
  render/run_render.zsh   # Layer 2 scenarios
  bootstrap.zsh           # Layer 0 provisioning
  run.zsh                 # entry point
```

## What the suite found (main vs PR #4)

Run on 2026-06-08, zsh 5.9 + tmux 3.6b:

- **Prediction logic** — identical on `main` and PR #4 (10/10 assertions each).
  The PR changes nothing here.
- **A1 — hook clobbering (`render_run` scenario A):** with a theme that installs
  its own `zle-line-init`, the theme hook fired **0×** on `main` (clobbered) and
  **2×** on PR #4 (preserved). The PR's `add-zle-hook-widget` change is the real
  fix and is **proven necessary**.
- **A2 — padding/residue (scenario C):** shrinking the list from 7 rows to 1 left
  **no stale rows on either build**; the snapshots are byte-identical. Plain
  `zle -M` already cleans up, so the PR's padding machinery is **not needed** to
  prevent residue.

> The render layer's A1 assertion fails on current `main` *by design* — it
> documents the bug. It turns green once the hook fix is merged (see the
> `continue-on-error` note in `.github/workflows/test.yml`).
