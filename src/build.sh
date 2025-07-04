#!/bin/bash
set -e

source src/config.sh

BUSYBOX_VERSION=$(get_config_value BUSYBOX_VERSION) || exit 1
KERNEL_VERSION=$(get_config_value KERNEL_VERSION) || exit 1
FIRMWARE_VERSION=$(get_config_value FIRMWARE_VERSION) || exit 1
BUILD_DIR=/build
OUT_ISO=$BUILD_DIR/lupin.iso

HOSTNAME=$(get_config_value HOSTNAME) || exit 1

export CCACHE_DIR=/root/.cache/ccache
export CCACHE_MAXSIZE=1G
export PATH="/usr/lib/ccache:$PATH"

echo "Kernel version: $KERNEL_VERSION"

mkdir -p \
    $BUILD_DIR/pkg \
    $BUILD_DIR/kernel \
    $BUILD_DIR/firmware \
    $BUILD_DIR/busybox \
    $BUILD_DIR/rootfs/usr/bin \
    $BUILD_DIR/rootfs/usr/sbin \
    $BUILD_DIR/rootfs/usr/lib/firmware \
    $BUILD_DIR/rootfs/usr/lib/modules \
    $BUILD_DIR/rootfs/usr/include \
    $BUILD_DIR/rootfs/usr/share/man \
    $BUILD_DIR/rootfs/etc \
    $BUILD_DIR/rootfs/home \
    $BUILD_DIR/iso/boot \
    $BUILD_DIR/iso/isolinux \
    $BUILD_DIR/initramfs
ln -s usr/bin $BUILD_DIR/rootfs/bin
ln -s usr/bin $BUILD_DIR/rootfs/sbin
ln -s usr/lib $BUILD_DIR/rootfs/lib
ln -s usr/lib $BUILD_DIR/rootfs/lib64
ln -s bin $BUILD_DIR/rootfs/usr/sbin

