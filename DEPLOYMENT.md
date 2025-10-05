# Deployment Guide - SSDP Sentinel

## Overview
This guide covers deploying SSDP Sentinel in production environments, including routers, edge devices, and network gateways.

---

## 🎯 Deployment Scenarios

### 1. Edge Router Deployment
Deploy at network edge to protect entire subnet from SSDP flood attacks.

### 2. Home Router
Protect home IoT devices (smart TVs, speakers, cameras) from UPnP vulnerabilities.

### 3. Enterprise Gateway
Deploy on corporate network gateway for centralized DDoS protection.

### 4. Cloud VM
Run on cloud instances (AWS, Azure, GCP) to protect cloud infrastructure.

---

## 📋 Pre-Deployment Checklist

### System Requirements
- [ ] Linux kernel 5.10 or higher
- [ ] BTF (BPF Type Format) support enabled
- [ ] Root/sudo access
- [ ] At least 512MB RAM
- [ ] 100MB free disk space
- [ ] Network interface with XDP support (or generic XDP fallback)

### Verify Requirements
```bash
# Check kernel version
uname -r

# Check BTF support
ls -la /sys/kernel/btf/vmlinux

# Check available interfaces
ip link show

# Check free memory
free -h

# Check disk space
df -h
```

---

## 🚀 Installation Methods

### Method 1: From Source (Recommended)

```bash
# 1. Clone repository
git clone https://github.com/your-org/upnp-ssdp-detection.git
cd upnp-ssdp-detection

# 2. Run setup script
sudo ./scripts/setup.sh

# 3. Place ML model
cp /path/to/SSDP_flood_detection.pmml models/

# 4. Build
make build

# 5. Install system-wide
sudo make install
```

### Method 2: Pre-built Binary

```bash
# Download latest release
wget https://github.com/your-org/upnp-ssdp-detection/releases/download/v1.0.0/ssdp-sentinel-linux-amd64.tar.gz

# Extract
tar -xzf ssdp-sentinel-linux-amd64.tar.gz
cd ssdp-sentinel

# Install
sudo cp ssdp-sentinel /usr/local/bin/
sudo chmod +x /usr/local/bin/ssdp-sentinel

# Copy configs
sudo mkdir -p /etc/ssdp-sentinel
sudo cp configs/config.yaml /etc/ssdp-sentinel/

# Copy model
sudo mkdir -p /usr/share/ssdp-sentinel/models
sudo cp models/SSDP_flood_detection.pmml /usr/share/ssdp-sentinel/models/
```

### Method 3: Docker Container

```bash
# Pull image
docker pull your-org/ssdp-sentinel:latest

# Run with host network and privileged mode
docker run -d \
  --name ssdp-sentinel \
  --privileged \
  --network host \
  --cap-add SYS_ADMIN \
  --cap-add NET_ADMIN \
  -v /sys/kernel/debug:/sys/kernel/debug \
  -v /etc/ssdp-sentinel:/etc/ssdp-sentinel \
  your-org/ssdp-sentinel:latest
```

---

## ⚙️ Configuration

### 1. Network Configuration

```yaml
# /etc/ssdp-sentinel/config.yaml

network:
  # Primary interface facing untrusted network
  interface: "eth0"
  
  # SSDP port (standard is 1900)
  ssdp_port: 1900
```

**Finding your interface:**
```bash
# List all interfaces
ip link show

# Show interface with IP addresses
ip addr show

# Identify WAN interface
ip route | grep default
```

### 2. ML Configuration

```yaml
ml:
  # Path to PMML model file
  model_path: "/usr/share/ssdp-sentinel/models/SSDP_flood_detection.pmml"
  
  # Confidence threshold for blocking (0.0-1.0)
  # Higher = fewer false positives, lower = more protection
  threshold_confidence: 0.85
  
  # Use simplified prediction (faster, slightly less accurate)
  use_simplified: false
```

**Threshold Guidelines:**
- **0.99**: Maximum precision, may miss some attacks
- **0.95**: High precision, good for sensitive environments
- **0.90**: Balanced precision and recall
- **0.85**: Default, good protection with low false positives
- **0.80**: Higher recall, more aggressive blocking

### 3. Performance Tuning

```yaml
ebpf:
  # Blocklist size (must be power of 2)
  blocklist_size: 10000
  
  # Ring buffer size (must be power of 2)
  ring_buffer_size: 262144  # 256 KB
  
  # XDP mode: "native" (faster) or "generic" (compatible)
  xdp_mode: "native"

performance:
  # Statistics reporting interval
  stats_interval: 10
  
  # Ring buffer poll timeout (ms)
  poll_timeout: 100
  
  # Concurrent ML inference workers
  max_inference_workers: 4
```

**XDP Mode Selection:**
- **native**: Requires driver support, best performance
- **generic**: Fallback mode, works on all interfaces, slower

**Test native support:**
```bash
# Check if driver supports XDP
ethtool -i eth0 | grep driver
# Look for: ixgbe, i40e, mlx5, etc.
```

