# Quick Start Guide - SSDP Sentinel

## 🚀 Quick Setup (5 Minutes)

### Prerequisites
- Linux system with kernel 5.10+ (check with `uname -r`)
- Go 1.21+ installed
- Root/sudo access
- Network interface with XDP support

### Step 1: Clone and Setup
```bash
cd upnp-ssdp-detection
./scripts/setup.sh
```

### Step 2: Add Your Model
```bash
# Copy your PMML model from the Jupyter notebook
cp path/to/SSDP_flood_detection.pmml models/
```

### Step 3: Configure
```bash
# Edit config file
nano configs/config.yaml

# Set your network interface
network:
  interface: "eth0"  # Change to your interface name
```

### Step 4: Build
```bash
make build
```

### Step 5: Run
```bash
sudo ./build/ssdp-sentinel -c configs/config.yaml
```

That's it! The system is now protecting your network.

---

## 🎯 What It Does

SSDP Sentinel monitors UDP traffic on port 1900 (SSDP) and:
1. **Fast Path**: Blocks known malicious IPs at kernel level (XDP)
2. **ML Analysis**: Analyzes suspicious traffic with Decision Tree ML
3. **Auto-Block**: Adds malicious IPs to blocklist automatically

---

## 📊 Monitoring

### View Live Statistics
```bash
# Terminal 1: Run sentinel
sudo ./build/ssdp-sentinel -c configs/config.yaml

# Terminal 2: Watch statistics
watch -n 2 'sudo bpftool map dump name statistics'
```

### Check Blocklist
```bash
sudo bpftool map dump name blocklist
```

### View Logs
```bash
# Real-time logs
tail -f /var/log/ssdp-sentinel.log

# Search for detections
grep "Malicious traffic detected" /var/log/ssdp-sentinel.log
```

---

## 🧪 Test It

### Generate Benign Traffic
```bash
# Normal SSDP discovery (should NOT be blocked)
nmap -sU -p 1900 --script=upnp-info 192.168.1.1
```

### Simulate Attack (Lab Only!)
```bash
# ⚠️  ONLY in isolated test environment!
sudo hping3 -2 -p 1900 --flood --rand-source 192.168.1.100
```

Watch logs to see detection in action:
```
INFO[0123] ⚠️  Malicious traffic detected - IP blocked  src_ip=192.168.1.100 confidence=0.95
```

---

## 🛠️ Common Commands

```bash
# Build
make build

# Clean and rebuild
make clean && make build

# Run tests
make test

# Install system-wide
sudo make install

# Start as service
sudo systemctl start ssdp-sentinel

# View service logs
sudo journalctl -u ssdp-sentinel -f
```

---

## 🔍 Troubleshooting

### Issue: "interface not found"
**Solution**: Check interface name
```bash
ip link show
# Use the correct interface name in configs/config.yaml
```

### Issue: "permission denied"
**Solution**: Run with sudo
```bash
sudo ./build/ssdp-sentinel -c configs/config.yaml
```

### Issue: "XDP attach failed"
**Solution**: Try generic XDP mode
```yaml
# In configs/config.yaml
ebpf:
  xdp_mode: "generic"
```

### Issue: "model not found"
**Solution**: Ensure PMML file exists
```bash
ls -la models/SSDP_flood_detection.pmml
```

---

## 📈 Performance Metrics

Expected performance:
- **Packet Rate**: 1M+ packets/sec
- **Latency**: < 10 microseconds (XDP fast path)
- **CPU Usage**: < 20% on modern CPU
- **Memory**: < 100 MB
- **Accuracy**: 99.998% (from CIC-DDoS2019 dataset)

---

## 🎓 For Your Presentation

### Key Points to Highlight:

1. **Hybrid Architecture**
   - Kernel-space: Fast blocklist filtering (XDP)
   - User-space: ML-based classification (Decision Tree)

2. **High Accuracy**
   - Trained on CIC-DDoS2019 dataset
   - 99.998% accuracy with 80 features

3. **Real-Time Protection**
   - Line-rate packet processing
   - Automatic threat response

4. **Production Ready**
   - CO-RE (Compile Once, Run Everywhere)
   - Supports kernel 5.10+
   - Comprehensive logging and monitoring

### Demo Flow:

```bash
# 1. Show system starting
sudo ./build/ssdp-sentinel -c configs/config.yaml

# 2. Generate benign traffic (in another terminal)
nmap -sU -p 1900 --script=upnp-info 192.168.1.1

# 3. Show statistics (in another terminal)
watch -n 1 'sudo bpftool map dump name statistics'

# 4. Point out:
#    - Packets processed
#    - No blocks for benign traffic
#    - Low CPU usage

# 5. (Optional) Simulate attack in safe environment
#    Show immediate detection and blocking
```

---

## 📚 Next Steps

1. **Read Full Documentation**: [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)
2. **Testing Guide**: [TESTING.md](TESTING.md)
3. **Deploy to Production**: See deployment section in README.md

---

## 🆘 Need Help?

- Check logs: `tail -f /var/log/ssdp-sentinel.log`
- Verify kernel: `uname -r` (need 5.10+)
- Check BTF: `ls /sys/kernel/btf/vmlinux`
- Test network: `ip link show`

---

## 📝 Configuration Quick Reference

```yaml
# Essential settings in configs/config.yaml

network:
  interface: "eth0"           # Your network interface
  
ml:
  model_path: "models/SSDP_flood_detection.pmml"
  threshold_confidence: 0.85  # Block if confidence >= 85%
  
logging:
  level: "info"               # debug, info, warn, error
  format: "json"              # json or text
```

---

## ✅ Success Checklist

- [ ] Kernel 5.10+ verified
- [ ] Dependencies installed (`./scripts/setup.sh`)
- [ ] PMML model in `models/` directory
- [ ] Config file customized
- [ ] Build successful (`make build`)
- [ ] Test run completed
- [ ] Statistics visible
- [ ] Ready for presentation!

---

**You're all set!** 🎉

For detailed information, see:
- Architecture: `IMPLEMENTATION_GUIDE.md`
- Testing: `TESTING.md`
- Full docs: `README.md`
