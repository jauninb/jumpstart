#!/bin/bash
# This script finds the commons scripts usage in the templates in the open-toolchain organization

curl -H "Accept: application/vnd.github.preview" "https://api.github.com/search/code?q=user:open-toolchain+path:.bluemix+filename:toolchain.yml&per_page=100" > github_otc-templates_repositories.json

# check if result is complete or not
RESULT_NOT_COMPLETE=$(cat github_otc-templates_repositories.json | jq -r '.incomplete_results')
if [ "$RESULT_NOT_COMPLETE" == "true" ]; then
   echo "WARNING: List of github.com/open-toolchain repositories is not complete - Only $(cat github_otc-templates_repositories.json | jq -r '.items | length') found out of $(cat github_otc-templates_repositories.json | jq -r '.total_count')"
fi

# prepare for templates cloning
rm -r -f templates
mkdir -p templates

cd templates

# clone commons repository
git clone --depth 1 https://github.com/open-toolchain/commons


# clone each otc template repo
for repo in $(cat ../github_otc-templates_repositories.json | jq -r '.items[] | .repository.html_url' | sort -u); do
   echo "Performing git clone $repo"
   git clone --depth 1 $repo
done

cd ..

# Define the script to inspects
# in case of PullRequest, we will only focus on the updated scripts file
SCRIPTS_TO_INSPECT=$(for filename in templates/commons/scripts/*.sh; do echo "${filename##*/}"; done)

rm -f templates_to_test.txt
for script in $(echo $SCRIPTS_TO_INSPECT); do
  echo "*** Inspecting usage of $script in otc templates repositories ***"
  grep -r "$script" templates/*/.bluemix | grep -v '#' | cut -d: -f1 | cut -d/ -f2 >> templates_to_test.txt
done
sort -u -o templates_to_test.txt templates_to_test.txt

echo "*** Templates to test:"
cat templates_to_test.txt
