PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: generate-webapp
generate-webapp:
	@echo "Generating webapp..."
	@cd $(PROJECT_DIR)webapp && yarn build
	rm -rf $(PROJECT_DIR)/frontend/src/main/resources/static/*
	cp -r $(PROJECT_DIR)webapp/out/* $(PROJECT_DIR)/frontend/src/main/resources/static/

.PHONY: build-images
build-images: generate-webapp
	@echo "Building images..."
	docker build -t dev/kv-shop-frontend:dev $(PROJECT_DIR)frontend -f $(PROJECT_DIR)frontend/Dockerfile
	docker build -t dev/inventory:dev $(PROJECT_DIR)inventory -f $(PROJECT_DIR)inventory/Dockerfile
	docker build -t dev/pricing:dev $(PROJECT_DIR)pricing -f $(PROJECT_DIR)pricing/Dockerfile
	docker build -t dev/coupon:dev $(PROJECT_DIR)coupon -f $(PROJECT_DIR)coupon/Dockerfile
	docker build -t dev/membership:dev $(PROJECT_DIR)membership -f $(PROJECT_DIR)membership/Dockerfile
	docker build -t dev/analytics:dev $(PROJECT_DIR)analytics -f $(PROJECT_DIR)analytics/Dockerfile

.PHONY: load-to-kind
load-to-kind:
	@echo "Loading images to kind..."
	kind load docker-image dev/kv-shop-frontend:dev
	kind load docker-image dev/inventory:dev
	kind load docker-image dev/pricing:dev
	kind load docker-image dev/coupon:dev
	kind load docker-image dev/membership:dev
	kind load docker-image dev/analytics:dev

.PHONY: deploy
deploy:
	@echo "Deploying to Kubernetes..."
	kubectl apply -f $(PROJECT_DIR)pricing/deployment/
	kubectl apply -f $(PROJECT_DIR)inventory/deployment/
	kubectl apply -f $(PROJECT_DIR)frontend/deployment/
	kubectl apply -f $(PROJECT_DIR)coupon/deployment/
	kubectl apply -f $(PROJECT_DIR)membership/deployment/
	kubectl apply -f $(PROJECT_DIR)analytics/deployment/

.PHONY: build-push-images-prod
build-push-images-prod: generate-webapp
	@echo "Building images..."
	docker buildx build -t edenfed/kv-mall-frontend:v0.1 $(PROJECT_DIR)frontend -f $(PROJECT_DIR)frontend/Dockerfile --platform linux/amd64,linux/arm64 --push
	docker buildx build -t edenfed/kv-mall-inventory:v0.1 $(PROJECT_DIR)inventory -f $(PROJECT_DIR)inventory/Dockerfile --platform linux/amd64,linux/arm64 --push
	docker buildx build -t edenfed/kv-mall-pricing:v0.1 $(PROJECT_DIR)pricing -f $(PROJECT_DIR)pricing/Dockerfile --platform linux/amd64,linux/arm64 --push
	docker buildx build -t edenfed/kv-mall-coupon:v0.1 $(PROJECT_DIR)coupon -f $(PROJECT_DIR)coupon/Dockerfile --platform linux/amd64,linux/arm64 --push
	docker buildx build -t edenfed/kv-mall-membership:v0.1 $(PROJECT_DIR)membership -f $(PROJECT_DIR)membership/Dockerfile --platform linux/amd64,linux/arm64 --push

.PHONY: deploy-infra
deploy-infra:
	@echo "Deploying infra to Kubernetes..."
	kubectl apply -f $(PROJECT_DIR)infra/namespaces.yaml
	kubectl apply -f $(PROJECT_DIR)infra/

.PHONY: restart
restart:
	@echo "Restarting pods..."
	kubectl delete pods --all