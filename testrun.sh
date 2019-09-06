#!/bin/bash
# uncomment to debug the script
# set -x

export DEVOPS_SIGNER=${DEVOPS_SIGNER:-"devops"}
export DEVOPS_SIGNER_PRIVATE_KEY=$(docker trust inspect $GUN | jq -r --arg GUN "$GUN" --arg DEVOPS_SIGNER "$DEVOPS_SIGNER" '.[] | select(.name=$GUN) | .Signers[] | select(.Name=$DEVOPS_SIGNER) | .Keys[0].ID')

# If $ARCHIVE_DIR then create the tar file containing certificates/keys created during initialization
# https://docs.docker.com/engine/security/trust/trust_key_mng/#back-up-your-keys , add public key
# and specific information for DCT initialization
if [[ "$ARCHIVE_DIR" ]]; then
    mkdir -p $ARCHIVE_DIR
    # keep the signer ids
    docker trust inspect $GUN | jq -r --arg GUN "$GUN" --arg DEVOPS_SIGNER "$DEVOPS_SIGNER" '.[] | select(.name=$GUN) | .Signers' > $ARCHIVE_DIR/dct_signers.json
    # keep the signed registry context
    echo "GUN=$GUN" > $ARCHIVE_DIR/dct.properties
    echo "REGISTRY_URL=${REGISTRY_URL}" >> $ARCHIVE_DIR/dct.properties
    echo "REGISTRY_REGION=${REGISTRY_REGION}" >> $ARCHIVE_DIR/dct.properties
    echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}" >> $ARCHIVE_DIR/dct.properties
    echo "IMAGE_NAME=${IMAGE_NAME}" >> $ARCHIVE_DIR/dct.properties
    echo "DOCKER_CONTENT_TRUST_SERVER=$DOCKER_CONTENT_TRUST_SERVER" >> $ARCHIVE_DIR/dct.properties
    # public key of signer are kept in archive as needed for CISE configuration for instance
    cp *.pub $ARCHIVE_DIR
fi