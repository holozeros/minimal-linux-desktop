## Build preparation
Now, let's start "building chroot environment"
```
su -
```
The folloing directive is very important. When working as the root user, incorrect commands will destroy the your computer. For example, if you forget to set the $LFS environment variable, executing "rm -rf $LFS/bin" will execute "rm -rf /bin" because $LFS is empty, the Host operting system will be completely corrupted.
In this works, $LFS is used frequently in many directives.
If you resume work or "su - user" (change user), $LFS may be empty. Always check the contents of $LFS with the "echo $LFS" directive while working, and issue the following if it is empty. 
```
export LFS=/mnt/lfs
```
If you need a new partition for building chroot environment, use cgdisk, gparted, etc.. to create a GPT partition of appropriate size. 
```
mkfs.ext4 /dev/<new partition for building chroot environment>
```
Format of EFI System Partition is fat32.
If it doesn't exist, create a new one.
```
mkfs.vfat /dev/<EFI System Partition>
```
Mount the new partition for building chroot environment to /mnt/lfs. for example in case /dev/sda2. Chroot environment will eventually become the root partition of a bootable linux OS.
A partition of USB storage will not be perhaps recognized by a stub kernel at boot time without initramfs, but available initramfs can't install yet. It's physical storage shuld be connected SATA or M.2, unuse USB storage.
```
mkdir -v /mnt/lfs
# You shuld change "sda2" to proper partition name.
mount -v /dev/sda2 $LFS
```
## Checking host system requirement  see:[Linux From Scratch book](https://www.linuxfromscratch.org/lfs/view/stable/chapter02/hostreqs.html)
Run the following script [version-check.sh](version-check.sh) and check outputs.
```
bash version-check.sh
```
## Bash setting
```
[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
```
## Directory settings
```
export LFS=/mnt/lfs
mkdir -v $LFS/home
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
mkdir -v $LFS/tools
ln -sv $LFS/tools /
```
```
mkdir -pv $LFS/{etc,var,lib,bin} $LFS/usr/{bin,src}
case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac
```
## Making local user in your host system
```
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
```
```
passwd lfs
```
```
chown -v lfs $LFS/*
```
```
su - lfs
```
```
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
    
cat > ~/.bashrc << "EOF"
  set +h
  umask 022
  LFS=/mnt/lfs
  LC_ALL=POSIX
  MAKEFLAGS="-j$(nproc)"
  LFS_TGT=$(uname -m)-lfs-linux-gnu
  PATH=/tools/bin:/bin:/usr/bin
  export LFS LC_ALL LFS_TGT PATH MAKEFLAGS
EOF
    
source ~/.bash_profile
```
## Downloading sources
```
export LFS=/mnt/lfs
cd $LFS/sources

wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
wget https://www.linuxfromscratch.org/lfs/view/stable/md5sums
```
If there are some tarballs that could not be downloaded automatically from the list, 
check the download address with LFS-11.0 Book or Google search and make up for it manually. 
If failed auto download anyone (e.g. ninja), retry download with an another link (find out and security check for yourself):
```
wget https://github.com/ninja-build/ninja/archive/v1.10.2.tar.gz
mv v1.10.2.tar.gz ninja-1.10.2.tar.gz
md5sum ninja-1.10.2.tar.gz
 # md5sum: 639f75bc2e3b19ab893eaf2c810d4eb4
```
## Additional sources for arch build system
```
cd $LFS/sources
```
The following downloads refer to BeyondLinux® FromScratch (System V Edition) version 11.0, Archlinux's PKGBUILD,..etc.
```
wget https://sources.archlinux.org/other/pacman/pacman-5.0.2.tar.gz
wget http://ftp.debian.org/debian/pool/main/f/fakeroot/fakeroot_1.26.orig.tar.gz
wget https://distfiles.dereferenced.org/pkgconf/pkgconf-1.8.0.tar.xz
wget https://github.com/djlucas/make-ca/releases/download/v1.7/make-ca-1.7.tar.xz
wget https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-2.2.29.tar.bz2
wget https://www.gnupg.org/ftp/gcrypt/gnutls/v3.7/gnutls-3.7.2.tar.xz
wget https://www.gnupg.org/ftp/gcrypt/gpgme/gpgme-1.16.0.tar.bz2
wget https://ftp.gnu.org/gnu/nettle/nettle-3.7.3.tar.gz
wget https://github.com/p11-glue/p11-kit/releases/download/0.24.0/p11-kit-0.24.0.tar.xz
wget https://www.nano-editor.org/dist/v5/nano-5.8.tar.xz
wget https://github.com/libarchive/libarchive/releases/download/v3.5.2/libarchive-3.5.2.tar.xz
wget https://www.gnupg.org/ftp/gcrypt/libassuan/libassuan-2.5.5.tar.bz2
wget https://www.gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.9.4.tar.bz2
wget https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.42.tar.bz2
wget https://www.gnupg.org/ftp/gcrypt/libksba/libksba-1.6.0.tar.bz2
wget https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.17.0.tar.gz
wget https://ftp.gnu.org/gnu/libunistring/libunistring-0.9.10.tar.xz
wget https://dist.libuv.org/dist/v1.42.0/libuv-v1.42.0.tar.gz
wget http://xmlsoft.org/sources/libxml2-2.9.12.tar.gz
wget https://www.gnupg.org/ftp/gcrypt/npth/npth-1.6.tar.bz2
wget http://ftp.rpm.org/popt/releases/popt-1.x/popt-1.18.tar.gz
wget https://downloads.sourceforge.net/freetype/freetype-2.11.0.tar.xz
wget https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.bz2
wget https://www.gnupg.org/ftp/gcrypt/pinentry/pinentry-1.2.0.tar.bz2
wget https://cmake.org/files/v3.21/cmake-3.21.2.tar.gz
wget https://www.samba.org/ftp/rsync/src/rsync-3.2.3.tar.gz
wget https://ftp.gnu.org/gnu/wget/wget-1.21.1.tar.gz
wget https://curl.se/download/curl-7.78.0.tar.xz
wget https://github.com/nghttp2/nghttp2/releases/download/v1.44.0/nghttp2-1.44.0.tar.xz
wget https://github.com/besser82/libxcrypt/releases/download/v4.4.26/libxcrypt-4.4.26.tar.xz
wget https://anduin.linuxfromscratch.org/BLFS/bdb/db-5.3.28.tar.gz
wget https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-2.1.27/cyrus-sasl-2.1.27.tar.gz
wget https://www.linuxfromscratch.org/patches/blfs/11.0/cyrus-sasl-2.1.27-doc_fixes-1.patch
wget https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.5.7.tgz
wget https://www.linuxfromscratch.org/patches/blfs/11.0/openldap-2.5.7-consolidated-1.patch
wget https://people.redhat.com/~dhowells/keyutils/keyutils-1.6.1.tar.bz2
wget https://kerberos.org/dist/krb5/1.19/krb5-1.19.2.tar.gz
wget https://people.redhat.com/sgrubb/audit/audit-3.0.6.tar.gz
wget https://www.kernel.org/pub/software/scm/git/git-2.33.0.tar.xz
wget https://doxygen.nl/files/doxygen-1.9.2.src.tar.gz
wget --no-check-certificate https://sources.archlinux.org/other/archlinux-keyring/archlinux-keyring-20211028.tar.gz
```
This linux desktop system(except the chroot environment) uses ABS to build all packages and installs using "pacman -U" option, so it doesn't require an archlinux repository, but it also allows you to build an archlinux distribution using only pacman.
Please verify md5sum arbitrarily. 
```
cat >> $LFS/sources/md5sums << "EOF" 
    f36f5e7e95a89436febe1bcca874fc33  pacman-5.0.2.tar.gz
    823212dc241793df8ff1d097769a3473  pkgconf-1.8.0.tar.xz
    e0356f5ae5623f227a3f69b5e8848ec6  make-ca-1.7.tar.xz
    cb1c68f2597f0a064232a841050eb6f2  fakeroot_1.26.orig.tar.gz
    5db3334b528cf756b1e583db01319a24  gnupg-2.2.29.tar.bz2
    95c32a1af583ecfcb280648874c0fbd9  gnutls-3.7.2.tar.xz
    e31b9e0efc5a2e1ec1bbed22e7a082a4  gpgme-1.16.0.tar.bz2
    a60273d0fab9c808646fcf5e9edc2e8f  nettle-3.7.3.tar.gz
    8ccf11c4a2e2e505b8e516d8549e64a5  p11-kit-0.24.0.tar.xz
    d2249e3dd108c830df00efd7c1b79d86  nano-5.8.tar.xz
    2ba9f1f8c169aa9caf8e2d34dde323be  libarchive-3.5.2.tar.xz
    7194453152bb67e3d45da698762b5d6f  libassuan-2.5.5.tar.bz2
    edc7becfe09c75d8f95ff7623e40c52e  libgcrypt-1.9.4.tar.bz2
    133fed221ba8f63f5842858a1ff67cb3  libgpg-error-1.42.tar.bz2
    d333b2e1381068d4f9a328240f062f0f  libksba-1.6.0.tar.bz2
    c46f6eb3bd1287031ae5d36465094402  libtasn1-4.17.0.tar.gz
    db08bb384e81968957f997ec9808926e  libunistring-0.9.10.tar.xz
    484dec4a06e183c20be815019ce9ddd0  libuv-v1.42.0.tar.gz
    f433a39be087a9f0b197eb2307ad9f75  libxml2-2.9.12.tar.gz
    375d1a15ad969f32d25f1a7630929854  npth-1.6.tar.bz2
    450f2f636e6a3aa527de803d0ae76c5a  popt-1.18.tar.gz
    f931582653774e310ed3a7e49b7167a3  freetype-2.11.0.tar.xz
    36cdea1058ef13cbbfdabe6cb019dc1c  fontconfig-2.13.1.tar.bz2
    32e09a982711d6e705f9d89020424c2d  pinentry-1.2.0.tar.bz2
    2ecc4091021c44f400bfbb25dcc77e97  cmake-3.21.2.tar.gz
    209f8326f5137d8817a6276d9577a2f1  rsync-3.2.3.tar.gz
    b939ee54eabc6b9b0a8d5c03ace879c9  wget-1.21.1.tar.gz
    419c2461366cf404160a820f7a902b7e  curl-7.78.0.tar.xz
    d9702786d89ec8053a96ab4768a172e4  nghttp2-1.44.0.tar.xz
    34954869627f62f9992808b6cff0d0a9  libxcrypt-4.4.26.tar.xz
    b99454564d5b4479750567031d66fe24  db-5.3.28.tar.gz
    a33820c66e0622222c5aefafa1581083  cyrus-sasl-2.1.27.tar.gz
    1a17a2d56984e95382b604833fe9b92d  cyrus-sasl-2.1.27-doc_fixes-1.patch
    e7847d1463ce4cdc8e3fd831d1cd267c  openldap-2.5.7.tgz
    79aab81c90018978ef698f389917b8ca  openldap-2.5.7-consolidated-1.patch
    919af7f33576816b423d537f8a8692e8  keyutils-1.6.1.tar.bz2
    eb51b7724111e1a458a8c9a261d45a31  krb5-1.19.2.tar.gz
    20750f9a7686f02b90a025303645f133  audit-3.0.6.tar.gz
    0990ff97af1511be0d9f0d3223dd4359  git-2.33.0.tar.xz
    84c0522bb65d17f9127896268b72ea2a  doxygen-1.9.2.src.tar.gz
    1b1ec243a3e7d568e15e08c490181fe1  archlinux-keyring-20211028.tar.gz
EOF
```
```
pushd $LFS/sources
   md5sum -c md5sums
popd
```
# Building chroot environment

