#!/usr/bin/env bash
# Provisioner: installs the V-Sekai base package set into the running VM
# during packer build. Runs as root (packer invokes via `sudo -E bash`).
set -euo pipefail

dnf -y update
dnf -y install \
  podman \
  containers-common \
  chrony \
  qemu-guest-agent

systemctl enable chronyd qemu-guest-agent

# Reset machine-id so cloned VMs get fresh IDs on first boot (cloud-init
# regenerates it). Without this every clone collides on the same DHCP
# client identifier and gets the same lease.
: > /etc/machine-id
rm -f /var/lib/dbus/machine-id || true

# Clear dnf cache + cloud-init state so the first real boot acts like
# a fresh install in the consumer's environment.
dnf clean all
cloud-init clean --logs

# Trim free blocks so the qcow2 sparse-allocates well.
fstrim -av || true
