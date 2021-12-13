# MINIMAL LINUX DESKTOP
Building a desktop environment from source codes to learn Linux. 
This OS will be built with reference to the Linux From Scratch 11.0 book and installed use pacman-5.0. 

## 1.Making chroot environment see: [Building chroot environment](Building%20chroot%20environment.md)
Make a chroot environment and then install the required commands to run Arch_Build_System(ABS).

## 2.booting the chroot environment see: [Building stub kernel](Building%20stub%20kernel.md) 
Building UEFI stub kernel and install systemd-boot. Then edit boot loader entry file. When booted the stub kernel,
bootloader does mount the chroot environment for root_filesystem.

## 3.Building minimal linux desktop
### Adjusting toolchain
```
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld
```
```
gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs

```
Test the toolchin.
```
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

	# [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]

grep -o '/lib.*crt[1in].*succeeded' dummy.log

	# /lib/../lib/crt1.o succeeded
	# /lib/../lib/crti.o succeeded
	# /lib/../lib/crtn.o succeeded

grep -B1 '^ /include' dummy.log

	#include <...> search starts here:
	# /include

grep 'SEARCH.*/lib' dummy.log |sed 's|; |\n|g'

	# SEARCH_DIR("/lib")
	# SEARCH_DIR("/usr/lib")

grep "/lib.*/libc.so.6 " dummy.log

	# attempt to open /lib/libc.so.6 succeeded

grep found dummy.log

	# found ld-linux-x86-64.so.2 at /lib/ld-linux-x86-64.so.2

rm -v dummy.c a.out dummy.log
```
### Make and install the essential custum packages for bootable system
Order to the following for satisfy the dependencies.
```
Linux-api-headers
Glibc
Zlib
Bzip2
Xz
File
Readline
M4
Bc
Binutils
GMP
MPFR
MPC
Attr
Acl
Shadow
GCC
Pkg-config
Ncurses
Libcap
Sed
Psmisc
Iana-Etc
Bison
Flex
Grep
Bash
Libtool
GDBM
Gperf
Expat
Inetutils
Perl
XML::Parser
Intltool
Autoconf
Automake
Kmod
Gettext
Libelf (from Elfutils)
Libffi
OpenSSL
Python
Ninja
Meson
Coreutils
Check
Diffutils
Gawk
Findutils
Groff
Less
Gzip
Zstd
IPRoute2
Kbd
Libpipeline
Make
Patch
Tar
Texinfo
nano
Procps-ng
Util-linux
E2fsprogs
Sysklogd
Sysvinit
Eudev
```
gpu_driver and xfce4 see:[]()

### Editing PKGBUILD
```
su -             # On the Host
./chroot-1.sh    # Enter the chroot environment
```
### Editing a custum PKGBUILD see: [PKGBUILD-collections/README.md](PKGBUILD-collections/README.md)
### After editing the custom PKGBUILD compile and make with ABS.
```
cd /usr/src/$pkgname/$pkgver/PKGBUILD
makepkg
```
Prepare and settings the packge manager
```
user add -m lfs
passwd lfs
su - lfs
nano /tools/etc/pacman.conf
# Comment out(delete "#" of top of the line ) the part of the followings and modify like the followings the path corectly for own environment.
      
		RootDir     = /
		DBPath      = /var/lib/pacman/
		CacheDir    = /var/cache/pacman/pkg/
		LogFile     = /var/log/pacman.log
		GPGDir      = /tools/etc/pacman.d/gnupg/
		HookDir     = /tools/etc/pacman.d/hooks/
```
Install packages with pacman.
```
pkgname=<name>
pkgver=<naumer>
cd /usr/src/$pkgname/$pkgver
pacman -U "$pkgname-$pkgver-1.pkg.tar.gz"
```
If quit for error which conflict existing package under the / directory(not under /tools),  issue:
```
pacman -U --force $pkgname-$pkgver.pkg.tar.zst
```
##### The --force directive is obsolete in later versions of Pacman 5.0. 

## Prerequisites
Host OS must pass version-check.sh of LFS-11.0 book. With a tiny mistake in build process can irreparably destroy the host system. Therefore, it is recommended to use a various Live-USB with persistence function which using Overlayfs as the host OS.
##### Refer to:e.g [Install_Arch_Linux_on_a_removable_medium](https://wiki.archlinux.org/title/Install_Arch_Linux_on_a_removable_medium)

The host should have a desktop environment and a browser. If you can't find a suitable existing Live-USB distribution, Install a new OS dedicated to host of build works into an USB storage.

     Machine architecture: x86_64, UEFI, GPTpartition.

When booting the stub kernel on a UEFI motherboard, Archlinux's boot loader called systemd-boot can be mount directly the stub kernel (without initramfs),  even the root file system partition that doesn't systemd's init processing. If you already have systemd-boot installed on your computer's EFI system partition, you can boot an OS you just created by adding a small config file. Compared to Grub, systemd-boot has the advantage of making it easier to know and control the boot behavior. 
    
    Storage for building this OS: SATA(HDD,SSD), M.2-SSD

For the root file system partition of this OS, an USB storage is not available. If you boot your machine connected some USB storage to a USB port that you don't know in advance what will be connected, the stub kernel may can not recognize the USB storage well. If you want to use USB storage, shuld install dracut(and dependency packages) and create initramfs.

    Graphics: nvidia card (or any Integrated GPU).

When using the nouveau driver, you may not be able to use multiple displays or select the desired resolution, depending on the type of nvidia card. Thankfully, for Linux users, Nvidia has published the driver packages that combines proprietary binaries with a collection of their wrappers. There are some caveats, such as kernel compilation, to install the proprietary nvidia driver. 
##### refer to: [stub kernel](https://github.com/holozeros/minimal-linux-desktop/blob/master/Building%20stub%20kernel.md)
