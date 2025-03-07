#!/bin/bash

# Ensure you're inside a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "Not a git repository. Exiting."
  exit 1
fi

# Get the latest commit message
COMMIT_MSG=$(git log -1 --pretty=%B | tr -d '\n')

# Get the ticket number from the branch name
TICKET=$(git rev-parse --abbrev-ref HEAD | grep -oP 'TDEV-\d+')

# Extract the commit message after the ticket
MESSAGE=$(echo "$COMMIT_MSG" | sed -E 's/TDEV-[0-9]+[.:]? *//')

# Ensure fallback title if message is empty
if [[ -z "$MESSAGE" ]]; then
  MESSAGE="Merge into develop"
fi

# Construct PR title
PR_TITLE="$TICKET $MESSAGE"

echo "Constructed PR title: $PR_TITLE"

# Check if PR already exists
PR_URL=$(gh pr list --state open --head "$(git rev-parse --abbrev-ref HEAD)" --json url --jq '.[0].url')

if [[ -n "$PR_URL" ]]; then
  echo "PR already exists: $PR_URL"
  EXISTS=true
else
  EXISTS=false
fi

# If PR doesn't exist, create a draft PR
if [[ "$EXISTS" == false ]]; then
  gh pr create --title "$PR_TITLE" \
    --body "This is an automatically created draft PR for the feature branch $(git rev-parse --abbrev-ref HEAD)." \
    --base "develop" \
    --head "$(git rev-parse --abbrev-ref HEAD)" \
    --draft
fi
