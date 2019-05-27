#!/bin/bash
# This script extracts the parameters that would be needed if using headless-api to instanciate a TC using the template
# this script is expected to be executed in the repository containing the .bluemix folder

TEMPLATE=$(basename $(pwd))

TEMPLATE_URL=$(git remote get-url origin)

echo "Instrospecting template $TEMPLATE to perform a headless toolchain instanciation - $TEMPLATE_URL"

TEMPLATE_PARAMETERS=$(grep -h -r '{{' .bluemix/*.yml | awk -F '{{' '{print $2}' | awk -F '}}' '{print $1}' | grep -v '^services' | sort -u)

for parameter in $TEMPLATE_PARAMETERS; do 
  echo "Filling parameter $parameter"
done

# find the IAM token
IAM_TOKEN=$(ibmcloud iam oauth-tokens --output JSON | jq -r .iam_token)

# Use provided resource group or used the default/configured one
if [ -z "$RESOURCE_GROUP" ]; then
  RESOURCE_GROUP=$(ibmcloud target --output JSON | jq -r .resource_group.guid)
fi

# Use provided region or used the configured one
if [ -z "$REGION_ID" ]; then
  REGION_ID=$(ibmcloud target --output JSON | jq -r .region.mccp_id)
fi
if [ -z "$REGION_NAME" ]; then
  REGION_NAME=$(ibmcloud target --output JSON | jq -r .region.name)
fi

CF_ORG_GUID=$(ibmcloud target --output JSON | jq -r .cf.org.guid)
CF_ORG_NAME=$(ibmcloud target --output JSON | jq -r .cf.org.name)
CF_SPACE_GUID=$(ibmcloud target --output JSON | jq -r .cf.space.guid)
CF_SPACE_NAME=$(ibmcloud target --output JSON | jq -r .cf.space.name)

# API Key is needed
API_KEY=${API_KEY:-$IBM_CLOUD_API_KEY}

# Fill the parameters to be given using -d
# dev-region,dev-organization,dev-space,api-key
PARAMETERS_DATA='-d "prod-region=eu-de" -d "prod-organization=bjn_cf_org" -d "prod-space=dev"'
FULLY_QUALIFIED_PARAMETERS_DATA='-d "form.pipeline.parameters.prod-region=eu-de" -d "form.pipeline.parameters.prod-organization=bjn_cf_org" -d "form.pipeline.parameters.prod-space=dev"'

curl -is -X POST -H "Authorization: $IAM_TOKEN" \
 -d "autocreate=true" \
 -d "apiKey=$API_KEY" \
 -d "resourceGroupId=$RESOURCE_GROUP" \
 -d "env_id=$REGION_ID" \
 -d "api-key=$API_KEY" \
 -d "orgGuid=$CF_ORG_GUID" \
 -d "spaceGuid=$CF_SPACE_GUID" \
 -d "prod-region=$REGION_NAME" -d "prod-organization=$CF_ORG_NAME" -d "prod-space=$CF_SPACE_NAME" \
 "https://cloud.ibm.com/devops/setup/deploy?repository=$TEMPLATE_URL"
