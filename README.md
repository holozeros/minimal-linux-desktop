# minimal linux desktop
This OS is build according to Linux From Scratch 11.0 book and install with pacman-5.0

[Prerequisites]
Host OS must pass version-check.sh of LFSbook.
machine architecture: x86_64, UEFI, GPTpartition
Graphics: nvidia card (or any Integrated GPU)

[Summary]
1.Building a chroot environment where /tools has the required commands to run chroot and Arch Build System(gcc,pacman,makepkg..).
2.Editing PKGBUILDs of all packages for minimal linux desktop.
3.Chroot into the above chroot environment, and make package-taballs from the PKGBUILDs with makepkg command, then install packages with pacaman into / of chroot environment. 
4.Building UEFI stub kernel and install systemd-boot. Then edit boot loader entry file.When booted the stub kernel, bootloader mount the minimal linux desktop to root-filsesystem.
5.Settings of the minmal linux desktop system.
