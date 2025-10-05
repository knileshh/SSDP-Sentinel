# UPnP SSDP Flood Detection - Go Implementation Guide

## 📚 Project Overview

This document outlines the complete implementation of an eBPF-based SSDP flood attack detection system using Go and Machine Learning, as described in the research paper "Securing UPnP Networks: An ML-Based Approach to SSDP Flood Attack Detection".

**Date**: October 30, 2025  
**Status**: Implementation Phase  
**Authors**: Nilesh Kumar, Shakir Ali, Tanishq Palkhe

---

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Network Interface Card (NIC)              │
└──────────────────────────┬──────────────────────────────────┘
                           │ Incoming Packets
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   KERNEL SPACE (eBPF)                        │
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │  XDP Hook - Early Packet Inspection                │     │
│  │  1. Check if UDP packet                            │     │
│  │  2. Check Blocklist Map                            │     │
│  │  3. Extract features                               │     │
│  │  4. XDP_DROP or forward to userspace              │     │
│  └──────────────┬─────────────────────────────────────┘     │
│                 │                                             │
│  ┌──────────────▼──────────────┐  ┌─────────────────────┐  │
│  │   Blocklist Map             │  │  Ring Buffer Map     │  │
│  │   (BPF_MAP_TYPE_HASH)      │  │  (Feature Export)    │  │
│  └──────────────▲──────────────┘  └──────────┬──────────┘  │
└─────────────────┼────────────────────────────┼──────────────┘
                  │                             │
                  │ Update                      │ Read Features
                  │                             ▼
┌─────────────────┴────────────────────────────────────────────┐
│                    USER SPACE (Go Application)                │
│                                                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  1. Load & Attach eBPF Programs                       │   │
│  │  2. Read Ring Buffer (packet features)                │   │
│  │  3. ML Model Inference (PMML Decision Tree)          │   │
│  │  4. Update Blocklist Map if malicious                │   │
│  │  5. Logging & Monitoring                             │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
upnp-ssdp-detection/
├── README.md
├── go.mod
├── go.sum
├── Makefile
│
├── cmd/
│   └── ssdp-sentinel/
│       └── main.go                 # Entry point
│
├── internal/
│   ├── ebpf/
│   │   ├── loader.go              # eBPF program loader
│   │   ├── maps.go                # eBPF map handlers
│   │   └── xdp_program.c          # XDP eBPF C code
│   │
│   ├── ml/
│   │   ├── model.go               # ML model interface
│   │   ├── pmml_loader.go         # PMML parser
│   │   └── inference.go           # Feature extraction & prediction
│   │
│   ├── network/
│   │   ├── features.go            # Network feature extraction
│   │   └── packets.go             # Packet parsing
│   │
│   └── config/
│       └── config.go              # Configuration management
│
├── pkg/
│   └── types/
│       └── types.go               # Shared types & structs
│
├── models/
│   └── SSDP_flood_detection.pmml  # Trained ML model
│
├── configs/
│   └── config.yaml                # Application config
│
├── scripts/
│   ├── setup.sh                   # Environment setup
│   ├── build.sh                   # Build script
│   └── deploy.sh                  # Deployment script
│
└── docs/
    ├── ARCHITECTURE.md
    ├── DEPLOYMENT.md
    └── TESTING.md
```

---

## 🔧 Implementation Components

### 1. **eBPF Kernel Program (C)**

**File**: `internal/ebpf/xdp_program.c`

#### Key Features:
- Attached to XDP hook for early packet processing
- Filters UDP traffic (SSDP uses UDP port 1900)
- Extracts 80 network features per the CIC-DDoS2019 dataset
- Uses BTF/CO-RE for kernel portability

#### eBPF Maps:
```c
// Blocklist Map - stores malicious IPs
struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 10000);
    __type(key, __u32);      // Source IP
    __type(value, __u64);    // Timestamp
} blocklist SEC(".maps");

// Ring Buffer - exports packet features to userspace
struct {
    __uint(type, BPF_MAP_TYPE_RINGBUF);
    __uint(max_entries, 256 * 1024);
} feature_export SEC(".maps");
```

#### Feature Extraction:
- Source/Destination IP & Port
- Protocol type
- Flow duration
- Packet counts (forward/backward)
- Packet lengths (min/max/mean/std)
- Inter-arrival times
- TCP flags
- Header lengths
- Flow rates (bytes/s, packets/s)
- Active/Idle times

---

### 2. **Go User-Space Application**

#### a. **eBPF Loader** (`internal/ebpf/loader.go`)

**Responsibilities**:
- Load eBPF object file
- Attach XDP program to network interface
- Initialize eBPF maps
- Handle CO-RE relocations

**Key Functions**:
```go
type EBPFLoader struct {
    objs     *ebpfObjects
    link     link.Link
    iface    string
}

