.PHONY: docker-build local logs stop

IMAGE_NAME := fhir-ru-zendoc
CONTAINER_NAME := fhir-ru-zendoc-local

# Build Docker image (linux/amd64 for compatibility with prod servers)
docker-build:
	docker build --platform linux/amd64 -t $(IMAGE_NAME):latest .

# Build and run locally
local: docker-build
	@docker stop $(CONTAINER_NAME) 2>/dev/null || true
	@docker rm $(CONTAINER_NAME) 2>/dev/null || true
	@docker run -d \
		--name $(CONTAINER_NAME) \
		-p 3333:3333 \
		$(IMAGE_NAME):latest
	@echo "Started on http://localhost:3333"
	@echo "View logs: make logs"

# Show container logs
logs:
	docker logs -f $(CONTAINER_NAME)

# Stop and remove container
stop:
	@docker stop $(CONTAINER_NAME) 2>/dev/null || true
	@docker rm $(CONTAINER_NAME) 2>/dev/null || true
