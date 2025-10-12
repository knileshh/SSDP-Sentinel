# Makefile for SSDP Sentinel
# UPnP SSDP Flood Detection System

# Variables
BINARY_NAME=ssdp-sentinel
BUILD_DIR=build
CMD_DIR=cmd/ssdp-sentinel
EBPF_DIR=internal/ebpf
INSTALL_PATH=/usr/local/bin
CONFIG_PATH=/etc/ssdp-sentinel

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod

# Build flags
LDFLAGS=-ldflags "-s -w"
BUILD_FLAGS=-v

.PHONY: all build clean test coverage install uninstall run help ebpf deps tidy fmt vet lint

## help: Display this help message
help:
	@echo "SSDP Sentinel - Makefile targets:"
	@echo ""
	@echo "Build targets:"
	@echo "  make build          - Build the binary"
	@echo "  make ebpf           - Generate eBPF bytecode"
	@echo "  make all            - Build everything (ebpf + binary)"
	@echo ""
	@echo "Development targets:"
	@echo "  make test           - Run tests"
	@echo "  make coverage       - Run tests with coverage"
	@echo "  make fmt            - Format code"
	@echo "  make vet            - Run go vet"
	@echo "  make lint           - Run linter"
	@echo "  make tidy           - Tidy go.mod"
	@echo ""
	@echo "Installation targets:"
	@echo "  make install        - Install binary and configs (requires sudo)"
	@echo "  make uninstall      - Remove installed files (requires sudo)"
	@echo ""
	@echo "Utility targets:"
	@echo "  make run            - Build and run"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make deps           - Download dependencies"

## all: Build everything
all: ebpf build

## build: Build the binary
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	$(GOBUILD) $(BUILD_FLAGS) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) ./$(CMD_DIR)
	@echo "✓ Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

## ebpf: Generate eBPF bytecode (requires bpf2go)
ebpf:
	@echo "Generating eBPF bytecode..."
	@cd $(EBPF_DIR) && go generate
	@echo "✓ eBPF bytecode generated"

## clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@$(GOCLEAN)
	@echo "✓ Clean complete"

## test: Run tests
test:
	@echo "Running tests..."
	$(GOTEST) -v ./...

## coverage: Run tests with coverage
coverage:
	@echo "Running tests with coverage..."
	@mkdir -p $(BUILD_DIR)
	$(GOTEST) -v -coverprofile=$(BUILD_DIR)/coverage.out ./...
	$(GOCMD) tool cover -html=$(BUILD_DIR)/coverage.out -o $(BUILD_DIR)/coverage.html
	@echo "✓ Coverage report: $(BUILD_DIR)/coverage.html"

## deps: Download dependencies
deps:
	@echo "Downloading dependencies..."
	$(GOMOD) download
	@echo "✓ Dependencies downloaded"

## tidy: Tidy go.mod
tidy:
	@echo "Tidying go.mod..."
	$(GOMOD) tidy
	@echo "✓ go.mod tidied"

## fmt: Format code
fmt:
	@echo "Formatting code..."
	$(GOCMD) fmt ./...
	@echo "✓ Code formatted"

## vet: Run go vet
vet:
	@echo "Running go vet..."
	$(GOCMD) vet ./...
	@echo "✓ No issues found"

## lint: Run linter (requires golangci-lint)
lint:
	@echo "Running linter..."
	@if command -v golangci-lint > /dev/null; then \
		golangci-lint run ./...; \
		echo "✓ Linting complete"; \
	else \
		echo "⚠️  golangci-lint not installed. Install: https://golangci-lint.run/usage/install/"; \
	fi

## install: Install binary and configs (requires sudo)
install: build
	@echo "Installing $(BINARY_NAME)..."
	@install -d $(INSTALL_PATH)
	@install -m 755 $(BUILD_DIR)/$(BINARY_NAME) $(INSTALL_PATH)/
	@install -d $(CONFIG_PATH)
	@install -m 644 configs/config.yaml $(CONFIG_PATH)/
	@install -d $(CONFIG_PATH)/models
	@if [ -f models/SSDP_flood_detection.pmml ]; then \
		install -m 644 models/SSDP_flood_detection.pmml $(CONFIG_PATH)/models/; \
	fi
	@echo "✓ Installation complete"
	@echo ""
	@echo "Binary installed to: $(INSTALL_PATH)/$(BINARY_NAME)"
	@echo "Config installed to: $(CONFIG_PATH)/config.yaml"
	@echo ""
	@echo "Run with: sudo $(BINARY_NAME) -c $(CONFIG_PATH)/config.yaml"

## uninstall: Remove installed files (requires sudo)
uninstall:
	@echo "Uninstalling $(BINARY_NAME)..."
	@rm -f $(INSTALL_PATH)/$(BINARY_NAME)
	@rm -rf $(CONFIG_PATH)
	@echo "✓ Uninstall complete"

## run: Build and run with default config
run: build
	@echo "Running $(BINARY_NAME)..."
	@sudo $(BUILD_DIR)/$(BINARY_NAME) -c configs/config.yaml
