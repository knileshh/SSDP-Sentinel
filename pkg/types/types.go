package types

import "net"

// PacketFeatures represents the 80 features for ML
type PacketFeatures struct {
    SourceIP   net.IP
    DestIP     net.IP
    SourcePort uint16
    DestPort   uint16
    Protocol   uint8
    
    // Flow statistics
    FlowDuration      uint64
    TotalFwdPackets   uint32
    TotalBwdPackets   uint32
    
    // TODO: Add remaining 72 features
}
