.PHONY: build clean

build:
	@echo "Building SSDP Sentinel..."
	go build -o build/ssdp-sentinel ./cmd/ssdp-sentinel

clean:
	rm -rf build/
