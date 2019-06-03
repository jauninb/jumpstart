#!/bin/bash
# uncomment to debug the script
# set -x

export REGISTRY_URL=${REGISTRY_URL:-'uk.icr.io'}
export REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE:-'bp2i'}
export IMAGE_NAME=${IMAGE_NAME:-'signed-hello-app'}

export DEVOPS_SIGNER=${DEVOPS_SIGNER:-"devops"}

export GUN="$REGISTRY_URL/$REGISTRY_NAMESPACE/$IMAGE_NAME"
export DOCKER_CONTENT_TRUST_SERVER=${DOCKER_CONTENT_TRUST_SERVER:-"https://$REGISTRY_URL:4443"}
echo "DOCKER_CONTENT_TRUST_SERVER=$DOCKER_CONTENT_TRUST_SERVER"

# Notary Setup usage avec DCT
# https://github.com/theupdateframework/notary/blob/master/docs/command_reference.md#set-up-notary-cli

export DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE=${DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE:-"dctrootpassphrase"}
export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE=${DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE:-"dctrepositorypassphrase"}

export NOTARY_ROOT_PASSPHRASE="$DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE"
export NOTARY_TARGETS_PASSPHRASE="$DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE"
export NOTARY_SNAPSHOT_PASSPHRASE="$DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE"
export NOTARY_AUTH=$(echo -e "iamapikey:$IBMCLOUD_API_KEY" | base64)

# repository init for the GUN (repo/namespace/image) using notary
notary -s $DOCKER_CONTENT_TRUST_SERVER -d ~/.docker/trust init "$GUN"
notary -s $DOCKER_CONTENT_TRUST_SERVER -d ~/.docker/trust publish "$GUN"

# create a devops key-pair dor the given DEVOPS_SIGNER
docker trust key generate "$DEVOPS_SIGNER"

# Add the public key to the signer for the $GUN
docker trust signer add --key "${DEVOPS_SIGNER}.pub" "$DEVOPS_SIGNER" "$GUN"

# remove/revoke the snapshot delegation
notary -s $DOCKER_CONTENT_TRUST_SERVER -d ~/.docker/trust key rotate "$GUN" snapshot -r
notary -s $DOCKER_CONTENT_TRUST_SERVER -d ~/.docker/trust publish "$GUN"

docker trust inspect --pretty $GUN

notary -s $DOCKER_CONTENT_TRUST_SERVER -d ~/.docker/trust delegation list "$GUN"

export DEVOPS_SIGNER_PRIVATE_KEY=$(docker trust inspect $GUN | jq -r --arg GUN "$GUN" --arg DEVOPS_SIGNER "$DEVOPS_SIGNER" '.[] | select(.name=$GUN) | .Signers[] | select(.Name=$DEVOPS_SIGNER) | .Keys[0].ID')

# If $ARCHIVE_DIR then create the tar file containing certificates/keys created during initialization
# https://docs.docker.com/engine/security/trust/trust_key_mng/#back-up-your-keys , add public key
# and specific information for DCT initialization
if [[ "$ARCHIVE_DIR" ]]; then
    mkdir -p $ARCHIVE_DIR
    echo "GUN=$GUN" > $ARCHIVE_DIR/dct.properties
    echo "REGISTRY_URL=${REGISTRY_URL}"
    echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}" >> $ARCHIVE_DIR/dct.properties
    echo "IMAGE_NAME=${IMAGE_NAME}" >> $ARCHIVE_DIR/dct.properties
    echo "DEVOPS_SIGNER=$DEVOPS_SIGNER" >> $ARCHIVE_DIR/dct.properties
    echo "DOCKER_CONTENT_TRUST_SERVER=$DOCKER_CONTENT_TRUST_SERVER" >> $ARCHIVE_DIR/dct.properties
    echo "DEVOPS_SIGNER_PRIVATE_KEY=$DEVOPS_SIGNER_PRIVATE_KEY" >> $ARCHIVE_DIR/dct.properties
    echo "DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE=$DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE" >> $ARCHIVE_DIR/dct.properties
    echo "DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE=$DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE" >> $ARCHIVE_DIR/dct.properties
    cp "${DEVOPS_SIGNER}.pub" $ARCHIVE_DIR
    umask 077; tar -zcvf $ARCHIVE_DIR/private_keys_backup.tar.gz ~/.docker/trust/private; umask 022
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