for rel_script in src/pkg/*.sh; do
    cd $BUILD_DIR
    script=$(realpath $rel_script)
    pkg_name=$(basename "$script" .sh)
    uppercase_pkg_name=$(echo "$pkg_name" | tr '[:lower:]' '[:upper:]')

    if get_config_bool "$uppercase_pkg_name"; then
        echo "Building $pkg_name..."

        OUT=$BUILD_DIR/rootfs

        mkdir -p $BUILD_DIR/pkg/$pkg_name
        cd $BUILD_DIR/pkg/$pkg_name

        source "$script"

        for dep in ${dependencies[@]}; do
            uppercase_dep_name=$(echo "$dep" | tr '[:lower:]' '[:upper:]')
            if ! get_config_bool "$uppercase_dep_name"; then
                echo "Error: $pkg_name depends on $dep, which wasn't enabled"
                exit 1
            fi
        done

        build

        unset -f build
        unset -v dependencies
        unset -v OUT
    fi
done

echo "Fetching busybox..."
cd $BUILD_DIR/busybox
wget -nc https://github.com/mirror/busybox/archive/refs/tags/${BUSYBOX_VERSION//./_}.tar.gz
tar -xf ${BUSYBOX_VERSION//./_}.tar.gz
mv busybox-${BUSYBOX_VERSION//./_} busybox-$BUSYBOX_VERSION

echo "Fetching kernel..."
cd $BUILD_DIR/kernel
wget -nc https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz
tar -xf linux-$KERNEL_VERSION.tar.xz

echo "Fetching firmware..."
cd $BUILD_DIR/firmware
wget -nc https://gitlab.com/kernel-firmware/linux-firmware/-/archive/$FIRMWARE_VERSION/linux-firmware-$FIRMWARE_VERSION.tar.gz
tar -xf linux-firmware-$FIRMWARE_VERSION.tar.gz
cp -a linux-firmware-$FIRMWARE_VERSION/* $BUILD_DIR/rootfs/usr/lib/firmware

echo "Building busybox..."
cd $BUILD_DIR/busybox
cd busybox-$BUSYBOX_VERSION
make defconfig
$BUILD_DIR/kernel/linux-$KERNEL_VERSION/scripts/config --enable CONFIG_STATIC
$BUILD_DIR/kernel/linux-$KERNEL_VERSION/scripts/config --disable CONFIG_TC
$BUILD_DIR/kernel/linux-$KERNEL_VERSION/scripts/config --disable CONFIG_INIT
$BUILD_DIR/kernel/linux-$KERNEL_VERSION/scripts/config --disable CONFIG_LINUXRC
make silentoldconfig
make CC="ccache gcc" -j$(nproc)
make install
cp _install/bin/busybox $BUILD_DIR/rootfs/usr/bin/busybox
for file in _install/usr/bin/* _install/bin/* _install/usr/sbin/* _install/sbin/*; do
    if [ ! -f $BUILD_DIR/rootfs/usr/bin/"$(basename "$file")" ]; then
        ln -s busybox $BUILD_DIR/rootfs/usr/bin/"$(basename "$file")"
    fi
done

echo "Building kernel..."
cd $BUILD_DIR/kernel
cd linux-$KERNEL_VERSION
make defconfig
./scripts/config --enable CONFIG_X86_64
./scripts/config --enable CONFIG_RD_GZIP
./scripts/config --enable CONFIG_SQUASHFS
./scripts/config --enable CONFIG_SQUASHFS_XZ
./scripts/config --enable CONFIG_ISO9660_FS
./scripts/config --enable CONFIG_OVERLAY_FS
./scripts/config --enable CONFIG_EXT4_FS
./scripts/config --enable CONFIG_DEVTMPFS
./scripts/config --enable CONFIG_DEVTMPFS_MOUNT
./scripts/config --enable CONFIG_REPRODUCIBLE_BUILD
./scripts/config --set-str CONFIG_LOCALVERSION ""
./scripts/config --disable CONFIG_DEBUG_INFO
./scripts/config --enable CONFIG_DRM
./scripts/config --enable CONFIG_DRM_KMS_HELPER
./scripts/config --enable CONFIG_DRM_FBDEV_EMULATION
./scripts/config --set-val CONFIG_DRM_FBDEV_OVERALLOC 100
./scripts/config --module CONFIG_DRM_I915
./scripts/config --module CONFIG_DRM_AMDGPU
./scripts/config --module CONFIG_DRM_NOUVEAU
./scripts/config --module CONFIG_DRM_VMWGFX
./scripts/config --module CONFIG_DRM_VBOXVIDEO
./scripts/config --module CONFIG_DRM_VIRTIO_GPU
./scripts/config --module CONFIG_DRM_BOCHS
./scripts/config --enable CONFIG_FB
./scripts/config --enable CONFIG_FB_SIMPLE
./scripts/config --enable CONFIG_FW_LOADER
./scripts/config --enable CONFIG_VT
./scripts/config --enable CONFIG_VT_CONSOLE
./scripts/config --enable CONFIG_HW_CONSOLE
make olddefconfig
make KBUILD_BUILD_TIMESTAMP="1970-01-01 00:00:00" \
     KBUILD_BUILD_USER="builder" \
     KBUILD_BUILD_HOST="localhost" \
     CC="ccache gcc" \
     -j$(nproc)
cp arch/x86/boot/bzImage $BUILD_DIR/iso/boot/vmlinuz
make INSTALL_MOD_PATH=$BUILD_DIR/rootfs modules_install

echo "Creating init script..."
cd $BUILD_DIR/rootfs
mkdir -p proc sys dev
cat > usr/bin/init << 'EOF'
#!/bin/sh
export PATH=/usr/local/sbin:/usr/local/bin:/usr/bin
export SHLVL=0
export HOME=/home
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
mkdir -p /dev/pts
mount -t devpts none /dev/pts
modprobe drm_kms_helper
modprobe amdgpu
modprobe i915
modprobe nouveau
modprobe virtio_gpu
modprobe bochs
hostname $(cat /etc/hostname)
exec </dev/tty1 >/dev/tty1 2>&1
while :
do
    clear
    echo -e "Welcome to \x1b[93mLupin\x1b[0m Linux"
    cd $HOME
    setsid /bin/sh -c "exec /bin/sh </dev/tty1 >/dev/tty1 2>&1"
done
EOF
chmod +x usr/bin/init

echo "Creating misc files..."
cd $BUILD_DIR/rootfs
cat > etc/os-release << 'EOF'
NAME="Lupin Linux"
PRETTY_NAME="Lupin Linux"
ID=lupin
ANSI_COLOR="93"
EOF
echo "$HOSTNAME" > etc/hostname
cat > etc/passwd << 'EOF'
root::0:0::/home:/bin/sh
EOF

echo "Creating squashfs filesystem..."
mksquashfs $BUILD_DIR/rootfs $BUILD_DIR/iso/rootfs.sqsh -noappend -comp xz

echo "Creating initramfs..."
cd $BUILD_DIR/initramfs
mkdir -p bin proc sys dev
cp -a $BUILD_DIR/busybox/busybox-$BUSYBOX_VERSION/_install/* .
cat > init << 'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
mkdir -p /mnt/cdrom /ro /newroot /cow
sleep 1
for i in $(seq 10); do
    for dev in /dev/sr0 /dev/sd*; do
        echo "Trying $dev..."
        mount "$dev" /mnt/cdrom 2>/dev/null && [ -f /mnt/cdrom/rootfs.sqsh ] && break
        umount /mnt/cdrom 2>/dev/null
    done
    if mountpoint -q /mnt/cdrom; then
        break
    fi
    echo "Waiting and trying again..."
    sleep 5
done
if ! mountpoint -q /mnt/cdrom; then
    echo "No valid ISO device found with rootfs.sqsh"
    exec sh
fi
mount -t squashfs /mnt/cdrom/rootfs.sqsh /ro
mount -t tmpfs tmpfs /cow
mkdir -p /cow/upper /cow/work
mount -t overlay overlay -o lowerdir=/ro,upperdir=/cow/upper,workdir=/cow/work /newroot
exec switch_root /newroot /sbin/init
EOF
chmod +x init
find . | cpio -o -H newc | gzip > $BUILD_DIR/iso/boot/initrd.gz

echo "Setting up isolinux..."
cp /usr/share/syslinux/isolinux.bin $BUILD_DIR/iso/isolinux/
cp /usr/share/syslinux/ldlinux.c32 $BUILD_DIR/iso/isolinux/
cat > $BUILD_DIR/iso/isolinux/isolinux.cfg << 'EOF'
DEFAULT linux
LABEL linux
  KERNEL /boot/vmlinuz
  APPEND initrd=/boot/initrd.gz quiet
EOF

echo "Creating ISO..."
xorriso -as mkisofs \
    -o "$OUT_ISO" \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -R -J -v $BUILD_DIR/iso/
isohybrid "$OUT_ISO"
