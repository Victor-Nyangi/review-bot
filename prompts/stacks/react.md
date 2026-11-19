# Stack checklist: React (JavaScript or TypeScript)

Check each item against the changed components and hooks.

- **XSS:** `dangerouslySetInnerHTML` with any value that can contain user input (API data,
  URL params, rich text) without sanitizing (e.g. DOMPurify); `href`/`src` built from user input
  that can be `javascript:`; HTML injected via refs (`innerHTML`).
- **Effect dependencies:** `useEffect`/`useMemo`/`useCallback` dependency arrays that omit values
  read inside (stale data, effects that never re-run) or include unstable objects/functions
  (infinite loops, request storms); missing cleanup for subscriptions, timers, and fetches whose
  results can arrive after unmount or after the input changed (race conditions).
- **Keys:** list items keyed by array index where items can be reordered, inserted or removed,
  or keys that are not unique; this corrupts component state.
- **State bugs:** state derived from props copied into `useState` and never synced; mutating
  state objects/arrays in place; setting state during render.
- **Secrets in the client bundle:** API keys, tokens or private URLs in client code or in
  `VITE_*`, `REACT_APP_*`, `NEXT_PUBLIC_*` variables; everything shipped to the browser is public.
- **Authorization in the UI only:** hiding a button is not access control; flag new UI-only
  permission checks when the matching API route does not enforce them (if visible in this repo).
- **Sensitive data:** personal or health data written to `localStorage`, logs or analytics.
- **Error and loading states:** a failed request that leaves the UI stuck or shows wrong data as
  if it were real.
