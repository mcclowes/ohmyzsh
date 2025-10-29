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
