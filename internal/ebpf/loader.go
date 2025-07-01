package ebpf

import (
    "github.com/cilium/ebpf"
    "github.com/sirupsen/logrus"
)

// Loader manages eBPF program lifecycle
type Loader struct {
    iface string
    log   *logrus.Logger
}

// NewLoader creates a new eBPF loader
func NewLoader(iface string, logger *logrus.Logger) *Loader {
    return &Loader{
        iface: iface,
        log:   logger,
    }
}

// Load loads the eBPF objects
func (l *Loader) Load() error {
    l.log.Info("Loading eBPF objects...")
    // TODO: Implement loading
    return nil
}
