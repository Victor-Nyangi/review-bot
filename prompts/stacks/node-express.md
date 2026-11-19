# Stack checklist: Node.js / Express (JavaScript or TypeScript)

Check each item against the changed code. Read the app/router setup, middleware and models
before deciding.

- **Authentication and authorization middleware:** every router that serves non-public data is
  mounted behind the auth middleware, and every route that touches a specific record checks that
  the caller may access that record (ownership, role, organization). Compare the new route with
  how sibling routes are mounted in the app entry point; a router mounted without the middleware
  the others use is a finding.
- **Input validation:** request bodies, params and query strings are validated (zod, joi,
  express-validator, class-validator) before use; types are enforced, not assumed from
  TypeScript annotations, which do not exist at runtime.
- **NoSQL operator injection:** `req.query`, `req.body` or `req.params` passed directly (or spread)
  into `find`, `findOne`, `updateOne`, `deleteMany` or aggregation stages lets a client send
  `{"$ne": null}`, `{"$gt": ""}` or `$where`. Whitelist fields and cast values to strings/ObjectIds;
  check `sanitizeFilter` / `strictQuery` settings.
- **Mass assignment:** `Model.create(req.body)` or `findByIdAndUpdate(id, req.body)` lets a client
  set roles, owner IDs or status.
- **Async error handling:** async handlers either use Express 5 or a wrapper so rejected promises
  reach the error middleware; no unhandled rejections; errors do not leak stack traces or internal
  details to clients.
- **Secrets and logging:** no tokens, passwords, API keys or personal/health data in logs or error
  responses; secrets come from configuration, not code.
- **Data exposure:** responses do not return password hashes, tokens or fields the caller should
  not see (use projections/DTOs).
- **Concurrency:** read-modify-write on documents uses atomic operators or transactions; webhook
  and job handlers are idempotent.
- **Performance:** queries inside loops, missing indexes for new filters, unbounded `find()`
  without limit/pagination on list endpoints.
- **Tests:** new routes have a test for the unauthenticated and the wrong-user case.
