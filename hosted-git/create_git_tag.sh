#!/bin/bash

url_to_parse=$GIT_URL
source <(curl -sSL "https://raw.githubusercontent.com/jauninb/jumpstart/master/url_utils.sh")

git_api_url="$proto$host/api/v4/projects/$(basename $(urlencode $path) .git)/repository/tags"

echo "Creating the tag $GIT_TAG on $GIT_COMMIT to repository $GIT_URL"

# Create the Tag
http_response=$(curl -s -w "\n%{http_code}" -X POST --header "Private-Token: $GIT_PASSWORD" $git_api_url \
  --form "tag_name=$GIT_TAG" \
  --form "ref=$GIT_COMMIT")

http_response=(${http_response[@]}) # convert to array
http_post_status=${http_response[-1]} # get last element (last line)
http_post_body=${http_response[@]::${#http_response[@]}-1} 

if [[ "$http_post_status" == "201" ]]; then
   echo "Tag $GIT_TAG created"
   RC=0
else
   echo "Tag $GIT_TAG creation failed - http status: $http_post_status - $http_post_body"
   RC=1
fi
