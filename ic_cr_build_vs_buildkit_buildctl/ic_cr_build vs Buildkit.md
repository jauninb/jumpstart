# ibmcloud cr build vs Buildkit buildctl

## Intent

The intent is to compare `ibmcloud cr build` command with the `buildkit ctl` command/tool in order to ease migration path from one to another 

## ibmcloud cr build command parameters

```
$ ibmcloud cr build --help
NAME:
  build - Build a Docker image in IBM Cloud Container Registry.

USAGE:
  ibmcloud cr build [--no-cache] [--pull] [--quiet | -q] [--build-arg KEY=VALUE ...] [--file FILE | -f FILE] --tag TAG DIRECTORY
DIRECTORY is the location of your build context, which contains your Dockerfile and prerequisite files.

OPTIONS:
  --no-cache              Optional: If specified, cached image layers from previous builds are not used in this build.
  --pull                  Optional: If specified, the base images are pulled even if an image with a matching tag already exists on the build host.
  --quiet, -q             Optional: If specified, the build output is suppressed unless an error occurs.
  --build-arg value       Optional: Specify an additional build argument in the format 'KEY=VALUE'. The value of each build argument is available as an environment variable when you specify an ARG line that matches the key in your Dockerfile.
  --file value, -f value  Optional: Specify the location of the Dockerfile relative to the build context. If not specified, the default is 'PATH/Dockerfile', where PATH is the root of the build context.
  --tag value, -t value   The full name for the image that you want to build, which includes the registry URL and namespace.
```

## Buildkit CLI install
As the buildkit CLI is not yet installed in the pipeline-base-image, the installation can be done using:
`curl -sL https://github.com/moby/buildkit/releases/download/v0.7.2/buildkit-v0.7.2.linux-amd64.tar.gz | tar -C /tmp -xz bin/buildctl && mv /tmp/bin/buildctl /usr/bin/buildctl && rmdir --ignore-fail-on-non-empty /tmp/bin`

## buildkit buildctl command parameters
```
root@5c900dc8ca1d:/# buildctl build --help
NAME:
   buildctl build - build

USAGE:

  To build and push an image using Dockerfile:
    $ buildctl build --frontend dockerfile.v0 --opt target=foo --opt build-arg:foo=bar --local context=. --local dockerfile=. --output type=image,name=docker.io/username/image,push=true


OPTIONS:
   --output value, -o value  Define exports for build result, e.g. --output type=image,name=docker.io/username/image,push=true
   --progress value          Set type of progress (auto, plain, tty). Use plain to show container output (default: "auto")
   --trace value             Path to trace file. Defaults to no tracing.
   --local value             Allow build access to the local directory
   --frontend value          Define frontend used for build
   --opt value               Define custom options for frontend, e.g. --opt target=foo --opt build-arg:foo=bar
   --no-cache                Disable cache for all the vertices
   --export-cache value      Export build cache, e.g. --export-cache type=registry,ref=example.com/foo/bar, or --export-cache type=local,dest=path/to/dir
   --import-cache value      Import build cache, e.g. --import-cache type=registry,ref=example.com/foo/bar, or --import-cache type=local,src=path/to/dir
   --secret value            Secret value exposed to the build. Format id=secretname,src=filepath
   --allow value             Allow extra privileged entitlement, e.g. network.host, security.insecure
   --ssh value               Allow forwarding SSH agent to the builder. Format default|<id>[=<socket>|<key>[,<key>]]
```

## buildctl build command to match ibmcloud cr build

### mandatory arguments
- ibmcloud cr build only rely on Dockerfile for the image definition (default to Dockerfile or to the --file value of the ibmcloud cr build).
  In addition, the path/context to access the Dockerfile corresponds to directory argument specified in the `ibmcloud cr build` command (default to .)
  ```
  buildctl build \
    --frontend dockerfile.v0 --opt filename=Dockerfile --local dockerfile=. 
  ```
- build context is given as the DIRECTORY argument for `ibmcloud cr build` command, this directory needs to be given as the build context for buildctl (default to .)
  ```
  buildctl build \
    --frontend dockerfile.v0 --opt filename=Dockerfile --local dockerfile=. \
    --local context=.
  ```
- the image tag provided using `--tag` parameter for `ibmcloud cr build` is provided with the --output argument.
  The structure of the argument is expected to be the same (ie The full name for the image that you want to build, which includes the registry URL and namespace.)
  ```
  buildctl build \
    --frontend dockerfile.v0 --opt filename=Dockerfile --local dockerfile=. \
    --local context=.
    --output type=image,name=<IC CR BUILD TAG ARGUMENT>,push=true
  ```

### optional parameters
- `ic cr build --no-cache` corresponds to `buildctl build --no-cache`
- `ic cr build --pull` (does not have equivalent?)
- `ic cr build --quiet` (does not have equivalent?)
- `ic cr build --file FILENAME` with FILENAME=PATH/DOCKERFILENAME corresponds to `--opt filename=DOCKERFILENAME --local dockerfile=PATH`

## Buildkit Buildctl in the context of a Container Registry Pipeline Job

### ibmcloud container registry context
`ibmcloud cr build` is not only building the OCI/Docker image but is laso pushing the bits to the ibmcloud container registry namespace/registry for the given image/tag.
`Buildkit buildctl` needs to be configured with CR access and the output parameter for buildctl build need to include --output with "push=true"

### environment variables relevant to the build
The following environment variables in the Container Registry Pipeline Job are relevant to the buildkit context to push to the container registry:
- IBM_CLOUD_API_KEY
- IBM_CLOUD_REGION

The following environment variables in the Container Registry Pipeline Job are relevant to the buildkit buildctl invocation:
- REGISTRY_URL (like REGISTRY_URL=us.icr.io)
- REGISTRY_NAMESPACE (like REGISTRY_NAMESPACE=jauninb)
- IMAGE_NAME (like IMAGE_NAME=hello-containers-20200910073457864)

### Provide the container registry information configuration to buildkit buildctl
A file named `config.json` must be created to provided the credentials to access the Container Registry:
```
# create a dry-run k8s secret of type docker-registry to obtain
# the content of a docker config.json file to access the target
# ibmcloud container registry
kubectl create secret --dry-run=true --output=json \
  docker-registry registry-dockerconfig-secret \
  --docker-server=${REGISTRY_URL} \
  --docker-password=${IBM_CLOUD_API_KEY} \
  --docker-username=iamapikey --docker-email=a@b.com | \
jq -r '.data[".dockerconfigjson"]' | base64 -d > config.json
```

### Sample ibmcloud cr build equivalent using buildkit
```
buildctl build \
    --frontend dockerfile.v0 --opt filename=Dockerfile --local dockerfile=. \
    --local context=. \
    --output type=image,name="${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}:latest",push=true
```

## TODO
Cache ?