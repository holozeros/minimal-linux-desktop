# Making PKGBUILD
 Must already done [building chroot environment](../Building%20chroot%20environment.md) and then mounted its partition to /mnt/lfs.
 
As root user on host

    su -
    export LFS=/mnt/lfs

    mount /dev/<partition name of the chroot environment> $LFS

Chroot into $LFS

    export LFS=/mnt/lfs
    mount -v --bind /dev $LFS/dev
    mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
    mount -vt proc proc $LFS/proc
    mount -vt sysfs sysfs $LFS/sys
    mount -vt tmpfs tmpfs $LFS/run
    if [ -h $LFS/dev/shm ]; then
        mkdir -pv $LFS/$(readlink $LFS/dev/shm)
    fi
    chroot "$LFS" /bin/env -i       \
        HOME=/root                  \
        TERM="$TERM"                \
        PS1='(chroot)\u:\w\$ '      \
        MAKEFLAGS="-j10"            \
        PATH=/tools/bin:/tools/sbin:/tools/usr/bin:/tools/usr/sbin:/usr/bin:/usr/sbin \
        /bin/bash --login +h
    umount -lR /mnt/lfs/*

Change to a local user(e.g lfs)

      su - lfs
    
Making skelton of PKGBUILD (e.g  [PKGBUILD.skl](PKGBUILD.skl))


## Tutorial editting PKGBUILD
Almost tarball_name_format have been looks like
```
"package name"-"version".tar.xz.
````
If host is desktop environment, you are able to refer to editor, browser and then needed text do copy&paste to nano on the terminal. When you are modified on Nano, refer to LFS-11.0 book or the instruction of the packages of building chroot environent and archlinux's original PKGBUILD..and other infomations on web.
The following variables refer to file name of the target source_tar_ball. 

        pkgname=' '
        pkgver=' '

Refer to the Arch Linux PKGBULD or LFS workbook description for the target source-tarball to determine the following variables: 

        pkgrel=
        pkgdesc=
        license=(' ')
        url='https://.. '
        
        sha256sums=(' ')
           or  
        md5sums=(' ')

 
This variable is almost constant here.

        arch=('x86_64')

These variables shuld be comment out, add top of the line #.

        # depends=()
        # groups=()
        # validpgpkeys=

These variable add as needed.

        provides=(' ')
        options=(' ')

##### case in making [PKGBUILD](zlib/1.2.11/PKGBUILD) of zlib-1.2.11.tar.xz

    mkdir -p /usr/src/zlib/1.2.11
    cd /usr/src/zlib/1.2.11
    cp ../../PKGBUILD.skl . && mv PKGBUILD.skl PKGBUILD
    nano PKGBUILD

or don't use PKGBUILD.skl, write with cat command directly. For example:

    cat > PKGBUILD << "EOF"
    pkgname="zlib"
    pkgver="1.2.11" 
    pkgrel="1"
    pkgdesc="Compression library implementing the deflate compression method found in gzip and PKZIP"
    arch=('x86_64')
    url="http://zlib.net"
    license=('custum')
    #backup=()
    source=(${pkgname}-${pkgver}.tar.xz)
    #install=glibc.install
    
    #prepare() {
    #}
    
    build() {
    cd "${pkgname}-${pkgver}"
    ./configure --prefix=/usr
    make
    }
    
    check() {
    cd "${pkgname}-${pkgver}"
    make check 2>&1 | ../../${pkgname}-${pkgver}-test.log
    }
    package() {
    cd "${pkgname}-${pkgver}"
    make DESTDIR=${pkgdir} install
    }
    EOF