### 4. Security Configuration

```yaml
security:
  # Blocklist entry TTL (seconds)
  # Entries auto-expire after this time
  blocklist_ttl: 300  # 5 minutes
  
  # Enable automatic cleanup
  auto_cleanup: true
  
  # Cleanup interval (seconds)
  cleanup_interval: 60
```

### 5. Logging Configuration

```yaml
logging:
  # Log level: debug, info, warn, error
  level: "info"
  
  # Log format: json (structured) or text (human-readable)
  format: "json"
  
  # Output: stdout, stderr, or file path
  output: "/var/log/ssdp-sentinel/ssdp-sentinel.log"
```

---

## 🔄 Systemd Service Setup

### Create Service File

```bash
sudo tee /etc/systemd/system/ssdp-sentinel.service > /dev/null <<EOF
[Unit]
Description=SSDP Sentinel - ML-based SSDP Flood Detection
Documentation=https://github.com/your-org/upnp-ssdp-detection
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ssdp-sentinel -c /etc/ssdp-sentinel/config.yaml
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=false
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/ssdp-sentinel

# Resource limits
LimitNOFILE=65536
LimitNPROC=512

[Install]
WantedBy=multi-user.target
EOF
```

### Enable and Start Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service (start on boot)
sudo systemctl enable ssdp-sentinel

# Start service
sudo systemctl start ssdp-sentinel

# Check status
sudo systemctl status ssdp-sentinel

# View logs
sudo journalctl -u ssdp-sentinel -f
```

### Service Management Commands

```bash
# Start service
sudo systemctl start ssdp-sentinel

# Stop service
sudo systemctl stop ssdp-sentinel

# Restart service
sudo systemctl restart ssdp-sentinel

# Reload configuration (graceful)
sudo systemctl reload ssdp-sentinel

# Check status
sudo systemctl status ssdp-sentinel

# Enable auto-start on boot
sudo systemctl enable ssdp-sentinel

# Disable auto-start
sudo systemctl disable ssdp-sentinel

# View logs (last 100 lines)
sudo journalctl -u ssdp-sentinel -n 100

# View logs (live)
sudo journalctl -u ssdp-sentinel -f

# View logs (since boot)
sudo journalctl -u ssdp-sentinel -b
```

---

## 📊 Monitoring

### 1. Real-Time Statistics

```bash
# Watch eBPF statistics
watch -n 2 'sudo bpftool map dump name statistics'

# Monitor with formatted output
watch -n 2 'sudo bpftool map dump name statistics | jq'
```

### 2. Prometheus Integration

Add to your configuration:

```yaml
monitoring:
  prometheus:
    enabled: true
    port: 9090
    path: "/metrics"
```

Metrics exposed:
- `ssdp_sentinel_total_packets`
- `ssdp_sentinel_ssdp_packets`
- `ssdp_sentinel_blocked_packets`
- `ssdp_sentinel_malicious_detections`
- `ssdp_sentinel_ml_inference_duration`

### 3. Grafana Dashboard

Import the provided dashboard:
```bash
# Import dashboard JSON
curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @grafana-dashboard.json
```

### 4. Log Aggregation

#### With ELK Stack (Elasticsearch, Logstash, Kibana)

**Logstash configuration:**
```ruby
# /etc/logstash/conf.d/ssdp-sentinel.conf
input {
  file {
    path => "/var/log/ssdp-sentinel/ssdp-sentinel.log"
    start_position => "beginning"
    codec => json
  }
}

filter {
  json {
    source => "message"
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "ssdp-sentinel-%{+YYYY.MM.dd}"
  }
}
```

#### With rsyslog

```bash
# /etc/rsyslog.d/ssdp-sentinel.conf
:programname, isequal, "ssdp-sentinel" /var/log/ssdp-sentinel/ssdp-sentinel.log
:programname, isequal, "ssdp-sentinel" stop
```

### 5. Alerting

#### Email Alerts (using mailx)

```bash
# Create alert script
cat > /usr/local/bin/ssdp-alert.sh << 'EOF'
#!/bin/bash
THRESHOLD=1000

BLOCKED=$(sudo bpftool map dump name statistics | grep blocked_packets | awk '{print $2}')

if [ "$BLOCKED" -gt "$THRESHOLD" ]; then
    echo "ALERT: $BLOCKED packets blocked by SSDP Sentinel" | \
    mail -s "SSDP Sentinel Alert" admin@example.com
fi
EOF

chmod +x /usr/local/bin/ssdp-alert.sh

# Add to cron
echo "*/5 * * * * /usr/local/bin/ssdp-alert.sh" | crontab -
```

#### Slack/Discord Webhooks

```bash
# Add to systemd service
ExecStartPost=/usr/local/bin/notify-start.sh

# notify-start.sh
#!/bin/bash
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H 'Content-Type: application/json' \
  -d '{"text":"SSDP Sentinel started successfully"}'
