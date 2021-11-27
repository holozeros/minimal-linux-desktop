export LFS=/mnt/lfs
cd $LFS/sources

cat > build-chroot-environment.sh << "END"
###########################
### binutils-2.37-pass1 ###
###########################
tar xf binutils-2.37.tar.xz
cd binutils-2.37
mkdir -v build
cd       build
../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --disable-werror
make
make install -j1
cd ../..
rm -rf binutils-2.37
########################
### gcc-11.2.0-pass1 ###
########################
tar xf gcc-11.2.0.tar.xz
cd gcc-11.2.0
tar -xf ../mpfr-4.1.0.tar.xz
mv -v mpfr-4.1.0 mpfr
tar -xf ../gmp-6.2.1.tar.xz
mv -v gmp-6.2.1 gmp
tar -xf ../mpc-1.2.1.tar.gz
mv -v mpc-1.2.1 mpc
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac
mkdir -v build
cd       build
../configure                                       \
    --target=$LFS_TGT                              \
    --prefix=$LFS/tools                            \
    --with-glibc-version=2.11                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --enable-initfini-array                        \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++
make
make install
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/install-tools/include/limits.h
cd ..
rm -rf gcc-11.2.0
#################################
### linux-api-headers-5.13.12 ###
#################################
tar xf linux-5.13.12.tar.xz
cd linux-5.13.12
make mrproper
make headers
find usr/include -name '.*' -delete
rm usr/include/Makefile
cp -rv usr/include $LFS/usr
cd ..
rm -rf linux-5.13.12
##################
### glibc-2.34 ###
##################
tar xf glibc-2.34.tar.xz
cd glibc-2.34
case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac
patch -Np1 -i ../glibc-2.34-fhs-1.patch
mkdir -v build
cd       build
echo "rootsbindir=/usr/sbin" > configparms
../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2                \
      --with-headers=$LFS/usr/include    \
      libc_cv_slibdir=/usr/lib
make -j1
make DESTDIR=$LFS install
sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep '/ld-linux'
  # [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
rm -v dummy.c a.out
$LFS/tools/libexec/gcc/$LFS_TGT/11.2.0/install-tools/mkheaders
cd ../..
rm -rf glibc-2.34
##############################
### libstdc++-11.2.0-pass1 ###
##############################
tar xf gcc-11.2.0.tar.xz
cd gcc-11.2.0
mkdir -v build
cd       build
../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/11.2.0
make
make DESTDIR=$LFS install
cd ../..
rm -rf gcc-11.2.0
##########
### m4 ###
##########
tar xf m4-1.4.19.tar.xz
cd m4-1.4.19
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf m4-1.4.19
###################
### ncurses-6.2 ###
###################
tar xf ncurses-6.2.tar.gz
cd ncurses-6.2
sed -i s/mawk// configure
mkdir build
pushd build
  ../configure
  make -C include
  make -C progs tic
popd
./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-debug              \
            --without-ada                \
            --without-normal             \
            --enable-widec
make
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so
cd ..
rm -rf ncurses-6.2
##################
### bash-5.1.8 ###
##################
tar xf bash-5.1.8.tar.gz
cd bash-5.1.8
./configure --prefix=/usr                   \
            --build=$(support/config.guess) \
            --host=$LFS_TGT                 \
            --without-bash-malloc
make
make DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh
cd ..
rm -rf bash-5.1.8
######################
### coreutils-8.32 ###
######################
tar xf coreutils-8.32.tar.xz
cd coreutils-8.32
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime
make
make DESTDIR=$LFS install
mv -v $LFS/usr/bin/chroot                                     $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1                        $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                                           $LFS/usr/share/man/man8/chroot.8
cd ..
rm -rf coreutils-8.32
#####################
### diffutils-3.8 ###
#####################
tar xf diffutils-3.8.tar.xz
cd diffutils-3.8
./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install
cd ..
rm -rf diffutils-3.8
#################
### file-5.40 ###
#################
tar xf file-5.40.tar.gz
cd file-5.40
mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
cd ..
rm -rf file-5.40
#######################
### findutils-4.8.0 ###
#######################
tar xf findutils-4.8.0.tar.xz
cd findutils-4.8.0
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf findutils-4.8.0
##################
### gawk-5.1.0 ###
##################
tar xf gawk-5.1.0.tar.xz
cd gawk-5.1.0
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf gawk-5.1.0
################
### grep-3.7 ###
###################
tar xf grep-3.7.tar.xz
cd grep-3.7
./configure --prefix=/usr   \
            --host=$LFS_TGT
