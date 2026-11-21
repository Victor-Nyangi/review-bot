# Stack checklist: Laravel (PHP)

Check each item against the changed code. Read the related model, policy, form request, route
file and middleware before deciding.

- **Authorization:** every controller action, Livewire action and API endpoint that reads or
  changes a record calls `$this->authorize()`, `Gate::authorize()`, a policy via `can` middleware,
  or a Form Request `authorize()` that actually checks the user. Route model binding alone is not
  authorization. A policy method that returns `true` unconditionally is a finding.
- **Tenant scoping:** queries on tenant-owned models are scoped to the current tenant/school
  (global scope, `whereBelongsTo`, or relationship query). `Model::find($id)` or `findOrFail` on
  user-supplied IDs without a scope or policy is an IDOR.
- **Mass assignment:** `create($request->all())`, `update($request->all())`, `fill($request->input())`
  or `$guarded = []` lets a client set `tenant_id`, `role`, `is_admin`, prices or status. Use
  `$request->validated()` or `only([...])` with explicit `$fillable`.
- **Validation:** every input used in a query or write is validated; `exists:` and `unique:` rules
  are scoped to the tenant where IDs are tenant-owned.
- **Livewire:** public properties are client-writable. A public `$userId`, `$schoolId`, `$role` or
  model ID that an action trusts without re-checking authorization is a finding; use `#[Locked]`
  or re-authorize in the action. Every action method authorizes on its own.
- **N+1 queries:** relationships used inside loops, Blade `@foreach`, API resources or
  `map()` are eager-loaded with `with()`/`load()`; counts use `withCount()`.
- **Queued jobs and listeners:** safe to run twice (retries, `tries`, `backoff`); external side
  effects (SMS, email, payments) are guarded by an idempotency key or a status check inside a
  transaction or lock; `ShouldBeUnique` where duplicates matter; models passed with
  `SerializesModels` may be stale.
- **Transactions:** multi-step writes that must succeed together use `DB::transaction()`;
  `lockForUpdate()` around read-modify-write of counters and balances.
- **Migrations:** `down()` reverses `up()`; dropping or renaming columns in use, adding NOT NULL
  without a default on a large table, or changing types that truncate data are findings.
- **Raw SQL:** `DB::raw`, `whereRaw`, `orderByRaw` with interpolated input instead of bindings.
- **Unescaped output:** Blade `{!! !!}` (or `v-html` in Vue components) on user-controlled
  content without sanitizing is stored or reflected XSS, a blocker.
- **Secrets and config:** `env()` called outside `config/` files; secrets or tokens logged.
- **Tests:** new authorization or tenant rules have a Pest/PHPUnit test proving the forbidden case
  returns 403/404, not just the happy path.
