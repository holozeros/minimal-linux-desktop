# Stub kernel

On the terminal of the host
```
su -
```
```
mkdir -p /lib/modules/5.15.2
chown lfs /lib/modules/5.15.2

```
su - lfs

cd /lib/modules/5.15.2
tar xf /mnt/lfs/sources/linux/5.15.2/linux-5.15.2.tar.xz
cd linux-5.15.2
```
Hardwares of my build system (e.g :
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
Kernel config for SysV-init.
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
          [*] Dynamic device file minor numbers
          (32) Max number of sound cards
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
    make -j$(nproc)
## Install
```
su -
cd /lib/modules/5.15.2
make modules_install

# mount /dev/<EFI System Partition> /boot

make install
```
Make sure that names of installed the file.

    ls /boot
