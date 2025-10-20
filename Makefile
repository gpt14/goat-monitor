# --- Variables ---
CLUSTER_NAME := goat-cluster
KIND_CONFIG := kind-config.yaml
NAMESPACE := default

# --- Default Target ---
.PHONY: all
all: build-image create-cluster load-image create-secret deploy-ingress deploy-exporter status

.PHONY: create-secret
create-secret:
	@echo "========Creating Kubernetes secret for Goat RPC URL========"
	@kubectl create secret generic goat-rpc-secret --from-env-file=.env -n goat-node -o=yaml --dry-run=client > k8s/secret.yaml

.PHONY: build-image
build-image:
	@echo "========Building Docker image: goat-exporter:latest========"
	@docker build -t goat-exporter:latest .

.PHONY: delete-image
delete-image:
	@echo "========Deleting Docker image: goat-exporter:latest========"
	@docker rmi goat-exporter:latest || echo "Image not found, skipping."

.PHONY: create-cluster
create-cluster:
	@echo "========Creating kind cluster: $(CLUSTER_NAME)========"
	@kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG)

.PHONY: load-image
load-image: $(KIND_CONFIG)
	@echo "========loading image onto kind cluster: $(CLUSTER_NAME)========"
	@kind load docker-image goat-exporter:latest --name $(CLUSTER_NAME)

.PHONY: delete-cluster
delete-cluster:
	@echo "========Deleting kind cluster: $(CLUSTER_NAME)========"
	@kind delete cluster --name $(CLUSTER_NAME)

# --- Ingress Controller ---
.PHONY: deploy-ingress
deploy-ingress:
	@echo "========Deploying NGINX Ingress controller...========"
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	@echo "Waiting for NGINX pods to be ready..."
	@for i in {1..15}; do \
	  if kubectl get pods -n ingress-nginx 2>/dev/null | grep -q "controller"; then \
	    kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s && exit 0; \
	  fi; \
	  echo "Waiting for ingress-nginx to register... ($$i/15)"; \
	  sleep 5; \
	done; \
	echo "Timed out waiting for ingress-nginx"

# --- Goat Exporter Deployment ---
.PHONY: deploy-exporter
deploy-exporter:
	@echo "========Deploying Goat Exporter...========"
	@kubectl create namespace goat-node || echo "Namespace goat-node already exists, skipping."
	@kubectl apply -f k8s/goat/deployment.yaml
	@kubectl --namespace goat-node wait --for=condition=Available --timeout=180s deployment/goat-node
	@kubectl apply -f k8s/goat/service.yaml
	@kubectl apply -f k8s/secret.yaml
	@kubectl apply -f k8s/deployment.yaml
	@kubectl apply -f k8s/service.yaml
	@kubectl apply -f k8s/ingress.yaml

# --- Utility Targets ---
.PHONY: logs
logs:
	@kubectl logs -l app=goat-exporter

.PHONY: test
test:
	@curl -v http://goat-exporter.localtest.me/metrics || echo "Failed to connect. Check Ingress setup."

.PHONY: status
status:
	@kubectl get pods,svc,ingress -A

.PHONY: clean
clean: delete-cluster delete-image
	@echo "========Cleaned up cluster and image.========"
