---
name: Proxmox OPNsense optimization
description: Proxmox VM setup for OPNsense - PCI passthrough, CPU config, Suricata IDS/IPS performance tuning
type: project
---

Ryan is running OPNsense as a VM on Proxmox with a 6-core CPU. Investigating performance optimizations for line-rate gigabit IDS/IPS.

**Current status (2026-03-23):**
- OPNsense VM has max cores assigned, CPU type set to "host"
- Suricata IPS is running but CPU maxes out, limiting download speeds
- Upload is fine (~1.2 Gbps), download bottlenecked by IDS inspection
- Speed test from homelab: 1010 Mbps down / 1213 Mbps up (AT&T, San Jose)
- CPU model not yet confirmed

**PCI passthrough plan:**
- Enable IOMMU in BIOS (VT-d for Intel, AMD-Vi for AMD)
- Add intel_iommu=on/amd_iommu=on iommu=pt to GRUB
- Load VFIO modules, bind NIC to vfio-pci driver
- Pass dedicated PCIe NIC to OPNsense VM (avoid passing the Proxmox management NIC)
- Watch out for IOMMU group sharing with onboard NICs

**Suricata IPS tuning priorities:**
1. Trim rulesets - keep malware/C2/botnet/trojan, drop irrelevant categories (games, policy, chat)
2. Only monitor WAN interface, skip LAN-to-LAN inspection
3. Reduce Suricata thread count to 2-3 to lower context switching
4. Keeping IPS mode (not switching to IDS) - Ryan wants active blocking of malware C2 traffic
5. Disable hardware offloading on interfaces (correctness in VMs)
6. PCI passthrough for NIC (incremental gain ~10-20%)
7. Ensure enough RAM allocated so Suricata rulesets don't cause swapping

**Why:** OPNsense IPS at gigabit speed is CPU-intensive. 6 cores may not be enough for full rulesets in IPS mode. Focused ruleset + tuning is the practical path forward.
**How to apply:** When discussing OPNsense performance, prioritize ruleset trimming over hardware changes. Ryan prefers keeping IPS active blocking over switching to passive IDS.
