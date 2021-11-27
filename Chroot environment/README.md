## Build preparation
Now, let's start "building chroot environment"

    su -

Below directive is very important, because $LFS is used frequently in many directives.
If $LFS is empty, there is a risk of destroying the host. 

    export LFS=/mnt/lfs

That physical storage shuld be SATA or M.2 connected, not USB storage.
This chroot environment will eventually become the root partition of a bootable linux OS.
Partition of the USB will not be perhaps recognized by a stub kernel at boot time without initramfs, but initramfs is can not support yet.
Therefore, the chroot environment should be built on an SSD or HDD partition with a SATA or M.2 connection. 
If you need a new partition for building chroot environment, use cgdisk, gparted, etc. to create a GPT partition of appropriate size.
File system format is as follows. 

    mkfs.ext4 /dev/<new partition for building chroot environment>

Format of EFI System Partition is fat32.
If it doesn't exist, create a new one.

    mkfs.vfat /dev/<EFI System Partition>

Mount the new partition for building chroot environment to /mnt/lfs. for example in case /dev/sda2

    mkdir -v /mnt/lfs
    
    # below directive is example, you shuld change the propery partition name 
    mount -v /dev/sda2 $LFS

## Checking host system requirement (see:[the LFS book](https://www.linuxfromscratch.org/lfs/view/stable/)

    cat > version-check.sh << "EOF"
    #!/bin/bash
    # Simple script to list version numbers of critical development tools.
    export LC_ALL=C
    bash --version | head -n1 | cut -d" " -f2-4
    MYSH=$(readlink -f /bin/sh)
    echo "/bin/sh -> $MYSH"
    echo $MYSH | grep -q bash || echo "ERROR: /bin/sh does not point to bash"
    unset MYSH
    echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
    bison --version | head -n1
    if [ -h /usr/bin/yacc ]; then
      echo "/usr/bin/yacc -> `readlink -f /usr/bin/yacc`";
    elif [ -x /usr/bin/yacc ]; then
      echo yacc is `/usr/bin/yacc --version | head -n1`
    else
      echo "yacc not found" 
    fi
    bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f1,6-
    echo -n "Coreutils: "; chown --version | head -n1 | cut -d")" -f2
    diff --version | head -n1
    find --version | head -n1
    gawk --version | head -n1
    if [ -h /usr/bin/awk ]; then
      echo "/usr/bin/awk -> `readlink -f /usr/bin/awk`";
    elif [ -x /usr/bin/awk ]; then
      echo awk is `/usr/bin/awk --version | head -n1`
    else 
      echo "awk not found" 
    fi
    gcc --version | head -n1
    g++ --version | head -n1
    ldd --version | head -n1 | cut -d" " -f2-  # glibc version
    grep --version | head -n1
    gzip --version | head -n1
    cat /proc/version
    m4 --version | head -n1
    make --version | head -n1
    patch --version | head -n1
    echo Perl `perl -V:version`
    python3 --version
    sed --version | head -n1
    tar --version | head -n1
    makeinfo --version | head -n1  # texinfo version
    xz --version | head -n1
    echo 'int main(){}' > dummy.c && g++ -o dummy dummy.c
    if [ -x dummy ]
      then echo "g++ compilation OK";
      else echo "g++ compilation failed"; fi
    rm -f dummy.c dummy
    EOF

Run following the shell script and check outputs of script.

    bash version-check.sh

