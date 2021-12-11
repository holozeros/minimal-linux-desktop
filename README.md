# MINIMAL LINUX DESKTOP
Building a desktop environment from source codes to learn Linux. 
This OS will be built with reference to the Linux From Scratch 11.0 book and installed use pacman-5.0. 

## 1.[Building chroot environment](Building%20chroot%20environment.md)
Build a chroot environment and then install the required commands to run Arh_Build_System(ABS).

## 2.booting the chroot environment.
Building UEFI stub kernel and install systemd-boot. Then edit boot loader entry file. When booted the stub kernel,
bootloader does mount the chroot environment for root_filesystem.
##### see: [Building stub kernel](Building%20stub%20kernel.md) 

#W 3.Building minimal linux desktop

### Editing PKGBUILD.
#### see: [PKGBUILD-collections/README.md](PKGBUILD-collections/README.md)

### Make custum packages
Chroot into the above chroot environment, and make package-tarballs from the PKGBUILD with makepkg command,as local user lfs.
On the host
```
su -
export LFS=/mnt/lfs
mount -v --bind /dev $LFS/dev
mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi
chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='\u:\w\$ '              \
    PATH=/tools/bin:/tools/sbin:/tools/usr/bin:/tools/usr/sbin \
    /tools/bin/bash --login +h
umount -lR /mnt/lfs/*
```
On the chroot environment
```
su - lfs
cd /usr/src/$pkgname/$pkgver/PKGBUILD
makepkg
```
### Installing custum packages with pacman
Install packages with pacman into / of chroot environment.
```
mv /usr/src/$pkgname/$pkgver/$pkgname-$pkgver.pkg.tar.zst /var/cache/pacman/pkg
cd /var/cache/pacman/pkg
pacman -U "$pkgname-$pkgver.pkg.tar.zst"
```
If quit for error which conflict existing package under the / directory(not under /tools),  issue:
```
pacman -U --force $pkgname-$pkgver.pkg.tar.zst
```
#### The --force directive is obsolete in later versions of Pacman 5.0. 
		
## Prerequisites
Host OS must pass version-check.sh of LFS-11.0 book. With a tiny mistake in build process can irreparably destroy the host system. Therefore, it is recommended to use a various Live-USB with persistence function which using Overlayfs as the host OS.
#### Refer to:e.g [Install_Arch_Linux_on_a_removable_medium](https://wiki.archlinux.org/title/Install_Arch_Linux_on_a_removable_medium)

The host should have a desktop environment and a browser. If you can't find a suitable existing Live-USB distribution, Install a new OS dedicated to host of build works into an USB storage.

     Machine architecture: x86_64, UEFI, GPTpartition.

When booting the stub kernel on a UEFI motherboard, Archlinux's boot loader called systemd-boot can be mount directly the stub kernel (without initramfs),  even the root file system partition that doesn't systemd's init processing. If you already have systemd-boot installed on your computer's EFI system partition, you can boot an OS you just created by adding a small config file. Compared to Grub, systemd-boot has the advantage of making it easier to know and control the boot behavior. 
    
    Storage for building this OS: SATA(HDD,SSD), M.2-SSD

For the root file system partition of this OS, an USB storage is not available. If you boot your machine connected some USB storage to a USB port that you don't know in advance what will be connected, the stub kernel may can not recognize the USB storage well. If you want to use USB storage, shuld install dracut(and dependency packages) and create initramfs.

    Graphics: nvidia card (or any Integrated GPU).

When using the nouveau driver, you may not be able to use multiple displays or select the desired resolution, depending on the type of nvidia card. Thankfully, for Linux users, Nvidia has published the driver packages that combines proprietary binaries with a collection of their wrappers. There are some caveats, such as kernel compilation, to install the proprietary nvidia driver. 
#### refer to: [stub kernel](https://github.com/holozeros/minimal-linux-desktop/blob/master/Building%20stub%20kernel.md)
