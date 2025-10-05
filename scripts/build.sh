#!/bin/bash
# Build script for SSDP Sentinel

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== Building SSDP Sentinel ==="
echo ""

# Check dependencies
echo "Checking dependencies..."
command -v clang >/dev/null 2>&1 || { echo "❌ clang not found"; exit 1; }
command -v go >/dev/null 2>&1 || { echo "❌ go not found"; exit 1; }
echo "✓ Dependencies OK"

# Generate eBPF bytecode
echo ""
echo "Generating eBPF bytecode..."
cd internal/ebpf
go generate
echo "✓ eBPF bytecode generated"

# Build Go binary
echo ""
echo "Building Go binary..."
cd "$PROJECT_ROOT"
go build -o build/ssdp-sentinel ./cmd/ssdp-sentinel
echo "✓ Binary built: build/ssdp-sentinel"

# Check binary
echo ""
echo "Binary info:"
file build/ssdp-sentinel
ls -lh build/ssdp-sentinel

echo ""
echo "=== Build Complete ==="
echo ""
echo "To run: sudo ./build/ssdp-sentinel -c configs/config.yaml"
