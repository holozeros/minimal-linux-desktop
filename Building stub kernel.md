# Stub kernel
Stub kernels boot with UEFI should be built in a host environment with a complete build environment. 
```
su - lfs

mkdir work
cd work
tar xf /mnt/lfs/sources/linux/5.15.2/linux-5.15.2.tar.xz
cd linux-5.15.2
```
Hardware  (e.g :
```
Motherboad: ASROCK B450 Pro4
CPU: Ryzen7
GPU: ASUS GeForce GT 710 (driver "https://jp.download.nvidia.com/XFree86/Linux-x86_64/470.86/NVIDIA-Linux-x86_64-470.86.run")
Storage type: NVME (sumson EVO-970 SSD with M.2 connection)
Audio device: [AMD] Family 17h (Models 00h-0fh) HD Audio Controller
```
```
make defconfig
make menuconfig

```
Kernel config for SysV-init. Check if it is set as follows, and if not, correct it.

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
   
   [*] Symmetric multi-processing support

   Processor family (Opteron/Athlon64/Hammer/K8)  --->
     (*) Opteron/Athlon64/Hammer/K8
     
   [*] Machine Check / overheating reporting 
   [*]   AMD MCE Features
   
   [ ] AMD Secure Memory Encryption (SME) support
   
   [*] MTRR (Memory Type Range Register) support
   [*] MTRR cleanup support 
   (0)   MTRR cleanup enable value (0-1) 
   (1)   MTRR cleanup spare reg num (0-7)
   
   [*] EFI runtime service support 
   [*]   EFI stub support
   [*]     EFI mixed-mode support

Binary Emulations  --->
   [*] IA32 Emulation

[*] Enable loadable module support --->

[*] Enable the block layer --->
    Partition Types --->
      [*] Advanced partition selection
        [*] EFI GUID Partition support

Device Drivers --->

    Generic Driver Options --->
      [*] Maintain a devtmpfs filesystem to mount at /dev
      [*]   Automount devtmpfs at /dev, after the kernel mounted the rootfs
      
    NVME Support --->
        # for M.2 SSD
      <*> NVM Express block device 
      [*] NVMe multipath support
      [ ] NVMe hardware monitoring
      < > NVM Express over Fabrics FC host driver
      < > NVM Express over Fabrics TCP host driver           

    Input device support --->
     <*> Generic input layer (needed for keyboard, mouse, ...) 
     <*>   Event interface
     [*]   Miscellaneous devices  ---> 
       <*>    User level driver support

# for external nvidia card
    Character devices --->
      [*] IPMI top-level message handler

    Graphics support --->
      <*> Direct Rendering Manager (XFree86 4.1.0 and higher DRI support)
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
          [*] EFI-based Framebuffer Support
    Console display driver support --->
      <*>  Framebuffer Console Support

    <*> Sound card support
      <*> Advanced Linux Sound Architecture --->
            
	  [*] Dynamic device file minor numbers
          (32) Max number of sound cards
            
	  [*] PCI sound devices  --->
            #Select the driver for your audio controller.e,g:
	    <*>   Intel/SiS/nVidia/AMD/ALi AC97 Controller  
	    
    HD-Audio  --->
      <*> HD Audio PCI
      [*] Build hwdep interface for HD-audio driver
	  #Select a codec or enable all and let the generic parse choose the right one:
      <*> Build HDMI/DisplayPort HD-audio codec support 
      [*] Enable generic HD-audio codec parser

    [*] USB support  --->
      <*>     xHCI HCD (USB 3.0) support
      <*>     EHCI HCD (USB 2.0) support
      <*>     OHCI HCD (USB 1.1) support
      <*>   USB Mass Storage support
      <*>     USB Attached SCSI

File systems --->
    [*] Inotify support for userspace
    <*> Second extended fs support
    <*> The Extended 3 (ext3) filesystem
    <*> The Extended 4 (ext4) filesystem
    DOS/FAT/NT Filesystems  --->
      <*> MSDOS fs support
      <*> VFAT (Windows-95) fs support
      (437) Default codepage for FAT
      (iso8859-1) Default iocharset for FAT
      [*]   Enable FAT UTF-8 option by default 
      <*> exFAT filesystem support
      (utf8) Default iocharset for exFAT
 
Pseudo Filesystems --->
    [*] /proc file system support
    [*] Tmpfs virtual memory file system support (former shm fs)
    [*] sysfs file system support

```
Keep defconfig, except the above.

## Make
    make -j$(nproc)
## Install
```
su -
make modules_install

  # <EFI System Partition> chenge to real device name of your EFI system partition.
mount /dev/<EFI System Partition> /boot

make install
```
Make sure that names of installed the file.

    ls /boot