In this section is different from the lfs-11.0 book. Here you need to install all of the chroot environment in the /tools directory. Test procedures that are possible but not required. Recommend that you install each package in stages, but you can also run a long script to install them all at once.

## BUILD [build-chroot-environment.sh](build_chroot_environment.sh)

Ryzen2700x(8 core) takes about 20 minuits. On the host as lfs user. 
```
cd $LFS/sources
chmod +x build-chroot-environment.sh
./build-chroot-environment.sh
```

## Changing owner
On the host.
```
su -
export LFS=/mnt/lfs
chown -R root:root $LFS/tools
mkdir -pv $LFS/{dev,proc,sys,run,etc}
mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3
cp /etc/{resolv.conf,hosts} $LFS/etc
```
## Striping
On the host as root.
```
rm -rf /tools/share/{info,man,doc}/*
rm -rf /tools/usr/share/{info,man,doc}/*
find /tools/{lib,libexec} -name \*.la -delete
```
## Backup
In the chroot environmennt as root.
```
exit  # It will be change into host environment from chroot environmennt.
su -
umount $LFS/dev{/pts,}
umount $LFS/{sys,proc,run}
export LFS=/mnt/lfs
cd $LFS 
tar -cJpf /PATH/to/lfs11-tools.tar.xz .
```
## Restore ( when starting over from here at a later step )
On the host.
```
su -
export LFS=/mnt/lfs
mount /dev/<the chroot environment partition> $LFS
cd $LFS 
rm -rf ./* 
tar -xpf /PATH/to/lfs11-tools.tar.xz
cd $LFS/sources
```
## Chroot
On the host.
```
su -
```
```
export LFS=/mnt/lfs
cat > chroot-1.sh << "EOF"
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
umount -v $LFS/dev{/pts,}
umount -v $LFS/{sys,proc,run}
EOF
chmod +x chroot-1.sh
./chroot-1.sh
```
## Creating dir
In the chroot environment as root.
```
mkdir -pv /{bin,boot,lib,lib64,sbin,usr,var}
mkdir -v /lib/locale
mkdir -pv /lib/udev/rules.d
mkdir -pv /etc/udev/rules.d
```
## Temporary toolchain settings
The following links will be overridden by the main system installation. 
```
ln -sfv /run /var/run
ln -sfv /run/lock /var/lock
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
ln -sfv /tools/bin/{bash,cat,chmod,curl,cut,dd,echo,install,ln,mkdir,nproc,pwd,printf,pwd,rm,stty,touch,uname} /bin
ln -sfv /tools/bin/bash /bin/sh
ln -sfv /tools/lib/libgcc_s.so{,.1}         /lib
ln -sfv /tools/lib/libstdc++.{a,so{,.6}}    /lib
ln -sfv /tools/lib/ld-linux-x86-64.so.2     /lib
ln -sfv /tools/lib/ld-linux-x86-64.so.2     /lib64
ln -sfv /tools/lib/ld-linux-x86-64.so.2     /lib64/ld-lsb-x86-64.so.3
ln -sfv /tools/lib/libncursesw.so.6         /lib
ln -sfv /tools/bin/{cut,env,md5sum,perl,openssl,trust} /usr/bin
ln -sv /proc/self/mounts /etc/mtab
```
## User settings
In the chroot environment as root.
```
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF
cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF

exec /bin/bash --login +h
```
```
echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester

mkdir -v /var/log
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp
```
## Back to to the host environment from chroot environment.
Issue:

    exit
        
