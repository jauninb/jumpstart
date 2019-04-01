#!/bin/bash
# uncomment to debug the script
# set -x

url_to_parse=$GIT_URL
source <(curl -sSL "https://raw.githubusercontent.com/jauninb/jumpstart/master/url_utils.sh")

git_api_url="$proto$host/api/v4/projects/$(basename $(urlencode $path) .git)/repository/branches"

# Create a git branch using REST API out of the provided GIT commit or a GIT tag
http_response=$(curl -s -w "\n%{http_code}" -X POST --header "Private-Token: $GIT_PASSWORD" $git_api_url \
  --form "branch=$NEW_GIT_BRANCH" \
  --form "ref=$GIT_COMMIT_OR_GIT_TAG")

http_response=(${http_response[@]}) # convert to array
http_post_status=${http_response[-1]} # get last element (last line)
http_post_body=${http_response[@]::${#http_response[@]}-1} 

if [[ "$http_post_status" == "201" ]]; then
  echo "Branch $NEW_GIT_BRANCH created"
  RC=0
else 
  echo "Branch creation failed - http status: $http_post_status - $http_post_body"
  RC=1
fi