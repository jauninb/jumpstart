Cloud Function Action for Delivery Pipeline run
================

Creates the Docker action container using IBM Cloud Functions/OpenWhisk to start a Delivery Pipeline run.

### Setup

1) Build and push the docker image containing the `pipeline-run.sh` script as `action/exec`
  Note: IBM Cloud Function can only use image from public registries - https://cloud.ibm.com/docs/openwhisk?topic=cloud-functions-prep#prep_docker
  
  ```
  docker build -t jauninb/pipeline-run-docker:1.0 .
  docker push jauninb/pipeline-run-docker:1.0
  ```

2) Create the cloud function namespace and set the CLI context to it

  ```
  ibmcloud fn namespace create pipeline-trigger-ns
  ibmcloud fn property set --namespace pipeline-trigger-ns
  ```

3) Create IBM Cloud docker action

  ```
  ibmcloud fn action create pipeline-run --docker jauninb/pipeline-run-docker:1.0
  ```

4) Configure the action with Toolchain context and Pipeline to execute as function arguments.
  The arguments to provide are:
  - the region (as `region` argument)
  - the resource group (as `resource_group` argument)
  - the toolchain id (as `toolchain_id` argument)
  - the pipeline id (as `pipeline_id` argument)

  ```
  ```

# Configure the toolchain and pipeline target for the action
5) Configure the authentication 
# Configure the 
# https://cloud.ibm.com/docs/openwhisk?topic=cloud-functions-namespaces#service-id-set-ui
# Test created action
ibmcloud fn action invoke pipeline-run --blocking
```