func (l *EBPFLoader) Load(iface string) error
func (l *EBPFLoader) AttachXDP() error
func (l *EBPFLoader) ReadRingBuffer(handler func(data []byte)) error
func (l *EBPFLoader) UpdateBlocklist(ip net.IP) error
func (l *EBPFLoader) Close() error
```

---

#### b. **ML Model Handler** (`internal/ml/model.go`)

**Responsibilities**:
- Load PMML Decision Tree model
- Parse 80 features from packet data
- Perform inference
- Return classification (Benign/Malicious)

**Key Functions**:
```go
type MLModel interface {
    LoadModel(path string) error
    Predict(features []float64) (bool, float64, error)
}

type DecisionTreeModel struct {
    pmmlModel *pmml.Model
    scaler    *preprocessing.Scaler
}

func (m *DecisionTreeModel) Predict(features []float64) (bool, float64, error)
```

**80 Features** (from CIC-DDoS2019):
1. Source Port
2. Destination Port
3. Protocol
4. Flow Duration
5. Total Fwd Packets
6. Total Backward Packets
7. Total Length of Fwd Packets
8. Total Length of Bwd Packets
9. Fwd Packet Length Max/Min/Mean/Std
10. Bwd Packet Length Max/Min/Mean/Std
... (see full list in implementation)

---

#### c. **Network Feature Extractor** (`internal/network/features.go`)

**Responsibilities**:
- Parse raw packet bytes from ring buffer
- Extract statistical features
- Calculate flow-level metrics
- Format for ML model input

**Key Functions**:
```go
type FeatureExtractor struct {
    flowCache map[string]*FlowState
}

type PacketFeatures struct {
    SourceIP        net.IP
    DestIP          net.IP
    SourcePort      uint16
    DestPort        uint16
    Protocol        uint8
    FlowDuration    uint64
    // ... 80 features total
}

func (fe *FeatureExtractor) ExtractFeatures(data []byte) (*PacketFeatures, error)
func (fe *FeatureExtractor) ToFeatureVector(pf *PacketFeatures) []float64
```

---

#### d. **Main Application** (`cmd/ssdp-sentinel/main.go`)

**Workflow**:
```go
func main() {
    // 1. Load configuration
    cfg := config.LoadConfig("configs/config.yaml")
    
    // 2. Initialize ML model
    mlModel := ml.NewDecisionTreeModel()
    mlModel.LoadModel(cfg.ModelPath)
    
    // 3. Load & attach eBPF program
    ebpfLoader := ebpf.NewLoader()
    ebpfLoader.Load(cfg.NetworkInterface)
    ebpfLoader.AttachXDP()
    
    // 4. Start ring buffer consumer
    go ebpfLoader.ReadRingBuffer(func(data []byte) {
        features := featureExtractor.ExtractFeatures(data)
        vector := features.ToFeatureVector()
        
        // 5. ML inference
        isMalicious, confidence := mlModel.Predict(vector)
        
        // 6. Update blocklist if malicious
        if isMalicious && confidence > 0.95 {
            ebpfLoader.UpdateBlocklist(features.SourceIP)
            log.Printf("Blocked IP: %s (confidence: %.2f)", 
                       features.SourceIP, confidence)
        }
    })
    
    // 7. Keep running & handle signals
    sigChan := make(chan os.Signal, 1)
    signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
    <-sigChan
    
    ebpfLoader.Close()
}
```

---

## 🔨 Build Process

### Prerequisites:
```bash
# Install Go 1.21+
sudo apt install golang-1.21

# Install LLVM/Clang for eBPF compilation
sudo apt install clang llvm libbpf-dev

# Install kernel headers
sudo apt install linux-headers-$(uname -r)

# Install Go dependencies
go get github.com/cilium/ebpf
go get github.com/go-pmml/pmml
```

### Makefile:
```makefile
.PHONY: generate build clean

# Generate eBPF Go bindings
generate:
	go generate ./...