make
make DESTDIR=$LFS install
cd ..
rm -rf grep-3.7
#################
### gzip-1.10 ###
#################
tar xf gzip-1.10.tar.xz
cd gzip-1.10
./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install
cd ..
rm -rf gzip-1.10
################
### make-4.3 ###
################
tar xf make-4.3.tar.gz
cd make-4.3
./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf make-4.3
###################
### patch-2.7.6 ###
###################
tar xf patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm -rf patch-2.7.6
###############
### sed-4.8 ###
###############
tar xf sed-4.8.tar.xz
cd sed-4.8
./configure --prefix=/usr   \
            --host=$LFS_TGT
make
make DESTDIR=$LFS install
cd ..
rm -rf sed-4.8
################
### tar-1.34 ###
################
tar xf tar-1.34.tar.xz
cd tar-1.34
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
cd ..
rm  -rf tar-1.34
################
### xz-5.2.5 ###
################
tar xf xz-5.2.5.tar.xz
cd xz-5.2.5
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.2.5
make
make DESTDIR=$LFS install
cd ..
rm -rf xz-5.2.5
############################
### binutils-2.37 pass 2 ###
############################
tar xf binutils-2.37.tar.xz
cd binutils-2.37
mkdir -v build
cd       build
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --disable-werror           \
    --enable-64-bit-bfd
make
make DESTDIR=$LFS install -j1
install -vm755 libctf/.libs/libctf.so.0.0.0 $LFS/usr/lib
cd ../..
rm -rf binutils-2.37
#########################
### gcc-11.2.0 pass 2 ###
#########################
tar xf gcc-11.2.0.tar.xz
cd gcc-11.2.0
tar -xf ../mpfr-4.1.0.tar.xz
mv -v mpfr-4.1.0 mpfr
tar -xf ../gmp-6.2.1.tar.xz
mv -v gmp-6.2.1 gmp
tar -xf ../mpc-1.2.1.tar.gz
mv -v mpc-1.2.1 mpc
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac
mkdir -v build
cd       build
mkdir -pv $LFS_TGT/libgcc
ln -s ../../../libgcc/gthr-posix.h $LFS_TGT/libgcc/gthr-default.h
../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --prefix=/usr                                  \
    CC_FOR_TARGET=$LFS_TGT-gcc                     \
    --with-build-sysroot=$LFS                      \
    --enable-initfini-array                        \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++
make
make DESTDIR=$LFS install
ln -sv gcc $LFS/usr/bin/cc
cd ../..
rm -rf gcc-11.2.0
#############################################
END
#############################################

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

cat > abs_build.sh << "END"
#######################
### libstdc++ pass2 ###
#######################
tar xf gcc-11.2.0.tar.xz
cd gcc-11.2.0
ln -s gthr-posix.h libgcc/gthr-default.h
mkdir -v build
cd       build
../libstdc++-v3/configure            \
    CXXFLAGS="-g -O2 -D_GNU_SOURCE"  \
    --prefix=/usr                    \
    --disable-multilib               \
    --disable-nls                    \
    --host=$(uname -m)-lfs-linux-gnu \
    --disable-libstdcxx-pch
make
make install
cd ../..
rm -rf gcc-11.2.0
####################
### gettext-0.21 ###
####################
tar xf gettext-0.21.tar.xz
cd gettext-0.21
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
cd ..
rm -rf gettext-0.21
###################
### bison-3.7.6 ###
###################
tar xf bison-3.7.6.tar.xz
cd bison-3.7.6
./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.7.6
make
make install
cd ..
rm -rf bison-3.7.6
###################
### perl-5.34.0 ###
###################
tar xf perl-5.34.0.tar.xz
cd perl-5.34.0
sh Configure -des                                        \
             -Dprefix=/usr                               \
             -Dvendorprefix=/usr                         \
             -Dprivlib=/usr/lib/perl5/5.34/core_perl     \
             -Darchlib=/usr/lib/perl5/5.34/core_perl     \
             -Dsitelib=/usr/lib/perl5/5.34/site_perl     \
             -Dsitearch=/usr/lib/perl5/5.34/site_perl    \
             -Dvendorlib=/usr/lib/perl5/5.34/vendor_perl \
             -Dvendorarch=/usr/lib/perl5/5.34/vendor_perl
make
make install
cd ..
rm -rf perl-5.34.0
####################
### python-3.9.6 ###
####################
tar xf Python-3.9.6.tar.xz
cd Python-3.9.6
./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip
make
make install
cd ..
rm -rf Python-3.9.6
###################
### texinfo-6.8 ###
###################
tar xf texinfo-6.8.tar.xz
cd texinfo-6.8
sed -e 's/__attribute_nonnull__/__nonnull/' \
    -i gnulib/lib/malloc/dynarray-skeleton.c
