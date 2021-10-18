# minimal linux desktop
Here, we will build a desktop environment from source to learn Linux. 
This OS is built with reference to the Linux From Scratch 11.0 book and installed use pacman-5.0. 

              This repository is still incomplete !!!

[Prerequisites]

    Host OS must pass version-check.sh of LFS-11.0 book.
            With a tiny mistake in the chroot environment build process can irreparably destroy the host system.
            Therefore, it is recommended to use a various live-usb with persistence function which using Overlayfs as the host OS.
            If it had desktop environment and browser, is better.
            If you can't find a suitable existing Live-USB distribution,
            Install a new OS dedicated to LFS build works into an USB strage.
            Refer to:
                https://wiki.archlinux.org/title/Install_Arch_Linux_on_a_removable_medium 

    Machine architecture: x86_64, UEFI, GPTpartition.
            When booting the stub kernel on a UEFI motherboard,
            Archlinux's boot loader, systemd-boot, can be mounted directly on the stub kernel (without initramfs) if it is a root partition known to the kernel,
            even if it is not the root file system partition that does systemd's init processing.
            If you already have systemd-boot installed on your computer's EFI system partition,
            you can boot an OS you just created by adding a small config file.
            Compared to Grub, systemd-boot has the advantage of making it easier to know and control the boot behavior. 
    
    strage: SATA(HDD,SSD), m.2-SSD
            For the root file system partition of this OS, an USB storage is not available here.
            The stub kernel doesn't support them, so you probably need initramfs.
            If you really want to use USB storage, install Dracut and create initramfs.
            
    Graphics: nvidia card (or any Integrated GPU).
            When using the nouveau driver, you may not be able to use multiple displays or select the desired resolution, depending on the type of Nvidia card.
            Thankfully, for Linux users, Nvidia has published the driver packages that combines proprietary binaries with a collection of their wrappers.
            There are some caveats, such as kernel compilation, to install the proprietary Nvidia driver. 


[Summary]

    1.Building a chroot environment where /tools has the required commands to run chroot and Arch Build System(gcc,pacman,makepkg..).
 
    2.Editing PKGBUILDs of all packages for minimal linux desktop.

    3.Chroot into the above chroot environment, and make package-tarballs from the PKGBUILDs with makepkg command, then install packages with pacaman into / of chroot environment. 

    4.Building UEFI stub kernel and install systemd-boot. Then edit boot loader entry file.When booted the stub kernel, bootloader does mount the minimal linux desktop to root-filsesystem.

    5.Settings of the minimal linux desktop system.
