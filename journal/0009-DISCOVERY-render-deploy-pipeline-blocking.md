---
name: render-deploy-pipeline-blocking
description: Discovery that Flutter CI failure blocked Render deploy step
type: discovery
---

# DISCOVERY: Flutter Build Failure Blocked Render Deploy

## Finding

The Render deploy failure at commit `200ed26` showed "Exited with status 1" but was NOT a backend code issue. The Flutter Web build step failed first, blocking the entire CI pipeline before it ever reached the Render deploy step.

## Root Cause

GitHub Actions CI pipeline structure:

1. Flutter build (`flutter build web`) — FAILS at `200ed26`
2. Flutter deploy (conditional on build success) — never reached
3. Backend deploy via Render — never reached

Four Dart compilation errors caused the Flutter build failure:

1. `guide_jobs_screen.dart:51` — unescaped apostrophe in string literal
2. `guide_detail_screen.dart:241` — `widget.planId` in `ConsumerWidget` context
3. `confirm_request_screen.dart:278` — `loading:` instead of `isLoading:` for PrimaryButton
4. `trip_plan_list_screen.dart:21` — `const MatchedGuide()` where constructor isn't const

## Implication

Flutter failures propagate to backend deploys when both are in the same pipeline. The Render deploy step is not isolated from Flutter build failures.

## Fix Applied

Fixed all 4 Flutter compilation errors, pushed commits `0097762` and `7429477`. Then pushed empty commit `86d319d` to retrigger full pipeline with all fixes in place.

## Pattern

When investigating deploy failures in a multi-stage pipeline: check whether the failing stage is actually the root cause, or whether a prior stage blocked it from running at all.
