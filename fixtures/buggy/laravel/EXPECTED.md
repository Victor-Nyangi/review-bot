# Laravel fixture: planted bugs

Line numbers are relative to this fixture directory. `scripts/make-selftest-branch.sh laravel`
copies everything except this file into `sandbox/laravel/`. A passing review finds all three.

| # | Severity | Where | Bug |
|---|---|---|---|
| 1 | blocker | `app/Http/Controllers/InvoiceController.php:31` (`show`) | **Missing authorization.** `show()` never calls `$this->authorize('view', $invoice)`, and route model binding is not tenant-scoped, so any signed-in user of any school can read any invoice (with student and payments) by ID. `update` and `destroy` do authorize, and `InvoicePolicy::view` exists. |
| 2 | should_fix | `app/Http/Controllers/InvoiceController.php:22-24` (`index`) | **N+1 queries.** `$invoice->student` and `$invoice->payments` are lazy-loaded inside `map()`: 1 + 2×50 queries per page. Fix: `->with('student')->withSum('payments', 'amount')`. |
| 3 | blocker | `app/Http/Controllers/InvoiceController.php:45` with `app/Models/Invoice.php:20` | **Mass assignment.** `$invoice->update($request->all())` on a model with `$guarded = []` lets the caller set `school_id`, `student_id` and `status` (e.g. mark an invoice `paid`, or move it to another school). The validation only covers `amount` and `due_on` but `all()` ignores it. Fix: `$invoice->update($request->validated())` and an explicit `$fillable`. |
