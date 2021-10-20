# MINIMAL LINUX DESKTOP
Build a desktop environment from source codes to learn Linux. 
This OS is built with reference to the Linux From Scratch 11.0 book and installed use pacman-5.0. 
Even beginners can create this chroot environment on their PC by following this procedure, but beginners don't understand the meaning of each command.
First, you need to read the Linux From Scratch book and experience building LFS yourself. 

## 1.Building chroot environment

[Building basic chroot environment](Building%20chroot%20environment.md).

     Building a chroot environment where /tools has the required commands to run chroot.

[Install arch build system in the chroot environment](installing%20ABS%20in%20chroot%20environment).

     Add Arch Build System (gcc,pacman,makepkg..) in the basic chroot system.

With a original stub kernel booting the chroot environment as root filesystem.

     Building UEFI stub kernel and install systemd-boot. Then edit boot loader entry file.When booted the stub kernel,
     bootloader does mount the minimal linux desktop to root-filsesystem.
	
## 2.Building minimal linux desktop

[List of mandatory packages in build order](List%20of%20mandatory%20packages).

[Editing PKGBUILD](PKGBUILD-collections/README.md)

Make custum packages

     Chroot into the above chroot environment, and make package-tarballs from the PKGBUILD with makepkg command,

Installing custum packages with pacamn

    Install packages with pacaman into / of chroot environment.


              This repository is still incomplete !!!
		
		

## Prerequisites

    Host OS must pass version-check.sh of LFS-11.0 book.
            With a tiny mistake in build process can irreparably destroy the host system.
            Therefore, it is recommended to use a various Live-USB with persistence function which using Overlayfs as the host OS.
##### Refer to: [Install_Arch_Linux_on_a_removable_medium](https://wiki.archlinux.org/title/Install_Arch_Linux_on_a_removable_medium)
            The host should have a desktop environment and a browser.
            If you can't find a suitable existing Live-USB distribution,
            Install a new OS dedicated to host of build works into an USB storage.

Machine architecture: x86_64, UEFI, GPTpartition.

            When booting the stub kernel on a UEFI motherboard,
            Archlinux's boot loader, systemd-boot, can be mounted directly on the stub kernel (without initramfs) if it is a root partition known to the kernel,
            even if it is not the root file system partition that does systemd's init processing.
            If you already have systemd-boot installed on your computer's EFI system partition,
            you can boot an OS you just created by adding a small config file.
            Compared to Grub, systemd-boot has the advantage of making it easier to know and control the boot behavior. 
    
Storage for building this OS: SATA(HDD,SSD), m.2-SSD

            For the root file system partition of this OS, an USB storage is not available.
            If you boot your machine connected some USB storage to a USB port that you don't know in advance what will be connected,
            the stub kernel may can not recognize the USB storage well. 
            If you want to use USB storage, shuld install Dracut and create initramfs.

Graphics: nvidia card (or any Integrated GPU).

            When using the nouveau driver, you may not be able to use multiple displays or select the desired resolution, depending on the type of Nvidia card.
            Thankfully, for Linux users, Nvidia has published the driver packages that combines proprietary binaries with a collection of their wrappers.
            There are some caveats, such as kernel compilation, to install the proprietary Nvidia driver. 
