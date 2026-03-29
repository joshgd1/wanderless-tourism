---
name: security-attack-chains
description: "Multi-step attack chains discovered in v2.1.0 red team: pickle+Redis RCE, eval/__import__ injection, auth degradation, PACT governance bypass. Use when reviewing security, auditing deserialization, or checking for chained vulnerabilities."
---

# Security Attack Chains — v2.1.0 Red Team Findings

Documented multi-step attack chains found during 2 rounds of red teaming (30+ findings). These patterns are the highest-severity vulnerabilities because they combine individually moderate issues into critical exploit chains.

## Chain 1: Redis URL Injection + pickle.loads = RCE (CRITICAL)

**Attack**: Attacker controls Redis URL -> points to malicious Redis -> injects crafted pickle payload -> `pickle.loads()` executes arbitrary code.

**Components**:

- **Write channel**: Unvalidated Redis URLs passed to `Redis.from_url()` (5 sites across mcp_server, cache nodes, trust governance)
- **Execution channel**: `pickle.loads()` deserializing from Redis (2 sites in cache.py, 2 in persistent_tiers.py)

**Fix applied in S1**: Replace all `pickle.loads()` with JSON deserialization. Validate all Redis URLs against `redis://` or `rediss://` scheme allowlist.

**Prevention pattern**:

```python
# NEVER: pickle.loads on data from external stores
data = pickle.loads(redis_client.get(key))  # RCE if Redis is attacker-controlled

# ALWAYS: JSON deserialization with schema validation
raw = redis_client.get(key)
data = json.loads(raw)
validate_schema(data)  # Additional validation for critical data

# ALWAYS: Validate Redis URLs before use
ALLOWED_SCHEMES = {"redis", "rediss"}
parsed = urllib.parse.urlparse(redis_url)
if parsed.scheme not in ALLOWED_SCHEMES:
    raise ValueError(f"Invalid Redis URL scheme: {parsed.scheme}")
```

## Chain 2: eval()/exec() with Exposed `__import__` = Code Injection (CRITICAL)

**Attack**: User-provided transform expressions or processing code executed with `__import__` in scope, enabling `__import__('os').system('rm -rf /')`.

**Components**:

- `processors.py:396,409,419,472` — `safe_globals` includes `"__builtins__": {"__import__": __import__}`
- `batch_processor.py:239-249` — `exec(processing_code, exec_globals)` with full `__builtins__`
- `mcp_integration.py:458-464` — `eval(expr, {"__builtins__": {}}, {})` exploitable via type methods

**Fix applied in S1**: Remove `__import__` from all `safe_globals`. Restrict `exec()` to validated, pre-approved processing functions. Replace `eval()` with bounded expression parsing.

**Prevention pattern**:

```python
# NEVER: __import__ in exec/eval globals
exec(user_code, {"__builtins__": {"__import__": __import__}})  # Full code exec

# NEVER: Full __builtins__ in exec globals
exec(user_code, {"__builtins__": __builtins__})  # Full code exec

# NEVER: eval with empty builtins (exploitable via type methods)
eval(user_expr, {"__builtins__": {}}, {})  # ().__class__.__bases__[0].__subclasses__()

# ALWAYS: Use ast.literal_eval for safe expression evaluation
import ast
result = ast.literal_eval(user_expr)  # Only literals: strings, numbers, dicts, lists

# ALWAYS: Use bounded operator for math expressions
import operator
SAFE_OPS = {'+': operator.add, '-': operator.sub, '*': operator.mul, '/': operator.truediv}
# Parse and evaluate using only safe operators with bounded exponents
```

## Chain 3: Auth Degradation + Timing Attack (CRITICAL)

**Attack**: Bare `except:` around PBKDF2 hash verification falls through to `password == stored_hash` — plaintext comparison with timing vulnerability.

**Components**:

- `auth.py:494-496` — bare `except:` catches PBKDF2 `ImportError` AND verification errors
- Fallback: `password == password_hash` — not constant-time, enables timing attack

