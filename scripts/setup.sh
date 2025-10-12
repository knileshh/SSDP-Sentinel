#!/bin/bash
# Setup script for SSDP Sentinel development environment

set -e

echo "=== SSDP Sentinel Setup ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  Some operations require root privileges. Please run with sudo."
fi

# Detect OS
OS="$(uname -s)"
echo "Detected OS: $OS"

# Install dependencies based on OS
if [ "$OS" = "Linux" ]; then
    if [ -f /etc/debian_version ]; then
        echo "Installing dependencies for Debian/Ubuntu..."
        apt-get update
        apt-get install -y \
            clang \
            llvm \
            libbpf-dev \
            linux-headers-$(uname -r) \
            build-essential \
            pkg-config \
            git
    elif [ -f /etc/redhat-release ]; then
        echo "Installing dependencies for RHEL/CentOS/Fedora..."
        dnf install -y \
            clang \
            llvm \
            libbpf-devel \
            kernel-devel \
            make \
            git
    else
        echo "⚠️  Unsupported Linux distribution. Please install dependencies manually:"
        echo "  - clang (>= 10)"
        echo "  - llvm (>= 10)"
        echo "  - libbpf-dev"
        echo "  - linux-headers"
    fi
elif [ "$OS" = "Darwin" ]; then
    echo "⚠️  macOS detected. eBPF/XDP is Linux-only."
    echo "You can develop on macOS but testing requires a Linux VM."
    echo ""
    echo "Installing Go dependencies only..."
else
    echo "⚠️  Unsupported OS: $OS"
    exit 1
fi

# Check Go installation
echo ""
echo "Checking Go installation..."
if ! command -v go &> /dev/null; then
    echo "❌ Go not found. Please install Go 1.21 or later:"
    echo "   https://golang.org/dl/"
    exit 1
fi

GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
echo "✓ Go $GO_VERSION installed"

# Check kernel version (Linux only)
if [ "$OS" = "Linux" ]; then
    echo ""
    echo "Checking kernel version..."
    KERNEL_VERSION=$(uname -r | cut -d. -f1-2)
    REQUIRED_VERSION="5.10"
    
    if awk "BEGIN {exit !($KERNEL_VERSION >= $REQUIRED_VERSION)}"; then
        echo "✓ Kernel $KERNEL_VERSION (>= $REQUIRED_VERSION required)"
    else
        echo "⚠️  Kernel $KERNEL_VERSION is older than recommended $REQUIRED_VERSION"
        echo "   Some eBPF features may not work correctly."
    fi
    
    # Check BTF support
    echo ""
    echo "Checking BTF support..."
    if [ -f /sys/kernel/btf/vmlinux ]; then
        echo "✓ BTF support enabled"
    else
        echo "⚠️  BTF not found at /sys/kernel/btf/vmlinux"
        echo "   CO-RE features may not work. Consider enabling CONFIG_DEBUG_INFO_BTF."
    fi
fi

# Install Go dependencies
echo ""
echo "Installing Go dependencies..."
cd "$(dirname "$0")/.."

# Verify go.mod syntax
if ! go mod verify &> /dev/null; then
    echo "⚠️  Running go mod tidy to fix dependencies..."
    go mod tidy
fi

if go mod download; then
    echo "✓ Go dependencies installed"
else
    echo "❌ Failed to download Go dependencies"
    echo "   Try running: go mod tidy"
    exit 1
fi

# Install bpf2go tool
echo ""
echo "Installing bpf2go..."
go install github.com/cilium/ebpf/cmd/bpf2go@latest
echo "✓ bpf2go installed"

# Create necessary directories
echo ""
echo "Creating directories..."
mkdir -p models
mkdir -p logs
mkdir -p build
echo "✓ Directories created"

# Check for PMML model
echo ""
if [ ! -f "models/SSDP_flood_detection.pmml" ]; then
    echo "⚠️  PMML model not found at models/SSDP_flood_detection.pmml"
    echo "   Please export your trained model from the Jupyter notebook."
else
    echo "✓ PMML model found"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Place your PMML model in models/SSDP_flood_detection.pmml"
echo "  2. Build the project: make build"
echo "  3. Run tests: make test"
echo "  4. Install: sudo make install"
echo "  5. Run: sudo ssdp-sentinel -c configs/config.yaml"
echo ""
