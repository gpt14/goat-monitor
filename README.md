## Introduction

The project contains kubernetes manifests files to setup a [GOAT RPC node](https://github.com/GOATNetwork/goat/blob/main/docker/mainnet.yaml) and a Prometheus exporter to monitor Current block height, Chain ID, Syncing status metrics for the GOAT RPC node.
The exporter pulls the metrics by sending RPC requests to the GOAT node.

```
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"<method>","params":[],"id":1}'
```
where the `<method>` can be `eth_blockNumber`, `eth_chainId` and `eth_syncing`

The GOAT RPC node is deployed as a single pod with two containers - `goat-get` and `goat` and is exposed as a `ClusterIP` service within a Kind cluster accessible at `http://goat-node.goat-node.svc`
The exporter is deployed as another pod running a single container and is exposed as an NGINX ingress accessible outside the Kind cluster at `http://goat-exporter.localtest.me`.

The deployment of the project on a local Kind cluster is automated using Make targets.

## Prerequisites
1. Docker
2. Kind
3. Make

## Configuring GOAT_RPC_NODE URL
Modify the `GOAT_RPC_NODE` value in the `.env` file. For example -

```env
GOAT_RPC_NODE=http://goat-node.goat-node.svc:8545
```

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

You can also run the following command
```
curl http://goat-exporter.localtest.me/metrics
```

## Cleaning up
Run `make clean` to delete the kind cluster and docker image

## Building image
Run `docker build -t goat-exporter:latest .`
Or
Run `make build-image`


