# Contributing

Thanks for your interest. This project has one strong opinion: **stay small.** It is
Python standard library only, no Node, no pip, no database, no build step. Keep it
that way. A change that adds a framework, a bundler, or a runtime dependency needs a
very good reason and will usually be declined in favor of a stdlib approach.

## Setup

```bash
git clone https://github.com/m-esm/my-inventory.git
cd my-inventory
python3 server.py        # http://localhost:8770/dashboard
```

No install step. Python 3.9+ is enough.

## Before you open a PR

- Run the server and click through the change. There is no build to "pass"; the
  proof is the app working. Capture/edit/delete, the duplicate flow, and the
  to-buy page are the paths most likely to break.
- Keep the diff focused. One concern per PR.
- Match the existing style. The HTML pages are intentionally framework-free; the
  server is a single file. Read [CLAUDE.md](CLAUDE.md) for the architecture, data
  model, and API contract before changing endpoints.
- Don't commit secrets or local state. `data/users.json`, `data/*.bak`,
  `data/pending.json`, `data/wishlist.json`, and `deploy/admin.env` are gitignored
  for a reason. Never add real credentials, server IPs, or personal data.

## Data safety

`data/` and `captures/` hold real inventory data. Any script or change that touches
them must back up first and must never `rm -rf` or `git clean` over them. Writes go
through the atomic save helpers in `server.py`, which keep a one-step `.bak`.

## Reporting bugs

Open an issue with what you did, what you expected, and what happened. A screenshot
of the dashboard state helps, since the app is visual.
