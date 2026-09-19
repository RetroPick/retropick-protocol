---
id: LP-FE-ROUTES
type: normative_implementation
status: ready
owner: launchpad-frontend
product: launchpad
version: v2
---

# Routes and Features

- `/` / `/discover`: launch discovery.
- `/create`: validated create wizard + economics review.
- `/launch/[token]`: metadata, curve state, activity, buy/sell, graduation/Kuru status.
- `/portfolio`: address positions/activity.
- `/profile/[address]`: creator/user profile and launches.
- `/activity`: protocol/address event feed.

Each implementation route defines field sources, writes, loading/empty/error/stale states, responsive behavior and acceptance tests.