```

---

## 🔒 Security Hardening

### 1. AppArmor Profile

```bash
# /etc/apparmor.d/usr.local.bin.ssdp-sentinel
#include <tunables/global>

/usr/local/bin/ssdp-sentinel {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  capability net_admin,
  capability sys_admin,
  capability sys_resource,

  network inet dgram,
  network inet6 dgram,

  /usr/local/bin/ssdp-sentinel r,
  /etc/ssdp-sentinel/** r,
  /usr/share/ssdp-sentinel/** r,
  /var/log/ssdp-sentinel/** w,
  /sys/kernel/debug/** rw,
  /sys/fs/bpf/** rw,
}
```

### 2. Firewall Rules

```bash
# Allow SSDP monitoring
sudo iptables -A INPUT -p udp --dport 1900 -j ACCEPT

# Allow Prometheus metrics (if enabled)
sudo iptables -A INPUT -p tcp --dport 9090 -j ACCEPT

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

### 3. File Permissions

```bash
# Secure configuration
sudo chown root:root /etc/ssdp-sentinel/config.yaml
sudo chmod 600 /etc/ssdp-sentinel/config.yaml

# Secure logs
sudo mkdir -p /var/log/ssdp-sentinel
sudo chown root:root /var/log/ssdp-sentinel
sudo chmod 750 /var/log/ssdp-sentinel
```

---

## 🔄 Updates and Maintenance

### Update Procedure

```bash
# 1. Stop service
sudo systemctl stop ssdp-sentinel

# 2. Backup configuration
sudo cp /etc/ssdp-sentinel/config.yaml /etc/ssdp-sentinel/config.yaml.backup

# 3. Update binary
sudo cp /path/to/new/ssdp-sentinel /usr/local/bin/
sudo chmod +x /usr/local/bin/ssdp-sentinel

# 4. Restart service
sudo systemctl start ssdp-sentinel

# 5. Verify
sudo systemctl status ssdp-sentinel
```

### Model Updates

```bash
# Update ML model
sudo cp /path/to/new/model.pmml /usr/share/ssdp-sentinel/models/SSDP_flood_detection.pmml

# Reload service
sudo systemctl reload ssdp-sentinel
```

### Log Rotation

```bash
# /etc/logrotate.d/ssdp-sentinel
/var/log/ssdp-sentinel/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
    sharedscripts
    postrotate
        systemctl reload ssdp-sentinel > /dev/null 2>&1 || true
    endscript
}
```

---

## 🌐 Cloud Deployments

### AWS EC2

```bash
# 1. Launch Ubuntu 22.04 instance
# 2. Enable Enhanced Networking
# 3. Install SSDP Sentinel
# 4. Configure security groups:
#    - Allow UDP 1900 (inbound)
#    - Allow TCP 9090 (monitoring, optional)
```

### Azure VM

```bash
# 1. Create Ubuntu 22.04 VM with Accelerated Networking
# 2. Install SSDP Sentinel
# 3. Configure Network Security Group:
#    - Allow UDP 1900
#    - Allow TCP 9090 (monitoring)
```

### Google Cloud Platform

```bash
# 1. Create Ubuntu 22.04 instance with gVNIC
# 2. Install SSDP Sentinel
# 3. Configure firewall rules:
gcloud compute firewall-rules create allow-ssdp \
  --allow udp:1900 \
  --source-ranges=0.0.0.0/0
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. XDP Attach Failure
```bash
# Error: XDP attach failed
# Solution: Use generic mode
ebpf:
  xdp_mode: "generic"
```

#### 2. BTF Not Found
```bash
# Error: BTF not available
# Solution: Enable BTF in kernel or use pre-built BTF
sudo apt install linux-headers-$(uname -r)
```

#### 3. Permission Denied
```bash
# Error: Operation not permitted
# Solution: Run with sudo or as root
sudo systemctl start ssdp-sentinel
```

#### 4. High CPU Usage
```bash
# Reduce ML inference workers
performance:
  max_inference_workers: 2
```

#### 5. Memory Issues
```bash
# Reduce ring buffer size
ebpf:
  ring_buffer_size: 131072  # 128 KB instead of 256 KB
```

---

## ✅ Post-Deployment Verification

```bash
# 1. Check service status
sudo systemctl status ssdp-sentinel

# 2. Verify XDP attachment
sudo bpftool prog list | grep xdp_ssdp_filter

# 3. Check statistics
sudo bpftool map dump name statistics

# 4. Test detection (in lab environment)
sudo hping3 -2 -p 1900 --flood --rand-source <test-ip>

# 5. Verify blocking
sudo bpftool map dump name blocklist

# 6. Check logs
sudo journalctl -u ssdp-sentinel -n 50
```

---

## 📞 Support

For deployment issues:
1. Check logs: `journalctl -u ssdp-sentinel`
2. Review configuration: `/etc/ssdp-sentinel/config.yaml`
3. Check system requirements
4. Review [TESTING.md](TESTING.md)

---

**Deployment complete!** Your network is now protected against SSDP flood attacks.
