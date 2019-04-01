#!/bin/bash
# uncomment to debug the script
# set -x

echo "DOCKER_CONTENT_TRUST_SERVER=$DOCKER_CONTENT_TRUST_SERVER"
# Pass phrase is needed to decrypt the private key by docker trust
echo "DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE=$DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE"
echo "PEM_FILE_NAME=$PEM_FILE_NAME"
echo "PEM_FILE_CONTENT_BASE64=$PEM_FILE_CONTENT_BASE64"

echo -e "$PEM_FILE_CONTENT_BASE64" | base64 -d - | tee $PEM_FILE_NAME

chmod 600 $PEM_FILE_NAME

# The following does not update the ~/.docker/trust/private so make it manually
#export DEVOPS_SIGNER="devops"
#docker trust key load $PEM_FILE_NAME --name $DEVOPS_SIGNER
#ls -l ~/.docker/trust/private

mkdir -p ~/.docker/trust/private
mv $PEM_FILE_NAME ~/.docker/trust/private
ls -l ~/.docker/trust/private
