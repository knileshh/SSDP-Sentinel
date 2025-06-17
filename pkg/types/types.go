package types

import (
    "net"
    "time"
)

// PacketFeatures represents all 80 features from CIC-DDoS2019
type PacketFeatures struct {
    // Basic info
    SourceIP   net.IP
    DestIP     net.IP
    SourcePort uint16
    DestPort   uint16
    Protocol   uint8
    Timestamp  time.Time
    
    // Flow features
    FlowDuration        uint64
    TotalFwdPackets     uint32
    TotalBwdPackets     uint32
    TotalLenFwdPackets  uint64
    TotalLenBwdPackets  uint64
    
    // Packet length stats
    FwdPacketLenMax  uint16
    FwdPacketLenMin  uint16
    FwdPacketLenMean float64
    FwdPacketLenStd  float64
    
    // TODO: Add remaining features
}
