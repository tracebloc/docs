# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo does

Mintlify-powered product documentation for tracebloc, published at https://docs.tracebloc.io. This is the current production docs site (replacing the older Docusaurus-based `documentation` repo).

## Preview and build

```bash
npm i -g mint     # Install Mintlify CLI (one-time)
mint dev          # Local preview at http://localhost:3000
mint broken-links # Check for broken links
mint update       # Update CLI to latest version
```

## Key files

- `docs.json` -- Mintlify configuration (navigation, theme, colors, SEO, footer)
- `AGENTS.md` -- Existing AI agent instructions (style guide, terminology)
- Pages are `.mdx` files with YAML frontmatter

## Content sections (defined in docs.json navigation)

- `overview/` -- Platform overview
- `create-use-case/` -- Prerequisites, dataset prep, defining use cases, templates
- `join-use-case/` -- Exploring, joining, training, hyperparameters, model optimization/evaluation
- `environment-setup/` -- Setup guide, configuration, EKS deployment, troubleshooting
- `tools-help/` -- tracebloc Python package, FAQs, key terms

## Deployment

Push to the default branch; the Mintlify GitHub app auto-deploys to production.

## Style notes (from AGENTS.md)

- Active voice, second person ("you")
- Sentence case for headings
- Bold for UI elements, code formatting for file names/commands/paths
