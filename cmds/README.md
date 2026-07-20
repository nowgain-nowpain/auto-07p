# `cmds/` — DEPRECATED legacy `@`-command scripts

The `@`-prefixed shell scripts in this directory are **deprecated** and will be
removed in a future release (refactor-plan.md W3). Each now prints a deprecation
notice on stderr when run. They are thin wrappers with direct equivalents in the
`auto` CLI and the Python command API — use those instead.

## Use instead

Interactively (the `auto` CLI) or in a Python script:

```python
r = run(e='ab', c='ab')     # was: @r ab
save(r, 'ab')               # was: @sv ab
r2 = load('ab')             # was: @lb ab
```

Common mappings (see the AUTO manual, `doc/auto.tex`, for the full list):

| legacy `@`-command | Python / `auto` command |
|---|---|
| `@r`   | `run(...)`            |
| `@R`   | `run(<restart>, ...)` |
| `@sv`  | `save(...)`           |
| `@ap`  | `append(...)`         |
| `@lb`  | `load(...)` / `relabel(...)` |
| `@cp`  | `copy(...)`           |
| `@mv`  | `move(...)`           |
| `@dl`  | `delete(...)`         |
| `@cl`  | `clean()`             |
| `@p` / `@pp` | `plot(...)` / PyPLAUT |

## Not deprecated: `cmds.make`

`cmds.make` (generated from `cmds.make.in` by `./configure`) is **retained**: it
is still the source of the CLI's build configuration (compiler and flags read by
[python/auto/runAUTO.py](../python/auto/runAUTO.py)). Retiring it is a separate
build-config migration (W3 steps 3/5), gated on moving the CLI's compile/link off
the `lib/*.o` glob to the installed `libauto` (W5) — not part of obsoleting the
`@`-scripts.
