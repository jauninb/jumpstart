#!/bin/bash
# uncomment to debug the script
# set -x

export DEVOPS_SIGNER=${DEVOPS_SIGNER:-"devops"}

# create a devops key-pair for the given DEVOPS_SIGNER
docker trust key generate "$DEVOPS_SIGNER"

# Add the public key to the signer for the $GUN
#docker trust signer add --key "${DEVOPS_SIGNER}.pub" "$DEVOPS_SIGNER" "$GUN"

#docker trust inspect --pretty $GUN

export DEVOPS_SIGNER_PRIVATE_KEY=$(docker trust inspect $GUN | jq -r --arg GUN "$GUN" --arg DEVOPS_SIGNER "$DEVOPS_SIGNER" '.[] | select(.name=$GUN) | .Signers[] | select(.Name=$DEVOPS_SIGNER) | .Keys[0].ID')

# If $ARCHIVE_DIR then create the tar file containing certificates/keys created during initialization
# https://docs.docker.com/engine/security/trust/trust_key_mng/#back-up-your-keys , add public key
# and specific information for DCT initialization
if [[ "$ARCHIVE_DIR" ]]; then
    mkdir -p $ARCHIVE_DIR
    echo "GUN=$GUN" > $ARCHIVE_DIR/dct.properties
    echo "REGISTRY_URL=${REGISTRY_URL}" >> $ARCHIVE_DIR/dct.properties
    echo "REGISTRY_REGION=${REGISTRY_REGION}" >> $ARCHIVE_DIR/dct.properties
    echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}" >> $ARCHIVE_DIR/dct.properties
    echo "IMAGE_NAME=${IMAGE_NAME}" >> $ARCHIVE_DIR/dct.properties
    echo "DOCKER_CONTENT_TRUST_SERVER=$DOCKER_CONTENT_TRUST_SERVER" >> $ARCHIVE_DIR/dct.properties
  #  echo "DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE=$DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE" >> $ARCHIVE_DIR/dct.properties
  #  echo "DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE=$DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE" >> $ARCHIVE_DIR/dct.properties
  #  cp *.pub $ARCHIVE_DIR
    docker trust inspect $GUN | jq -r --arg GUN "$GUN" --arg DEVOPS_SIGNER "$DEVOPS_SIGNER" '.[] | select(.name=$GUN) | .Signers' > $ARCHIVE_DIR/dct_signers.json
else 
    # No ARCHIVE_DIR so echo the information required to configure DCT
    # Look for the private key file generated for the devops_signer
    echo "Private Key for $DEVOPS_SIGNER"
    cat ~/.docker/trust/private/$DEVOPS_SIGNER_PRIVATE_KEY.key

    export PEM_FILE_NAME=$DEVOPS_SIGNER_PRIVATE_KEY.key
    export PEM_FILE_CONTENT_BASE64=$(cat ~/.docker/trust/private/$DEVOPS_SIGNER_PRIVATE_KEY.key | base64 -w0)

    echo "# DCT Related variables for signing $GUN"
    echo "export DOCKER_CONTENT_TRUST_SERVER=$DOCKER_CONTENT_TRUST_SERVER"
    echo "export DEVOPS_SIGNER=$DEVOPS_SIGNER"
    echo "export DCT_DISABLED=false"
    echo "# PEM_FILE related environment variables (should be defined as secured stage properties)"
    echo "export DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE=$DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE"
    echo "export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE=$DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE"
    echo "export PEM_FILE_NAME=$DEVOPS_SIGNER_PRIVATE_KEY.key"
    echo "export PEM_FILE_CONTENT_BASE64=\"$PEM_FILE_CONTENT_BASE64\""
fi