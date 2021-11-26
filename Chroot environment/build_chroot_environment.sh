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
###############
### ncurses ###
###############
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
umount -v $LFS/dev/pts
umount -v $LFS/dev
umount -v $LFS/sys
umount -v $LFS/proc
umount -v $LFS/run


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

>>>>>>>>



#################
### tcl8.6.11 ###
#################

tar xf tcl8.6.11-src.tar.gz
cd tcl8.6.11

cd unix
./configure --prefix=/tools
make
# TZ=UTC make test
make install
chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers
ln -sv tclsh8.6 /tools/bin/tclsh

cd ../..
rm -rf tcl8.6.11

####################
### expect5.45.4 ###
####################

tar xf expect5.45.4.tar.gz
cd expect5.45.4

cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure
./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include
make
make SCRIPTS="" install
ln -s /tools/lib/expect5.45.4/libexpect5.45.4.so /tools/lib/libexpect-5.45.4.so

cd ..
rm -rf expect5.45.4

#####################
### dejagnu-1.6.3 ###
#####################

tar xf dejagnu-1.6.3.tar.gz
cd dejagnu-1.6.3

mkdir -v build
cd       build

../configure --prefix=/tools
make install

cd ../..
rm -rf dejagnu-1.6.3

####################
### check-0.15.2 ###
####################

tar xf check-0.15.2.tar.gz
cd check-0.15.2

PKG_CONFIG= ./configure --prefix=/tools
make
make install

cd ..
rm -rf check-0.15.2

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
./configure --prefix=/tools              \
            --mandir=/tools/share/man    \
            --with-shared                \
            --without-debug              \
            --without-ada                \
            --without-normal             \
            --enable-widec
