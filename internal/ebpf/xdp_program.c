// SPDX-License-Identifier: GPL-2.0
// XDP program for SSDP packet filtering

#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

SEC("xdp")
int xdp_ssdp_filter(struct xdp_md *ctx) {
    // TODO: Implement packet filtering
    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
