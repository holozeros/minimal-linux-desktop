# Stub kernel
Stub kernels boot with UEFI should be built in a host environment with a complete build environment. Since UEFI has different specifications depending on the motherboard, kernels built in the minimum Chroot environment may not boot well. 
```
su - lfs

mkdir work
cd work
tar xf /mnt/lfs/sources/linux-5.13.12.tar.xz
cd linux-5.13.12

make defconfig
make menuconfig
```
As example of machine
```
CPU is Ryzen7
Graphics is NVIDIA card
Storage is SSD with M.2 connection
```
Kernel config for SystemV-init ( not systemd ). Check if it is set as follows, and if not, correct it.
```
General setup  --->
  [*] System V IPC
	[*] Control Group support
	[ ] Enable deprecated sysfs features to support old userspace tools
	[*] Configure standard kernel features (expert users)  --->
		[*] Enable eventpoll support
		[*] Enable signalfd() system call
		[*] Enable timerfd() system call

Processor type and features  --->
   [*] Machine Check / overheating reporting 
   [ ]   Intel MCE Features
   [*]   AMD MCE Features
   Processor family (Opteron/Athlon64/Hammer/K8)  --->
     (*) Opteron/Athlon64/Hammer/K8
     ( ) Intel P4 / older Netburst based Xeon
     ( ) Core 2/newer Xeon
     ( ) Intel Atom
     ( ) Generic-x86-64
   [*]   MTRR (Memory Type Range Register) support
   [*]   MTRR cleanup support 
   (0)     MTRR cleanup enable value (0-1) 
   (1)     MTRR cleanup spare reg num (0-7)
   [ ]   AMD Secure Memory Encryption (SME) support
   [*] Symmetric multi-processing support
   [*] EFI runtime service support 
   [*]   EFI stub support
   [*]     EFI mixed-mode support

Bus options (PCI etc.)  --->
   [*] Mark VGA/VBE/EFI FB as generic system framebuffer

Binary Emulations  --->
   [*] IA32 Emulation

Firmware Drivers  --->
    EFI (Extensible Firmware Interface) Support  --->
        <*> EFI Variable Support via sysfs

[*] Enable loadable module support --->

[*] Enable the block layer --->
   Partition Types --->
      [*] Advanced partition selection
      [*] EFI GUID Partition support

[*] Networking support --->

Device Drivers --->
    
  Generic Driver Options --->
    [*] Maintain a devtmpfs filesystem to mount at /dev
    [ ]   Automount devtmpfs at /dev, after the kernel mounted the rootfs

  NVME Support --->
     <*> NVM Express block device 
     [*] NVMe multipath support
     [*] NVMe hardware monitoring
     <*> NVM Express over Fabrics FC host driver
     <*> NVM Express over Fabrics TCP host driver           

  SCSI device support  --->
    <*> SCSI disk support

  Character devices --->
    [*] IPMI top-level message handler

  Network device support --->
    <*> PPP (point-to-point protocol) support
    <*>   PPP support for async serial ports
    <*>   PPP support for sync tty ports

  Input device support --->
    <*>  Event interface

  [*] USB support  --->
    <*>     xHCI HCD (USB 3.0) support
    <*>     EHCI HCD (USB 2.0) support
    <*>     OHCI HCD (USB 1.1) support
    <*>   USB Mass Storage support 

  Graphics support --->
    < > Direct Rendering Manager (XFree86 4.1.0 and higher DRI support)
    [*] VGA Arbitration
    -*- /dev/agpgart (AGP Support) --->
    < >   nVidia Framebuffer Support
    < >   nVidia Riva support
    < > Nouveau (nVidia) cards
             .
             .
             .
    Frame buffer Devices --->
      <*> Support for frame buffer devices --->
          [ ] EFI-based Framebuffer Support
          [*] Simple framebuffer support
    Console display driver support --->
      <*>  Framebuffer Console Support

  <*> Sound card support
        <*> Advanced Linux Sound Architecture --->
            [*] PCI sound devices  --->
                Select the driver for your audio controller.
                HD-Audio  --->
                   Select a codec or enable all and let the generic parse choose the right one:
                   [*] Build Realtek HD-audio codec support
                   [*] ...
                   [*] Build Silicon Labs 3054 HD-modem codec support
                   [*] Enable generic HD-audio codec parser
                [*] Dynamic device file minor numbers
                (32) Max number of sound cards

File systems --->
  [*] Inotify support for userspace

  <*> Second extended fs support
  <*> The Extended 3 (ext3) filesystem
  <*> The Extended 4 (ext4) filesystem
  <*> Reiserfs support
  <*> JFS filesystem support
  <*> XFS filesystem support
  <*> Btrfs filesystem support
  DOS/FAT/NT Filesystems  --->
    <*> MSDOS fs support
    <*> VFAT (Windows-95) fs support
 
Pseudo Filesystems --->
    [*] /proc file system support
    [*] Tmpfs virtual memory file system support (former shm fs)
    [*] sysfs file system support

```
Keep defconfig, except the above.