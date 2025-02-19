# Architecture Design

## Hybrid Approach
- Kernel space: Fast packet filtering (eBPF/XDP)
- User space: ML inference (Go + Decision Tree)

## ML Model
- Algorithm: Decision Tree
- Features: 80 (CIC-DDoS2019)
- Format: PMML
- Accuracy: 99.998%

## Data Flow
1. XDP intercepts UDP:1900 packets
2. Check blocklist (kernel map)
3. Extract 80 features
4. Ring buffer â†’ userspace
5. ML inference
6. Update blocklist if malicious
