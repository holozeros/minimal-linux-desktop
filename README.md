# MINIMAL LINUX DESKTOP
Building a desktop environment from source codes to learn Linux. 
This OS will be built with reference to the Linux From Scratch 11.0 book and installed use pacman-5.0. 

## 1.Making chroot environment see: [Building chroot environment](Chroot%20environment)
Make a chroot environment and then install the required commands to run Arch_Build_System(ABS).

## 2.booting the chroot environment see: [Building stub kernel](Building%20stub%20kernel/README.md) 
Building UEFI stub kernel and install systemd-boot. Then edit boot loader entry file. When booted the stub kernel,
the stub kernel mount the chroot environment as root_filesystem.

## 3.Building minimal linux desktop
### Adjusting toolchain
On the Host
```
su -   
mount /dev/"My chroot_environment_partition" /mnt/lfs
export LFS=/mnt/lfs
./chroot-1.sh
```
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
Test the toolchain.
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
tzdata
	nano locale.gen
        en_US.UTF-8 UTF-8
```
cat > /etc/locale.gen << "EOF"
#!/bin/sh
set -e
LOCALEGEN=/etc/locale.gen
LOCALES=/share/i18n/locales
if [ -n "$POSIXLY_CORRECT" ]; then
  unset POSIXLY_CORRECT
fi
[ -f $LOCALEGEN -a -s $LOCALEGEN ] || exit 0;
# Remove all old locale dir and locale-archive before generating new
# locale data.
rm -rf /lib/locale/* || true
umask 022
is_entry_ok() {
  if [ -n "$locale" -a -n "$charset" ] ; then
    true
  else
    echo "error: Bad entry '$locale $charset'"
    false
  fi
}
echo "Generating locales..."
while read locale charset; do \
	case $locale in \#*) continue;; "") continue;; esac; \
	is_entry_ok || continue
	echo -n "  `echo $locale | sed 's/\([^.\@]*\).*/\1/'`"; \
	echo -n ".$charset"; \
	echo -n `echo $locale | sed 's/\([^\@]*\)\(\@.*\)*/\2/'`; \
	echo -n '...'; \
        if [ -f $LOCALES/$locale ]; then input=$locale; else \
        input=`echo $locale | sed 's/\([^.]*\)[^@]*\(.*\)/\1\2/'`; fi; \
	localedef -i $input -c -f $charset -A /share/locale/locale.alias $locale; \
	echo ' done'; \
done < $LOCALEGEN
echo "Generation complete."
EOF
```
        locale-gen
	localedef -f UTF-8 -i en_US en_US
```
cat > /tools/etc/locale.gen << "EOF"
#!/bin/sh
set -e
LOCALEGEN=/tools/etc/locale.gen
LOCALES=/tools/share/i18n/locales
if [ -n "$POSIXLY_CORRECT" ]; then
  unset POSIXLY_CORRECT
fi
[ -f $LOCALEGEN -a -s $LOCALEGEN ] || exit 0;
# Remove all old locale dir and locale-archive before generating new
# locale data.
rm -rf /lib/locale/* || true
umask 022
is_entry_ok() {
  if [ -n "$locale" -a -n "$charset" ] ; then
    true
  else
    echo "error: Bad entry '$locale $charset'"
    false
  fi
}
echo "Generating locales..."
while read locale charset; do \
	case $locale in \#*) continue;; "") continue;; esac; \
	is_entry_ok || continue
	echo -n "  `echo $locale | sed 's/\([^.\@]*\).*/\1/'`"; \
	echo -n ".$charset"; \
	echo -n `echo $locale | sed 's/\([^\@]*\)\(\@.*\)*/\2/'`; \
	echo -n '...'; \
        if [ -f $LOCALES/$locale ]; then input=$locale; else \
        input=`echo $locale | sed 's/\([^.]*\)[^@]*\(.*\)/\1\2/'`; fi; \
	localedef -i $input -c -f $charset -A /tools/share/locale/locale.alias $locale; \
	echo ' done'; \
done < $LOCALEGEN
echo "Generation complete."
EOF
```
        /tools/etc/locale-gen
	/tools/bin/localedef -f UTF-8 -i en_US en_US

