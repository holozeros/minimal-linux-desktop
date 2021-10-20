## Build preparation

This part is refer to lfs-11.0 book.
The host OS should use live USB, as work mistakes can corrupt the host OS. 
Follow those instructions in this order throughout.
If the state of the shell changes due to interruption of work, you need to revert to the previous environment. 

    su -

Below directive is very important, because $LFS is used frequently in many directives.
If $LFS is empty, there is a risk of destroying the host. 

    export LFS=/mnt/lfs

For new creation root file system partition: ext4.
That physical strage shuld be SATA or M.2, not USB strage.
This chroot environment will eventually become the root partition of a bootable linux OS.
Partition of the USB storage will not be perhaps recognized by a stub kernel at boot time without initramfs, but initramfs is can not support yet.
Therefore, the chroot environment should be built on an SSD or HDD partition with a SATA or M.2 connection. 

    # mkfs.ext4 /dev/<new root file system partition>

ETI System Partition: fat32.
If it doesn't exist, create a new one.

    # mkfs.vfat /dev/<EFI System Partition>

Mount the partition formated ext4 to /mnt/lfs. for example in case /dev/sda2 is the target partition:

    mkdir -v /mnt/lfs
    
    # below directive is examle, you shuld cheng the propery real partition name 
    mount -v /dev/sda2 $LFS

## checking host system requirement

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

Run below shell script and check outputs of script.

    bash version-check.sh