When back to the host environment, to check the mount status. Issue:

    mount

Look at the output of mount, make sure the following directories are not mounted.
```
1./mnt/lfs/dev and  /mnt/lfs/dev/pts
2./mnt/lfs/sys
3./mnt/lfs/proc
4./mnt/lfs/run
```
If left mounted kernel's virtual file systems on these directories, the storage and hardware of the host PC will be damaged.
If you cannot unmount these, interrupt further operations and reboot the host immediately. 


# Install ABS
It's best to install each package step by step, but you can also run this long script to install it all at once. 

## Build [abs_build.sh](abs_build.sh)
Ryzen2700x(8 core) takes about xx minuits.
In the chroot environment as root.
```
cd /sources
chmod +x abs-build.sh
./abs-build.sh
```
```
/tools/bin/cat > ~/.bash_profile << "EOF"
exec /tools/bin/env -i HOME=$HOME TERM=$TERM PS1='(chroot)\u:\w\$ ' /tools/bin/bash
EOF
```
```
/tools/bin/cat > ~/.bashrc << "EOF"
set +h
umask 022
LC_ALL=POSIX
MAKEFLAGS="-j$(nproc)"
LFS_TGT=$(uname -m)-pc-linux-gnu
PATH=/tools/bin:/tools/sbin:/tools/usr/bin:/tools/usr/sbin
export LC_ALL LFS_TGT PATH MAKEFLAGS
EOF
```
```
source ~/.bash_profile
```
## Pacman settings
In the chroot environment as root.
```
mkdir -p /var/lib/pacman
mkdir -p /var/cache/pacman/pkg
pacman-key --init
pacman-key --populate archlinux
```
```
cat >> /tools/etc/pacman.conf << "EOF"
[core]
Include = /tools/etc/pacman.d/mirrorlist
[extra]
Include = /tools/etc/pacman.d/mirrorlist
[community]
Include = /tools/etc/pacman.d/mirrorlist
EOF
```
```
cat > /tools/etc/pacman.d/mirrorlist << "EOF"
# This is an example when your location is Japan
# Server = ftp://ftp.jaist.ac.jp/pub/Linux/ArchLinux/$repo/os/$arch
Server = http://ftp.jaist.ac.jp/pub/Linux/ArchLinux/$repo/os/$arch
EOF
```
Modify makepkg.conf and pacman.conf
```
nano /tools/etc/makepkg.conf
```
```
  #########################################################################
  # SOURCE ACQUISITION
  #########################################################################
  #
  #-- The download utilities that makepkg should use to acquire sources
  #  Format: 'protocol::agent'
  DLAGENTS=('file::/bin/curl -k -qgC - -o %o %u'
          'ftp::/tools/bin/curl -k -qgfC - --ftp-pasv --retry 3 --retry-delay 3 -o %o>
          'http::/tools/bin/curl -k -qgb "" -fLC - --retry 3 --retry-delay 3 -o %o %u'
          'https::/tools/bin/curl -k -qgb "" -fLC - --retry 3 --retry-delay 3 -o %o %>
          'rsync::/tools/bin/rsync --no-motd -zz %u %o'
          'scp::/tools/bin/scp -C %u %o')
                     .
                     .
                     .

  #########################################################################
  # ARCHITECTURE, COMPILE FLAGS
  #########################################################################
  #
  CARCH="x86_64"
  CHOST="x86_64-pc-linux-gnu"
  
  #-- Compiler and Linker Flags
  CPPFLAGS="-D_FORTIFY_SOURCE=2"
  CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt"
  CXXFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt"
  LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
  #-- Make Flags: change this for DistCC/SMP systems
  MAKEFLAGS="-j${nproc}"
  #-- Debugging flags
  #DEBUG_CFLAGS="-g -fvar-tracking-assignments"
  #DEBUG_CXXFLAGS="-g -fvar-tracking-assignments"
                    .
                    .
                    .

```
```
nano /tools/etc/pacman.conf
```
```
  [options]
  # The following paths are commented out with their default values listed.
  # If you wish to use different paths, uncomment and update the paths.
  RootDir     = /
  DBPath      = /var/lib/pacman/
  CacheDir    = /var/cache/pacman/pkg/
  LogFile     = /var/log/pacman.log
  GPGDir      = /tools/etc/pacman.d/gnupg/
  HookDir     = /tools/etc/pacman.d/hooks/
  HoldPkg     = pacman glibc
```
```
mkdir -p /var/lib/pacman
mkdir -p /var/cache/pacman/pkg
pacman -Syu
```
## ABS settings
ABS enable use only local user (disable root user).
In the chroot environment as root.
```
groupadd lfs
useradd -s /tools/bin/bash -g lfs -m -k /dev/null lfs
passwd lfs
```
su - lfs
```
```
/tools/bin/cat > ~/.bash_profile << "EOF"
exec /tools/bin/env -i HOME=$HOME TERM=$TERM PS1='(chroot)\u:\w\$ ' /tools/bin/bash
EOF
```
```
/tools/bin/cat > ~/.bashrc << "EOF"
set +h
umask 022
LC_ALL=POSIX
MAKEFLAGS="-j$(nproc)"
LFS_TGT=$(uname -m)-pc-linux-gnu
PATH=/tools/bin:/tools/sbin:/tools/usr/bin:/tools/usr/sbin
export LC_ALL LFS_TGT PATH MAKEFLAGS
EOF
```
```
source ~/.bash_profile
```
## Striping
On the host (After complete building the chroot environment)._
```
su -
strip --strip-debug /tools/lib/*
strip --strip-unneeded /tools/{,s}bin/*
```
```
rm -rf /tools/share/{info,man,doc}/*
rm -rf /tools/{man,doc}
rm -rf /tools/usr/share/{info,man,doc}/*
rm -rf /tools/x86_64-lfs-linux-gnu
find /tools/{lib,libexec} -name \*.la -delete
find /tools/usr/{lib,libexec} -name \*.la -delete
```
## Backup
On the host._
```
su -
cd /mnt/lfs
tar cJpf /Path/to/tools-pacman5.tar.xz .
```
## Restor (when starting over from here in a later step)
On the host
```
# su -
# export $LFS
# mount /dev/<partition to use as the chroot environment> $LFS
# cd $LFS
# rm -rf ./*
# tar -xpf /Path/to/tools-pacman5.tar.xz
```