Zlib
Bzip2
Xz
zstd
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
Gettext
Pkg-config
Ncurses
Libcap
Sed
Psmisc
Bison
Flex
Grep
Bash
Shadow
Libtool
GDBM
Gperf
Expat
Inetutils
Intltool
Autoconf
Automake
Libelf (from Elfutils)
Libffi
Coreutils
Check
Diffutils
Gawk
Findutils
Groff
Less
Gzip
Patch
Tar
Texinfo
IPRoute2
Kbd
Libpipeline
Make
nano
Kmod
eudev
udev-lfs
Procps-ng
Util-linux
E2fsprogs
Sysklogd
Sysvinit


libunistring
libxml2
GCC
	LC_ALL=en_US.UTF-8 makepkg
Iana-Etc
db
Perl
XML::Parser

OpenSSL
Python
Ninja
Meson

```
gpu_driver and xfce4 see:[]()
### Prepare and settings the packge manager
On the Host
```
su -   
mount /dev/"chroot_environment_partition" /mnt/lfs
export LFS=/mnt/lfs
./chroot-1.sh
ln -s /tools/bin/curl /bin/curl
user add -m lfs
passwd lfs
```
```
nano /tools/etc/makepkg.conf
# Comment out (delete "#" of top of the line) and modify like the followings.
	#########################################################################
	# SOURCE ACQUISITION
	#########################################################################
	#
	#-- The download utilities that makepkg should use to acquire sources
	#  Format: 'protocol::agent'
	DLAGENTS=('ftp::/bin/curl -gqfC - --ftp-pasv --retry 3 --retry-delay 3 -o %o %u -k'
        	'http::/bin/curl -gqb "" -fLC - --retry 3 --retry-delay 3 -o %o %u -k'
          	'https::/bin/curl -gqb "" -fLC - --retry 3 --retry-delay 3 -o %o %u -k'
          	'rsync::/bin/rsync --no-motd -z %u %o'
          	'scp::/bin/scp -C %u %o')

	#########################################################################
	# ARCHITECTURE, COMPILE FLAGS
	#########################################################################
	#
	CARCH="x86_64"
	CHOST="x86_64-pc-linux-gnu"

	#-- Compiler and Linker Flags
	CPPFLAGS="-D_FORTIFY_SOURCE=2 -fpic"
	CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt -fexceptions \
        	-Wp,-D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security \
        	-fstack-clash-protection -fcf-protection -fpic"
	CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"
	LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
```
```
nano /tools/etc/pacman.conf
# Comment out(delete "#" of top of the line ) the part of the followings and modify like the followings the path corectly for own environment.
      
		RootDir     = /
		DBPath      = /var/lib/pacman/
		CacheDir    = /var/cache/pacman/pkg/
		LogFile     = /var/log/pacman.log
		GPGDir      = /tools/etc/pacman.d/gnupg/
		HookDir     = /tools/etc/pacman.d/hooks/
```
## Editing PKGBUILD
On the chroot environmment
```
su - lfs
```
Editing a custum PKGBUILD see: [PKGBUILD-collections](PKGBUILD-collections/README.md)
After editing the custom PKGBUILD and making the packages with ABS.
```
cd /usr/src/$pkgname/$pkgver/PKGBUILD
makepkg
```
## Install packages with pacman
```
su -
pkgname="name"
pkgver="naumer"
cd /usr/src/$pkgname/$pkgver
pacman -U "$pkgname-$pkgver-1.pkg.tar.gz"
```
If quit for error which conflict existing package under the / directory.  issue:
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
##### refer to: [Building stub kernel](Building%20stub%20kernel)
