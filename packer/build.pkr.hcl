packer {
  required_version = ">= 1.10"
  required_plugins {
    qemu = {
      version = "~> 1.1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "source_image_url" {
  type        = string
  description = "URL of the upstream qcow2 to layer on top of."
  default     = "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-9.7-20260518.x86_64.qcow2"
}

variable "source_image_checksum" {
  type        = string
  description = "Checksum of the source image in `<algorithm>:<hex>` form."
  default     = "sha256:28937fedfaddb141a33bb353b7ee8f968bfdb1d69729a367a62cd5d7f2219f71"
}

variable "output_directory" {
  type    = string
  default = "../output"
}

variable "vm_name" {
  type    = string
  default = "linux-base-image.qcow2"
}

variable "version" {
  type        = string
  description = "Tag for the resulting image. CI passes the git ref / release tag."
  default     = "dev"
}

# qemu-builder pattern: take the upstream cloud image, boot it with a tiny
# cidata ISO (cloud-init NoCloud) that drops a packer SSH key, run install
# scripts over SSH, shut down, capture the modified qcow2. Run
# `./scripts/prepare-cidata.sh` once before `packer build` to generate the
# ephemeral SSH keypair + user-data.
source "qemu" "linux-base" {
  iso_url      = var.source_image_url
  iso_checksum = var.source_image_checksum

  disk_image  = true
  disk_size   = "10G"
  format      = "qcow2"
  accelerator = "kvm"
  cpus        = 2
  memory      = 2048
  headless    = true

  output_directory = var.output_directory
  vm_name          = var.vm_name

  cd_files = ["./cidata/user-data", "./cidata/meta-data"]
  cd_label = "cidata"

  ssh_username         = "almalinux"
  ssh_private_key_file = "./cidata/ssh_key"
  ssh_timeout          = "10m"

  shutdown_command = "sudo shutdown -h now"

  qemuargs = [
    ["-cpu", "host"],
    ["-display", "none"],
  ]
}

build {
  name    = "linux-base-image-${var.version}"
  sources = ["source.qemu.linux-base"]

  provisioner "shell" {
    script          = "./scripts/install.sh"
    execute_command = "sudo -E bash {{ .Path }}"
  }
}
