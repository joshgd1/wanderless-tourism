# Flutter API & Auth Patterns

Production patterns for Flutter API clients with JWT authentication, Riverpod state management, and GoRouter navigation with auth redirects.

## ApiClient Singleton with Dio

```dart
import 'package:dio/dio.dart';

class ApiClient {
  static Dio? _dio;
  static String? _baseUrl;
  static String? _authToken;

  static Dio get _dioInstance {
    _dio ??= Dio(BaseOptions(
      baseUrl: _baseUrl ?? ApiConfig.defaultUrl ?? 'http://localhost:8000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    return _dio!;
  }

  void setAuthToken(String token) {
    _authToken = token;
    _dioInstance.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _authToken = null;
    _dioInstance.options.headers.remove('Authorization');
  }

  Map<String, String> get _authHeaders {
    if (_authToken == null) return {};
    return {'Authorization': 'Bearer $_authToken'};
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    final resp = await _dioInstance.post(path, data: data, options: Options(headers: _authHeaders));
    return resp.data as Map<String, dynamic>;
  }
}
```

**Key pattern**: Static `_authHeaders` getter reads `_authToken` at call time, NOT at construction — so headers reflect current auth state.

## Riverpod FutureProvider with Auth Check

```dart
final guideOpenGroupsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(guideAuthProvider);
  if (authState.guideId == null) return [];  // Early return for unauthenticated
  final api = ApiClient();
  final data = await api.getGroups(status: 'OPEN');
  return data.where((g) => g['guide_id'] == null).toList().cast<Map<String, dynamic>>();
});
```

**Key pattern**: Provider watches auth state; returns `[]` for unauthenticated users (avoids 401 on every call).

## 401 Error → Login Redirect (CRITICAL)

Every API call screen MUST handle 401 by redirecting to login, NOT showing retry.

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final groupsAsync = ref.watch(groupsProvider);

  return groupsAsync.when(
    loading: () => const AppLoading(message: 'Loading...'),
    error: (e, _) => _handleError(context, e),
    data: (groups) => GroupListView(groups: groups),
  );
}

Widget _handleError(BuildContext context, Object e) {
  final errStr = e.toString();
  final isUnauthorized = errStr.contains('401') || errStr.contains('Authorization');

  if (isUnauthorized) {
    return EmptyState(
      icon: Icons.lock_outline,
      title: 'Session expired',
      subtitle: 'Please sign in again',
      action: AppButton(label: 'Go to Sign In', onPressed: () => context.go('/login')),
    );
  }

  return EmptyState(
    icon: Icons.error_outline,
    title: 'Failed to load',
    subtitle: errStr,
    action: AppButton(label: 'Retry', onPressed: () => ref.invalidate(groupsProvider)),
  );
}
```

**Why**: `FutureProvider.when(error:)` catches ALL exceptions. Without explicit 401 handling, expired-token users see "Retry" button and get stuck in an auth-error loop. The `contains('401')` check catches both Dio's 401 response and any backend message containing "Unauthorized" or "Authorization required".

## Confirmation Dialog Before Sensitive Actions

```dart
Future<void> _claimGroup(BuildContext context, Map<String, dynamic> group) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Claim This Group?'),
      content: Text('You will be assigned as the guide for "${group['destination']}".'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        AppButton(label: 'Confirm Claim', onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await api.claimGroup(group['id'] as int);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group claimed!')));
      ref.invalidate(guideOpenGroupsProvider);
    }
  } on DioException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.response?.data?['detail'] ?? e.message}')),
      );
    }
  }
}
```

**Key pattern**: `DioException` gives access to `e.response?.data?['detail']` for server error messages. Always check `context.mounted` before showing SnackBar/dialog after async gap.

## GoRouter Auth Shell Route

```dart
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => AuthShell(child: child),  // wraps with auth check
      routes: [
        GoRoute(path: '/groups', builder: (context, state) => const GroupsScreen()),
        GoRoute(path: '/group/:groupId', builder: (context, state) {
          final groupId = int.parse(state.pathParameters['groupId']!);
          return GroupDetailScreen(groupId: groupId);
        }),
      ],
    ),
  ],
);
```

## Common Error Patterns

| Error               | Detection                                                         | Response                                |
| ------------------- | ----------------------------------------------------------------- | --------------------------------------- |
| 401 Unauthorized    | `e.toString().contains('401')`                                    | Redirect to `/login`                    |
| 403 Forbidden       | `e.toString().contains('403')`                                    | Show "Access denied" message            |
| 409 Conflict (race) | `e.toString().contains('409')`                                    | Show server message from `detail` field |
| Network error       | `e is DioException && e.type == DioExceptionType.connectionError` | Show "No internet" with retry           |
| 404 Not found       | `e.toString().contains('404')`                                    | Show "Not found" empty state            |
| 500 Server error    | `e.toString().contains('500')`                                    | Show "Server error, try later"          |

## API Response Parsing

```dart
// Always cast explicitly — Dio returns `dynamic`
final resp = await _dioInstance.get(path, options: Options(headers: _authHeaders));
return resp.data as Map<String, dynamic>;  // for single object
return (resp.data as List).cast<Map<String, dynamic>>();  // for lists

// For paginated responses
final data = resp.data as Map<String, dynamic>;
return data['items'] as List;
final total = data['total'] as int;
```

## When to Use These Patterns

Use this skill when:

- Building Flutter screens that call REST APIs
- Implementing JWT authentication flows
- Setting up Riverpod providers with async API data
- Handling API errors with navigation consequences
- Implementing confirmation dialogs for destructive or irreversible actions
