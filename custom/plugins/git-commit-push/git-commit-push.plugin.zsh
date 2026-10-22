# Stage every change, commit it, and push the current branch.
unalias gcp 2>/dev/null

gcp() {
  if (( $# == 0 )); then
    print -u2 "usage: gcp <commit message>"
    return 2
  fi

  command git add --all &&
    command git commit --message "$*" &&
    git push
}