**Fix applied in S1**: Fail-closed on auth library import failure. Replace all `==` hash comparisons with `hmac.compare_digest()`.

**Prevention pattern**:

```python
# NEVER: Fallback to plaintext comparison on crypto failure
try:
    return pbkdf2_verify(password, stored_hash)
except:  # Catches ImportError AND verification errors!
    return password == stored_hash  # Plaintext + timing attack

# ALWAYS: Fail-closed on crypto unavailability
try:
    from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
except ImportError:
    raise AuthenticationError("Cryptography library required for authentication")

# ALWAYS: Constant-time comparison
import hmac
if not hmac.compare_digest(computed_hash.encode(), stored_hash.encode()):
    raise AuthenticationError("Invalid credentials")
```

## Chain 4: PACT Governance Bypass via Backup Restore (HIGH)

**Attack**: `restore_governance_store()` calls `_envelope_store.save_role_envelope()` directly, bypassing engine validation, audit trail, thread safety, and NaN/Inf checks. An attacker with backup access can inject widened envelopes.

**Components**:

- 5 code paths to `save_role_envelope()`: engine.set_role_envelope(), engine.set_task_envelope(), backup restore, InMemoryStore, SqliteStore
- Only the engine paths validated monotonic tightening
- `_multi_level_verify()` was fail-OPEN: parse errors returned `(None, "")` meaning "no block"

**Fix applied in S1**: Enforce monotonic tightening in all 5 code paths. Make `_multi_level_verify()` fail-closed.

**Prevention pattern**:

```python
# NEVER: Write to envelope store directly
store.save_role_envelope(address, attacker_controlled_envelope)  # No validation!

# ALWAYS: Route through GovernanceEngine which validates
engine.set_role_envelope(address, envelope)  # Validates monotonic tightening

# NEVER: Fail-open on parse errors in governance code
try:
    addr = Address.parse(role_address)
except Exception:
    return (None, "")  # "No ancestor blocks" = fail-open

# ALWAYS: Fail-closed
try:
    addr = Address.parse(role_address)
except Exception:
    return (BLOCKED, "Failed to parse address")  # Deny on error
```

## Chain 5: 0.0.0.0 + Missing Headers + Wildcard CORS (HIGH)

**Attack**: Default server binds to all interfaces + no security headers + wildcard CORS = any machine on the network can interact with the server with no restrictions.

**Components**:

- 8 server endpoints default to `host="0.0.0.0"`
- No CSP, HSTS, X-Content-Type-Options, X-Frame-Options headers
- 4 components default to `allow_origins=["*"]`

**Status**: Not yet fixed (scheduled for S3 session). Requires changing defaults to `127.0.0.1`, adding security headers middleware, and deny-by-default CORS. See milestone `S3a`, `S3c`, `S3d` in `workspaces/kailash/todos/active/000-milestones.md`.

## Cross-Cutting: NaN/Inf Bypass in Governance (MEDIUM)

**Attack**: `float('nan')` in context dicts bypasses ALL numeric comparisons because `NaN < X` and `NaN > X` are both `False`. Budget checks, financial constraints, and daily totals all pass silently.

**Prevention**: `math.isfinite()` on EVERY numeric value BEFORE any comparison. Check both per-action values (cost, amount) AND cumulative values (daily_total, session_cost).

## Red Team Statistics

| Metric          | Value                                                                     |
| --------------- | ------------------------------------------------------------------------- |
| Rounds          | 2                                                                         |
| Agents deployed | 4 (security-reviewer, deep-analyst, coc-expert, gold-standards-validator) |
| Total findings  | 30+                                                                       |
| CRITICAL        | 4 (pickle RCE, eval injection, auth degradation, PACT fail-open)          |
| HIGH            | 9 (header forwarding, info disclosure, timing attacks, CORS, etc.)        |
| MEDIUM          | 10                                                                        |
| LOW             | 6                                                                         |

<!-- Trigger Keywords: attack chain, RCE chain, pickle RCE, eval injection, auth bypass, timing attack, Redis poisoning, PACT bypass, governance bypass, deserialization, code execution, security audit -->
