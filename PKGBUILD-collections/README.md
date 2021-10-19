# Making PKGBUILD for minimal linux desktop
 Must already done building the chroot environment.
 
As root user on host

    export $LFS
    mount /dev/<partition name of the chroot environment> $LFS
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
    
Making skelton of PKGBUILD (for example [PKGBUILD.skl](https://github.com/holozeros/minimal-linux-desktop/blob/master/PKGBUILD-collections/PKGBUILD.skl))
 
    cd /sources
    cat > PKGBUILD.skl << "EOF"
    ...    
    EOF
    
Making PKGBUILD (Almost source tar ball name format have been looks like "packagename"-"version".tar.xz)
case in making PKGBUILD of zlib-1.2.11.tar.xz

    mkdir -p /sources/zlib/1.2.11
    cd /sources/zlib/1.2.11
    cp ../../PKGBUILD.skl . && mv PKGBUILD.skl PKGBUILD
    nano PKGBUILD
    
 if host is desktop environment,
 you are able to refer to editor, browser and then needed text do copy&past to nano on the terminal.
 When you are modified on Nano, refer to LFS-11.0 book or the instruction of the packages of building chroot environent and archlinux's original PKGBUILD..and other infomations on web.
