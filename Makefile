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
	@echo "  install-hooks  (re)install the git pre-push hook that runs 'make check'"
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
	@$(MAKE) --no-print-directory install-hooks

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

# install-hooks: put a pre-push hook in place that runs `make check`, so the
# canon's "run the tests before you push" is carried by the tooling rather than
# by memory. Factored out of `setup` so it is independently runnable and
# testable, and so a contributor who only wants the hook need not rerun the
# full `make setup`.
#
# Honest by design: the hook catches FORGETTING, not defiance — `git push
# --no-verify` skips it and always will. And it refuses to clobber a pre-push
# hook that is already there and not ours (e.g. one the pre-commit framework
# manages), rather than silently stomping a contributor's setup.
#
# `git rev-parse --git-path hooks` (not a hard-coded `.git/hooks`) so it lands
# in the right place inside a linked worktree or a submodule, where the git dir
# is not `.git`.
.PHONY: install-hooks
install-hooks:
	@if ! git rev-parse --git-dir >/dev/null 2>&1; then \
	  echo "note: not a git checkout — skipping pre-push hook install"; \
	elif hp="$$(git config --get core.hooksPath 2>/dev/null || true)"; [ -n "$$hp" ] && { \
	       hd="$$(git rev-parse --git-path hooks)"; \
	       case "$$hd" in /*) hdd="$$hd";; *) hdd="$$PWD/$$hd";; esac; \
	       cpar="$$(cd "$$(dirname "$$hdd")" 2>/dev/null && pwd -P || true)"; \
	       ctop="$$(cd "$$(git rev-parse --show-toplevel)" && pwd -P)"; \
	       [ -z "$$cpar" ] || case "$$cpar/" in "$$ctop/"*) false;; *) true;; esac; \
	     }; then \
	  echo "note: core.hooksPath is set to '$$hp', outside this repo — skipping."; \
	  echo "      That is a shared hooks dir; installing here would run 'make check' from every repo you push."; \
	  echo "      Add 'make check' to that hook by hand if you want it everywhere."; \
	else \
	  hook="$$(git rev-parse --git-path hooks)/pre-push"; \
	  if [ -e "$$hook" ] && ! grep -q 'tracebloc pre-push hook' "$$hook" 2>/dev/null; then \
	    echo "note: $$hook already exists and is not ours — leaving it untouched."; \
	    echo "      add 'make check' to it, or remove it and re-run 'make install-hooks'."; \
	  else \
	    mkdir -p "$$(dirname "$$hook")" && \
	    printf '%s\n' \
	      '#!/bin/sh' \
	      '# tracebloc pre-push hook installed by make setup (backend#1606).' \
	      '# Runs make check so a push that would be red in CI is caught locally first.' \
	      '# It catches forgetting, not defiance: git push --no-verify skips it.' \
	      '#' \
	      '# Nothing to check on a delete/no-op push: a branch delete streams a' \
	      '# local sha of all-zeros on stdin (no new commits). Skip so a red tree' \
	      '# cannot block "git push --delete", and cleanup pushes stay free.' \
	      'z=0000000000000000000000000000000000000000' \
	      'had_update=0' \
	      'while read -r _ local_sha _ _; do' \
	      '  [ "$$local_sha" != "$$z" ] && had_update=1' \
	      'done' \
	      '[ "$$had_update" = 0 ] && exit 0' \
	      '#' \
	      '# Degrade gracefully when the toolchain is absent: GUI/IDE git clients' \
	      '# (Tower, GitKraken, VS Code) launch hooks with a minimal PATH, so make' \
	      '# may be missing — and several do not expose --no-verify. Skipping beats' \
	      '# hard-blocking every push with "make: command not found".' \
	      'command -v make >/dev/null 2>&1 || exit 0' \
	      '#' \
	      '# Git exports GIT_DIR/GIT_WORK_TREE/etc into hook processes; a nested git' \
	      '# invocation (from a test, tool, or setuptools-scm) then fails in a linked' \
	      '# worktree with exit status 128. Clear them so make check runs as from the shell.' \
	      'unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY' \
	      'exec make check' > "$$hook" && \
	    chmod +x "$$hook" && \
	    echo "==> pre-push hook installed at $$hook" && \
	    echo "    'make check' now runs before each push (skip once with: git push --no-verify)"; \
	  fi; \
	fi
