FROM openjdk:8 AS base

LABEL maintainer="Benoit Jaunin <jaunin.b@fr.ibm.com>"

RUN apt-get update
RUN apt-get install -y curl git maven jq sudo

WORKDIR /root

# Install Node as pre-requisite for SonarJS plugin execution
ARG NODEJS_VERSION=v8.15.1
ARG NODEJS_DISTRO=linux-x64
ADD https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-${NODEJS_DISTRO}.tar.xz /root
RUN sudo tar -xJvf node-${NODEJS_VERSION}-${NODEJS_DISTRO}.tar.xz -C /root
RUN rm node-${NODEJS_VERSION}-${NODEJS_DISTRO}.tar.xz
ENV PATH $PATH:/root/node-${NODEJS_VERSION}-${NODEJS_DISTRO}/bin

# Install sonar-scanner CLI
ARG SONAR_SCANNER_VERSION=3.3.0.1492
ADD https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip /root/sonar-scanner.zip

RUN \
	unzip sonar-scanner.zip && \
	rm sonar-scanner.zip && \
	mv sonar-scanner-${SONAR_SCANNER_VERSION} sonar-scanner

ENV SONAR_RUNNER_HOME=/root/sonar-scanner
ENV PATH $PATH:/root/sonar-scanner/bin

# Install IDRA/DevopsInsights CLI
RUN npm install -g grunt-idra3

FROM base AS warmed-up
# Add a warmed-up user cache to /root/.sonar/cache
# Expecting the --build-arg WARMED_UP_SONAR_USERCACHE to be defined
ARG WARMED_UP_SONAR_USERCACHE
RUN echo "Sonar scanner user-cache warmed-up provided: ${WARMED_UP_SONAR_USERCACHE}"
RUN mkdir -p /root/.sonar/cache
ADD ${WARMED_UP_SONAR_USERCACHE} /root/.sonar/cache
RUN ls -l /root/.sonar/cache
