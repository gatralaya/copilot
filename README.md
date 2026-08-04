# .copilot — Shared AI Agent Config

> **Single source of truth** for AI agent definitions, skills, prompts, and instructions across multiple repos.

This is a **git submodule** used by [Flow](https://github.com/ynwd/flow) and other repos that share the same AI-native development workflow.

## Structure

```
.
├── copilot-instructions.md   # Entry point — routing rules, triggers, agent table
├── guardrails.md             # Security, operational, and architecture rules
├── architecture.md           # Project structure diagram
├── PULL_REQUEST_TEMPLATE.md  # PR checklist
│
├── agents/                   # Agent definitions (.agent.md)
│   ├── orchestrator.agent.md     # Entry point — task queue, dispatch
│   ├── implementer.agent.md      # Full-stack router → BE/FE
│   ├── implementer-be.agent.md   # Backend Go specialist
│   ├── implementer-fe.agent.md   # Frontend React/TS specialist
│   ├── reviewer.agent.md         # Code review, boundary checks
│   ├── analyst.agent.md          # Requirements analysis, spec authoring
│   └── planner.agent.md          # Manual-only — large user stories
│
├── instructions/             # Modular reference docs
│   ├── architecture.md           # Module registration, boundaries, conventions
│   ├── task-orchestration.md     # Queue flow, self-healing, checkpoints
│   ├── feature-workflow.md       # Dev pipeline, wireframe/UI design
│   ├── frontend-performance.md   # Code splitting, caching, memoization
│   └── build-and-git.md         # Build commands, git workflow
│
├── prompts/                  # Reusable prompt templates (.prompt.md)
│   ├── add-endpoint.prompt.md    # Add endpoint to existing module
│   ├── checkpoint.prompt.md      # Write checkpoint to session/current.md
│   ├── code-review.prompt.md     # Review diff/PR against rules
│   └── explain-module.prompt.md  # Explain module end-to-end
│
├── skills/                   # Executable skills (SKILL.md + scripts)
│   ├── init-core-project/        # Init core from templates
│   ├── new-feature-module/       # Scaffold new module
│   ├── add-card-component/       # Install shared Card component
│   ├── add-shared-component/     # Promote component to shared
│   ├── clean-root/               # Clean all generated files
│   ├── db-migration/             # Database schema migration
│   ├── feature-spec/             # Feature specification
│   ├── release/                  # Version bump, CHANGELOG, git tag
│   ├── reset-tasks/              # Reset task queue
│   ├── squash-commits/           # Squash commits on branch
│   ├── sync-copilot/             # Sync this submodule to upstream
│   └── webhook-to-task/          # Issue tracker → task queue
│
├── ISSUE_TEMPLATE/           # GitHub issue templates
├── specs/                    # Feature specification templates
└── tasks/                    # Task queue templates
```

## Usage

This repo is meant to be used as a **git submodule** — not cloned directly.

## Parent repo integration

When a repository includes this submodule, it should treat the contents of `.copilot/agents`, `.copilot/prompts`, `.copilot/skills`, `.copilot/instructions`, and `.copilot/guardrails.md` as reusable Copilot assets. The parent repository should create its own repo-specific instructions file at `.github/copilot-instructions.md` and use that file as the canonical entry point for routing rules, workflow policy, task handling, and repository conventions.

For template-based usage, the parent repo should create or adapt `.github/copilot-instructions.md` to fit its own conventions, while keeping shared agent/skill/prompt definitions in the submodule. Keep repo-specific state such as tasks, specs, and workflow artifacts in `.github/`, and avoid duplicating the shared agent/skill/prompt definitions in the parent repository.

### What the parent repo should put in `.github/copilot-instructions.md`

Users should create a file like this in the parent repository:

```md
# Repository Custom Instructions

Project-wide guidelines applied to every interaction.

> **Canonical instruction file:** This repository keeps its repo-specific Copilot instructions here, in `.github/copilot-instructions.md`.
>
> **Submodule-aware integration:** This repository uses `.copilot` as a shared submodule. The shared assets under `.copilot/agents`, `.copilot/prompts`, `.copilot/skills`, and `.copilot/instructions` are reusable implementation assets.

## Routing rules

- Use the shared submodule assets for agents, prompts, skills, and reusable guidance.
- Keep repo-specific policy, conventions, and task workflow in this file.
- Use `.github/tasks/queue.md` for task tracking and `.github/specs/` for feature specs.

## Default workflow

1. Create or update a task in `.github/tasks/queue.md`.
2. Gather requirements and write the spec in `.github/specs/<feature>.md` when needed.
3. Use the relevant shared skill or prompt from `.copilot/` when appropriate.
4. Keep implementation and repo-specific decisions in this repository, not in the submodule.
```

This example is intentionally lightweight and should be expanded with project-specific conventions, preferred commands, and architectural rules.

### Add to your repo

```bash
git submodule add https://github.com/gatralaya/copilot.git .copilot
```

### Clone with submodule

```bash
git clone --recurse-submodules <your-repo-url>
```

### Update from upstream

```bash
git submodule update --remote --merge
```

## How It Works

| What | Where | Who edits |
|---|---|---|
| **Shared config** (agents, skills, prompts, instructions) | This repo (`.copilot/`) | Shared config maintainers |
| **Repo-specific state** (tasks, specs, CI/CD) | Parent repo (`.github/`) | Repo developers |

The parent repo's `.github/copilot-instructions.md` is the canonical entry point for repo-specific behavior, while `.copilot/` provides reusable agents, prompts, skills, and instructions.

### Path Convention

- Shared config paths use `.copilot/` prefix: `.copilot/skills/init-core-project/SKILL.md`
- Repo-specific paths use `.github/` prefix: `.github/tasks/queue.md`, `.github/workflows/ci.yml`

## Skills Quick Reference

| Skill | Trigger | Command |
|---|---|---|
| `init-core-project` | init, core files, template core | `make init` |
| `new-feature-module` | new feature, scaffold, create module | `make scaffold name=<name>` |
| `sync-copilot` | sync submodule, push upstream | `make sync` |
| `release` | release, version, tag, publish | `release.sh [major\|minor\|patch]` |
| `clean-root` | clean, reset project | `make clean` |
| `squash-commits` | squash, clean git history | `squash-commits.sh "message"` |
| `db-migration` | migration, schema, add table | `run-migration.sh <file>` |
| `reset-tasks` | reset queue, clean checkpoint | `make reset-tasks` |

## Contributing

1. Edit files in this repo
2. Push to `main` (or open a PR)
3. Parent repos pull via `git submodule update --remote --merge`

## License

MIT
