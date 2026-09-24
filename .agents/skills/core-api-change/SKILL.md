---
name: core-api-change
description: Carry a change to the C++ public API in core/ all the way downstream — design check, header edit, six platform implementations, C ABI + Rust/Dart/C# regeneration, per-binding verification, and the commits in core and the workspace. Use this whenever a task adds, renames, removes or reshapes anything in core/src/*.h ("add SetSkipTaskbar to Window", "expose X to Flutter", "new module for Y"), whenever generated bindings are stale or `./codegen check` fails, and whenever the user says "sync the bindings", "regenerate", "propagate core", or asks why an API is missing from Dart / Rust / C#. Also use it before running `./codegen sync` for any reason — the script commits with `git add -A` in core and stages all of bindings/ in the workspace commit, and this skill is the pre-flight that keeps unrelated work out of those commits.
---

# core-api-change

`./codegen sync` does the mechanical half: regenerate, bump each binding's embedded core,
rerun bindgen / ffigen, commit core and the workspace. This skill is the other half — the decisions
and checks the script cannot make. Work through the phases in order; each one ends in
something you can verify before moving on.

```
1 design  →  2 pre-flight  →  3 core edit  →  4 regenerate + read the output
          →  5 hand-written layers  →  6 verify  →  7 commit  →  8 report
```

## 1. Design the signature first

Read [specs/api-style.md](../../../specs/api-style.md) and run its checklist against the
signature **before** writing any platform code — a signature that changes after six
platform files exist is six files of rework. For a new type also read
`specs/object-model.md` (identity vs value object); for a new module,
`specs/architecture.md` §5.

Where neighbouring headers disagree, the spec says which side is the rule. Do not copy
the nearest neighbour.

## 2. Pre-flight: look before the script commits

`./codegen sync` runs `git add -A` in core and `git add bindings/<lang>` in the workspace,
where all three bindings live. Anything lying around in those trees lands in a commit
titled `Sync with core <sha>`.

```bash
make status                                   # dirty files + branch of every submodule
git status --short                            # workspace itself
for r in core; do
  printf '%-18s %s  behind origin/main: %s\n' "$r" \
    "$(git -C "$r" branch --show-current || echo DETACHED)" \
    "$(git -C "$r" rev-list --count HEAD..origin/main 2>/dev/null)"
done
```

- **A binding is dirty with unrelated work** (`git status --short bindings/`)
  → do not run `sync`. Use the manual
  path in §7. Ask the user only if you cannot tell whether the work is related.
- **A submodule is on a detached HEAD or behind `origin/main`** → check out `main` and
  fast-forward first. `sync` refuses detached HEADs, but it does not notice "on main,
  10 commits behind", and committing there moves the workspace pointer backwards.
- **core is dirty with files that are not part of this change** → stage narrowly and
  commit core yourself before `sync` (it only commits core when core is dirty).

## 3. Edit core

1. Header in `core/src/<module>.h`, with the Doxygen block and — when behaviour differs
   per platform — the six-line `@note Platform availability:` block.
2. **All six** `core/src/platform/<os>/<module>_<os>.{cpp,mm}`. A platform that cannot
   support it still gets a stub (no-op / `false` / default value); a missing definition
   is a link error on that platform only, which you will not see locally.
3. New handle type → append an `IdTypeTag<T>` entry in
   `core/src/foundation/id_allocator.h`. Append only, never renumber.
4. New header that should cross the ABI → add it to `API_HEADERS` in
   `tools/codegen/shared/src/lib.rs` (kept roughly in dependency order for
   readability; the generator does not depend on it). If a hand-written file of the
   same name already exists in a binding, the generator skips it — delete it first.
5. Build what you can locally:

```bash
cmake -S core -B core/build && cmake --build core/build -j
ctest --test-dir core/build --output-on-failure
```

Only the host platform compiles here. Say so in the report; for the others use the
`remote-hosts` skill or let CI answer.

## 4. Regenerate, then read the output

```bash
./codegen 2>&1 | tee /tmp/codegen.log     # C ABI, then Rust / Dart / C#
grep -i 'skipped' /tmp/codegen.log
```

