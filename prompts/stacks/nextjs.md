# Stack checklist: Next.js

Apply the React checklist too. In addition:

- **Server/client boundary:** a `"use client"` module importing server-only code, secrets or
  database clients; server components passing secrets or full records (with fields the user must
  not see) as props to client components, which serializes them into the page.
- **Environment variables:** anything prefixed `NEXT_PUBLIC_` is in the browser bundle; secrets
  must not be.
- **Server Actions and Route Handlers:** each one authenticates and authorizes the caller itself;
  they are public HTTP endpoints even when only called from your UI. Inputs are validated.
- **Middleware:** a `matcher` that leaves protected routes or API routes uncovered; auth checks
  that run only in middleware but not in the handler.
- **Caching:** user-specific data cached across users (`fetch` cache, `unstable_cache`, route
  segment config, `revalidate`) or mutations that do not revalidate the affected paths.
- **Data fetching:** sequential awaits that could run in parallel on hot pages; client-side
  fetching of data that needs authorization the API does not enforce.
- **Redirects and URLs:** open redirects from `searchParams` (`redirect(next)` without checking
  the target is same-origin).
