# Correctness, security, and conventions

Three lenses. Each section lists what to look for, then the false positives that lens reliably produces — read both halves, because the second half is what keeps the report short.

---

# Correctness

A correctness finding names inputs or state that produce a wrong result. If you cannot name them, you have a suspicion.

## Where bugs actually live

**Boundaries of a collection.** Empty, one element, and the last element. An empty list returned as `undefined` or `null` instead of `[]`, then indexed or measured. Off-by-one in a slice, a loop bound, or pagination arithmetic. `length - 1` on something that can be empty.

**The absent value.** Null, undefined, `None`, zero, empty string, `NaN`, and missing keys. Look for `if (value)` where `0` or `""` is a legitimate value, and for optional chaining that silently produces `undefined` where the caller expects a number.

**Type coercion and comparison.** In JavaScript: `==` vs `===`, `NaN !== NaN`, `[] == false`, sorting numbers with the default comparator. In Python: mutable default arguments, `is` vs `==`, integer division. In SQL: `NULL` comparisons, which are never `TRUE`.

**Error paths.** Every `catch`, `except`, `rescue`, and `if err != nil`. Does it swallow? A bare `catch {}`, `except: pass`, or a catch that logs and continues with a half-built object hides the failure and produces a wrong result further on. This is an explicit rule in the user's global CLAUDE.md — errors are handled explicitly, fail loudly and early — so a swallowing handler is a conventions finding as well as a correctness one.

**Resources.** Files, connections, locks, subscriptions, timers, event listeners. Opened on one path and closed on the happy path only. A `finally`, `defer`, `with`, or `using` that is missing means the leak happens exactly when things are already going wrong.

**Concurrency.** Check-then-act on shared state. A read, a decision, and a write that are not atomic. An `await` between a validity check and the use of what was checked. Two requests arriving at once — does the second see the first's half-finished state?

**Time, money, and text.** Naive datetimes where the system spans zones. Daylight-saving arithmetic done by adding 86,400. Floating point for currency. String length on text that can contain non-ASCII, where "characters" and "code units" diverge.

**State machines.** Can the code reach a state it does not handle? Retry logic that retries a non-idempotent operation. A cache invalidated on one write path and not another.

**The contract mismatch.** Read the function's callers before judging its argument handling. Most real bugs are a disagreement between two places about what a value can be: the caller that can pass `null`, the schema that allows a field the parser assumes is present, the API that changed its response shape.

## Correctness false positives

- Defensive checks a type system already guarantees.
- "Missing validation" that a framework middleware, decorator, schema, or route guard performs before the handler runs. Go find it before flagging it.
- Unhandled cases that cannot occur given the call sites. Check them.
- Theoretical concurrency in code that provably runs single-threaded.
- Anything the compiler, type checker, or a configured linter reports. Those run in CI.

---

# Security

Security review here is about untrusted input reaching somewhere it should not, and about who is allowed to do what. Name the class (a CWE number, or the mechanism) or it is not a finding.

## Where to look

**Injection.** String-built SQL, shell commands, LDAP filters, XPath. Look for concatenation or interpolation into any of these — parameterized queries and argument arrays are the fix, and their absence is the finding. `eval`, `exec`, `Function()`, `pickle.loads`, `yaml.load` without `SafeLoader`, and deserialization of anything a user controls.

**Output encoding.** In templates and components: `innerHTML`, `dangerouslySetInnerHTML`, `v-html`, `|safe`, `html_safe`, `@Html.Raw`, `{{{ }}}`. Each one is a place where escaping was deliberately turned off; check what flows into it.

**Authentication and authorization.** These are different findings. Authentication asks who you are, authorization asks what you may see. The common defect is an endpoint that authenticates but never checks that this user owns this record — pass an ID belonging to someone else and it returns their data. Check every handler that takes an ID from the request. In a university system this is the most likely route to a FERPA disclosure, so it is also a privacy finding.

**Secrets.** Keys, tokens, passwords, and connection strings written into tracked files. The global CLAUDE.md forbids these outright, along with hardcoding the user's email address. An env-var read, a placeholder, or a test fixture is not a finding — open the line and see which it is.

**Path and file handling.** User input in a filesystem path without normalization — `../` traversal. Uploads trusted for their type, extension, or size based on what the client claimed.

**Transport and redirects.** `http://` for anything carrying credentials or records. TLS verification disabled. A redirect target taken from a query parameter without an allowlist.

**Randomness.** `Math.random()`, `rand()`, or a seeded PRNG used for a token, session ID, password reset link, or anything else that must be unguessable.

**Dependencies.** A new dependency is a finding on its own terms — the global CLAUDE.md says none are added without asking. Check whether one appeared for something the standard library already does.

## Security false positives

- Findings on data that provably never crosses a trust boundary — a constant, a value from the same codebase, a build-time literal.
- Missing input validation on an internal function whose only callers already validated.
- Generic "this could be exploited" with no path from an input to the sink. Trace the path or drop it.
- Cryptography opinions where the project uses a standard library correctly.
- Anything a dependency scanner reports. Those run in CI.

---

# Conventions

The rules come from step 2 of the skill: the project's CLAUDE.md, the global CLAUDE.md, the linter configs, and the surrounding code — in that order. Never invent one.

## Run the linter, then review for what it cannot check

If ESLint, Ruff, Prettier, or an equivalent is configured, run it and report what it says. Then spend the review on the rules no linter encodes. From the user's global CLAUDE.md, these are the ones that show up in code:

- **Smallest change that solves the problem.** A fix that arrives with an unrelated refactor, rename, or dependency bump bundled in.
- **No new dependency without asking.** A package pulled in for something the standard library covers.
- **Errors handled explicitly, no catch-all that swallows.** See the correctness lens.
- **No comment by default.** A comment belongs only where the code cannot carry it: why this approach over the obvious one, a constraint or bug being worked around, an invariant the types do not state, or a deliberate break from convention. A comment restating, narrating, or labeling the code is a finding; so is a banner block, a comment above every function, or one longer than two lines. A missing comment on a non-obvious decision is also a finding.
- **No commented-out code.** It is deleted, not left in.
- **No hardcoded secrets, tokens, connection strings, or the user's email.** Environment variables, and the review says which ones need setting.
- **Tests exist where the project asks for them.** Missing coverage is a finding only if the project requires it. Otherwise say what you would test, in one line, outside the findings.

## Consistency with the neighbours

Where nothing is written down, the convention is what the adjacent files do: naming, file layout, error-handling shape, import style, how the module exports. A file that does it differently for no reason is a LOW finding. A file that does it differently because it genuinely needs to is not a finding at all — check which before writing it up.

## Conventions false positives

- Style the project has not written down and does not consistently follow.
- Rules from a linter config that is present but disabled for that path or that rule.
- A violation the author suppressed deliberately with an inline ignore comment. That is a decision.
- Applying a convention from one language to a file in another.
- Your own preferences. Those go in the "Preferences" list, and only if they are worth the user's time.
