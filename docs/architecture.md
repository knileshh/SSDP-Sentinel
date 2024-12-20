# Architecture Ideas

## Hybrid Approach
- Kernel space: Fast packet filtering
- User space: ML inference

## Data Flow
1. XDP intercepts packets
2. Check blocklist (kernel)
3. Extract features
4. Send to userspace for ML
5. Update blocklist
