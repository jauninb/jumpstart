#!/bin/bash

url_to_parse=$GIT_URL
source <(curl -sSL "https://raw.githubusercontent.com/jauninb/jumpstart/master/url_utils.sh")

git_api_url="$proto$host/api/v4/projects/$(basename $(urlencode $path) .git)/merge_requests"

# Create the MergeRequest
http_response=$(curl -s -w "\n%{http_code}" -X POST --header "Private-Token: $GIT_PASSWORD" $git_api_url \
  --form "source_branch=$GIT_BRANCH" \
  --form "target_branch=$TARGET_GIT_BRANCH" \
  --form "title=Merge Request for $GIT_COMMIT" \
  --form "remove_source_branch=false")

http_response=(${http_response[@]}) # convert to array
http_post_status=${http_response[-1]} # get last element (last line)
http_post_body=${http_response[@]::${#http_response[@]}-1} 

if [[ "$http_post_status" == "201" ]]; then
   mr_iid=$(echo $http_post_body | jq -r '.iid')
   mr_merge_status=$(echo $http_post_body | jq -r '.merge_status')
   mr_web_url=$(echo $http_post_body | jq -r '.web_url')
   echo "MergeRequest created - iid: $mr_iid - $mr_web_url"
   # Accept the MergeRequest is possible
   if [[ "$mr_merge_status" == "can_be_merged" ]]; then
      echo "Accept MergeRequest from $GIT_BRANCH to $TARGET_GIT_BRANCH"
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
        RC=3
	  fi
   else
      echo "MergeRequest ( $mr_web_url ) can not be automatically merged - $mr_merge_status"
      RC=2
   fi
else
   echo "MergeRequest creation failed - http status: $http_post_status - $http_post_body"
   RC=1
fi
