---
name: flutter-api-patterns-skill
description: Decision to codify Flutter API/auth patterns into a skill file
type: decision
---

# DECISION: Codify Flutter API & Auth Patterns into Skill

## Decision

Create `.claude/skills/19-flutter-patterns/flutter-api-patterns.md` as a new skill capturing Flutter API client patterns discovered during group-tours implementation.

## Rationale

The group-tours implementation surfaced recurring Flutter patterns that were repeatedly needed:

1. **ApiClient singleton** with static Dio instance and dynamic auth headers
2. **Riverpod FutureProvider with auth watching** — returns `[]` for unauthenticated users
3. **401 → login redirect** — critical pattern to avoid auth-error loops
4. **Confirmation dialogs before sensitive actions**
5. **GoRouter ShellRoute for auth-protected navigation**
6. **Error detection table** — 401/403/409/500/404 handling

These patterns were re-applied across multiple screens (guide_jobs_screen, guide_detail_screen, confirm_request_screen, trip_plan_list_screen) and would be lost without codification.

## What Was Captured

- `flutter-api-patterns.md` — 192 lines covering all 6 pattern categories
- `SKILL.md` index updated to reference new skill under "API & Auth Patterns" section

## Classification

- **Skill type**: Variant (Flutter/Dart-specific)
- **Upstream**: `.claude/skills/19-flutter-patterns/flutter-api-patterns.md`
- **Proposal**: Created at `.claude/.proposals/latest.yaml`

## Applied To

- `app/lib/features/guide/screens/guide_jobs_screen.dart`
- `app/lib/features/guide_detail/screens/guide_detail_screen.dart`
- `app/lib/features/trip_plan/screens/confirm_request_screen.dart`
- `app/lib/features/trip_plan/screens/trip_plan_list_screen.dart`
- `app/lib/core/api_client.dart`

## Why Now

These patterns emerged during the Render deploy failure investigation (May 4, 2026). Without codification, the next Flutter implementation session would rediscover the same patterns through the same compilation failures.
