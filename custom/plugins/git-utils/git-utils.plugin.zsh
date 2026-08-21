# Git Utils Plugin
# Custom git utility functions

# Remove the last commit from both local and remote
# Usage: git_remove_last_commit
function git_remove_last_commit() {
  # Check if we're in a git repository
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    return 1
  fi

  # Get current branch name
  local current_branch=$(git branch --show-current)

  if [[ -z "$current_branch" ]]; then
    echo "Error: Not on a branch (detached HEAD state)"
    return 1
  fi

  # Check if there are any commits
  if ! git rev-parse HEAD > /dev/null 2>&1; then
    echo "Error: No commits found"
    return 1
  fi

  # Warn if on main/master branch
  if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]]; then
    echo "Warning: You are on the '$current_branch' branch!"
    echo -n "Are you sure you want to remove the last commit? [y/N] "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo "Aborted."
      return 0
    fi
  fi

  # Show the commit that will be removed
  echo "The following commit will be removed:"
  echo "----------------------------------------"
  git log -1 --oneline
  echo "----------------------------------------"
  echo -n "Continue? [y/N] "
  read -r confirm

  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    return 0
  fi

  # Remove the commit locally
  echo "Removing commit locally..."
  git reset --hard HEAD~1

  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to remove commit locally"
    return 1
  fi

  # Check if the branch exists on remote
  if git rev-parse --verify "origin/$current_branch" > /dev/null 2>&1; then
    echo "Removing commit from remote..."
    git push --force origin "$current_branch"

    if [[ $? -ne 0 ]]; then
      echo "Error: Failed to push to remote. Local commit has been removed."
      return 1
    fi

    echo "Success: Last commit removed from local and remote!"
  else
    echo "Success: Last commit removed locally (branch not found on remote)!"
  fi
}

# Alias for convenience
alias grmlc='git_remove_last_commit'

# Push, setting the upstream automatically when the branch isn't on the remote
# yet, instead of failing with "no upstream branch".
# Usage: git_push_auto_upstream [<git push args>]
function git_push_auto_upstream() {
  local -a value_flags=(-o --push-option --receive-pack --exec --repo)
  local arg has_target=0 has_upstream_flag=0 skip_next=0 rest=0

  for arg in "$@"; do
    if (( skip_next )); then
      skip_next=0
      continue
    fi
    if (( rest )); then
      has_target=1
      break
    fi
    case "$arg" in
      --) rest=1 ;;
      -u|--set-upstream) has_upstream_flag=1 ;;
      --repo=*) has_target=1 ;;
      *)
        if (( ${value_flags[(Ie)$arg]} )); then
          skip_next=1
        elif [[ "$arg" != -* ]]; then
          has_target=1
        fi
        ;;
    esac
  done

  # An explicit remote, or an explicit -u, means the caller knows what they want.
  if (( has_target || has_upstream_flag )); then
    command git push "$@"
    return
  fi

  local branch=$(command git symbolic-ref --quiet --short HEAD 2>/dev/null)
  if [[ -z "$branch" ]] || command git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' &>/dev/null; then
    command git push "$@"
    return
  fi

  local remote=$(command git config --get "branch.$branch.remote")
  if [[ -z "$remote" ]]; then
    local -a remotes=(${(f)"$(command git remote)"})
    if (( ${remotes[(Ie)origin]} )); then
      remote=origin
    elif (( ${#remotes} == 1 )); then
      remote=$remotes[1]
    else
      # No remote, or several and no obvious pick — let git report it.
      command git push "$@"
      return
    fi
  fi

  print -u2 "git-utils: no upstream, running: git push --set-upstream $remote $branch"
  command git push --set-upstream "$@" "$remote" "$branch"
}

# Wrap `git` so a bare `git push` gets the behaviour above.
# Set GIT_AUTO_UPSTREAM=false to opt out.
function git() {
  if [[ "$1" == push && "${GIT_AUTO_UPSTREAM:-true}" == true ]]; then
    shift
    git_push_auto_upstream "$@"
    return
  fi
  command git "$@"
}

alias gpu='git_push_auto_upstream'
