# Stack checklist: Django / Django REST Framework (Python)

Check each item against the changed code. Read the related models, serializers, permissions,
settings and URL config before deciding.

- **DRF permissions:** every view and viewset sets `permission_classes` appropriate to the data;
  `AllowAny` on anything that is not genuinely public is a finding. Check that the project default
  in `REST_FRAMEWORK` settings is not being relied on where it is `AllowAny`. Object-level checks
  (`has_object_permission`) are only called by `get_object()`; list views need queryset scoping.
- **Queryset scoping:** `get_queryset()` filters by the current tenant/school/user;
  `queryset = Model.objects.all()` on a tenant-owned model with no override exposes every tenant.
  Lookups by ID from the URL or body must go through the scoped queryset.
- **Serializers:** `fields = "__all__"` or writable fields that let a client set ownership,
  tenant, role or status; nested writes without validation; sensitive fields returned.
- **Celery tasks:** idempotent under retries and duplicate delivery (`acks_late`, `autoretry_for`,
  `retry()`); side effects such as SMS, email or payments guarded by a status check or idempotency
  key; counters updated with `F()` expressions or `select_for_update()`, not read-modify-write;
  tasks receive IDs, not model instances.
- **Transactions:** multi-step writes in `transaction.atomic()`; tasks enqueued with
  `transaction.on_commit()` so they do not run before the row exists.
- **Query performance:** `select_related` / `prefetch_related` for relations used in loops and
  serializers; `.count()`/`.exists()` instead of `len()` on querysets; no unbounded querysets in
  list endpoints without pagination.
- **Migrations:** reversible; `RunPython` has a reverse function; adding non-null columns to big
  tables, renaming/dropping fields still read by the running code, and data migrations importing
  models directly instead of `apps.get_model` are findings.
- **Raw SQL:** `raw()`, `extra()`, `cursor.execute()` with f-strings or `%` formatting instead of
  parameters.
- **Timezones:** `datetime.now()` / `date.today()` instead of `timezone.now()` / `timezone.localdate()`
  when `USE_TZ=True`; naive datetimes compared with aware ones; day boundaries computed in UTC
  when the business rule is local time (attendance, school days).
- **Secrets and settings:** `DEBUG`, `ALLOWED_HOSTS`, `SECRET_KEY` or credentials hard-coded;
  personal data logged.
- **Tests:** new permission or scoping rules have a test proving another tenant gets 403/404.