./configure --prefix=/usr
make
make install
cd ..
rm -rf texinfo-6.8
#########################
### util-linux-2.37.2 ###
#########################
tar xf util-linux-2.37.2.tar.xz
cd util-linux-2.37.2
mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime    \
            --libdir=/usr/lib    \
            --docdir=/usr/share/doc/util-linux-2.37.2 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            runstatedir=/run
make
make install
cd ..
rm -rf util-linux-2.37.2
###################
### ncurses-6.2 ###
###################
tar xf ncurses-6.2.tar.gz
cd ncurses-6.2
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --enable-pc-files       \
            --enable-widec
make
make install
for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done
rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
rm -fv /usr/lib/libncurses++w.a
cd ..
rm -rf ncurses-6.2
#################
### tcl8.6.11 ###
#################
tar xf tcl8.6.11-src.tar.gz
cd tcl8.6.11
cd unix
./configure --prefix=/usr
make
# TZ=UTC make test
make install
chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sv tclsh8.6 /usr/bin/tclsh
cd ../..
rm -rf tcl8.6.11
####################
### expect5.45.4 ###
####################
tar xf expect5.45.4.tar.gz
cd expect5.45.4
cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure
./configure --prefix=/usr         \
            --with-tcl=/usr/lib   \
            --with-tclinclude=/usr/include
make
make SCRIPTS="" install
ln -s /usr/lib/expect5.45.4/libexpect5.45.4.so /usr/lib/libexpect-5.45.4.so
cd ..
rm -rf expect5.45.4
#####################
### dejagnu-1.6.3 ###
#####################
tar xf dejagnu-1.6.3.tar.gz
cd dejagnu-1.6.3
mkdir -v build
cd       build
../configure --prefix=/usr
make install
cd ../..
rm -rf dejagnu-1.6.3
####################
### check-0.15.2 ###
####################
tar xf check-0.15.2.tar.gz
cd check-0.15.2
PKG_CONFIG= ./configure --prefix=/usr
make
make install
cd ..
rm -rf check-0.15.2
###################
### bzip2-1.0.8 ###
###################
tar xf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /usr/lib/libbz2.a
cd ..
rm -rf bzip2-1.0.8
###################
### zlib-1.2.11 ###
###################
tar xf zlib-1.2.11.tar.xz
cd zlib-1.2.11
./configure --prefix=/usr
make
make check
make install
cd ..
rm -rf zlib-1.2.11
#################
### gmp-6.2.1 ###
#################
tar xf gmp-6.2.1.tar.xz
cd gmp-6.2.1
./configure --prefix=/usr      \
            --enable-cxx       \
            --disable-static
make
make check 2>&1 | tee gmp-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
#	 197
make install
cd ..
rm -rf gmp-6.2.1
##################
### mpfr-4.1.0 ###
##################
tar xf mpfr-4.1.0.tar.xz
cd mpfr-4.1.0
./configure --prefix=/usr          \
            --disable-static       \
            --enable-thread-safe
make
make check
make install
cd ..
rm -rf mpfr-4.1.0
#################
### mpc-1.2.1 ###
#################
tar xf mpc-1.2.1.tar.gz
cd mpc-1.2.1
./configure --prefix=/usr    \
            --disable-static
make
make check
make install
cd ..
rm -rf mpc-1.2.1
#####################
### pkgconf-1.8.0 ###
#####################
tar xf pkgconf-1.8.0.tar.xz
cd pkgconf-1.8.0
./configure --prefix=/usr                   \
     --with-system-libdir=/lib:/usr/lib     \
     --with-system-includedir=/include:/usr/include
make
make install
ln -sr /usr/bin/pkgconf /usr/bin/pkg-config
cd ..
rm -rf pkgconf-1.8.0
# pkg-config is specific of LFS: https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
#tar xf pkg-config-0.29.2.tar.gz
#cd pkg-config-0.29.2
#
#./configure --prefix=/tools              \
#            --with-internal-glib         \
#            --disable-host-tool          \
#            --docdir=/share/doc/pkg-config-0.29.2
#make
#make check
#make install
#
#cd ..
#rm -rf pkg-config-0.29.2
##################
### attr-2.5.1 ###
##################
tar xf attr-2.5.1.tar.gz
cd attr-2.5.1
./configure --prefix=/usr   \
            --disable-static  \
            --sysconfdir=/usr/etc 
make
make check
make install
cd ..
rm -rf attr-2.5.1
#################
### acl-2.3.1 ###
#################
tar xf acl-2.3.1.tar.xz
cd acl-2.3.1
./configure --prefix=/usr       \
            --disable-static