The `skipped` lines are the point of this step. A method whose signature uses a type the
generator cannot map is **dropped with a warning, not an error** — the build stays green
and the API is simply absent from every binding. Known baseline (2026-09-17, 8 lines):
three `ModifierKey` operators, `RunApp`, class `Dialog`,
`PositioningStrategy::GetRelativeWindow`, `Shortcut::GetCallback`,
`KeyboardMonitor::GetInternalEventEmitter`. Any line naming your new API means: go back
to §1 and change the signature (api-style.md §7 lists what crosses the bridge).

Then read the generated C header for your module (`core/src/capi/<module>_c.h`):

- Does the function name read well? An unexpected `_with_<param>` suffix means you
  added an overload — rename instead (api-style.md §1.6).
- Did the getter become a property in the bindings? It only does when it is `const`,
  takes no arguments and starts with `Get` / `Is` / `Has`.
- For events: every payload field you expect is in the C struct. Fields come from
  `GetXxx() const` on the event class; unsupported types vanish silently.

Never edit a file that starts with `// AUTO-GENERATED. DO NOT EDIT.` — change the header
or the generator and rerun.

## 5. Hand-written layers the generator does not touch

Files without the banner are never overwritten, so they are also never updated:

| Repo | Hand-written | When to touch it |
|---|---|---|
| `bindings/flutter` | `packages/nativeapi/lib/nativeapi.dart` (exports), `lib/src/widgets/`, `CHANGELOG.md`, examples | new module → add the export; user-visible change → CHANGELOG entry |
| `bindings/rust` | `crates/nativeapi/src/lib.rs`, examples | `modules.rs` is generated now, so a new module needs no manual `pub mod`; re-exports in `lib.rs` still do |
| `bindings/csharp` | examples, tests | when a rename breaks them |
| core | `examples/<module>_example/`, `<module>_c_example/` | new module or a behaviour worth demonstrating |

A rename or removal in core breaks hand-written callers in these places — grep each
binding for the old name.

## 6. Verify each binding

```bash
./codegen check                                         # generated files are current
(cd bindings/rust && cargo check --workspace)
(cd bindings/flutter/packages/nativeapi && dart analyze)
(cd bindings/csharp && dotnet build NativeAPI.slnx)
```

`flutter analyze` may rewrite `packages/nativeapi/analysis_options.yaml` — revert that
before committing. A toolchain that is not installed is a skipped check, not a passed
one; list it as skipped in the report.

For anything with visible behaviour, run the relevant example through the `gui-test`
skill rather than trusting the compile.

## 7. Commit

**Clean trees (the normal case):**

```bash
./codegen sync -m "<imperative core commit message>"
```

It commits core with your message, then the workspace as `Sync with core <sha9>`: the
core pointer plus everything regenerated under `bindings/` and each binding's `cxx_impl`
gitlink. It does not push.

**A binding has unrelated work — manual path.** Same steps, staged narrowly:

1. Commit core yourself (`git -C core add <paths> && git -C core commit -m ...`).
2. In each binding: update the embedded core submodule (`cxx_impl`) to that sha,
   fetching from the local `core/`; rust → rerun bindgen (command in
   `tools/codegen/README.md`); flutter → `python3 codegen.py --no-submodule-update` in
   `packages/cnativeapi`.
3. Workspace: `git add core` plus only the generated paths and the `cxx_impl` gitlinks
   under `bindings/`; commit as `Sync with core <sha9>`.

Either way: no Co-Authored-By trailers; after staging, read `git status --short` and
`git diff --cached --stat` in each repo **before** committing — a file you did not write
showing up there is the signal to stop and unstage.

Push only when asked, and in this order so no remote pointer dangles:
core → workspace (`./codegen sync --push` does exactly this).

## 8. Report

State, per item, what is true rather than what was attempted:

- the new / changed signatures, and any api-style rule you consciously bent and why;
- platforms: compiled locally / compiled remotely / stub only / untested;
- `skipped` lines: none new, or which;
- per binding: regenerated, hand-written parts updated, check passed / skipped;
- commits created (repo + sha) and whether anything is pushed;
- anything left dirty in a working tree that you deliberately did not commit.
