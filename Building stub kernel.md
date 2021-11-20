# Stub kernel

On the terminal of the host
```
su -
```
If you have already build the chroot environment and its pertition mount to /mnt/lfs, isuue:
```
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
```
cd /sources
wget https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.15.2.tar.xz
cd /usr/src
tar xf /sources/linux-5.15.2.tar.xz
chown -R lfs linux-5.15.2

su - lfs
cd /usr/src/linux-5.15.2
```
Configuring kernel settings
```
make defconfig

```
Kernel configration for SysV-init compatible.
My Hardwares (e.g
```
Motherboad: ASROCK B450 Pro4
CPU: Ryzen7
GPU: ASUS GeForce GT 710 (driver "https://jp.download.nvidia.com/XFree86/Linux-x86_64/470.86/NVIDIA-Linux-x86_64-470.86.run")
Storage type: NVME (sumson EVO-970 SSD with M.2 connection)
Audio device: [AMD] Family 17h (Models 00h-0fh) HD Audio Controller
```
```
make menuconfig
```
```
General setup  --->
    [*] System V IPC

Processor type and features  --->

   Processor family (Opteron/Athlon64/Hammer/K8)  --->
     (*) Opteron/Athlon64/Hammer/K8
     
   [*] Machine Check / overheating reporting 
   [*]   AMD MCE Features
   
   [ ] AMD Secure Memory Encryption (SME) support
      
[*] Enable loadable module support --->

[*] Enable the block layer --->
    Partition Types --->
      [*] Advanced partition selection
        [*] EFI GUID Partition support

Device Drivers --->

    NVME Support --->
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

    [*] Network device support  --->
      [*]   Ethernet driver support  --->
                 [*]   Realtek devices
		 < >     RealTek RTL-8139 C+ PCI Fast Ethernet Adapter support
		 < >     RealTek RTL-8129/8130/8139 PCI Fast Ethernet Adapter supp
		 <*>     Realtek 8169/8168/8101/8125 ethernet support

    Graphics support --->
      <*> /dev/agpgart (AGP Support)  --->
      -*- VGA Arbitration
      (16)  Maximum number of GPUs
      [ ] Laptop Hybrid Graphics - GPU switching support
      <*> Direct Rendering Manager (XFree86 4.1.0 and higher DRI support)
      [*] VGA Arbitration
      -*- /dev/agpgart (AGP Support) --->
      < >    .
      < >    .
      < > Nouveau (nVidia) cards    <--- "< >" is uncheck !!!, becouse confrict NVIDIA 470.86 driver 
      < >    .
      < >    .
      < >    .
      Frame buffer Devices --->
        <*> Support for frame buffer devices --->
          --- Support for frame buffer devices
	  [ ]   Enable firmware EDID
	  [ ]   Framebuffer foreign endianness support  ----
	  [*]   Enable Video Mode Handling Helpers
	  [*]   Enable Tile Blitting Support
	     *** Frame buffer hardware drivers ***
	  [ ]          .
          [ ]          .
	  [*]   VESA VGA graphics support
          [*]   EFI-based Framebuffer Support
	  [ ]          .
	  [ ]          .

     Console display driver support --->
       (80) Initial number of console screen columns
       (25) Initial number of console screen rows
       -*- Framebuffer Console support
       -*-   Map the console to the primary display device

   <*> Sound card support
       <*> Advanced Linux Sound Architecture --->
         [*] PCI sound devices  --->
            <*> Intel/SiS/nVidia/AMD/ALi AC97 Controller  
	    
   HD-Audio  --->
     <*> HD Audio PCI
     [*] Build hwdep interface for HD-audio driver
     <*> Build HDMI/DisplayPort HD-audio codec support 
     [*] Enable generic HD-audio codec parser

   [*] USB support  --->
     <*>     xHCI HCD (USB 3.0) support
     <*>     EHCI HCD (USB 2.0) support
     <*>     OHCI HCD (USB 1.1) support
     <*>     USB Mass Storage support
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
```
make -j$(nproc)
```
## Install
```
make modules_install

# mount /dev/<EFI System Partition> /boot

make install
```
Make sure that names of installed the file.
```
ls /boot
```    
Back to the Host environment.
```
exit
chown -R root /lib/modules/5.15.2
```
