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

The parent repo's `.github/copilot-instructions.md` is a **thin wrapper** that points to `.copilot/copilot-instructions.md` as the canonical entry point.

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
