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
	@echo "  check-all   check + the SDK install-extras gate (needs network)"
	@echo "  setup       npm i -g mint"
	@echo
	@echo "  dev         mint dev — local preview on http://localhost:3000"

# ---- check -------------------------------------------------------
#
# MEASURED at 1.8 s on the current tree, and green.
#
# This repo has no test suite. The automated checks on a docs PR are the
# org-shared ones (gitleaks + house-rules, which need the shared checker
# from tracebloc/.github and are not reproducible from a working tree),
# preview-page-coverage.yml — which probes the RENDERED site over HTTP
# after Mintlify has deployed, so by construction it cannot run against
# local files — and sdk-extras-check.yml, which CAN run locally and is
# wired into check-all below.
#
# `mint broken-links` is what catches a bad link before pushing. It is
# also the check that would have caught the class of problem
# preview-page-coverage.yml exists to catch, one step earlier.
.PHONY: check
check: guard-mint
	$(MINT) broken-links

# check-all adds the one gate that needs network: every documented
# `pip install "tracebloc[...]"` line must name an extra that really
# exists in the release its floor resolves to (backend#1858). Kept out of
# `check` so the fast path stays offline and under the 60 s budget.
.PHONY: check-all
check-all: check check-sdk-extras
	@echo "==> check-all: green"

.PHONY: check-sdk-extras
check-sdk-extras:
	python3 scripts/check-sdk-extras.py

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
