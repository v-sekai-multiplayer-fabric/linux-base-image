# linux-base-image

AlmaLinux 9 GenericCloud qcow2 with podman, chrony, and qemu-guest-agent
preinstalled. Other V-Sekai VM images (`restic-backup-image`,
`cockroach-crdb-image`, `zone-backend-image`) `FROM` this and add their
service binaries + quadlets on top.

## Output

GitHub release artifact: `linux-base-image-<version>.qcow2` plus a
`.sha512` file. Consumers download by URL and pin the version.

## Build

CI (`.github/workflows/build.yml`) runs packer on each push to `main`
and on schedule. Output uploads as a draft release; tag the release to
publish.

Local:

```sh
cd packer
packer init build.pkr.hcl
packer build build.pkr.hcl
ls output/
```

Requires `qemu-system-x86_64` and KVM. Linux only; on macOS/Windows use
the GitHub Actions builder.

## What's in the image

- AlmaLinux 9.7 (source: `AlmaLinux-9-GenericCloud-9.7-20260518.x86_64.qcow2`)
- `podman` and `containers-common` for quadlet-driven services
- `chrony` (enabled) for time sync
- `qemu-guest-agent` (enabled) so Harvester/libvirt see VM state
- Default `almalinux` user kept; cloud-init untouched (downstream
  images inject SSH keys + service config via cloud-init data sources)

## Why bake an image instead of running cloud-init on first boot

Cold-boot install of versitygw / cockroach / Elixir release via
cloud-init takes minutes per VM and depends on upstream package mirrors
being reachable at boot time. Baking moves that into CI (once per
release) and leaves runtime cloud-init for only the things that vary
per VM: SSH keys, hostname, secret material.

## Inheritance

Downstream image repos pin the parent release version explicitly:

```hcl
# in restic-backup-image's build.pkr.hcl
variable "parent_image_url" {
  default = "https://github.com/v-sekai-multiplayer-fabric/linux-base-image/releases/download/v0.1.0/linux-base-image-v0.1.0.qcow2"
}
```

Never `latest`. Bumping the parent in a downstream is a deliberate PR.
