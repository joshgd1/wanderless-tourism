# DISCOVERY: 401 error handling in group screens showed Retry instead of redirect to login

## Context

Both `groups_screen.dart` and `group_detail_screen.dart` detected API errors but showed a "Retry" button for ALL error types — including 401 Unauthorized. Users with expired sessions saw "Failed to load groups" with a Retry button instead of being redirected to login.

## Fix applied

Updated error handlers in both screens to:
1. Check if error message contains `'401'` or `'Authorization'`
2. Show "Session expired — please sign in again" message
3. Show "Go to Sign In" button that calls `context.go('/login')` instead of retry

## Files changed

- `app/lib/features/groups/screens/groups_screen.dart` — error widget updated
- `app/lib/features/groups/screens/group_detail_screen.dart` — error widget updated

## How to apply

Standard pattern for Riverpod error handlers: check `e.toString().contains('401') || e.toString().contains('Authorization')` and redirect to `/login`.