make
make install
cd ..
rm -rf acl-2.3.1
###################
### libcap-2.53 ###
###################
tar xf libcap-2.53.tar.xz
cd libcap-2.53
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
make test
make prefix=/usr lib=lib install
chmod -v 755 /usr/lib/lib{cap,psx}.so.2.53
cd ..
rm -rf libcap-2.53
###################
### psmisc-23.4 ###
###################
tar xf psmisc-23.4.tar.xz
cd psmisc-23.4
./configure --prefix=/usr
make
make install
cd ..
rm -rf psmisc-23.4
#########################
### iana-etc-20210611 ###
#########################
tar xf iana-etc-20210611.tar.gz
cd iana-etc-20210611
cp services protocols /etc
cd ..
rm -rf iana-etc-20210611
##################
### flex-2.6.4 ###
##################
tar xf flex-2.6.4.tar.gz
cd flex-2.6.4
./configure --prefix=/usr
make
make check
make install
ln -sv /usr/bin/flex /usr//bin/lex
cd ..
rm -rf flex-2.6.4
################
### bc-5.0.0 ###
################
tar xf bc-5.0.0.tar.xz
cd bc-5.0.0
CC=gcc ./configure --prefix=/usr -G -O3
make
make test
make install
cd ..
rm -rf bc-5.0.0
####################
### readline-8.1 ###
####################
tar xf readline-8.1.tar.gz
cd readline-8.1
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr      \
            --disable-static   \
            --with-curses
make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install
ldconfig
cd ..
rm -rf readline-8.1
################
### nano-5.8 ###
################
tar xf nano-5.8.tar.xz
cd nano-5.8
./configure --prefix=/usr             \
            --sysconfdir=/etc         \
            --enable-utf8
make
make install
cd ..
rm -rf nano-5.8
#####################
### libtool-2.4.6 ###
#####################
tar xf libtool-2.4.6.tar.xz
cd libtool-2.4.6
./configure --prefix=/usr
make
# make check
make install
rm -fv /usr/lib/libltdl.a
cd ..
rm -rf libtool-2.4.6
##################
### shadow-4.9 ###
##################
tar xf shadow-4.9.tar.xz
cd shadow-4.9
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD SHA512:' \
    -e 's:/var/spool/mail:/var/mail:'                 \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                \
    -i etc/login.defs
sed -e "224s/rounds/min_rounds/" -i libmisc/salt.c
touch /usr/bin/passwd
sed -i 's/1000/999/' etc/useradd
./configure --prefix=/usr           \
            --sysconfdir=/etc       \
            --with-group-name-max-length=32
make
make install
mkdir -p /etc/default
useradd -D --gid 999
pwconv
grpconv
sed -i 's/yes/no/' /etc/default/useradd
# passwd root
cd ..
rm -rf shadow-4.9
###############
### dejagnu ###
###############
tar xf dejagnu-1.6.3.tar.gz
cd dejagnu-1.6.3
mkdir -v build
cd       build
../configure --prefix=/usr
make install
make check
cd ../..
rm -rf dejagnu-1.6.3
#################
### gdbm-1.20 ###
#################
tar xf gdbm-1.20.tar.gz
cd gdbm-1.20
./configure --prefix=/usr      \
            --disable-static   \
            --enable-libgdbm-compat
make
make install
# make -k check
cd ..
rm -rf gdbm-1.20
#################
### gperf-3.1 ###
#################
tar xf gperf-3.1.tar.gz
cd gperf-3.1
./configure --prefix=/usr
make
make install
cd ..
rm -rf gperf-3.1
###################
### expat-2.4.1 ###
###################
tar xf expat-2.4.1.tar.xz
cd expat-2.4.1
./configure --prefix=/usr --disable-static
make
make check
make install
cd ..
rm -rf expat-2.4.1
#####################
### inetutils-2.1 ###
#####################
tar xf inetutils-2.1.tar.xz
cd inetutils-2.1
./configure --prefix=/usr              \
            --bindir=/bin              \
            --localstatedir=/var       \
            --disable-logger           \
            --disable-whois            \
            --disable-rcp              \
            --disable-rexec            \
            --disable-rlogin           \
            --disable-rsh              \
            --disable-servers
make
make check
make install
mv -v /usr/{,s}sbin/ifconfig
cd ..
rm -rf inetutils-2.1
ln -s /usr/etc/services /etc/
ln -s /usr/etc/protocols /etc/
ping -c 3 google.com
################
### less-590 ###
################
tar xf less-590.tar.gz
cd less-590
./configure --prefix=/usr --sysconfdir=/tools/etc
make
make install
cd ..
rm -rf less-590
######################
### elfutils-0.185 ###
######################
tar xf elfutils-0.185.tar.bz2
cd elfutils-0.185
./configure --prefix=/usr                  \
            --disable-debuginfod           \
            --enable-libdebuginfod=dummy
