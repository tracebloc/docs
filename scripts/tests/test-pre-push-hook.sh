#!/bin/sh
# test-pre-push-hook.sh — behaviour tests for `make install-hooks` and the
# generated pre-push hook, driven by running real `make` against a copy of the
# Makefile in a throwaway git repo. Pure POSIX sh, no test framework, so
# `make test-hooks` runs it anywhere.
#
# Covers the branches a future edit could silently break:
#   * fresh install writes an executable, ours-marked hook
#   * re-install is idempotent (ours -> rewrite, no error)
#   * a foreign pre-push hook is left untouched
#   * core.hooksPath outside the repo is refused (no shared-dir stomp), in every
#     escaping form — including a `..` hidden behind a not-yet-created prefix
#     (`missing/../..`), where the ancestor-walk climbed past the missing prefix
#     and read the worktree as the target, writing pre-push into the parent
#     (backend#2716). A `..` in the not-yet-created suffix is unresolvable until
#     the prefix exists, so the guard refuses it.
#   * an in-repo hooks dir — real, or not yet created (fresh clone) — installs
#   * the hook skips delete-only / no-op pushes (all-zero local sha)
#   * the hook degrades gracefully when `make` is off PATH (GUI clients)
set -eu

# Hermetic: ignore the developer's global/system git config so an ambient
# core.hooksPath (corp dotfiles, husky) can't make install-hooks skip and fail
# the fresh-install/reinstall assertions. Every git here sees only local config.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

REPO_ROOT=$(unset CDPATH; cd -- "$(dirname -- "$0")/../.." && pwd)
MAKEFILE="$REPO_ROOT/Makefile"
Z=0000000000000000000000000000000000000000
fails=0
check() { if [ "$1" = "$2" ]; then echo "  ok: $3"; else echo "  FAIL: $3 (got '$1', want '$2')"; fails=$((fails + 1)); fi; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
git init -q .
git config user.email t@t; git config user.name t
cp "$MAKEFILE" ./Makefile
hook=.git/hooks/pre-push

# 1) fresh install
make -s install-hooks >/dev/null
check "$( [ -x "$hook" ] && echo yes )" "yes" "fresh install writes an executable hook"
check "$(grep -c 'tracebloc pre-push hook' "$hook")" "1" "hook carries the ours-marker"

# 2) idempotent re-install
make -s install-hooks >/dev/null
check "$(grep -c 'tracebloc pre-push hook' "$hook")" "1" "re-install stays idempotent"

# 3) foreign hook left untouched
printf '#!/bin/sh\necho FOREIGN\n' > "$hook"
make -s install-hooks >/dev/null
check "$(grep -c FOREIGN "$hook")" "1" "foreign hook is preserved"
rm -f "$hook"

# 4) core.hooksPath pointing OUTSIDE the repo is refused, in every escaping form
# (absolute, relative, and .. segments that string-prefix as inside). Assert the
# resolved shared dir stays empty — checking only .git/hooks would miss a hook
# written into the configured dir, and a string-prefix guard misses .. escapes.
outside=$(mktemp -d)                       # a sibling of $work, definitely outside
for form in "$outside" "../$(basename "$outside")" "$work/../$(basename "$outside")"; do
  git config core.hooksPath "$form"
  make -s install-hooks >/dev/null
  check "$( [ -e "$outside/pre-push" ] && echo present || echo absent )" "absent" "core.hooksPath outside repo refused: $form"
  rm -f "$outside/pre-push"
  git config --unset core.hooksPath
done
rm -rf "$outside"

# 4b) core.hooksPath INSIDE the repo is honoured (install proceeds there).
mkdir -p "$work/.githooks"
git config core.hooksPath .githooks
make -s install-hooks >/dev/null
check "$(grep -c 'tracebloc pre-push hook' "$work/.githooks/pre-push" 2>/dev/null || echo 0)" "1" "core.hooksPath inside repo: hook installed there"
git config --unset core.hooksPath
rm -rf "$work/.githooks"

# 4c) core.hooksPath escapes to a dir OUTSIDE the worktree, in the shapes earlier
# guards missed: a bare `..`/`./..` (the dirname guard resolved it back inside),
# and a `..` hidden behind a not-yet-created prefix — `missing/../..`,
# `missing/../../shared` — where the ancestor-walk climbed past the missing prefix
# and read the worktree as the target. Both wrote pre-push above the worktree, the
# stomp the guard exists to prevent (backend#2716). Assert nothing lands outside.
esc=$(mktemp -d)
mkdir -p "$esc/repo"
( cd "$esc/repo" && git init -q . && git config user.email t@t && git config user.name t \
  && cp "$MAKEFILE" ./Makefile )
for form in ".." "./.." "missing/../.." "missing/../../shared"; do
  ( cd "$esc/repo" && git config core.hooksPath "$form" && make -s install-hooks >/dev/null )
  check "$(find "$esc" -name pre-push -not -path "$esc/repo/*" 2>/dev/null | head -1 | grep -q . && echo present || echo absent)" "absent" "core.hooksPath parent-escape refused: $form"
  find "$esc" -name pre-push -not -path "$esc/repo/*" -delete 2>/dev/null
  ( cd "$esc/repo" && rm -rf missing shared )
done
rm -rf "$esc"

# 4d) a not-yet-created IN-REPO hooks dir still INSTALLS — the fresh-clone case
# the ancestor-walk exists for, and the arm the suffix-`..` refusal must not
# over-block. No `..`, so it is unambiguously in-repo.
git config core.hooksPath freshhooks
make -s install-hooks >/dev/null
check "$(grep -c 'tracebloc pre-push hook' "$work/freshhooks/pre-push" 2>/dev/null || echo 0)" "1" "core.hooksPath in-repo but not-yet-created: hook installed"
git config --unset core.hooksPath
rm -rf "$work/freshhooks"

# reinstall a clean ours-hook for the behavioural cases
make -s install-hooks >/dev/null

# 5) delete-only push (all-zero local sha) is skipped without running make
if printf 'refs/heads/x %s refs/heads/x %s\n' "$Z" deadbeef | sh "$hook"; then rc=0; else rc=$?; fi
check "$rc" "0" "delete-only push is skipped (exit 0)"

# 6) real push but make absent -> graceful skip, not 'command not found'
if printf 'refs/heads/x deadbeef refs/heads/x 000\n' | env PATH= /bin/sh "$hook"; then rc=0; else rc=$?; fi
check "$rc" "0" "missing make degrades to skip (exit 0)"

echo "--- pre-push hook tests: $( [ "$fails" -eq 0 ] && echo ALL GREEN || echo "$fails FAILED" ) ---"
[ "$fails" -eq 0 ]
