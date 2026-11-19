# Django fixture: planted bugs

Line numbers are relative to this fixture directory. `scripts/make-selftest-branch.sh django`
copies everything except this file into `sandbox/django/`. A passing review finds all three.

| # | Severity | Where | Bug |
|---|---|---|---|
| 1 | blocker | `attendance/views.py:13` | **`AllowAny` on a personal-data endpoint.** The viewset overrides the project default (`IsAuthenticated` in `presence/settings.py`) with `AllowAny`, so anonymous callers can list, edit and delete attendance records, including students' names and guardian phone numbers. (`perform_create` also crashes for anonymous users on `request.user.school`.) |
| 2 | blocker | `attendance/views.py:14` | **Unscoped queryset.** `queryset = AttendanceRecord.objects...` with no `get_queryset()` filtering by `self.request.user.school`, so even an authenticated teacher sees and can modify every school's records. Fix: `get_queryset()` returning `AttendanceRecord.objects.filter(school=self.request.user.school)`. |
| 3 | should_fix | `attendance/tasks.py:7-21` | **Non-idempotent Celery task.** `autoretry_for=(SmsGatewayError,)` retries the whole task, and `absence_count` is incremented (read-modify-write, not `F()`) before `send_sms`, so each retry counts the absence again; a retry after a delivered SMS (e.g. timeout, or failure saving `guardian_notified`) texts the guardian again. There is no `guardian_notified` check at the start. Fix: return early if already notified, increment with `F("absence_count") + 1` once, guarded by the record's state in a transaction. |

Bonus, not required: `notify_guardian_of_absence.delay()` in `perform_create` is not wrapped in
`transaction.on_commit()`, so the task can run before the row is committed.
