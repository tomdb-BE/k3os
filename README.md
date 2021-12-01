
![GitHub go.mod Go version](https://img.shields.io/github/go-mod/go-version/rancher/rke2os)
![GitHub release (latest SemVer including pre-releases)](https://img.shields.io/github/v/release/rancher/rke2os?include_prereleases&label=release&sort=semver)

Welcome to RKE2OS!

WARNING: this is an experimental fork of https://github.com/rancher/k3os
For testing purposes only - not supported by author/rancher - use at own risk

# rke2OS

rke2OS is a Linux distribution designed to remove as much OS maintenance
as possible in a Kubernetes cluster. It is specifically designed to only
have what is needed to run [rke2](https://github.com/rancher/rke2). Additionally
the OS is designed to be managed by `kubectl` once a cluster is bootstrapped.
Nodes only need to join a cluster and then all aspects of the OS can be managed
from Kubernetes. Both rke2OS and rke2 upgrades are handled by the rke2OS operator.

1. [Quick Start](#quick-start)
1. [Design](#design)
1. [Installation](#installation)
1. [Configuration](#configuration)
1. [Upgrade/Maintenance](#upgrade-and-maintenance)
1. [Building](#building)
1. [Configuration Reference](#configuration-reference)

## Quick Start

Download the ISO from the latest [release](https://github.com/rancher/rke2os/releases) and run it
in VMware, VirtualBox, KVM, or bhyve. The server will automatically start a single node Kubernetes cluster.
Log in with the user `rancher` and run `kubectl`. This is a "live install" running from the ISO media
and changes will not persist after reboot.

To copy rke2OS to local disk, after logging in as `rancher` run `sudo rke2os install`. Then remove the ISO
from the virtual machine and reboot.

Live install (boot from ISO) requires at least 2GB of RAM. Local install requires 1GB RAM.

## Design

Core design goals of rke2OS are

1. Minimal OS for running Kubernetes by way of rke2
2. Ability to upgrade and configure using `kubectl`
3. Versatile installation to allow easy creation of OS images.

### File System Structure

Critical to the design of rke2OS is how that file system is structured. A booted system will
look as follows

```
/etc - ephemeral
/usr - read-only (except /usr/local is writable and persistent)
/rke2os - system files
/home - persistent
/var - persistent
/opt - persistent
/usr/local - persistent
```

#### /etc

All configuration in the system is intended to be ephemeral. If you change anything in `/etc` it
will revert on next reboot. If you wish to persist changes to the configuration they must be done
in the rke2OS `config.yaml` which will be applied on each boot.

#### /usr

The entire user space is stored in `/usr` and as read-only. The only way to change `/usr` is to
change versions of rke2OS. The directory `/usr/local` is a symlink to `/var/local` and therefore
writable.

#### /rke2os

The rke2OS directory contains the core operating system files references on boot to construct the
file system. It contains squashfs images and binaries for rke2OS, rke2, and the Linux kernel. On
boot the appropriate version for all three will be chosen and configured.

#### /var, /usr/local, /home, /opt

Persistent changes should be kept in `/var`, `/usr/local`, `/home`, or `/opt`.

### Upstream Distros

Most of the user-space binaries comes from Alpine and are repackaged for rke2OS. Currently the
kernel source is coming from Ubuntu 20.04 LTS. Some code and a lot of inspiration came from
[LinuxKit](https://github.com/linuxkit/linuxkit)

## Installation

### Interactive Installation

Interactive installation is done from booting from the ISO. The installation is done by running
`rke2os install`. The `rke2os install` sub-command is only available on systems booted live.
An installation to disk will not have `rke2os install`. Follow the prompts to install rke2OS to disk.

***The installation will format an entire disk. If you have a single hard disk attached to the system
it will not ask which disk but just pick the first and only one.***

### Automated Installation

Installation can be automated by using kernel cmdline parameters. There are a lot of creative
solutions to booting a machine with cmdline args. You can remaster the rke2OS ISO, PXE boot,
use qemu/kvm, or automate input with packer. The kernel and initrd are available in the rke2OS release
artifacts, along with the ISO.

The cmdline value `rke2os.mode=install` or `rke2os.fallback_mode=install` is required to enable automated installations.
Below is a reference of all cmdline args used to automate installation

| cmdline                 | Default | Example                                           | Description                     |
|:------------------------|---------|---------------------------------------------------|---------------------------------|
| rke2os.mode               |         | install                                           | Boot rke2OS to the installer, not an interactive session |
| rke2os.fallback_mode      |         | install                                           | If a valid RKE2OS_STATE partition is not found to boot from, run the installation |
| rke2os.install.silent     | false   | true                                              | Ensure no questions will be asked |
| rke2os.install.force_efi  | false   | true                                              | Force EFI installation even when EFI is not detected |
| rke2os.install.device     |         | /dev/vda                                          | Device to partition and format (/dev/sda, /dev/vda) |
| rke2os.install.config_url |         | [https://gist.github.com/.../dweomer.yaml](https://gist.github.com/dweomer/8750d56fb21a3fbc8d888609d6e74296#file-dweomer-yaml) | The URL of the config to be installed at `/rke2os/system/config.yaml` |
| rke2os.install.iso_url    |         | https://github.com/rancher/rke2os/../rke2os-amd64.iso | ISO to download and install from if booting from kernel/vmlinuz and not ISO. |
| rke2os.install.no_format  |         | true                                              | Do not partition and format, assume layout exists already |
| rke2os.install.tty        | auto    | ttyS0                                             | The tty device used for console |
| rke2os.install.debug      | false   | true                                              | Run installation with more logging and configure debug for installed system |
| rke2os.install.power_off  | false   | true                                              | Shutdown the machine after install instead of rebooting |

#### Custom partition layout

By default rke2OS expects one partition to exist labeled `RKE2OS_STATE`. `K3OS_STATE` is expected to be an ext4 formatted filesystem with at least 2GB of disk space. The installer will create this
partitions and file system automatically, or you can create them manually if you have a need for an advanced file system layout.

### Bootstrapped Installation

You can install rke2OS to a block device from any modern Linux distribution. Just download and run [install.sh](https://raw.githubusercontent.com/rancher/rke2os/master/install.sh).
This script will run the same installation as the ISO but is a bit more raw and will not prompt for configuration.

```
Usage: ./install.sh [--force-efi] [--debug] [--tty TTY] [--poweroff] [--takeover] [--no-format] [--config https://.../config.yaml] DEVICE ISO_URL

Example: ./install.sh /dev/vda https://github.com/rancher/rke2os/releases/download/v0.10.0/rke2os.iso

DEVICE must be the disk that will be partitioned (/dev/vda). If you are using --no-format it should be the device of the RKE2OS_STATE partition (/dev/vda2)

The parameters names refer to the same names used in the cmdline, refer to README.md for
more info.
```

### Remastering ISO

To remaster the ISO all you need to do is copy `/rke2os` and `/boot` from the ISO to a new folder. Then modify `/boot/grub/grub.cfg` to add whatever kernel cmdline args for auto-installation.
To build a new ISO just use the utility `grub-mkrescue` as follows:

```bash
# Ubuntu: apt install grub-efi grub-pc-bin mtools xorriso
# CentOS: dnf install grub2-efi grub2-pc mtools xorriso
# Alpine: apk add grub-bios grub-efi mtools xorriso
mount -o loop rke2os.iso /mnt
mkdir -p iso/boot/grub
cp -rf /mnt/rke2os iso/
cp /mnt/boot/grub/grub.cfg iso/boot/grub/

# Edit iso/boot/grub/grub.cfg

grub-mkrescue -o rke2os-new.iso iso/ -- -volid RKE2OS
```

GRUB2 CAVEAT: Some non-Alpine installations of grub2 will create `${ISO}/boot/grub2` instead of `${ISO}/boot/grub`
which will generally lead to broken installation media. Be mindful of this and modify the above commands
(that work with this path) accordingly. *Systems that exhibit this behavior typically have `grub2-mkrescue`
on the path instead of `grub-mkrescue`.*

### Takeover Installation

A special mode of installation is designed to install to a current running Linux system. This only works on ARM64 and x86_64. Download [install.sh](https://raw.githubusercontent.com/rancher/rke2os/master/install.sh)
and run with the `--takeover` flag. This will install rke2OS to the current root and override the grub.cfg. After you reboot the system rke2OS will then delete all files on the root partition that are not rke2OS and then shutdown. This mode is particularly handy when creating cloud images. This way you can use an existing base image like Ubuntu and install rke2OS over the top, snapshot, and create a new image.

In order for this to work a couple of assumptions are made. First the root (/) is assumed to be an ext4 partition. Also it is assumed that grub2 is installed and looking for the configuration at `/boot/grub/grub.cfg`. When running `--takeover` ensure that you also set `--no-format` and DEVICE must be set to the partition of `/`. Refer to the AWS packer template to see this mode in action. Below is any example of how to run a takeover installation.

```bash
./install.sh --takeover --debug --tty ttyS0 --config /tmp/config.yaml --no-format /dev/vda1 https://github.com/rancher/rke2os/releases/download/v0.10.0/rke2os.iso
```

### ARM Overlay Installation

If you have a custom ARMv7 or ARM64 device you can easily use an existing bootable ARM image to create a rke2OS setup.
All you must do is boot the ARM system and then extract `rke2os-rootfs-arm.tar.gz` to the root (stripping one path,
look at the example below) and then place your cloud-config at `/rke2os/system/config.yaml`. For example:

```bash
curl -sfL https://github.com/rancher/rke2os/releases/download/v0.10.0/rke2os-rootfs-arm.tar.gz | tar zxvf - --strip-components=1 -C /
cp myconfig.yaml /rke2os/system/config.yaml
sync
reboot -f
```

This method places rke2OS on disk and also overwrites `/sbin/init`.
On next reboot your ARM bootloader and kernel should be loaded,
but then when user space is to be initialized rke2OS should take over.
One important consideration at the moment is that rke2OS assumes the root device is not read only.
This typically means you need to remove `ro` from the kernel cmdline.
This should be fixed in a future release.

## Configuration

All configuration is done through a single cloud-init style config file that is
either packaged in the image, downloaded though cloud-init or managed by
Kubernetes. The configuration file is found at

```
/rke2os/system/config.yaml
/var/lib/rancher/rke2os/config.yaml
/var/lib/rancher/rke2os/config.d/*
```

The `/rke2os/system/config.yaml` file is reserved for the system installation and should not be
modified on a running system. This file is usually populated by during the image build or
installation process and contains important bootstrap information (such as networking or cloud-init
data sources).

The `/var/lib/rancher/rke2os/config.yaml` or `config.d/*` files are intended to be used at runtime.
These files can be manipulated manually, through scripting, or managed with the Kubernetes operator.

### Sample `config.yaml`

A full example of the rke2OS configuration file is as below.

```yaml
ssh_authorized_keys:
- ssh-rsa AAAAB3NzaC1yc2EAAAADAQAB...
- github:ibuildthecloud
write_files:
- encoding: ""
  content: |-
    #!/bin/bash
    echo hello, local service start
  owner: root
  path: /etc/local.d/example.start
  permissions: '0755'
hostname: myhost
init_cmd:
- "echo hello, init command"
boot_cmd:
- "echo hello, boot command"
run_cmd:
- "echo hello, run command"

rke2os:
  data_sources:
  - aws
  - cdrom
  modules:
  - kvm
  - nvme
  sysctl:
    kernel.printk: "4 4 1 7"
    kernel.kptr_restrict: "1"
  dns_nameservers:
  - 8.8.8.8
  - 1.1.1.1
  ntp_servers:
  - 0.us.pool.ntp.org
  - 1.us.pool.ntp.org
  wifi:
  - name: home
    passphrase: mypassword
  - name: nothome
    passphrase: somethingelse
  password: rancher
  server_url: https://someserver:6443
  token: TOKEN_VALUE
  labels:
    region: us-west-1
    somekey: somevalue
  rke2_args:
  - server
  - "--cluster-init"
  environment:
    http_proxy: http://myserver
    https_proxy: http://myserver
  taints:
  - key1=value1:NoSchedule
  - key1=value1:NoExecute
```

Refer to the [configuration reference](#configuration-reference) for full details of each
configuration key.

### Kubernetes

Since rke2OS is built on rke2 all Kubernetes configuration is done by configuring
rke2. This is primarily done through `environment` and `rke2_args` keys in `config.yaml`.
The `write_files` key can be used to populate the `/var/lib/rancher/rke2/server/manifests`
folder with apps you'd like to deploy on boot.

Refer to [rke2 docs](https://github.com/rancher/rke2/blob/master/README.md) for more
information on how to configure Kubernetes.

### Kernel cmdline

All configuration can be passed as kernel cmdline parameters too. The keys are dot
separated. For example `rke2os.token=TOKEN`. If the key is a slice, multiple values are set by
repeating the key, for example `rke2os.dns_nameserver=1.1.1.1 rke2os.dns_nameserver=8.8.8.8`. You
can use the plural or singular form of the name, just ensure you consistently use the same form. For
map values the form `key[key]=value` form is used, for example `rke2os.sysctl[kernel.printk]="4 4 1 7"`.
If the value has spaces in it ensure that the value is quoted. Boolean keys expect a value of
`true` or `false` or no value at all means `true`. For example `rke2os.install.efi` is the same
as `rke2os.install.efi=true`.

### Phases

Configuration is applied in three distinct phases: `initrd`, `boot`, `runtime`. `initrd`
is run during the initrd phase before the root disk has been mounted. `boot` is run after
the root disk is mounted and the file system is setup, but before any services have started.
There is no networking available yet at this point. The final stage `runtime` is executed after
networking has come online. If you are using a configuration from a cloud provider (like AWS
userdata) it will only be run in the `runtime` phase. Below is a table of which config keys
are supported in each phase.

| Key                  | initrd | boot | runtime |
|----------------------|--------|------|---------|
| ssh_authorized_keys  |        |  x   |    x    |
| write_files          |    x   |  x   |    x    |
| hostname             |    x   |  x   |    x    |
| run_cmd              |        |      |    x    |
| boot_cmd             |        |  x   |         |
| init_cmd             |    x   |      |         |
| rke2os.data_sources    |        |      |    x    |
| rke2os.modules         |    x   |  x   |    x    |
| rke2os.sysctls         |    x   |  x   |    x    |
| rke2os.ntp_servers     |        |  x   |    x    |
| rke2os.dns_nameservers |        |  x   |    x    |
| rke2os.wifi            |        |  x   |    x    |
| rke2os.password        |    x   |  x   |    x    |
| rke2os.server_url      |        |  x   |    x    |
| rke2os.token           |        |  x   |    x    |
| rke2os.labels          |        |  x   |    x    |
| rke2os.rke2_args        |        |  x   |    x    |
| rke2os.environment     |    x   |  x   |    x    |
| rke2os.taints          |        |  x   |    x    |

### Networking

Networking is powered by `connman`. To configure networking a couple of helper keys are
available: `rke2os.dns_nameserver`, `rke2os.ntp_servers`, `rke2os.wifi`. Refer to the
[reference](#configuration-reference) for a full explanation of those keys. If you wish
to configure a HTTP proxy set the `http_proxy`, and `https_proxy` fields in `rke2os.environment`.
All other networking configuration should be done by configuring connman directly by using the
`write_files` key to create connman [service](https://manpages.debian.org/testing/connman/connman-service.config.5.en.html)
files.

## Upgrade and Maintenance

Upgrading and reconfiguring rke2OS is all handled through the Kubernetes operator. The operator
is still in development. More details to follow. The basic design is that one can set the
desired rke2 and rke2OS versions, plus their configuration and the operator will roll that out to
the cluster.

### Automatic Upgrades

Integration with [rancher/system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) has been implemented as of [v0.9.0](https://github.com/rancher/rke2os/releases/tag/v0.9.0).
To enable a rke2OS node to automatically upgrade from the [latest GitHub release](https://github.com/rancher/rke2os/releases/latest) you will need to make sure it has the label
`rke2os.io/upgrade` with value `latest` (for rke2OS versions prior to v0.11.x please use label `plan.upgrade.cattle.io/rke2os-latest`). The upgrade controller will then spawn an upgrade job
that will drain most pods, upgrade the rke2OS content under `/rke2os/system`, and then reboot. The system should come back up running the latest
kernel and rke2 version bundled with rke2OS and ready to schedule pods.

#### Pre v0.9.0

If your rke2OS installation is running a version prior to the v0.9.0 release or one of its release candidates you can setup
the system upgrade controller to upgrade your rke2OS by following these steps:

```shell script
# apply the system-upgrade-controller manifest (once per cluster)
kubectl apply -f https://raw.githubusercontent.com/rancher/rke2os/v0.10.0/overlay/share/rancher/rke2/server/manifests/system-upgrade-controller.yaml
# after the system-upgrade-controller pod is Ready, apply the plan manifest (once per cluster)
kubectl apply -f https://raw.githubusercontent.com/rancher/rke2os/v0.10.0/overlay/share/rancher/rke2/server/manifests/system-upgrade-plans/rke2os-latest.yaml
# apply the `plan.upgrade.cattle.io/rke2os-latest` label as described above (for every rke2OS node), e.g.
kubectl label nodes -l rke2os.io/mode plan.upgrade.cattle.io/rke2os-latest=enabled # this should work on any cluster with rke2OS installations at v0.7.0 or greater
```

### Manual Upgrades

For single-node or development use cases, where the operator is not being used, you can upgrade the rootfs and kernel with the following commands. If you do not specify RKE2OS_VERSION, it will default to the latest release.

When using an overlay install such as on Raspberry Pi (see [ARM Overlay Installation](#arm-overlay-installation)) the original distro kernel (such as Raspbian) will continue to be used. On these systems the rke2os-upgrade-kernel script will exit with a warning and perform no action.

```bash
export RKE2OS_VERSION=v0.10.0
/usr/share/rancher/rke2os/scripts/rke2os-upgrade-rootfs
/usr/share/rancher/rke2os/scripts/rke2os-upgrade-kernel
```

You should always remember to backup your data first, and reboot after upgrading.

#### Manual Upgrade Scripts Have Been DEPRECATED

These scripts have been deprecated as of v0.9.0 are still on the system at `/usr/share/rancher/rke2os/scripts`.

## Building

To build rke2OS you just need Docker and then run `make`. All artifacts will be put in `./dist/artifacts`.
If you are running on Linux you can run `./scripts/run` to run a VM of rke2OS in the terminal. To exit
the instance type `CTRL+a c` to get the qemu console and then `q` for quit.

The source for the kernel is in `https://github.com/rancher/rke2os-kernel` and similarly you
just need to have Docker and run `make` to compile the kernel.

## Configuration Reference

Below is a reference of all keys available in the `config.yaml`

### `ssh_authorized_keys`

A list of SSH authorized keys that should be added to the `rancher` user. rke2OS primarily
has one user, `rancher`. The `root` account is always disabled, has no password, and is never
assigned a ssh key. SSH keys can be obtained from GitHub user accounts by using the format
`github:${USERNAME}`. This is done by downloading the keys from `https://github.com/${USERNAME}.keys`.

Example

```yaml
ssh_authorized_keys:
- "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2TBZGjE+J8ag11dzkFT58J3XPONrDVmalCNrKxsfADfyy0eqdZrG8hcAxAR/5zuj90Gin2uBR4Sw6Cn4VHsPZcFpXyQCjK1QDADj+WcuhpXOIOY3AB0LZBly9NI0ll+8lo3QtEaoyRLtrMBhQ6Mooy2M3MTG4JNwU9o3yInuqZWf9PvtW6KxMl+ygg1xZkljhemGZ9k0wSrjqif+8usNbzVlCOVQmZwZA+BZxbdcLNwkg7zWJSXzDIXyqM6iWPGXQDEbWLq3+HR1qKucTCSxjbqoe0FD5xcW7NHIME5XKX84yH92n6yn+rxSsyUfhJWYqJd+i0fKf5UbN6qLrtd/D"
- "github:ibuildthecloud"
```

### `write_files`

A list of files to write to disk on boot. These files can be either plain text, gziped, base64 encoded,
or base64+gzip encoded.

Example

```yaml
write_files:
- encoding: b64
  content: CiMgVGhpcyBmaWxlIGNvbnRyb2xzIHRoZSBzdGF0ZSBvZiBTRUxpbnV4...
  owner: root:root
  path: /etc/connman/main.conf
  permissions: '0644'
- content: |
    # My new /etc/sysconfig/samba file

    SMDBOPTIONS="-D"
  path: /etc/sysconfig/samba
- content: !!binary |
    f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAwARAAAAAAABAAAAAAAAAAJAVAAAAAA
    AEAAHgAdAAYAAAAFAAAAQAAAAAAAAABAAEAAAAAAAEAAQAAAAAAAwAEAAAAAAA
    AAAAAAAAAwAAAAQAAAAAAgAAAAAAAAACQAAAAAAAAAJAAAAAAAAcAAAAAAAAAB
    ...
  path: /bin/arch
  permissions: '0555'
- content: |
    15 * * * * root ship_logs
  path: /etc/crontab
```

### `hostname`

Set the system hostname. This value will be overwritten by DHCP if DHCP supplies a hostname for
the system.

Example

```yaml
hostname: myhostname
```

### `init_cmd`, `boot_cmd`, `run_cmd`

All three keys are used to run arbitrary commands on startup in the respective phases of `initrd`,
`boot` and `runtime`. Commands are ran after `write_files` so it is possible to write a script to
disk and run it from these commands. That often makes it easier to do longer form setup.

### `rke2os.data_sources`

These are the data sources used for download config from cloud provider. The valid options are:

    aws
    cdrom
    digitalocean
    gcp
    hetzner
    openstack
    packet
    scaleway
    vultr

More than one can be supported at a time, for example:

```yaml
rke2os:
  data_sources:
  - openstack
  - cdrom
```

When multiple data sources are specified they are probed in order and the first to provide `/run/config/userdata` will halt further processing.

### `rke2os.modules`

A list of kernel modules to be loaded on start.

Example

```yaml
rke2os:
  modules:
  - kvm
  - nvme
```

### `rke2os.sysctls`

Kernel sysctl to setup on start. These are the same configuration you'd typically find in `/etc/sysctl.conf`.
Must be specified as string values.

```yaml
rke2os:
  sysctl:
    kernel.printk: 4 4 1 7      # the YAML parser will read as a string
    kernel.kptr_restrict: "1"   # force the YAML parser to read as a string
```

### `rke2os.ntp_servers`

**Fallback** ntp servers to use if NTP is not configured elsewhere in connman.

Example

```yaml
rke2os:
  ntp_servers:
  - 0.us.pool.ntp.org
  - 1.us.pool.ntp.org
```

### `rke2os.dns_nameservers`

**Fallback** DNS name servers to use if DNS is not configured by DHCP or in a connman service config.

Example

```yaml
rke2os:
  dns_nameservers:
  - 8.8.8.8
  - 1.1.1.1
```

### `rke2os.wifi`

Simple wifi configuration. All that is accepted is `name` and `passphrase`. If you require more
complex configuration then you should use `write_files` to write a connman service config.

Example:

```yaml
rke2os:
  wifi:
  - name: home
    passphrase: mypassword
  - name: nothome
    passphrase: somethingelse
```

### `rke2os.password`

The password for the `rancher` user. By default there is no password for the `rancher` user.
If you set a password at runtime it will be reset on next boot because `/etc` is ephemeral. The
value of the password can be clear text or an encrypted form. The easiest way to get this encrypted
form is to just change your password on a Linux system and copy the value of the second field from
`/etc/shadow`. You can also encrypt a password using `openssl passwd -1`.

Example

```yaml
rke2os:
  password: "$1$tYtghCfK$QHa51MS6MVAcfUKuOzNKt0"
```

Or clear text

```yaml
rke2os:
  password: supersecure
```

### `rke2os.server_url`

The URL of the rke2 server to join as an agent.

Example

```yaml
rke2os:
  server_url: https://myserver:6443
```

### `rke2os.token`

The cluster secret or node token. If the value matches the format of a node token it will
automatically be assumed to be a node token. Otherwise it is treated as a cluster secret.

Example

```yaml
rke2os:
  token: myclustersecret
```

Or a node token

```yaml
rke2os:
  token: "K1074ec55daebdf54ef48294b0ddf0ce1c3cb64ee7e3d0b9ec79fbc7baf1f7ddac6::node:77689533d0140c7019416603a05275d4"
```

### `rke2os.labels`

Labels to be assigned to this node in Kubernetes on registration. After the node is first registered
in Kubernetes the value of this setting will be ignored.

Example

```yaml
rke2os:
  labels:
    region: us-west-1
    somekey: somevalue
```

### `rke2os.rke2_args`

Arguments to be passed to the rke2 process. The arguments should start with `server` or `agent` to be valid.
`rke2_args` is an exec-style (aka uninterpreted) argument array which means that when specifying a flag with a value one
must either join the flag to the value with an `=` in the same array entry or specify the flag in an entry by itself
immediately followed the value in another entry, e.g.:

```yaml
# Rke2 flags with values joined with `=` in single entry
rke2os:
  rke2_args:
  - server
  - "--cluster-cidr=10.107.0.0/23"
  - "--service-cidr=10.107.1.0/23"

# Effectively invokes rke2 as:
# exec "rke2" "server" "--cluster-cidr=10.107.0.0/23" "--service-cidr=10.107.1.0/23" 
```

```yaml
# Rke2 flags with values in following entry
rke2os:
  rke2_args:
  - server
  - "--cluster-cidr"
  - "10.107.0.0/23"
  - "--service-cidr"
  - "10.107.1.0/23"

# Effectively invokes rke2 as:
# exec "rke2" "server" "--cluster-cidr" "10.107.0.0/23" "--service-cidr" "10.107.1.0/23" 
```

### `rke2os.environment`

Environment variables to be set on rke2 and other processes like the boot process.
Primary use of this field is to set the http proxy.

Example

```yaml
rke2os:
  environment:
    http_proxy: http://myserver
    https_proxy: http://myserver
```

### `rke2os.taints`

Taints to set on the current node when it is first registered. After the
node is first registered the value of this field is ignored.

```yaml
rke2os:
  taints:
  - "key1=value1:NoSchedule"
  - "key1=value1:NoExecute"
```

## License

Copyright (c) 2014-2020 [Rancher Labs, Inc.](http://rancher.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
