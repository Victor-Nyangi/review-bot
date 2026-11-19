# Stack checklist: general

No specific framework was detected. Work out the language and framework from the files, then
apply the base rules with these checks:

- **Inputs at trust boundaries:** HTTP handlers, CLI arguments, files, queue messages and
  environment are validated before use; nothing user-controlled reaches a shell, SQL/NoSQL query,
  template, file path or URL fetch without escaping or whitelisting.
- **Authorization:** every entry point that reads or changes data checks who the caller is and
  whether they may touch that specific record.
- **Error handling:** errors are not swallowed; failures leave data consistent; external calls have
  timeouts and do not retry non-idempotent operations blindly.
- **Resources:** files, connections and locks are closed/released on every path; no unbounded
  memory growth from user-controlled sizes.
- **Concurrency:** shared state is protected; read-modify-write is atomic; scheduled or retried
  work is idempotent.
- **Secrets:** none in code, config committed to the repo, logs or error messages.
- **CI and infrastructure files:** workflows that run untrusted code with secrets, over-broad
  permissions, unpinned third-party actions, Dockerfiles running as root or baking in secrets.
- **Tests:** risky logic changes come with a test that would fail without the change.
