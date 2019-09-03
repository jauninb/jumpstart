#!/bin/bash
# uncomment to debug the script
# set -x


# If $ARCHIVE_DIR then create the tar file containing certificates/keys created during initialization
# https://docs.docker.com/engine/security/trust/trust_key_mng/#back-up-your-keys , add public key
# and specific information for DCT initialization
if [[ "$ARCHIVE_DIR" ]]; then
    mkdir -p $ARCHIVE_DIR
    # keep the signer ids
    # keep the signed registry context
    echo "GUN=$GUN" > $ARCHIVE_DIR/dct.properties
    echo "REGISTRY_URL=${REGISTRY_URL}" >> $ARCHIVE_DIR/dct.properties
    echo "REGISTRY_REGION=${REGISTRY_REGION}" >> $ARCHIVE_DIR/dct.properties
    echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}" >> $ARCHIVE_DIR/dct.properties
    echo "IMAGE_NAME=${IMAGE_NAME}" >> $ARCHIVE_DIR/dct.properties
    echo "DOCKER_CONTENT_TRUST_SERVER=$DOCKER_CONTENT_TRUST_SERVER" >> $ARCHIVE_DIR/dct.properties
    # public key of signer are kept in archive as needed for CISE configuration for instance
    cp ~/.docker/trust/private/*.pub $ARCHIVE_DIR

    # if no vault is configured, keep the passphrase and backup the keys in the archive
    # https://docs.docker.com/engine/security/trust/trust_key_mng/#back-up-your-keys
    if [ -z "$VAULT_INSTANCE" ]; then
      echo "No Vault instance defined - backing-up the keys in $ARCHIVE_DIR directory"
      echo "DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE=$DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE" >> $ARCHIVE_DIR/dct.properties
      echo "DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE=$DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE" >> $ARCHIVE_DIR/dct.properties
      umask 077; tar -zcvf $ARCHIVE_DIR/private_keys_backup.tar.gz --directory ~ .docker/trust/private; umask 022
    else
      echo "Vault instance $VAULT_INSTANCE defined - it would be used for the key backup"
    fi
fi