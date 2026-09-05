# Git Workflow

## Purpose
Keep parallel AI / sub-agent development safe by isolating every unit of work and integrating only tested changes.

## Protected Working Model

### Long-lived branches
- `main` — stable project history. Do not develop directly here.
- `prototype/combat-v01` — current Phase 1 integration branch. Do not develop directly here.
- Future phases should use their own integration branch, e.g. `phase2/mech-customization`.

### Short-lived work branches
Every implementation task must use its own branch created from the current integration branch.

Naming:
- `feature/<issue>-<short-name>` for gameplay/features
- `fix/<issue>-<short-name>` for bugs
- `refactor/<issue>-<short-name>` for behavior-preserving architecture work
- `test/<issue>-<short-name>` for test-only changes
- `docs/<issue-or-topic>-<short-name>` or `chore/<topic>` for documentation/tooling

Examples:
- `fix/30-visible-auto-playback`
- `feature/31-combat-impact-feedback`
- `refactor/32-split-combat-presentation`

## Mandatory Flow
1. Identify the integration branch and sync from it.
2. Create a dedicated work branch before editing code.
3. One branch should normally represent one GitHub issue / coherent change.
4. Keep the branch narrowly scoped. Do not mix unrelated cleanup or refactoring.
5. Commit using the issue number when one exists.
6. Run relevant local tests.
7. Push only the dedicated work branch.
8. Open a Pull Request back to the integration branch.
9. GitHub Regression / required CI must be green before merge.
10. Resolve conflicts on the work branch, then re-run CI.
11. Merge only after the change is reviewable and green.
12. Delete the short-lived branch after merge when practical.

## Direct-Push Rules
Do not directly push implementation changes to:
- `main`
- `prototype/combat-v01`
- any future shared phase/integration branch

Exception: only an explicit user instruction naming the shared branch and asking for a direct emergency fix may override this rule. An AI must not infer an exception by itself.

## Parallel AI / Sub-Agent Rules
Parallel work is encouraged when tickets are independent, but each worker must use a different branch.

Before starting parallel work, each ticket must state:
- functional dependencies;
- whether it can run independently;
- expected shared files;
- merge-conflict risk;
- integration order if one exists.

Classification:
- **parallel-safe** — no functional dependency and little/no expected shared-file overlap.
- **parallel-limited** — logically independent but expected to edit shared files; separate branches are still mandatory, and integration must be sequenced carefully.
- **blocked** — functional dependency requires another ticket to land first.

Two AI workers must never intentionally work from the same mutable feature branch at the same time.

## Integration Discipline
- PR target must be the current phase/integration branch, not automatically `main`.
- Rebase or merge the latest integration branch into the work branch before final merge when the branch has drifted materially.
- Never force-push a shared integration branch.
- Never use conflict resolution as an excuse to discard another ticket's behavior.
- After merging parallel tickets, run the full regression suite on the integration branch.

## Refactor Rule
Architecture refactors should be their own ticket and branch whenever practical. Do not combine large structural refactors with gameplay changes because that makes parallel work and review unreliable.

## Current Phase 1 Integration
Historical section: current work targets `phase2/build-your-mech`; see `phase2-scope.md`. The Phase 1 branch and ticket examples below are retained for reference.
For the current prototype:
- integration branch: `prototype/combat-v01`
- #30 should use a branch such as `fix/30-visible-auto-playback`
- #31 should use a separate branch such as `feature/31-combat-impact-feedback`
- because both may touch the current monolithic `src/main.gd`, treat them as **parallel-limited** until the codebase is modularized.
