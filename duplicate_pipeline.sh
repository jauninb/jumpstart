#!/bin/bash
# uncomment to debug the script
# set -x
# This script does a duplication of a pipeline into an existing empty pipeline
# It requires cURL, jq (https://stedolan.github.io/jq/) and yq (https://yq.readthedocs.io/en/latest/) available

BEARER_TOKEN=$(ibmcloud iam oauth-tokens | sed 's/^IAM token:[ ]*//')

REGION=$(ibmcloud target | grep -i region: | awk '{print $2};')

PIPELINE_API_URL="https://devops-api.$REGION.bluemix.net/v1/pipeline"

if [ -z "$SOURCE_PIPELINE_ID" ]; then
  echo "Source pipeline not defined"
  #exit 1
fi

if [ -z "$TARGET_PIPELINE_ID" ]; then
  echo "Target pipeline not defined"
  #exit 1
fi

curl -H "Authorization: $BEARER_TOKEN" -H "Accept: application/x-yaml" -o "${SOURCE_PIPELINE_ID}.yaml" "$PIPELINE_API_URL/pipelines/$SOURCE_PIPELINE_ID"

echo "YAML from source pipeline"
cat "${SOURCE_PIPELINE_ID}.yaml"

# Find the token url for the git tile
curl -H "Authorization: $BEARER_TOKEN" -H "Content-Type: application/json" -o "${SOURCE_PIPELINE_ID}_inputsources.json" "$PIPELINE_API_URL/pipelines/$SOURCE_PIPELINE_ID/inputsources"

# Remove the hooks
yq 'del(. | .hooks)' $SOURCE_PIPELINE_ID.yaml > "${TARGET_PIPELINE_ID}.yaml"

# Add the token url
yq -r '.stages[] | select( .inputs[0].type=="git") | .inputs[0].url' $SOURCE_PIPELINE_ID.yaml |\
while IFS=$'\n\r' read -r input_gitrepo 
do
  token_url=$(cat ${SOURCE_PIPELINE_ID}_inputsources.json | jq -r --arg git_repo "$input_gitrepo" '.[] | select( .repo_url==$git_repo ) | .token_url')
  echo "$input_gitrepo => $token_url"

  # Add a token field/line for input of type git and url being $git_repo
  cp -f $TARGET_PIPELINE_ID.yaml tmp-$TARGET_PIPELINE_ID.yaml

  yq -r --yaml-output --arg input_gitrepo "$input_gitrepo" --arg token_url "$token_url" '.stages[] | if ( .inputs[0].type=="git" and .inputs[0].url==$input_gitrepo) then  .inputs[0]=(.inputs[0] + { "token": $token_url}) else . end' tmp-$TARGET_PIPELINE_ID.yaml | yq -s --yaml-output  '{"stages": .}' > $TARGET_PIPELINE_ID.yaml
  
done

cat $TARGET_PIPELINE_ID.yaml

# Include the yaml as rawcontent (ie needs to replace cr by \n and " by \" )
echo '{}' | jq --rawfile yaml $TARGET_PIPELINE_ID.yaml '{"config": {"format": "yaml","content": $yaml}}' > ${TARGET_PIPELINE_ID}_configuration.json

# HTTP PUT to target pipeline
curl -is -H "Authorization: $BEARER_TOKEN" -H "Content-Type: application/json" -X PUT -d @${TARGET_PIPELINE_ID}_configuration.json $PIPELINE_API_URL/pipelines/$TARGET_PIPELINE_ID/configuration 

# Check the configuration if it has been applied correctly
curl -H "Authorization: $BEARER_TOKEN" -H "Accept: application/json" $PIPELINE_API_URL/pipelines/$TARGET_PIPELINE_ID/configuration

# echoing the secured properties (pipeline and stage) that can not be valued there
echo "The following pipeline secure properties needs to be updated with appropriate values:"
yq -r '.properties[] | select(.type=="secure") | .name' ${TARGET_PIPELINE_ID}.yaml

echo "The following stage secure properties needs to be updated with appropriate values:"
yq -r '.stages[] | . as $stage | .properties // [] | .[] | select(.type=="secure") | [$stage.name] + [.name] | join(" - ")' ${TARGET_PIPELINE_ID}.yaml