## bash setting

    [ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

## directory settings

    export LFS=/mnt/lfs
    # mount /dev/<For new creation root file system partition> $LFS

    mkdir -v $LFS/tools
    mkdir -v $LFS/sources
    ln -sv $LFS/tools /
    chmod -v a+wt $LFS/sources

## making local user in your host system

    groupadd lfs
    useradd -s /bin/bash -g lfs -m -k /dev/null lfs
    passwd lfs

    chown -v lfs $LFS/tools

    su - lfs
    
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

## downloading sources

    export LFS=/mnt/lfs
    cd $LFS/sources

    wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list
    wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
    wget https://www.linuxfromscratch.org/lfs/view/stable/md5sums
    wget --no-check-certificate https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.46.tar.gz

If there are some tarballs that could not be downloaded automatically from the list, 
check the download address with LFS-11.0 Book or Google search and make up for it manually. 

## additional sources for arch build system

    cd $LFS/sources

The following downloads refer to BeyondLinux® FromScratch (System V Edition) version 11.0, Archlinux PKGBLD, etc.

    wget https://sources.archlinux.org/other/pacman/pacman-5.0.2.tar.gz
    wget http://ftp.debian.org/debian/pool/main/f/fakeroot/fakeroot_1.26.orig.tar.gz
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

This system uses ABS to build custom packages and installs using pacman, 
so it doesn't require an archlinux repository, but it also allows you to build an archlinux distribution using only pacman.
Please verify md5sum arbitrarily. 

    cat >> $LFS/sources/md5sums << "EOF" 
    f36f5e7e95a89436febe1bcca874fc33  pacman-5.0.2.tar.gz
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
    EOF

    pushd $LFS/sources
      md5sum -c md5sums
    popd



The bellow instructions are different from the lfs-11.0 book.
Here we should install the chroot environment in /tools directory.
Test procedures that are possible but not required are commented out. 
Now,begining build the base of chroot environment.
It's best to install each package step by step, but you can also run a long script to install it all at once. 
If install it all at once, create a script that builds at once, then execute the script on the terminal.
```

cd $LFS/sources

cat > build-chroot-environment.sh << "END"
###########################
### binutils-2.37-pass1 ###
###########################

tar xf binutils-2.37.tar.xz
cd binutils-2.37

mkdir -v build
cd       build
../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror
make
case $(uname -m) in
  x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
esac
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

for file in gcc/config/{linux,i386/linux{,64}}.h
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

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
    --prefix=/tools                                \
    --with-glibc-version=2.11                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --enable-initfini-array                        \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libmpx                               \
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
cp -rv usr/include /tools

cd ..
rm -rf linux-5.13.12

##################
### glibc-2.34 ###
##################

tar xf glibc-2.34.tar.xz
cd glibc-2.34

patch -Np1 -i ../glibc-2.34-fhs-1.patch
mkdir -v build
cd       build
echo "rootsbindir=/tools/sbin" > configparms
../configure                             \
      --prefix=/tools                    \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2                \
      --with-headers=/tools/include      \
      libc_cv_slibdir=/tools/lib         \
      libc_cv_forced_unwind=yes          \
      libc_cv_c_cleanup=yes
make
make install
sed '/RTLDLIST=/s@/tools@@g' -i /tools/bin/ldd

echo 'int main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools'
	# [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
rm -v dummy.c a.out

/tools/libexec/gcc/$LFS_TGT/11.2.0/install-tools/mkheaders

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
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/11.2.0

make
make install

cd ../..
rm -rf gcc-11.2.0

###########################
### binutils-2.37-pass2 ###
###########################

tar xf binutils-2.37.tar.xz
cd binutils-2.37

mkdir -v build
cd       build

CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../configure                   \
    --prefix=/tools            \
    --with-sysroot             \
    --with-lib-path=/tools/lib \
    --enable-64-bit-bfd        \
    --disable-nls              \
    --disable-werror
make
make install
make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin

cd ../..
rm -rf binutils-2.37

########################
### GCC-11.2.0-pass2 ###
########################

tar xf gcc-11.2.0.tar.xz
cd gcc-11.2.0

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

for file in gcc/config/{linux,i386/linux{,64}}.h
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

tar -xf ../mpfr-4.1.0.tar.xz
mv -v mpfr-4.1.0 mpfr
tar -xf ../gmp-6.2.1.tar.xz
mv -v gmp-6.2.1 gmp
tar -xf ../mpc-1.2.1.tar.gz
mv -v mpc-1.2.1 mpc

mkdir -v build
cd       build

CC=$LFS_TGT-gcc                                    \
CXX=$LFS_TGT-g++                                   \
AR=$LFS_TGT-ar                                     \
RANLIB=$LFS_TGT-ranlib                             \
../configure                                       \
    --prefix=/tools                                \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --enable-languages=c,c++                       \
    --disable-libstdcxx-pch                        \
    --disable-multilib                             \
    --disable-bootstrap                            \
    --disable-libgomp
make
make install
ln -sv gcc /tools/bin/cc

echo 'int main(){}' > dummy.c
cc dummy.c
readelf -l a.out | grep ': /tools'
#	[Requesting program interpreter: /tools/lib/ld-linux.so.2]
rm -v dummy.c a.out

cd ../..
rm -rf gcc-11.2.0

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

## BUILD (build-chroot-environment.sh)

Ryzen2700x(8 core) takes about 20 minuits.
```
cd $LFS/sources
chmod +x build-chroot-environment.sh
./build-chroot-environment.sh
```

## strip

    rm -rf /tools/{,share}/{info,man,doc}

## backup
```
# cd $LFS/tools
# tar -cJpf <Path>/tools11-base.tar.xz .
# sync
# cd $LFS/sources
```

## When starting over from here in a later step

As root user.
```
# export $LFS
# mount /dev/<For new creation root file system partition> $LFS
# cd $LFS
# rm -rf tools && mkdir tools && cd tools
# chown -v lfs $LFS/tools
# tar -xpf <Path>/tools11-base.tar.xz
```

## chroot

changeing to root user
```
exit

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
umount -lR /mnt/lfs/*
```
## return to the host environment.Issue:
    exit
Because all directories in $LFS are unmounted for safety confirmation, output of exit display some warnnings.

# This is very important !
        
If returned the host environment, to check the mount status. Issue:

    mount

Look at the output of mount, make sure the following directories are not mounted.
```
/mnt/lfs/dev
/mnt/lfs/sys
/mnt/lfs/proc
/mnt/lfs/run
```

If left mounted kernel's virtual file systems on these deirectories, the storage and hardware of the host PC will be damaged.
If you cannot unmount these, interrupt further operations and reboot the host immediately. 

If return the host and /mnt/lfs/dev,/mnt/lfs/sys/,/mnt/lfs/proc/,/mnt/lfs/run had been succsesed unmount, 
you're safely back on the host, you can ignore some warnnings of the exit output in the chroot environment. 
