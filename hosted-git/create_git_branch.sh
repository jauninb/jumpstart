#!/bin/bash
url_to_parse=$GIT_URL
source <(curl -sSL "https://raw.githubusercontent.com/jauninb/jumpstart/master/url_utils.sh")

git_api_url="$proto$host/api/v4/projects/$(basename $(urlencode $path) .git)/repository/branches"

# Create a git branch using REST API out of the provided GIT_COMMIT
http_response=$(curl -s -w "\n%{http_code}" -X POST --header "Private-Token: $GIT_PASSWORD" $git_api_url \
  --form "branch=$NEW_GIT_BRANCH" \
  --form "ref=$GIT_COMMIT")
