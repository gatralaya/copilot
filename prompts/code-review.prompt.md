---
agent: 'reviewer'
description: 'Review a module, diff, or PR against this repo module-boundary and architecture rules. Trigger: user says "review module X", "review the index module", "code review", "check architecture", etc.'
---

Review the module `${input:module:Which module to review? (folder name under modules/, or leave empty for working tree diff)}` against the repository rules in `.github/copilot-instructions.md`.

If a module name is provided, read all files in `modules/<module>/` and review them holistically.
If a specific range is selected (`${selection}`), review that range instead.
Otherwise, review the working tree diff.

Check specifically for:

1. **Module boundary violations** — any file in `modules/<feature-a>/` importing directly
   from `modules/<feature-b>/`'s Go package or TS files. Flag it even if it "would work".
2. **Misplaced shared code** — a component added to root `components/` or logic added to
   `core/` that is actually only used by one feature. It should live inside that feature's
   `modules/<feature>/` folder instead.
3. **New modules that skip the standard shape** — a new `modules/<feature>/` folder missing
   `module.go` (route registration) or mixing multiple unrelated features into one folder.
4. **Frontend calling the backend directly** — any `.tsx`/`.ts` file outside `api.ts` calling
   `fetch()` against this feature's own route. All calls should go through that feature's
   `api.ts`.
5. **Go conventions** — unwrapped errors (missing `%w`), global state instead of constructor
   injection, missing table-driven tests for new logic.
6. **Frontend conventions** — `any` types, class components, missing prop types.

Output format:

- Group findings by severity: **Must fix** (breaks module boundary rules) vs **Suggestion**
  (style/convention).
- For each finding: file path, one-line explanation, and a concrete fix — not just "this is
  wrong".
- If nothing violates the rules, say so explicitly rather than inventing nitpicks.
