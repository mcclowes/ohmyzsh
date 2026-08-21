#!/usr/bin/env zsh
# Tests for the git push auto-upstream wrapper in git-utils.
# Run: zsh custom/plugins/git-utils/tests/git-push-upstream.test.zsh

set -u

local plugin_dir="${0:A:h:h}"
source "$plugin_dir/git-utils.plugin.zsh"

typeset -g pass=0 fail=0
typeset -g sandbox=""

ok() { print "  ok - $1"; (( pass++ )); return 0 }
notok() { print "  NOT OK - $1"; (( fail++ )); return 0 }

assert_eq() {
  if [[ "$1" == "$2" ]]; then
    ok "$3"
  else
    notok "$3"
    print "      expected: $2"
    print "      actual:   $1"
  fi
}

# Fresh repo with a bare "origin" and one commit on branch feat/thing.
setup_repo() {
  sandbox=$(mktemp -d)
  command git init --bare -q "$sandbox/origin.git"
  command git init -q -b main "$sandbox/work"
  command git -C "$sandbox/work" config user.email t@example.com
  command git -C "$sandbox/work" config user.name test
  command git -C "$sandbox/work" config push.autoSetupRemote false
  command git -C "$sandbox/work" remote add origin "$sandbox/origin.git"
  print seed > "$sandbox/work/file"
  command git -C "$sandbox/work" add file
  command git -C "$sandbox/work" commit -qm seed
  cd "$sandbox/work"
}

teardown_repo() {
  cd /
  [[ -n "$sandbox" ]] && rm -rf "$sandbox"
}

upstream_of() { command git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null }

print "git push auto-upstream"

# 1. No upstream: git push should set it up and push.
setup_repo
command git checkout -q -b feat/thing
git push >/dev/null 2>&1
assert_eq "$(upstream_of)" "origin/feat/thing" "sets upstream when branch is not on the remote"
assert_eq "$(command git rev-parse HEAD)" "$(command git rev-parse origin/feat/thing)" "actually pushes the commit"
teardown_repo

# 2. Upstream already set: plain passthrough.
setup_repo
command git push -q -u origin main >/dev/null 2>&1
print more > extra; command git add extra; command git commit -qm extra
git push >/dev/null 2>&1
assert_eq "$(command git rev-parse HEAD)" "$(command git rev-parse origin/main)" "pushes normally when upstream exists"
teardown_repo

# 3. Explicit remote/refspec: do not silently add -u.
setup_repo
command git checkout -q -b feat/explicit
git push origin HEAD >/dev/null 2>&1
assert_eq "$(upstream_of)" "" "leaves upstream unset when a remote is given explicitly"
assert_eq "$(command git rev-parse HEAD)" "$(command git rev-parse origin/feat/explicit)" "still pushes with an explicit remote"
teardown_repo

# 4. Flags only still counts as no target.
setup_repo
command git checkout -q -b feat/flags
git push --quiet >/dev/null 2>&1
assert_eq "$(upstream_of)" "origin/feat/flags" "sets upstream when only flags are passed"
teardown_repo

# 5. Single non-origin remote is used.
setup_repo
command git remote rename origin fork >/dev/null 2>&1
command git checkout -q -b feat/fork
git push >/dev/null 2>&1
assert_eq "$(upstream_of)" "fork/feat/fork" "uses the only remote when there is no origin"
teardown_repo

# 6. Non-push subcommands pass through untouched.
setup_repo
assert_eq "$(git rev-parse --abbrev-ref HEAD)" "main" "passes other subcommands through"
teardown_repo

# 7. Detached HEAD falls through to real git (which errors).
setup_repo
command git checkout -q --detach HEAD
git push >/dev/null 2>&1
assert_eq "$(( $? != 0 ))" "1" "falls through on detached HEAD"
teardown_repo

# 8. Opt-out.
setup_repo
command git checkout -q -b feat/optout
GIT_AUTO_UPSTREAM=false git push >/dev/null 2>&1
assert_eq "$(upstream_of)" "" "GIT_AUTO_UPSTREAM=false disables the wrapper"
teardown_repo

print ""
print "$pass passed, $fail failed"
(( fail == 0 ))
