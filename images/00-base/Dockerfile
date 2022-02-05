### BASE ###
FROM debian:bullseye-slim as base
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    bash \
    bash-completion \
    ca-certificates \
    connman \
    conntrack \
    coreutils \
    cryptsetup \
    curl \
    dbus \
    dmidecode \
    dosfstools \
    e2fsprogs \
    efibootmgr \
    findutils \
    glusterfs-client \
    grub2 \
    haveged \
    htop \
    hyperv-daemons \
    iproute2 \
    iptables \
    irqbalance \
    jq \
    kbd \
    libusb-0.1-4 \
    logrotate \
    lsscsi \
    lvm2 \
    mdadm \
    multipath-tools \
    nfs-client \
    open-iscsi \
    openrc \
    openssh-client \
    openssh-server \
    parted \
    procps \
    qemu-guest-agent \
    rng-tools \
    rsync \
    strace \
    smartmontools \
    sudo \
    tar \
    tzdata \
    util-linux \
    vim \
    wireguard-tools \
    wpasupplicant \
    xfsprogs \
    xz-utils \
# replicate the default "no idea, friend" behavior of virt-what
 && touch /usr/sbin/virt-what \
 && chmod +x /usr/sbin/virt-what