make
# make check # FAIL: run-backtrace-native.sh
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a
cd ..
rm -rf elfutils-0.185
####################
### libffi-3.4.2 ###
####################
tar xf libffi-3.4.2.tar.gz
cd libffi-3.4.2
./configure --prefix=/usr            \
            --disable-static         \
            --with-gcc-arch=native   \
            --disable-exec-static-tramp
make
make check
make install
cd ..
rm -rf libffi-3.4.2
######################
### openssl-1.1.1l ###
######################
tar xf openssl-1.1.1l.tar.gz
cd openssl-1.1.1l
./config --prefix=/usr                     \
         --openssldir=/etc/ssl             \
         --libdir=lib                      \
         shared                            \
         zlib-dynamic
make
make test
sed -i '/INSTALL_LIBS/s/libcrypto.a lmv /usr/etc/protocols /usr/etc/ibssl.a//' Makefile
make MANSUFFIX=ssl install
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.1l
cd ..
rm -rf openssl-1.1.1l
###################
### perl-5.34.0 ###
###################
tar xf perl-5.34.0.tar.xz
cd perl-5.34.0
patch -Np1 -i ../perl-5.34.0-upstream_fixes-1.patch
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des                                           \
             -Dprefix=/usr                                  \
             -Dvendorprefix=/usr                            \
             -Dprivlib=/usr/lib/perl5/5.34/core_perl        \
             -Darchlib=/usr/lib/perl5/5.34/core_perl        \
             -Dsitelib=/usr/lib/perl5/5.34/site_perl        \
             -Dsitearch=/usr/lib/perl5/5.34/site_perl       \
             -Dvendorlib=/usr/lib/perl5/5.34/vendor_perl    \
             -Dvendorarch=/usr/lib/perl5/5.34/vendor_perl   \
             -Dman1dir=/usr/share/man/man1                  \
             -Dman3dir=/usr/share/man/man3                  \
             -Dpager="/usr/bin/less -isR"                   \
             -Duseshrplib                                   \
             -Dusethreads
make
make test
make install
unset BUILD_ZLIB BUILD_BZIP2
cd ..
rm -rf perl-5.34.0
#######################
### XML-Parser-2.46 ###
#######################
tar xf XML-Parser-2.46.tar.gz
cd XML-Parser-2.46
perl Makefile.PL
make
make test
make install
cd ..
rm -rf XML-Parser-2.46
#######################
### intltool-0.51.0 ###
#######################
tar xf intltool-0.51.0.tar.gz
cd intltool-0.51.0
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make
make check
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
cd ..
rm -rf intltool-0.51.0
#####################
### autoconf-2.71 ###
#####################
tar xf autoconf-2.71.tar.xz
cd autoconf-2.71
./configure --prefix=/usr
make
make check
make install
cd ..
rm -rf autoconf-2.71
#######################
### automake-1.16.4 ###
#######################
tar xf automake-1.16.4.tar.xz
cd automake-1.16.4
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.4
make
make -j4 check
make install
cd ..
rm -rf automake-1.16.4
#####################
### libtool-2.4.6 ###
#####################
tar xf libtool-2.4.6.tar.xz
cd libtool-2.4.6
./configure --prefix=/usr
make
make check
make install
rm -fv /usr/lib/libltdl.a
cd ..
rm -rf libtool-2.4.6
##################
### zstd-1.5.0 ###
##################
tar xf zstd-1.5.0.tar.gz
cd zstd-1.5.0
make
make check
make prefix=/usr install
rm -v /usr/lib/libzstd.a
ln -sr /usr/bin/zstd /usr/bin/
cd ..
rm -rf zstd-1.5.0
###############
### kmod-29 ###
###############
tar xf kmod-29.tar.xz
cd kmod-29
./configure --prefix=/usr                \
            --sysconfdir=/etc            \
            --with-xz                    \
            --with-zstd                  \
            --with-zlib
make
make install
for target in depmod insmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /usr/sbin/$target
done
ln -sfv kmod /usr/bin/lsmod
cd ..
rm -rf kmod-29
####################
### Python-3.9.6 ###
####################
tar xf Python-3.9.6.tar.xz
cd Python-3.9.6
./configure --prefix=/usr          \
            --enable-shared        \
            --with-system-expat    \
            --with-system-ffi      \
            --with-ensurepip=yes   \
            --enable-optimizations
