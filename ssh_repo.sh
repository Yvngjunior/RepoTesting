#!/bin/bash
set -euo pipefail

# Minimal GitHub Repo Creator Bot (SSH clone URL output)
# Requirements: curl, jq, and GITHUB_TOKEN env var set
# Usage:
#   export GITHUB_TOKEN=your_token_here
#   ./create_repo.sh

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "❌ Please export your GitHub token first:"
  echo "   export GITHUB_TOKEN=YOUR_GITHUB_TOKEN"
  exit 1
fi

# 1) Prompt for repo details
read -p "Repo name (required): " REPO_NAME
if [ -z "$REPO_NAME" ]; then
  echo "❌ Repo name cannot be empty."
  exit 1
fi

read -p "Description (optional): " DESCRIPTION
read -p "Visibility (public/private) [public]: " VISIBILITY
VISIBILITY=${VISIBILITY:-public}
if [[ "$VISIBILITY" != "public" && "$VISIBILITY" != "private" ]]; then
  echo "❌ Invalid visibility. Use public or private."
  exit 1
fi

echo "Choose license:"
echo "  1) none"
echo "  2) MIT"
echo "  3) Apache-2.0"
echo "  4) gpl-3.0"
read -p "License number [1]: " LIC_CHOICE
LIC_CHOICE=${LIC_CHOICE:-1}
case $LIC_CHOICE in
  2) LICENSE="MIT" ;;
  3) LICENSE="Apache-2.0" ;;
  4) LICENSE="gpl-3.0" ;;
  *) LICENSE="" ;;
esac

# 2) Create repo via GitHub API
POST_DATA="{\"name\":\"$REPO_NAME\",\"description\":\"$DESCRIPTION\",\"private\":$( [ "$VISIBILITY" = "private" ] && echo true || echo false )"
if [ -n "$LICENSE" ]; then
  POST_DATA+=",\"license_template\":\"$LICENSE\""
fi
POST_DATA+="}"

RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "$POST_DATA" https://api.github.com/user/repos)

# 3) Extract SSH URL using jq
CLONE_URL=$(echo "$RESPONSE" | jq -r '.ssh_url // empty')
FULL_NAME=$(echo "$RESPONSE" | jq -r '.full_name // empty')
ERROR_MSG=$(echo "$RESPONSE" | jq -r '.message // empty')

if [ -n "$CLONE_URL" ]; then
  echo "✅ Repo created: $FULL_NAME"
  echo "👉 SSH URL: $CLONE_URL"
else
  echo "❌ Failed to create repo."
  echo "GitHub says: $ERROR_MSG"
fi
