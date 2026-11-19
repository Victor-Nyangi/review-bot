# TypeScript fixture (Express + React): planted bugs

Line numbers are relative to this fixture directory. `scripts/make-selftest-branch.sh ts`
copies everything except this file into `sandbox/ts/`. Detection should report two stacks,
`node-express` and `react`, from the one `package.json`. A passing review finds all three.

| # | Severity | Where | Bug |
|---|---|---|---|
| 1 | blocker | `server/routes/patients.ts:8` | **Mongo operator injection.** `Patient.find(req.query)` passes the raw query string object to Mongo. `?nationalId[$ne]=x` or `?diagnosis[$regex]=.` returns every patient; any field can be filtered. Fix: whitelist and cast fields (`{ fullName: String(req.query.fullName) }`), scope by `clinicId`, and project out sensitive fields. |
| 2 | blocker | `server/app.ts:11` | **Missing auth middleware.** `/api/patients` is mounted without `requireAuth` (unlike `/api/appointments` on the line above), so patient search and `GET /:id` are public; there is also no `clinicId` check on `findById`, so even with auth any clinic could read any patient. |
| 3 | blocker | `client/src/components/PatientNotes.tsx:19` | **Stored XSS.** Note bodies are user-written text rendered with `dangerouslySetInnerHTML` and no sanitizing, so a note containing `<img src=x onerror=...>` runs script in every clinician's session (and the bearer `token` is in scope). Fix: render as text, or sanitize with DOMPurify. |
