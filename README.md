# tracebloc documentation

Product documentation for [tracebloc](https://tracebloc.io), built on
[Mintlify](https://mintlify.com) and published at
**[docs.tracebloc.io](https://docs.tracebloc.io)**. This is the current
production docs site (it replaced the older Docusaurus-based `documentation`
repo).

## Local preview

```bash
npm i -g mint      # install the Mintlify CLI (one-time)
mint dev           # local preview at http://localhost:3000
mint broken-links  # check for broken links
```

## Structure

Pages are `.mdx` files with YAML frontmatter; navigation, theme, and redirects
live in [`docs.json`](docs.json).

| Section | Contents |
|---------|----------|
| `overview/` | Platform overview |
| `create-use-case/` | Prerequisites, dataset prep, defining use cases, templates |
| `join-use-case/` | Exploring, joining, training, hyperparameters, model optimization/evaluation |
| `environment-setup/` | Setup guide, quickstart, deployment (local / bare-metal / EKS / AKS / OpenShift), configuration, operations, CLI, security, troubleshooting |
| `tools-help/` | tracebloc Python package, FAQs, key terms |

Some pages are **synced** from other repos (e.g. `environment-setup/setup-guide.mdx`
from `tracebloc/client`'s README) — see [`.github/sync-sources.yml`](.github/sync-sources.yml).
Edit the source repo for synced content, not the generated page.

## Contributing

- Follow the style guide in [`AGENTS.md`](AGENTS.md) and the canonical vocabulary
  in [`TERMINOLOGY.md`](TERMINOLOGY.md) — one concept, one word.
- Add new pages to the navigation in `docs.json`, or they won't be reachable.
- `CLAUDE.md` has the same guidance oriented for Claude Code.

## Deployment

The Mintlify GitHub app auto-deploys to production on push to the default branch
(`main`). Open a PR against `main`.
