# MINIMAL LINUX DESKTOP
Build a desktop environment from source codes to learn Linux. 
This OS is built with reference to the Linux From Scratch 11.0 book and installed use pacman-5.0. 

see: [Linux From Scratch Version 11.0](https://www.linuxfromscratch.org/lfs/view/stable/)

	I. Introduction
	II. Preparing for the Build
	  2.Preparing the Host System
	  3.Packages and Patches
	  4.Final Preparations
	III. Building the LFS Cross Toolchain and Temporary Tools
	  5.Compiling a Cross-Toolchain

Follow the LFS-11.0 book until just before Chapter5"Compiling the Cross Toolchain". 
Then follow this text steps for Chapter5 and beyond.
For that purpose, required to have the experience of reading the Linux From Scratch book from start to finish and completing the LFS build. 

# 1.Building chroot environment

## Building basic chroot environment.
Building a chroot environment where /tools has the required commands to run chroot.
##### see: [Building chroot environment](Building%20chroot%20environment.md)

## Install arch build system in the chroot environment.
Add Arch Build System (gcc,pacman,makepkg..) in the basic chroot system. 
##### see: [Add ABS in chroot environment](Add%20ABS%20in%20chroot%20environment.md)

##### refer to: [Pacman Home Page](https://archlinux.org/pacman/), [Byound Linux From Scratch v11.0-stable-sysV](https://www.linuxfromscratch.org/blfs/downloads/stable/BLFS-BOOK-11.0-nochunks.html)

## With a custum stub kernel booting the chroot environment as root filesystem.
Building UEFI stub kernel and install systemd-boot. Then edit boot loader entry file.When booted the stub kernel,
bootloader does mount the minimal linux desktop to root-filsesystem.
##### see: [Building stub kernel](Building%20stub%20kernel.md) 

# 2.Building minimal linux desktop

## List of mandatory packages in build order.
##### see: [List of packages](List%20of%20mandatory%20packages).

## Editing PKGBUILD.
##### see: [PKGBUILD-collections/README.md](PKGBUILD-collections/README.md)

## Make custum packages
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
cd /sources/PKGBUILD/$pkgname/$pkgver
makepkg --skipchecksums --skippgpcheck
```
## Installing custum packages with pacman
Install packages with pacman into / of chroot environment.
```
mv /sources/PKGBUILD/$pkgname/$pkgver/$pkgname-$pkgver.pkg.tar.zst /var/cache/pacman/pkg
cd /var/cache/pacman/pkg
pacman -U "$pkgname-$pkgver.pkg.tar.zst"
```
If quit for error which conflict existing package under the / directory(not under /tools),  issue:
```
pacman -U  --force $pkgname-$pkgver.pkg.tar.zst
```
##### The --force directive is obsolete in Pacman 5.0 and later versions. 
		
## Prerequisites
Host OS must pass version-check.sh of LFS-11.0 book. With a tiny mistake in build process can irreparably destroy the host system. Therefore, it is recommended to use a various Live-USB with persistence function which using Overlayfs as the host OS.
##### Refer to: [Install_Arch_Linux_on_a_removable_medium](https://wiki.archlinux.org/title/Install_Arch_Linux_on_a_removable_medium)

The host should have a desktop environment and a browser. If you can't find a suitable existing Live-USB distribution, Install a new OS dedicated to host of build works into an USB storage.

     Machine architecture: x86_64, UEFI, GPTpartition.

When booting the stub kernel on a UEFI motherboard, Archlinux's boot loader, systemd-boot, can be mounted directly on the stub kernel (without initramfs) if it is a root partition known to the kernel, even if it is not the root file system partition that does systemd's init processing. If you already have systemd-boot installed on your computer's EFI system partition, you can boot an OS you just created by adding a small config file. Compared to Grub, systemd-boot has the advantage of making it easier to know and control the boot behavior. 
    
    Storage for building this OS: SATA(HDD,SSD), M.2-SSD

For the root file system partition of this OS, an USB storage is not available. If you boot your machine connected some USB storage to a USB port that you don't know in advance what will be connected, the stub kernel may can not recognize the USB storage well. If you want to use USB storage, shuld install dracut(and dependency packages) and create initramfs.

    Graphics: nvidia card (or any Integrated GPU).

When using the nouveau driver, you may not be able to use multiple displays or select the desired resolution, depending on the type of nvidia card. Thankfully, for Linux users, Nvidia has published the driver packages that combines proprietary binaries with a collection of their wrappers. There are some caveats, such as kernel compilation, to install the proprietary nvidia driver. 
##### refer to: [stub kernel](https://github.com/holozeros/minimal-linux-desktop/blob/master/Building%20stub%20kernel.md)