# Build eBPF program
build-ebpf:
	clang -O2 -g -target bpf -c internal/ebpf/xdp_program.c \
	  -o internal/ebpf/xdp_program.o

# Build Go application
build: generate build-ebpf
	go build -o bin/ssdp-sentinel cmd/ssdp-sentinel/main.go

# Run tests
test:
	go test -v ./...

# Clean build artifacts
clean:
	rm -rf bin/ internal/ebpf/*.o
```

---

## 🚀 Deployment

### 1. **Prerequisites Check**:
```bash
# Check kernel version (5.10+ recommended)
uname -r

# Check BTF support
ls /sys/kernel/btf/vmlinux

# Check eBPF capabilities
cat /proc/sys/kernel/unprivileged_bpf_disabled
```

### 2. **Installation**:
```bash
# Clone repository
cd "e:\CollegeWork\Academics\Research Work\UPnP Final Review\Router Implementation"

# Build
make build

# Run as root (required for eBPF)
sudo ./bin/ssdp-sentinel --config configs/config.yaml --interface eth0
```

### 3. **Configuration** (`configs/config.yaml`):
```yaml
network:
  interface: "eth0"
  
ml:
  model_path: "models/SSDP_flood_detection.pmml"
  confidence_threshold: 0.95
  
ebpf:
  blocklist_max_entries: 10000
  ringbuf_size: 262144  # 256KB
  
logging:
  level: "info"
  output: "/var/log/ssdp-sentinel.log"
```

---

## 📊 Testing Strategy

### 1. **Unit Tests**:
- Feature extraction accuracy
- PMML model loading
- eBPF map operations

### 2. **Integration Tests**:
- End-to-end packet processing
- ML model inference pipeline
- Blocklist update mechanism

### 3. **Performance Tests**:
- Throughput measurement (packets/sec)
- Latency benchmarks
- CPU/Memory profiling

### 4. **Attack Simulation**:
```bash
# Generate SSDP flood traffic (testing only)
hping3 --udp -p 1900 --flood <target-ip>
```

---

## 📈 Expected Performance

Based on the research paper results:

| Metric | Value |
|--------|-------|
| **Accuracy** | 99.998% |
| **True Positives** | 770,565 |
| **True Negatives** | 225 |
| **False Positives** | 2 |
| **False Negatives** | 6 |
| **Precision (Benign)** | 0.97 |
| **Recall (Benign)** | 0.99 |
| **F1-Score** | 1.00 |

---

## 🔐 Security Considerations

1. **Root Privileges**: Required for eBPF operations
2. **Resource Limits**: Configure `ulimit` for eBPF maps
3. **Rate Limiting**: Implement userspace rate limiting
4. **Model Updates**: Periodic retraining mechanism
5. **Logging**: Secure log storage and rotation

---

## 📚 Dependencies

```go
// go.mod
module github.com/your-org/upnp-ssdp-detection

go 1.21

require (
    github.com/cilium/ebpf v0.12.3
    github.com/google/gopacket v1.1.19
    github.com/spf13/viper v1.18.2
    github.com/sirupsen/logrus v1.9.3
    gopkg.in/yaml.v3 v3.0.1
)
```

---

## 🐛 Troubleshooting

### Common Issues:

1. **eBPF Program Won't Load**:
   ```bash
   # Check dmesg for verifier errors
   sudo dmesg | grep bpf
   ```

2. **Permission Denied**:
   ```bash
   # Run with CAP_BPF and CAP_NET_ADMIN
   sudo setcap cap_bpf,cap_net_admin+ep ./bin/ssdp-sentinel
   ```

3. **Model Loading Errors**:
   - Verify PMML file path
   - Check feature count (must be 80)

---

## 📖 References

1. Cilium eBPF Library: https://github.com/cilium/ebpf
2. Linux XDP: https://www.kernel.org/doc/html/latest/networking/af_xdp.html
3. CIC-DDoS2019 Dataset: https://www.unb.ca/cic/datasets/ddos-2019.html
4. PMML Specification: http://dmg.org/pmml/v4-4-1/GeneralStructure.html

---

## 👥 Contributors

- Nilesh Kumar - nilesh.kumar2024@vitstudent.ac.in
- Shakir Ali - shakir.ali2024@vitstudent.ac.in
- Tanishq Palkhe - tanishq.palkhe2024@vitstudent.ac.in

---

## 📝 License

This project is part of academic research at Vellore Institute of Technology.

---

**Last Updated**: October 30, 2025
