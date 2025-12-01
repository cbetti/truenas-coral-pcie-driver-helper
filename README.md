# TrueNAS Coral PCIe Driver Helper

Small helper scripts to build and maintain the Google Coral PCIe Edge TPU kernel
modules (`gasket`, `apex`) on **TrueNAS Community Edition / TrueNAS SCALE** after
kernel upgrades.

**Maintainer note**: This weekend project grew legs and wandered onto GitHub.
Happy if it helps, but my time for issues and PRs is limited. Consider it "open
source with a sleepy maintainer." Fork as needed!

## What this does

Running `./scripts/run-on-this-kernel.sh`:

- Enables the TrueNAS development toolchain via `install-dev-tools`.
- Adds the official Coral APT repository and GPG key.
- Installs the userspace library `libedgetpu1-std`.
- Fetches `google/gasket-driver`, applies local patches, and builds a
  `gasket-dkms_<kernel>.deb`.
- Installs the DKMS package and loads `gasket` + `apex`.
- Verifies that `/dev/apex_0` (and friends) exist.
- Records what was installed in `notes/<kernel>.md`.

All state (source tree and built `.deb` files) lives under the repo’s `artifacts/`
directory.

> **Tested on:** TrueNAS SCALE 25.10.0.1 with kernel `6.12.33-production+truenas`.

## Requirements

- TrueNAS SCALE with shell access as `root`.
- A PCIe (or PCIe-via-M.2) Coral Edge TPU.
- Internet access for APT and GitHub.
- Familiarity with visudo.

Note: `install-dev-tools` is a one-way TrueNAS change that enables extra APT repos
and build tools. There is no official “undo” for that.

## Quick start

Choose a dataset and clone the repo, for example:

```bash
cd /mnt/tank/apps      # adjust pool/path as you like
git clone https://github.com/you/truenas-coral-pcie-driver.git coral-driver
cd coral-driver
```

Build and install the drivers for the current kernel:

```bash
./scripts/run-on-this-kernel.sh
```

If everything succeeds you should see `/dev/apex_0` on the host:

```bash
ls /dev/apex*
```

Re-run `./scripts/run-on-this-kernel.sh` **after each SCALE upgrade** (or any
time the kernel changes and `/dev/apex_0` disappears).

## Recommended: load on boot (Post-init script)

To have TrueNAS try to load the modules at boot using `scripts/post-init.sh`:

1. In the TrueNAS UI, go to **System Settings → Advanced → Init/Shutdown
   Scripts.**
1. Add a new script:
   - Type: Script
   - When: Post Init
   - Script: `/mnt/tank/apps/coral-driver/scripts/post-init.sh`
     (adjust path if you cloned elsewhere)
   - Run As User: `root`
1. Save and enable the entry.

This script only runs `modprobe gasket` and `modprobe apex` and logs whether
`/dev/apex_0`, `/dev/apex_1` (for Dual Edge), etc. are present.

## What gets changed on the host

This repo’s scripts may:

- Enable the TrueNAS dev toolchain via `install-dev-tools`.
- Add:
  - `/etc/apt/sources.list.d/coral-edgetpu.list`
  - `/etc/apt/trusted.gpg.d/coral-edgetpu.gpg`
- Install:
  - `libedgetpu1-std`
  - `gasket-dkms_<kernel>.deb`
- Add module autoload config:
  - `/etc/modules-load.d/coral.conf` (loads `gasket` and `apex`)

## Removing everything

To remove the Coral driver and APT configuration:

```bash
apt remove gasket-dkms
rm /etc/apt/sources.list.d/coral-edgetpu.list
rm /etc/apt/trusted.gpg.d/coral-edgetpu.gpg
rm /etc/modules-load.d/coral.conf
rm /etc/modprobe.d/coral.conf 2>/dev/null || true
apt update
```

Then disable or delete the TrueNAS Post-init entry if you created one, and
(optionally) delete the repo:

```bash
rm -rf /mnt/tank/apps/coral-driver
```

Reboot to ensure the system comes up clean.

## License

This project is licensed under the GNU General Public License v2.0 (GPL-2.0-only).
See LICENSE for details. Use at your own risk; no warranty is provided.