## Bash setting

    [ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

## Directory settings

    export LFS=/mnt/lfs
    # mount /dev/<For new creation root file system partition> $LFS

    mkdir -v $LFS/home
        # mount -v -t ext4 /dev/<yyy> $LFS/home
    
    mkdir -v $LFS/sources
    chmod -v a+wt $LFS/sources
    mkdir -v $LFS/tools
    ln -sv $LFS/tools /
```
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done
case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac
```
## Making local user in your host system

    groupadd lfs
    useradd -s /bin/bash -g lfs -m -k /dev/null lfs
```
passwd lfs
```
```
chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac
chown -v lfs $LFS/sources
```
```
su - lfs
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

## Downloading sources

    export LFS=/mnt/lfs
    cd $LFS/sources

    wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list
    wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
    wget https://www.linuxfromscratch.org/lfs/view/stable/md5sums
    wget https://github.com/ninja-build/ninja/archive/v1.10.2.tar.gz
    mv v1.10.2.tar.gz ninja-1.10.2.tar.gz

If there are some tarballs that could not be downloaded automatically from the list, 
check the download address with LFS-11.0 Book or Google search and make up for it manually. 

## Additional sources for arch build system

    cd $LFS/sources

The following downloads refer to BeyondLinux® FromScratch (System V Edition) version 11.0, Archlinux's PKGBUILD,..etc.

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

This system uses ABS to build custom packages and installs using pacman, 
so it doesn't require an archlinux repository, but it also allows you to build an archlinux distribution using only pacman.
Please verify md5sum arbitrarily. 

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
    34954869627f62f9992808b6cff0d0a9  libxcrypt--4.4.26.tar.xz
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
    EOF

    pushd $LFS/sources
      md5sum -c md5sums
    popd

# Building chroot environment

In this section is different from the lfs-11.0 book. Here you need to install all of the chroot environment in the / tools directory. Test procedures that are possible but not required are commented out. Now start building the base for your chroot environment. We recommend that you install each package in stages, but you can also run a long script to install them all at once. If you want to install at once, create the script(build-chroot-environment.sh) build at once and execute it on the terminal. 

## BUILD (build-chroot-environment.sh)

Ryzen2700x(8 core) takes about 20 minuits.
```
cd $LFS/sources
chmod +x build-chroot-environment.sh
./build-chroot-environment.sh
```

######################
### Changing Owner ###
######################
su -
export LFS=/mnt/lfs
chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -R root:root $LFS/lib64 ;;
esac
mkdir -pv $LFS/{dev,proc,sys,run}
mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3

##############
### Chroot ###
##############
mount -v --bind /dev $LFS/dev
mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login +h
umount -v $LFS/dev{/pts,}
umount -v $LFS/{sys,proc,run}

####################
### creating dir ###
####################
mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}
ln -sfv /run /var/run
ln -sfv /run/lock /var/lock
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
ln -sv /proc/self/mounts /etc/mtab
cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/bin/false
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
uuidd:x:80:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF
echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester
exec /bin/bash --login +h
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp





-----------------------------
striping
```
rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools
```

backup
```
exit
umount $LFS/dev{/pts,}
umount $LFS/{sys,proc,run}
rm /tools
export LFS=/mnt/lfs
cd $LFS 
tar -cJpf $HOME/lfs11-pacman5.tar.xz .
```

restore
```
su -
export LFS=/mnt/lfs
cd $LFS 
rm -rf ./* 
tar -xpf $HOME/lfs11-pacman5.tar.xz
```



Strip
```
    rm -rf /tools/{,share}/{info,man,doc}
```
Backup
```
# cd $LFS/tools
# tar -cJpf <Path>/tools-base-11.tar.xz .
# sync
# cd $LFS/sources
```

When starting over from here in a later step

As root user.
```
# export $LFS
# mount /dev/<For new creation root file system partition> $LFS
# cd $LFS
# rm -rf tools && mkdir tools && cd tools
# tar -xpf <Path>/tools-base-11.tar.xz
```

## Chroot

changeing to root user from lfs
```
exit
```

```
export LFS=/mnt/lfs
```
```
chown -R root:root $LFS/tools
mkdir -pv $LFS/{dev,proc,sys,run,root,tmp,usr/{bin,lib},etc}
mkdir -v $LFS/tools/usr
mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3 
cp /etc/resolv.conf /mnt/lfs/etc

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
umount -v /mnt/lfs/dev/pts
umount -v /mnt/lfs/dev
umount -v /mnt/lfs/sys
umount -v /mnt/lfs/proc
umount -v /mnt/lfs/run
```
## Back to to the host environment.
Issue:

    exit

# This is very important !
        
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

# Entering the chroot environment
On the terminal

    su - 

Make sure that the chroot environment partition is mounted on /mnt/lfs.

    lsblk

If you already built the basic chroot environment and then it's mount to /mnt/lfs, isuue:
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
umount -v /mnt/lfs/dev/pts
umount -v /mnt/lfs/dev
umount -v /mnt/lfs/proc
umount -v mnt/lfs/sys
umount -v /mnt/lfs/run
```

## Settings the filesystem
```
ln -srv /usr/bin /bin
ln -sv /tools/bin/{bash,cat,echo,env,pwd,stty,uname,nproc} /usr/bin
ln -sv /tools/bin/bash /usr/bin/sh
ln -sv /tools/bin/perl /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib
ln -sv /tools/lib /tools/usr/lib
ln -sv /tools/include /tools/usr/include
ln -sv /tools/include/ncursesw/* /tools/include/
sed 's/tools/usr/' /tools/lib/libstdc++.la > /usr/lib/libstdc++.la
```
```
ln -sv /proc/self/mounts /etc/mtab
```
## Settings the root user environment
```
cat > ~/.bash_profile << "EOF"
exec /tools/bin/env -i HOME=$HOME TERM=$TERM PS1='(chroot)\u:\w\$ ' /tools/bin/bash
EOF
```
```
cat > ~/.bashrc << "EOF"
set +h
umask 022
LC_ALL=POSIX
MAKEFLAGS="-j$(nproc)"
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/tools/sbin:/tools/usr/bin:/tools/usr/sbin
export LC_ALL LFS_TGT PATH MAKEFLAGS
EOF
```
```
source ~/.bash_profile
```
```
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF
```
```
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
uuidd:x:80:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF
```
```
exec /tools/bin/bash --login +h
```

## Install ABS
It's best to install each package step by step, but you can also run this long script to install it all at once. 

## Build (build-ABS.sh)
Ryzen2700x(8 core) takes about xx minuits.
```
cd /sources
chmod +x build-ABS.sh
./build-ABS.sh
```
## Pacman settings
```
pacman-key --init
pacman-key --populate archlinux
```
```
cat >> /etc/pacman.conf << "EOF"
[core]
Include = /etc/pacman.d/mirrorlist
[extra]
Include = /etc/pacman.d/mirrorlist
[community]
Include = /etc/pacman.d/mirrorlist
EOF
```
```
cat > /etc/pacman.d/mirrorlist << "EOF"
# This is an example when your location is Japan
# Server = ftp://ftp.jaist.ac.jp/pub/Linux/ArchLinux/$repo/os/$arch
Server = http://ftp.jaist.ac.jp/pub/Linux/ArchLinux/$repo/os/$arch
EOF
```
```
pacman -Syu
```
## For using ABS
ABS enable use only local user (disable root user).
```
groupadd lfs
useradd -s /tools/bin/bash -g lfs -m -k /dev/null lfs
passwd lfs
```
```
su - lfs
```
```
cat > ~/.bash_profile << "EOF"
exec /tools/bin/env -i HOME=$HOME TERM=$TERM PS1='(chroot)\u:\w\$ ' /tools/bin/bash
EOF
```
```
cat > ~/.bashrc << "EOF"
set +h
umask 022
LC_ALL=POSIX
MAKEFLAGS="-j$(nproc)"
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/tools/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export LC_ALL LFS_TGT PATH MAKEFLAGS
EOF
```
```
source ~/.bash_profile
```
## Backup
Exit from chroot environment
```
exit
```
```
su -
cd /mnt/lfs
tar cJpf <Where you want to store Path>/tools-pacman-11.tar.xz
```
## When starting over from here in a later step
Exit chroot. Then as root user on host:
```
# su -
# export $LFS
# mount /dev/<partition to use as the chroot environment> $LFS
# cd $LFS
# rm -rf ./*
# tar -xpf <Path>/tools-pacman-11.tar.xz
```
