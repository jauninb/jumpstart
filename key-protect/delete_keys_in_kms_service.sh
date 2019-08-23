#!/bin/bash
# uncomment to debug the script
# set -x

export KP_INSTANCE_NAME=${KP_INSTANCE_NAME:-"KeyProtect-rw"}

export KP_GUID=$(ibmcloud resource service-instances --output JSON | jq --arg kp_name "$KP_INSTANCE_NAME" -r '.[] | select((.sub_type=="kms") and (.name==$kp_name)) | .guid')

if [ -z "$KP_GUID" ]; then
  echo "No Key Protect instance service found with name $KP_INSTANCE_NAME"
else
  ibmcloud kp -i "$KP_GUID" list
  echo "Deleting keys in KeyProtect instance service $KP_INSTANCE_NAME (id: $KP_GUID):"
  ibmcloud kp -i "$KP_GUID" list | tail -n +6 | awk '{print $1}' | while read -r key_ID ; do
    if [ "$key_ID" ]; then
      ibmcloud kp -i "$KP_GUID" delete "$key_ID"
    fi
  done
fi
