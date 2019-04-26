#!/bin/bash
# uncomment to debug the script
# set -x
unset url_to_parse
unset git_api_url
unset http_response
unset http_get_status
unset http_get_body

url_to_parse=$GIT_URL
source <(curl -sSL "https://raw.githubusercontent.com/jauninb/jumpstart/master/url_utils.sh")

git_api_url="$proto$host/api/v4/projects/$(basename $(urlencode $path) .git)/repository/commits/$GIT_COMMIT/refs?type=branch"

# Find the branch reference for the git commit
http_response=$(curl -s -w "\n%{http_code}" -X GET --header "Private-Token: $GIT_PASSWORD" $git_api_url)

http_response=(${http_response[@]}) # convert to array
http_get_status=${http_response[-1]} # get last element (last line)
http_get_body=${http_response[@]::${#http_response[@]}-1} 

echo "HTTP GET $git_api_url - $http_get_status"
echo "$http_get_body"

if echo "$http_get_body" | jq -e --arg TARGET_GIT_BRANCH "${TARGET_GIT_BRANCH}"  '.[] | select(.name==$TARGET_GIT_BRANCH)'; then
  RC=0
else
  RC=1
fi
