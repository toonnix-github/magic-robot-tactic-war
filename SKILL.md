# Architecture & Implementation Skill

## Purpose
Use this skill for every implementation, refactor, test, or architecture change in Magic Robot Tactic War.

The project must remain easy to extend by multiple independent AI/Codex workers. New work must therefore preserve clear ownership boundaries and avoid recreating a monolith.

## Mandatory Decoupling Rule
All new functionality must be decoupled by responsibility.

This does **not** mean creating one file per function. It means every function must have one clear owner and belong to the smallest appropriate module for its responsibility.

Before adding or changing a function, identify its owner:
- combat rules / damage / attacks / parts / statuses -> `src/combat/`
- movement / pathing / terrain / height / LOS -> grid/combat grid module
- AI planning / scoring / tactical decision -> `src/ai/`
- battle presentation / timing / animation / feedback -> `src/presentation/`
- battle HUD / inspection / player UI input -> `src/ui/`
- authoritative configuration / weapons / pilots / Orbs / missions / build data -> `src/data/`
- scene lifecycle / top-level coordination only -> `src/main.gd`

## Function Design Requirements
For every new or modified function:
- Keep one primary responsibility.
- Prefer pure functions when state mutation is not required.
- Pass explicit inputs and return explicit outputs instead of reaching into unrelated module internals.
- Do not read or mutate another subsystem's state when the same result can be achieved through an explicit API.
- Keep simulation logic independent from rendering and presentation timing.
- Keep data definitions independent from UI and battle presentation.
- Avoid circular module dependencies.
- Avoid hidden side effects.
- Avoid giant functions that mix state mutation, combat calculation, UI rendering, and presentation.
- Avoid convenience wrappers that only move code cosmetically while the real responsibility remains in `main.gd`.

## `main.gd` Rule
`src/main.gd` is an orchestrator, not a default implementation location.

Do not add feature logic directly to `main.gd` merely because it already has access to all state. New feature behavior should normally live in its owning module and be invoked from `main.gd` only for top-level coordination.

Acceptable responsibilities for `main.gd` include:
- scene lifecycle;
- wiring modules together;
- top-level battle/mission coordination;
- shared state references where a dedicated state object is not yet justified;
- debug/benchmark entry points.

If a ticket would require substantial new combat, AI, HUD, presentation, or data logic inside `main.gd`, stop and create or extend the appropriate module first.

## Parallel-Work Design Test
Before implementation, ask:

> Could another agent change a neighboring subsystem without editing the same implementation file or understanding this function's internals?

If the answer is no, improve the boundary before adding more feature code unless the ticket explicitly requires a cross-cutting integration change.

Ordinary Phase 2 work should allow, as much as practical:
- a build/data agent to work without touching battle presentation;
- a HUD agent to work without touching combat resolution;
- a combat agent to work without touching HUD drawing;
- an AI agent to work without touching presentation;
- a presentation agent to consume resolved combat events without recomputing gameplay state.

## Tests Must Protect Boundaries
Tests should verify behavior **and** important ownership boundaries where regression risk is high.

Do not rely only on tests that check whether a file/class exists. Prefer tests that prove:
- authoritative data comes from the intended data module;
- combat resolution is delegated to combat modules;
- UI/presentation consumes resolved state rather than recomputing it;
- old monolithic implementations do not silently reappear in `main.gd`;
- deterministic gameplay results remain unchanged when presentation is enabled/disabled.

## Refactor While Implementing
Small local refactors needed to maintain an existing boundary are encouraged inside the ticket scope.

Do not perform broad unrelated architecture rewrites opportunistically. If proper decoupling requires a large cross-cutting change, surface it as a separate refactor ticket with dependency and parallel-work impact documented.

## Completion Check
Before declaring a ticket complete, verify:
1. Every new function has a clear module owner.
2. `main.gd` did not gain subsystem implementation that belongs elsewhere.
3. Simulation, UI, presentation, AI, and data concerns remain separated.
4. The change does not create a circular dependency.
5. Parallel agents can work on neighboring concerns with minimal shared-file contention.
6. Regression and deterministic tests remain green.
