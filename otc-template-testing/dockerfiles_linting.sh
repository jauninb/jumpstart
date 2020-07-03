#!/bin/bash
# This script finds the Dockerfile files in the open-toolchain organization and perform a Dockerlint of them
#set -x

curl -H "Accept: application/vnd.github.preview" "https://api.github.com/search/code?q=user:open-toolchain+filename:Dockerfile&per_page=100" | jq -r -c '.items[] | select(.name=="Dockerfile") | ("https://raw.githubusercontent.com/" + .repository.full_name + "/master/" + .path)' | \
  sort -u -r | tr -d '\r' > dockerfile_urls.lst

for dockerfile_url in $( < dockerfile_urls.lst); do
   echo "========================================="
   echo "Performing docker lint using hadolint for $dockerfile_url"
   curl -s --retry 3 --no-keepalive -o aDockerfile "$dockerfile_url"
   #cat aDockerfile
   #echo "** Doing docker lint **"
   docker run --rm -i hadolint/hadolint < aDockerfile
done
