#######################################
# Base fetcher container
FROM alpine:latest AS fetcher

RUN apk add --no-cache \
    curl \
    upx

ARG RELEASE_VERSION=v1.0.1

ADD https://github.com/operator-framework/operator-sdk/releases/download/${RELEASE_VERSION}/operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu /root/operator-sdk
ADD https://github.com/operator-framework/operator-sdk/releases/download/${RELEASE_VERSION}/ansible-operator-${RELEASE_VERSION}-x86_64-linux-gnu /root/ansible-operator
ADD https://github.com/operator-framework/operator-sdk/releases/download/${RELEASE_VERSION}/helm-operator-${RELEASE_VERSION}-x86_64-linux-gnu /root/helm-operator

#######################################
# Final container
FROM alpine:latest AS final

ENV DILL_GID 500000
ENV DILL_UID 500000
ENV DILL_HOME /home/dill

RUN apk add --no-cache \
    ansible \
    curl \
    docker \
    git \
    openssh \
    shadow

COPY --from=fetcher /root/operator-sdk /usr/bin/operator-sdk
RUN chmod +x /usr/bin/operator-sdk

COPY --from=fetcher /root/ansible-operator /usr/bin/ansible-operator
RUN chmod +x /usr/bin/ansible-operator

COPY --from=fetcher /root/helm-operator /usr/bin/helm-operator
RUN chmod +x /usr/bin/helm-operator

RUN groupadd --gid "$DILL_GID" dill && \
    useradd --uid "$DILL_UID" --gid "$DILL_GID" -G docker dill

RUN mkdir "$DILL_HOME" && \
    chown -R "$DILL_UID":"$DILL_GID" "$DILL_HOME" \
    && chmod -R g+rw "$DILL_HOME"

USER dill
WORKDIR "$DILL_HOME"
