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
# MEASURED at 1.8 s warm (2.9 s cold) on the current tree, and green.
#
# The "and green" half of that claim was false from the day it was
# written, and is only true again as of this commit. `mint broken-links`
# MDX-parses the repo-meta markdown at the root, and the org-standards
# sync had already written HTML comments — which MDX cannot represent —
# into CLAUDE.md on 2026-08-10, the day before this target landed. So
# `make check` was red on develop for its entire life up to here, and the
# pre-push hook that runs it would have blocked every push. Fixed by
# listing those files in .mintignore, which carries the reasoning and the
# per-file measurements.
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
#
# The prerequisite is spelled `guard-toolchain` — the uniform name the pre-push
# hook asks for before it runs `make check` (backend#1995) — and in this repo
# that is guard-mint.
.PHONY: check
check: guard-toolchain
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

# guard-toolchain: is the toolchain `check` needs on PATH at all?
#
# The uniform name every repo exposes, so the pre-push hook can ask one
# question — "can this shell run check at all?" — and skip itself on failure
# rather than hard-failing the push on "mint: command not found"
# (backend#1995). GUI/IDE git clients launch hooks with a minimal PATH, where
# /usr/bin/make is present but `npm i -g mint` output is not.
#
# Reuses guard-mint rather than making a second copy of that check: `check`
# depends on this target, so the mint probe lives in exactly one place and
# cannot drift as `check` changes. (`check-all` additionally needs python3,
# which is a base-system tool and is not gated here; the hook only runs
# `check`.)
#
# node is checked too, because mint IS a node program — its bin is a
# `#!/usr/bin/env node` script. mint on PATH without node on PATH is a REAL
# combination: `npm i -g mint` can land the shim in a prefix a GUI hook shell
# has while nvm/fnm/volta put node somewhere it does not. Then mint is found and
# dies with "env: node: No such file or directory", exit 127 — the same hard
# failure backend#1995 is about.
#
# TOOLS, NOT DEPENDENCIES: it asks whether mint and node are on PATH, never
# whether the docs tree is in a state mint would accept. A broken link is a real
# failure and must NOT be skipped just because "cannot run" and "runs and fails"
# look similar from the outside.
.PHONY: guard-toolchain
guard-toolchain: guard-mint
	@command -v node >/dev/null 2>&1 || { \
	  echo "node is not on PATH — the Mintlify CLI is a Node program; install Node, then:"; \
	  echo "  make setup"; \
	  exit 1; }

# dev: local preview, per README.md.
.PHONY: dev
dev: guard-mint
	$(MINT) dev

# test-hooks: run the install-hooks / pre-push-hook behaviour suite on demand.
# Not a `check` dependency: it runs real `make` in throwaway git repos, so an
# environment quirk (old git, noexec /tmp) could block a local push on something
# CI never sees. Run it directly with `make test-hooks` (backend#1749).
.PHONY: test-hooks
test-hooks:
	@sh scripts/tests/test-pre-push-hook.sh

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
#
# The core.hooksPath guard below resolves the HOOKS DIRECTORY ITSELF, not its
# parent (frontend-app#809). Two cases the parent-based version got wrong:
#
#   symlink   core.hooksPath=.githooks where .githooks is a symlink to a shared
#             dir. `dirname` is the checkout root, which resolves in-repo, so it
#             installed — and the write went THROUGH the symlink into the shared
#             dir. The one path element that can point elsewhere was the only
#             one never resolved.
#   worktree  a linked worktree whose core.hooksPath is the main repo's
#             .git/hooks. The parent is outside the worktree's toplevel, so it
#             skipped — even though that directory belongs to the SAME
#             repository, and the worktree silently got no hook.
#
# So: resolve the hooks dir itself when it exists, else the deepest existing
# ancestor (there is no symlink left to resolve below that), and count it as
# in-repo if it is under EITHER the worktree toplevel OR the repo's common git
# dir. The common-git-dir arm is what fixes the worktree case without
# re-opening the shared-dir case the guard legitimately exists to catch. An
# unresolvable path still skips: "cannot tell" is not evidence that it is ours.
#
# One escape the walk alone still missed: a `..` hidden behind a not-yet-created
# prefix (core.hooksPath=missing/../..) makes it climb PAST the missing prefix to
# the worktree and read it as in-repo — writing pre-push into the parent, the
# stomp above. That suffix is unresolvable until the prefix exists, so the guard
# tracks what it walked past and refuses any `..` left in that tail (backend#2716).
.PHONY: install-hooks
install-hooks:
	@if ! git rev-parse --git-dir >/dev/null 2>&1; then \
	  echo "note: not a git checkout — skipping pre-push hook install"; \
	elif hp="$$(git config --get core.hooksPath 2>/dev/null || true)"; [ -n "$$hp" ] && { \
	       hd="$$(git rev-parse --git-path hooks)"; \
	       case "$$hd" in /*) hdd="$$hd";; *) hdd="$$PWD/$$hd";; esac; \
	       hdx="$$hdd"; sfx=''; \
	       while [ ! -d "$$hdx" ] && [ "$$hdx" != "$$(dirname "$$hdx")" ]; do \
	         sfx="$$(basename "$$hdx")/$$sfx"; hdx="$$(dirname "$$hdx")"; \
	       done; \
	       chd="$$(cd "$$hdx" 2>/dev/null && pwd -P || true)"; \
	       ctop="$$(cd "$$(git rev-parse --show-toplevel)" && pwd -P)"; \
	       cgd="$$(cd "$$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P || true)"; \
	       inr=0; \
	       case "$$chd/" in "$$ctop/"*) inr=1;; esac; \
	       if [ -n "$$cgd" ]; then case "$$chd/" in "$$cgd/"*) inr=1;; esac; fi; \
	       case "/$$sfx" in */../*) inr=0;; esac; \
	       [ -z "$$chd" ] || [ "$$inr" = 0 ]; \
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
	      '# worktree with exit status 128. Clear them so the make runs below behave' \
	      '# as they do from an ordinary shell.' \
	      'unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY' \
	      '#' \
	      '# Guarding on make alone was not enough (backend#1995): /usr/bin/make ships' \
	      '# with the Xcode CLT and sits on the default launchd PATH, while the tools' \
	      '# make check actually runs — yarn/node via nvm/fnm/volta, mint via npm -g —' \
	      '# are put on PATH by shell rc files this hook shell never sources. So the' \
	      '# skip above passed and the push then hard-failed on "command not found":' \
	      '# exactly the outcome the skip exists to prevent, and VS Code offers no' \
	      '# --no-verify on push.' \
	      '#' \
	      '# Ask the Makefile rather than restating the tool list here: guard-toolchain' \
	      '# is a prerequisite of check itself, so it cannot drift when check gains a' \
	      '# dependency. It guards on the TOOLS, not on installed dependencies — a' \
	      '# missing node_modules is a real failure and must not be skipped.' \
	      'make guard-toolchain >/dev/null 2>&1 || exit 0' \
	      'exec make check' > "$$hook" && \
	    chmod +x "$$hook" && \
	    echo "==> pre-push hook installed at $$hook" && \
	    echo "    'make check' now runs before each push (skip once with: git push --no-verify)"; \
	  fi; \
	fi
