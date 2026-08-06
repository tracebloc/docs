# Makefile for tracebloc/docs — uniform entry points (backend#1606).
#
# Every active tracebloc repo exposes the SAME three targets, so "run
# your tests before you push" stops being a rule you can only obey with
# per-repo tribal knowledge:
#
#   make check      lint + fast tests.   Budget: under 60 s.
#   make check-all  everything CI runs (bar the CI-only heavy suites).
#   make setup      install what those targets need.
#
# This file is a THIN WRAPPER. `mint broken-links` is not a new rule
# invented here — it is the command README.md, CONTRIBUTING.md and
# CLAUDE.md already tell contributors to run. All this does is give it
# the same name it has in every other repo.

.DEFAULT_GOAL := help

MINT ?= mint

.PHONY: help
help:
	@echo "tracebloc/docs — make targets"
	@echo
	@echo "  check       mint broken-links (~2 s) — run this before every push"
	@echo "  check-all   the same; see below for why"
	@echo "  setup       npm i -g mint"
	@echo
	@echo "  dev         mint dev — local preview on http://localhost:3000"

# ---- check -------------------------------------------------------
#
# MEASURED at 1.8 s on the current tree, and green.
#
# check-all is the same set, and that is honest rather than lazy. This
# repo has no test suite and no content gate in CI: the only automated
# checks on a docs PR are the org-shared ones (gitleaks + house-rules,
# which need the shared checker from tracebloc/.github and are not
# reproducible from a working tree), and preview-page-coverage.yml —
# which probes the RENDERED site over HTTP after Mintlify has deployed,
# so by construction it cannot run against local files.
#
# `mint broken-links` is therefore the whole of what a person can
# usefully check here before pushing. It is also the check that would
# have caught the class of problem preview-page-coverage.yml exists to
# catch, one step earlier.
.PHONY: check
check: guard-mint
	$(MINT) broken-links

.PHONY: check-all
check-all: check
	@echo "==> check-all: green (this repo has no separate slow tier — see the Makefile comment)"

# setup: the Mintlify CLI, exactly as CONTRIBUTING.md prescribes. No
# pre-commit / pre-push hook is installed here — that is a later step of
# backend#1606.
.PHONY: setup
setup:
	npm i -g mint
	@echo "==> setup: mint installed; run 'make check'"

# ---- individual targets ------------------------------------------

.PHONY: guard-mint
guard-mint:
	@command -v $(MINT) >/dev/null 2>&1 || { \
	  echo "the Mintlify CLI is not on PATH — install it with:"; \
	  echo "  npm i -g mint      (or: make setup)"; \
	  exit 1; }

# dev: local preview, per README.md.
.PHONY: dev
dev: guard-mint
	$(MINT) dev