make
make TIC_PATH=$(pwd)/build/progs/tic install
echo "INPUT(-lncursesw)" > /tools/lib/libncurses.so
ln -sr /tools/include/ncursesw/* /tools/include

cd ..
rm -rf ncurses-6.2

##################
### bash-5.1.8 ###
##################
tar xf bash-5.1.8.tar.gz
cd bash-5.1.8

./configure --prefix=/tools                 \
            --without-bash-malloc
make
make install
ln -sv bash /tools/bin/sh 

cd ..
rm -rf bash-5.1.8

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
make PREFIX=/tools install
cp -av libbz2.so.* /tools/lib
ln -sv libbz2.so.1.0.8 /tools/lib/libbz2.so
cp -v bzip2-shared /tools/bin/bzip2
for i in /tools/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /tools/lib/libbz2.a

cd ..
rm -rf bzip2-1.0.8

######################
### coreutils-8.32 ###
######################

tar xf coreutils-8.32.tar.xz
cd coreutils-8.32

./configure --prefix=/tools                   \
            --enable-install-program=hostname
make
# make RUN_EXPENSIVE_TESTS=yes check
make install
mv -v /tools/bin/chroot /tools/sbin
mkdir -pv /tools/share/man/man8
mv -v /tools/share/man/man1/chroot.1 /tools/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /tools/share/man/man8/chroot.8

cd ../
rm -rf coreutils-8.32

#####################
### diffutils-3.8 ###
#####################

tar xf diffutils-3.8.tar.xz
cd diffutils-3.8

./configure --prefix=/tools
make
# make check
make install

cd ..
rm -rf diffutils-3.8

#################
### file-5.40 ###
#################

tar xf file-5.40.tar.gz
cd file-5.40

./configure --prefix=/tools
make
make install

cd ..
rm -rf file-5.40

#######################
### findutils-4.8.0 ###
#######################

tar xf findutils-4.8.0.tar.xz
cd findutils-4.8.0

./configure --prefix=/tools
make
# make check
make install

cd ..
rm -rf findutils-4.8.0

##################
### gawk-5.1.0 ###
##################

tar xf gawk-5.1.0.tar.xz
cd gawk-5.1.0

./configure --prefix=/tools
make
make install

cd ..
rm -rf gawk-5.1.0

####################
### gettext-0.21 ###
####################

tar xf gettext-0.21.tar.xz
cd gettext-0.21

EMACS="no" ./configure --prefix=/tools --disable-shared
make

cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /tools/bin

cd ..
rm -rf gettext-0.21

################
### grep-3.7 ###
################

tar xf grep-3.7.tar.xz
cd grep-3.7

./configure --prefix=/tools
make
# make check
make install

cd ..
rm -rf grep-3.7

#################
### gzip-1.10 ###
#################

tar xf gzip-1.10.tar.xz
cd gzip-1.10

./configure --prefix=/tools
make
# make check
make install

cd ..
rm -rf gzip-1.10

#################
### m4-1.4.19 ###
#################

tar xf m4-1.4.19.tar.xz
cd m4-1.4.19

./configure --prefix=/tools
make
# make check
make install

cd ..
rm -rf m4-1.4.19

################
### make-4.3 ###
################

tar xf make-4.3.tar.gz
cd make-4.3

./configure --prefix=/tools --without-guile
make
# make check
make install

cd ..
rm -rf make-4.3

###################
### patch-2.7.6 ###
###################

tar xf patch-2.7.6.tar.xz
cd patch-2.7.6

./configure --prefix=/tools
make
# make check
make install

cd ..
rm -rf patch-2.7.6

###################
### perl-5.34.0 ###
###################

tar xf perl-5.34.0.tar.xz
cd perl-5.34.0

sh Configure -des                                          \
             -Dprefix=/tools                               \
             -Dlibs=-lm                                    \
             -Dvendorprefix=/tools                         \
             -Dprivlib=/tools/lib/perl5/5.34/core_perl     \
             -Darchlib=/tools/lib/perl5/5.34/core_perl     \
             -Dsitelib=/tools/lib/perl5/5.34/site_perl     \
             -Dsitearch=/tools/lib/perl5/5.34/site_perl    \
             -Dvendorlib=/tools/lib/perl5/5.34/vendor_perl \
             -Dvendorarch=/tools/lib/perl5/5.34/vendor_perl
make
# make test
make install
cp -v perl cpan/podlators/scripts/pod2man /tools/bin
cp -Rv lib/* /tools/lib/perl5/5.34

cd ..
rm -rf perl-5.34.0

###############
### sed-4.8 ###
###############

tar xf sed-4.8.tar.xz
cd sed-4.8

./configure --prefix=/tools
make
# make check
make install

cd ..
rm -rf sed-4.8

################
### tar-1.34 ###
################

cd $LFS/sources
tar xf tar-1.34.tar.xz
cd tar-1.34

./configure --prefix=/tools
make
# make check
make install

cd ..
rm -rf tar-1.34

####################
#### texinfo-6.8 ###
####################

tar xf texinfo-6.8.tar.xz
cd texinfo-6.8

sed -e 's/__attribute_nonnull__/__nonnull/' \
    -i gnulib/lib/malloc/dynarray-skeleton.c
./configure --prefix=/tools
make
make install

cd ..
rm -rf texinfo-6.8

###################
### bison-3.7.6 ###
###################

tar xf bison-3.7.6.tar.xz
cd bison-3.7.6

./configure --prefix=/tools
make
# make check
make install

cd ..
rm -rf bison-3.7.6

################
### xz-5.2.5 ###
################

tar xf xz-5.2.5.tar.xz
cd xz-5.2.5

./configure --prefix=/tools
make
# make check
make install

cd ..
rm -rf xz-5.2.5

####################
### Python-3.9.6 ###
####################

tar xf Python-3.9.6.tar.xz
cd Python-3.9.6

./configure --prefix=/tools   \
            --enable-shared   \
            --without-ensurepip
make
make install

cd ..
rm -rf Python-3.9.6

#########################
### util-linux-2.37.2 ###
#########################

tar xf util-linux-2.37.2.tar.xz
cd util-linux-2.37.2

mkdir -pv /var/lib/hwclock
./configure --prefix=/tools                                \
            ADJTIME_PATH=/var/lib/hwclock/adjtime          \
            --disable-static                               \
            --without-systemdsystemunitdir                 \
            --disable-makeinstall-chown                    \
            PKG_CONFIG=""
make
make install

cd ..
rm -rf util-linux-2.37.2

END
```
