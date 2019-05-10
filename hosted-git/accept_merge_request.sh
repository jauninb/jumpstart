#!/bin/bash
# set -x

unset url_to_parse
unset git_api_url
unset http_response
unset http_post_status
unset http_post_body

url_to_parse=$GIT_URL
source <(curl -sSL "https://raw.githubusercontent.com/jauninb/jumpstart/master/url_utils.sh")

git_api_url="$proto$host/api/v4/projects/$(basename $(urlencode $path) .git)/merge_requests"

if [[ "$GIT_EVENT_PROVIDER" == "gitlab" ]] && [[ "$GIT_EVENT_TYPE" == "merge_request" ]]; then
  # GIT_REQUEST_URL=https://git.eu-de.bluemix.net/bp2i-s8-tc/lamp-playbook-bp2i/merge_requests/1
  mr_web_url=$GIT_REQUEST_URL
  # Find the MergeRequest id from the GIT_REQUEST_URL
  mr_iid=${GIT_REQUEST_URL##*/}
  http_response=$(curl -s -w "\n%{http_code}" -X PUT --header "Private-Token: $GIT_PASSWORD" $git_api_url/$mr_iid/merge \
    --form "sha=$GIT_COMMIT" \
    --form "squash=false" \
  )
  http_response=(${http_response[@]}) # convert to array
  http_put_status=${http_response[-1]} # get last element (last line)
  http_put_body=${http_response[@]::${#http_response[@]}-1}
  if [[ "$http_put_status" == "201" ]]; then
    echo "MergeRequest ( $mr_web_url ) was merged automatically"
  RC=0
  else
    echo "MergeRequest ( $mr_web_url ) was not merged automatically - http status: $http_put_status - $http_put_body"
  RC=1
  fi
else
  echo "Git event triggering pipeline is not a Merge Request"
fi
