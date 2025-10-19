## Prerequisites
1. Docker
2. Kind
3. Make

## Running the project
Run the `make` command. This will 

- build the docker image for `goat-exporter`
- create a kind cluster
- load the `goat-exporter` docker image on the kind node
- deploy nginx ingress controller
- deploy k8s manifests for `goat-node` and `goat-exporter` under the `k8s` directory
- display status of all the resources deployed on kind

The goat exporter will be accessible at http://goat-exporter.localtest.me/metrics

## Post deployment test
Run `make test` to send a curl request to the /metrics endpoint after the deployment is completed

## Cleaning up
Run `make clean` to delete the kind cluster and docker image

## Building image
Run `docker build -t goat-exporter:latest .`
Or
Run `make build-image`
