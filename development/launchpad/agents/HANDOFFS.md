# Agent Handoffs

Handoffs are artifact contracts, not prose status messages.

Every handoff records:
- requirement IDs;
- producer/consumer;
- commit/ref;
- produced artifact paths;
- verification commands/results;
- residual blockers;
- downstream interface version.

Canonical handoff definitions live in `../control/handoffs.yaml`.