make
make install
cd ..
rm -rf Python-3.9.6
####################
### ninja-1.10.2 ###
####################
tar xf ninja-1.10.2.tar.gz
cd ninja-1.10.2
export NINJAJOBS=16
sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc
python3 configure.py --bootstrap
./ninja ninja_test
./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
cd ..
rm -rf ninja-1.10.2
####################
### meson-0.59.1 ###
####################
tar xf meson-0.59.1.tar.gz
cd meson-0.59.1
python3 setup.py build
python3 setup.py install --root=dest
cp -rv dest/* /
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
cd ..
rm -rf meson-0.59.1
#######################
### libtasn1-4.17.0 ###
#######################
tar xf libtasn1-4.17.0.tar.gz
cd libtasn1-4.17.0
./configure --prefix=/usr --disable-static
make
make check
make install
cd ..
rm -rf libtasn1-4.17.0
#####################
### libuv-v1.42.0 ###
#####################
tar xf libuv-v1.42.0.tar.gz
cd libuv-v1.42.0
sh autogen.sh
./configure --prefix=/usr --disable-static
make
make install
cd ..
rm -rf libuv-v1.42.0
######################
### libxml2-2.9.12 ###
######################
tar xf libxml2-2.9.12.tar.gz
cd libxml2-2.9.12
./configure --prefix=/usr    \
            --disable-static   \
            --with-history     \
            --with-python=/usr/bin/python3
make
make install
cd ..
rm -rf libxml2-2.9.12
######################
### nghttp2-1.44.0 ###
######################
tar xf nghttp2-1.44.0.tar.xz
cd nghttp2-1.44.0
./configure --prefix=/usr     \
            --disable-static  \
            --enable-lib-only \
            --docdir=/share/doc/nghttp2-1.44.0
make
make install
cd ..
rm -rf nghttp2-1.44.0
###################
### make-ca-1.7 ###
###################
tar xf make-ca-1.7.tar.xz
cd make-ca-1.7
make install
install -vdm755 /etc/ssl/local
#/usr/sbin/make-ca -g
cd ..
rm -rf make-ca-1.7
######################
### p11-kit-0.24.0 ###
######################
tar xf p11-kit-0.24.0.tar.xz
cd p11-kit-0.24.0
sed '20,$ d' -i trust/trust-extract-compat &&
cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications
# Generate a new trust store
/usr/sbin/make-ca -f -g
EOF
mkdir p11-build
cd    p11-build
meson --prefix=/usr       \
      --buildtype=release   \
      -Dtrust_paths=/etc/pki/anchors
ninja
ninja test
ninja install &&
ln -sfv /usr/libexec/p11-kit/trust-extract-compat \
        /usr/bin/update-ca-certificates
ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so
cd ../..
rm -rf p11-kit-0.24.0
cd /usr/bin
ln -s /usr/bin/cut
ln -s /usr/bin/openssl
ln -s /usr/bin/md5sum
ln -s /usr/bin/trust
cd /sources
make-ca -g
###################
### Wget-1.21.1 ###
###################
tar xf wget-1.21.1.tar.gz
cd wget-1.21.1
./configure --prefix=/usr      \
            --sysconfdir=/etc    \
            --with-ssl=openssl
make
# make check
make install
cd ..
rm -rf wget-1.21.1
###################
### cURL-7.78.0 ###
###################
tar xf curl-7.78.0.tar.xz
cd curl-7.78.0
grep -rl '#!.*python$' | xargs sed -i '1s/python/&3/'
./configure --prefix=/usr                         \
            --disable-static                        \
            --with-openssl                          \
            --enable-threaded-resolver              \
            --with-ca-path=/etc/ssl/certs &&
make
make test
make install
cd ..
rm -rf curl-7.78.0
########################
### libarchive-3.5.2 ###
########################
tar xf libarchive-3.5.2.tar.xz
cd libarchive-3.5.2
./configure --prefix=/usr --disable-static &&
make
LC_ALL=C make check
make install
cd ..
rm -rf libarchive-3.5.2
####################
### cmake-3.21.2 ###
####################
tar xf cmake-3.21.2.tar.gz
cd cmake-3.21.2
sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake &&
./bootstrap --prefix=/usr      \
            --system-libs        \
            --no-system-jsoncpp  \
            --no-system-librhash
make
make install
cd ..
rm -rf cmake-3.21.2
#########################
### libgpg-error-1.42 ###
#########################
tar xf libgpg-error-1.42.tar.bz2
cd libgpg-error-1.42
./configure --prefix=/usr
make
make install
cd ..
rm -rf libgpg-error-1.42
#######################
### libassuan-2.5.5 ###
#######################
tar xf libassuan-2.5.5.tar.bz2
cd libassuan-2.5.5
./configure --prefix=/usr
make
make check
make install
cd ..
rm -rf libassuan-2.5.5
####################
### GPGME-1.16.0 ###
####################
tar xf gpgme-1.16.0.tar.bz2
cd gpgme-1.16.0
sed 's/defined(__sun.*$/1/' -i src/posix-io.c
./configure --prefix=/usr --disable-gpg-test
make
make install
cd ..
rm -rf gpgme-1.16.0
################
### npth-1.6 ###
################
tar xf npth-1.6.tar.bz2
cd npth-1.6
./configure --prefix=/usr
make
make check
make install
cd ..
rm -rf npth-1.6
#####################
### libksba-1.6.0 ###
#####################
tar xf libksba-1.6.0.tar.bz2
cd libksba-1.6.0
./configure --prefix=/usr
make
make check
make install
cd ..
rm -rf libksba-1.6.0
#######################
### libgcrypt-1.9.4 ###
#######################
tar xf libgcrypt-1.9.4.tar.bz2
cd libgcrypt-1.9.4
./configure --prefix=/usr
make
make check
make install
cd ..
rm -rf libgcrypt-1.9.4
#################
### libxcrypt ###
#################
tar xf libxcrypt-4.4.26.tar.xz
cd libxcrypt-4.4.26
./configure \
  --prefix=/usr \
  --disable-static \
  --enable-hashes=strong,glibc \
  --enable-obsolete-api=no \
  --disable-failure-tokens
make
make check
make install
cd ..
rm -rf libxcrypt-4.4.26
######################
### pinentry-1.2.0 ###
######################
tar xf pinentry-1.2.0.tar.bz2
cd pinentry-1.2.0
./configure --prefix=/usr --enable-pinentry-tty
make
make install
cd ..
rm -rf pinentry-1.2.0
####################
### nettle-3.7.3 ###
####################
tar xf nettle-3.7.3.tar.gz
cd nettle-3.7.3
./configure --prefix=/usr --disable-static
make
make check
make install
chmod   -v   755 /usr/lib/lib{hogweed,nettle}.so
install -v -m755 -d /usr/share/doc/nettle-3.7.3 &&
install -v -m644 nettle.html /usr/share/doc/nettle-3.7.3
cd ..
rm -fr nettle-3.7.3
###########################
### libunistring-0.9.10 ###
###########################
tar xf libunistring-0.9.10.tar.xz
cd libunistring-0.9.10
./configure --prefix=/usr  \
            --disable-static
make
make check
make install
cd ..
rm -rf libunistring-0.9.10
####################
### GnuTLS-3.7.2 ###
####################
tar xf gnutls-3.7.2.tar.xz
cd gnutls-3.7.2
./configure --prefix=/usr   \
            --disable-guile \
            --disable-rpath \
            --with-default-trust-store-pkcs11="pkcs11:"
make
# make check
make install
cd ..
rm -rf gnutls-3.7.2
####################
### GnuPG-2.2.29 ###
####################
tar xf gnupg-2.2.29.tar.bz2
cd gnupg-2.2.29
sed -e '/noinst_SCRIPTS = gpg-zip/c sbin_SCRIPTS += gpg-zip' \
    -i tools/Makefile.in
./configure --prefix=/usr          \
            --localstatedir=/var     \
            --sysconfdir=/etc
make
make check
make install
cd ..
rm -rf gnupg-2.2.29
#####################
### fakeroot-1.26 ###
#####################
tar xf fakeroot_1.26.orig.tar.gz
cd fakeroot-1.26
 ./configure --prefix=/usr \
    --libdir=/usr/lib/libfakeroot \
    --disable-static \
    --with-ipc=sysv
make
make install
install -dm0755 /etc/ld.so.conf.d/
echo '/tools/lib/libfakeroot' > /etc/ld.so.conf.d/fakeroot.conf
cd ..
rm -rf fakeroot-1.26
################$$##
### pacman-5.0.2 ###
####################
# 6.0
# meson build
# ninja -C build
# ninja -C build install
# 5.0.2
tar xf pacman-5.0.2.tar.gz
cd pacman-5.0.2
./configure --prefix=/usr   \
            --disable-doc     \
            --disable-shared  \
            --sysconfdir=/etc \
            --localstatedir=/var
make
make install
cd ..
rm -rf pacman-5.0.2
##################################
### archlinux-keyring-20210902 ###
##################################
tar xf archlinux-keyring-20211028.tar.gz
cd archlinux-keyring-20211028
make PREFIX=/usr install
cd ..
rm -rf archlinux-keyring-20211028
#################
### popt-1.18 ###
#################
tar xf popt-1.18.tar.gz
cd popt-1.18
./configure --prefix=/usr --disable-static &&
make
make check
make install
cd ..
rm -rf popt-1.18
###################
### rsync-3.2.3 ###
###################
tar xf rsync-3.2.3.tar.gz
cd rsync-3.2.3
groupadd -g 48 rsyncd &&
useradd -c "rsyncd Daemon" -m -d /home/rsync -g rsyncd \
    -s /bin/false -u 48 rsyncd
./configure --prefix=/usr   \
            --disable-lz4      \
            --disable-xxhash   \
            --without-included-zlib &&
make
make check
make install
cd ..
rm -rf rsync-3.2.3
#################
### e2fsprogs ###
#################
tar xf e2fsprogs-1.46.4.tar.gz
cd e2fsprogs-1.46.4
mkdir -v build
cd       build
../configure --prefix=/usr     \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make
make check
make install
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
cd ../..
rm -rf e2fsprogs-1.46.4
############
### krb5 ###
############
tar xf krb5-1.19.2.tar.gz
cd krb5-1.19.2
cd src &&
sed -i -e 's@\^u}@^u cols 300}@' tests/dejagnu/config/default.exp     &&
sed -i -e '/eq 0/{N;s/12 //}'    plugins/kdb/db2/libdb2/test/run.test &&
sed -i '/t_iprop.py/d'           tests/Makefile.in                    &&
./configure --prefix=/usr          \
            --sysconfdir=/etc        \
            --localstatedir=/var/lib \
            --runstatedir=/run       \
            --with-system-et         \
            --with-system-ss         \
            --with-system-verto=no   \
            --enable-dns-for-realm &&
make
make install
cd ../..
rm -rf krb5-1.19.2
################
### keyutils ###
################
tar xf keyutils-1.6.1.tar.bz2
cd keyutils-1.6.1
sed -i 's:$(LIBDIR)/$(PKGCONFIG_DIR):/tools/lib/pkgconfig:' Makefile &&
make
make NO_ARLIB=1 LIBDIR=/usr/lib BINDIR=/usr/bin SBINDIR=/usr/sbin install
cd ..
rm -rf keyutils-1.6.1
###################
### berkeley-db ###
###################
tar xf db-5.3.28.tar.gz
cd db-5.3.28
sed -i 's/\(__atomic_compare_exchange\)/\1_db/' src/dbinc/atomic.h
cd build_unix                        &&
../dist/configure --prefix=/usr      \
                  --enable-compat185 \
                  --enable-dbm       \
                  --disable-static   \
                  --enable-cxx       &&
make
make docdir=/usr/share/doc/db-5.3.28 install &&
chown -v -R root:root                          \
      /usr/bin/db_*                          \
      /usr/include/db{,_185,_cxx}.h          \
      /usr/lib/libdb*.{so,la}                \
      /usr/share/doc/db-5.3.28
      
cd ../..
rm -rf db-5.3.28
###################
### grof-1.22.4 ###
###################
tar xf groff-1.22.4.tar.gz
cd groff-1.22.4
PAGE=letter ./configure --prefix=/usr
make -j1
make install
cd ..
rm -rf groff-1.22.4
### cyrus-sasl ###
##################
tar xf cyrus-sasl-2.1.27.tar.gz
cd cyrus-sasl-2.1.27
patch -Np1 -i ../cyrus-sasl-2.1.27-doc_fixes-1.patch
./configure --prefix=/usr      \
            --sysconfdir=/etc    \
            --enable-auth-sasldb \
            --with-dbpath=/var/lib/sasl/sasldb2 \
            --with-sphinx-build=no              \
            --with-saslauthd=/var/run/saslauthd &&
make -j1
make install &&
install -v -dm755                          /usr/share/doc/cyrus-sasl-2.1.27/html &&
install -v -m644  saslauthd/LDAP_SASLAUTHD /usr/share/doc/cyrus-sasl-2.1.27      &&
install -v -m644  doc/legacy/*.html        /usr/share/doc/cyrus-sasl-2.1.27/html &&
install -v -dm700 /var/lib/sasl
cd ..
rm -rf cyrus-sasl-2.1.27
################
### openldap ###
################
tar xf openldap-2.5.7.tgz
cd openldap-2.5.7
patch -Np1 -i ../openldap-2.5.7-consolidated-1.patch &&
autoconf &&
./configure --prefix=/usr   \
            --sysconfdir=/etc \
            --disable-static  \
            --enable-dynamic  \
            --enable-versioning  \
            --disable-debug   \
            --disable-slapd &&
make depend &&
make
make install
cd ..
rm -rf openldap-2.5.7
#############################
END
#############################



################
### striping ###
################
rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools

##############
### backup ###
##############
exit
umount $LFS/dev{/pts,}
umount $LFS/{sys,proc,run}
rm /tools
export LFS=/mnt/lfs
cd $LFS 
tar -cJpf $HOME/lfs11-pacman5.tar.xz .

###############
### restore ###
###############
su -
export LFS=/mnt/lfs
cd $LFS 
rm -rf ./* 
tar -xpf $HOME/lfs11-pacman5.tar.xz


