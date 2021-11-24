## Build preparation
Follow to [the LFS book](https://www.linuxfromscratch.org/lfs/view/stable/) complete up to Chapter 4 of LFS.
In this section, I will briefly summarize up to Chapter 4 of the LFS book and supplement it a little. 

 The host OS should use live USB, as work mistakes can corrupt the host OS. 
 Follow those instructions in this order throughout.
 If the state of the shell changes due to interruption of work, you need to revert to the previous environment. 

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

    # mkfs.ext4 /dev/<new partition for building chroot environment>

Format of EFI System Partition is fat32.
If it doesn't exist, create a new one.

    # mkfs.vfat /dev/<EFI System Partition>

Mount the new partition for building chroot environment to /mnt/lfs. for example in case /dev/sda2

    mkdir -v /mnt/lfs
    
    # below directive is example, you shuld change the propery partition name 
    mount -v /dev/sda2 $LFS

## Checking host system requirement

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

    mkdir -v $LFS/tools
    mkdir -v $LFS/sources
    ln -sv $LFS/tools /
    chmod -v a+wt $LFS/sources

## Making local user in your host system

    groupadd lfs
    useradd -s /bin/bash -g lfs -m -k /dev/null lfs
```
passwd lfs
```
```
chown -v lfs $LFS/tools
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
    wget --no-check-certificate https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.46.tar.gz
    wget --no-check-certificate https://www.python.org/ftp/python/3.9.6/Python-3.9.6.tar.xz
    wget --no-check-certificate https://www.python.org/ftp/python/doc/3.9.6/python-3.9.6-docs-html.tar.bz2
    wget https://www.linuxfromscratch.org/lfs/view/stable/md5sums


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
    EOF

    pushd $LFS/sources
      md5sum -c md5sums
    popd

# Building chroot environment

In this section is different from the lfs-11.0 book. Here you need to install all of the chroot environment in the / tools directory. Test procedures that are possible but not required are commented out. Now start building the base for your chroot environment. We recommend that you install each package in stages, but you can also run a long script to install them all at once. If you want to install at once, create a script to build at once and execute it on the terminal. 
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

## BUILD (build-chroot-environment.sh)

Ryzen2700x(8 core) takes about 20 minuits.
```
cd $LFS/sources
chmod +x build-chroot-environment.sh
./build-chroot-environment.sh
```

## Strip

    rm -rf /tools/{,share}/{info,man,doc}

## Backup
```
# cd $LFS/tools
# tar -cJpf <Path>/tools-base-11.tar.xz .
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
When returning to the host, if /mnt/lfs/dev/pts, /mnt/lfs/dev, /mnt/lfs/sys, /mnt/lfs/proc, /mnt/lfs/run succeeds in unmounting, you can ignore the warning. It is important to check the dangerous elements once in this way, but after this checking, change the unmount script of the chroot script.

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
```
cat > build-ABS.sh << "END"
###################
### zlib-1.2.11 ###
###################

tar xf zlib-1.2.11.tar.xz
cd zlib-1.2.11

./configure --prefix=/tools
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

./configure --prefix=/tools    \
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

./configure --prefix=/tools        \
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

./configure --prefix=/tools    \
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

./configure --prefix=/tools                 \
     --with-system-libdir=/lib:/usr/lib     \
     --with-system-includedir=/include:/usr/include
make
make install
ln -sr /tools/bin/pkgconf /tools/usr/bin/pkg-config

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

./configure --prefix=/tools   \
            --disable-static  \
            --sysconfdir=/tools/etc 
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

./configure --prefix=/tools       \
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
make prefix=/tools lib=lib
make test
make prefix=/tools lib=lib install
chmod -v 755 /tools/lib/lib{cap,psx}.so.2.53

cd ..
rm -rf libcap-2.53

###################
### psmisc-23.4 ###
###################

tar xf psmisc-23.4.tar.xz
cd psmisc-23.4

./configure --prefix=/tools
make
make install

cd ..
rm -rf psmisc-23.4

#########################
### iana-etc-20210611 ###
#########################

tar xf iana-etc-20210611.tar.gz
cd iana-etc-20210611

cp services protocols /tools/etc

cd ..
rm -rf iana-etc-20210611

##################
### flex-2.6.4 ###
##################

tar xf flex-2.6.4.tar.gz
cd flex-2.6.4

./configure --prefix=/tools
make
make check
make install
ln -sv /tools/bin/flex /tools//bin/lex

cd ..
rm -rf flex-2.6.4

################
### bc-5.0.0 ###
################

tar xf bc-5.0.0.tar.xz
cd bc-5.0.0

CC=gcc ./configure --prefix=/tools -G -O3
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
./configure --prefix=/tools    \
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

./configure --prefix=/tools           \
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

./configure --prefix=/tools
make
# make check
make install
rm -fv /tools/lib/libltdl.a

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

./configure --prefix=/tools         \
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

../configure --prefix=/tools
make install
make check

cd ../..
rm -rf dejagnu-1.6.3

#################
### gdbm-1.20 ###
#################

tar xf gdbm-1.20.tar.gz
cd gdbm-1.20

./configure --prefix=/tools    \
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

./configure --prefix=/tools
make
make install

cd ..
rm -rf gperf-3.1

###################
### expat-2.4.1 ###
###################

tar xf expat-2.4.1.tar.xz
cd expat-2.4.1

./configure --prefix=/tools --disable-static
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

./configure --prefix=/tools            \
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
mv -v /tools/{,s}sbin/ifconfig

cd ..
rm -rf inetutils-2.1

ln -s /tools/etc/services /etc/
ln -s /tools/etc/protocols /etc/
ping -c 3 google.com

################
### less-590 ###
################

tar xf less-590.tar.gz
cd less-590

./configure --prefix=/tools --sysconfdir=/tools/etc
make
make install

cd ..
rm -rf less-590

######################
### elfutils-0.185 ###
######################

tar xf elfutils-0.185.tar.bz2
cd elfutils-0.185

./configure --prefix=/tools                \
            --disable-debuginfod           \
            --enable-libdebuginfod=dummy
make
# make check # FAIL: run-backtrace-native.sh
make -C libelf install
install -vm644 config/libelf.pc /tools/lib/pkgconfig
rm /tools/lib/libelf.a

cd ..
rm -rf elfutils-0.185

####################
### libffi-3.4.2 ###
####################

tar xf libffi-3.4.2.tar.gz
cd libffi-3.4.2

./configure --prefix=/tools          \
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

./config --prefix=/tools                   \
         --openssldir=/etc/ssl             \
         --libdir=lib                      \
         shared                            \
         zlib-dynamic
make
make test
sed -i '/INSTALL_LIBS/s/libcrypto.a lmv /tools/etc/protocols /tools/etc/ibssl.a//' Makefile
make MANSUFFIX=ssl install
mv -v /tools/share/doc/openssl /tools/share/doc/openssl-1.1.1l

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
             -Dprefix=/tools                                \
             -Dvendorprefix=/tools                          \
             -Dprivlib=/tools/lib/perl5/5.34/core_perl      \
             -Darchlib=/tools/lib/perl5/5.34/core_perl      \
             -Dsitelib=/tools/lib/perl5/5.34/site_perl      \
             -Dsitearch=/tools/lib/perl5/5.34/site_perl     \
             -Dvendorlib=/tools/lib/perl5/5.34/vendor_perl  \
             -Dvendorarch=/tools/lib/perl5/5.34/vendor_perl \
             -Dman1dir=/tools/share/man/man1                \
             -Dman3dir=/tools/share/man/man3                \
             -Dpager="/tools/bin/less -isR"                 \
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
./configure --prefix=/tools
make
make check
make install
install -v -Dm644 doc/I18N-HOWTO /tools/share/doc/intltool-0.51.0/I18N-HOWTO

cd ..
rm -rf intltool-0.51.0

#####################
### autoconf-2.71 ###
#####################

tar xf autoconf-2.71.tar.xz
cd autoconf-2.71

./configure --prefix=/tools
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

./configure --prefix=/tools --docdir=/tools/share/doc/automake-1.16.4
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

./configure --prefix=/tools
make
make check
make install
rm -fv /tools/lib/libltdl.a

cd ..
rm -rf libtool-2.4.6

##################
### zstd-1.5.0 ###
##################

tar xf zstd-1.5.0.tar.gz
cd zstd-1.5.0

make
make check
make prefix=/tools install
rm -v /tools/lib/libzstd.a
ln -sr /tools/bin/zstd /usr/bin/

cd ..
rm -rf zstd-1.5.0

###############
### kmod-29 ###
###############

tar xf kmod-29.tar.xz
cd kmod-29

./configure --prefix=/tools              \
            --sysconfdir=/etc            \
            --with-xz                    \
            --with-zstd                  \
            --with-zlib
make
make install
for target in depmod insmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /tools/sbin/$target
done

ln -sfv kmod /tools/bin/lsmod

cd ..
rm -rf kmod-29

####################
### Python-3.9.6 ###
####################

tar xf Python-3.9.6.tar.xz
cd Python-3.9.6

./configure --prefix=/tools        \
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
install -vm755 ninja /tools/bin/
install -vDm644 misc/bash-completion /tools/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /tools/share/zsh/site-functions/_ninja

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
install -vDm644 data/shell-completions/bash/meson /tools/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /tools/share/zsh/site-functions/_meson

cd ..
rm -rf meson-0.59.1

#######################
### libtasn1-4.17.0 ###
#######################

tar xf libtasn1-4.17.0.tar.gz
cd libtasn1-4.17.0

./configure --prefix=/tools --disable-static
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
./configure --prefix=/tools --disable-static
make
make install

cd ..
rm -rf libuv-v1.42.0

######################
### libxml2-2.9.12 ###
######################

tar xf libxml2-2.9.12.tar.gz
cd libxml2-2.9.12

./configure --prefix=/tools    \
            --disable-static   \
            --with-history     \
            --with-python=/tools/bin/python3
make
make install

cd ..
rm -rf libxml2-2.9.12

######################
### nghttp2-1.44.0 ###
######################

tar xf nghttp2-1.44.0.tar.xz
cd nghttp2-1.44.0

./configure --prefix=/tools   \
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

make DESTDIR=/tools install
install -vdm755 /etc/ssl/local
#/tools/sbin/make-ca -g

mv -v /tools/usr/sbin/make-ca /tools/sbin
mv -v /tools/usr/libexec/make-ca /tools/libexec/

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
/tools/libexec/make-ca/copy-trust-modifications
# Generate a new trust store
/tools/sbin/make-ca -f -g
EOF
mkdir p11-build
cd    p11-build

meson --prefix=/tools       \
      --buildtype=release   \
      -Dtrust_paths=/etc/pki/anchors
ninja
ninja test
ninja install &&
ln -sfv /tools/libexec/p11-kit/trust-extract-compat \
        /tools/bin/update-ca-certificates
ln -sfv ./pkcs11/p11-kit-trust.so /tools/lib/libnssckbi.so

cd ../..
rm -rf p11-kit-0.24.0

cd /usr/bin
ln -s /tools/bin/cut
ln -s /tools/bin/openssl
ln -s /tools/bin/md5sum
ln -s /tools/bin/trust
cd /sources
make-ca -g

###################
### Wget-1.21.1 ###
###################

tar xf wget-1.21.1.tar.gz
cd wget-1.21.1

./configure --prefix=/tools      \
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
./configure --prefix=/tools                         \
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

./configure --prefix=/tools --disable-static &&
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

./bootstrap --prefix=/tools      \
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

./configure --prefix=/tools
make
make install

cd ..
rm -rf libgpg-error-1.42

#######################
### libassuan-2.5.5 ###
#######################

tar xf libassuan-2.5.5.tar.bz2
cd libassuan-2.5.5

./configure --prefix=/tools
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
./configure --prefix=/tools --disable-gpg-test
make
make install

cd ..
rm -rf gpgme-1.16.0

################
### npth-1.6 ###
################

tar xf npth-1.6.tar.bz2
cd npth-1.6

./configure --prefix=/tools
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

./configure --prefix=/tools
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

./configure --prefix=/tools
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
  --prefix=/tools \
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

./configure --prefix=/tools --enable-pinentry-tty
make
make install

cd ..
rm -rf pinentry-1.2.0

####################
### nettle-3.7.3 ###
####################

tar xf nettle-3.7.3.tar.gz
cd nettle-3.7.3
./configure --prefix=/tools --disable-static
make
make check
make install
chmod   -v   755 /tools/lib/lib{hogweed,nettle}.so
install -v -m755 -d /tools/share/doc/nettle-3.7.3 &&
install -v -m644 nettle.html /tools/share/doc/nettle-3.7.3

cd ..
rm -fr nettle-3.7.3

###########################
### libunistring-0.9.10 ###
###########################

tar xf libunistring-0.9.10.tar.xz
cd libunistring-0.9.10

./configure --prefix=/tools  \
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

./configure --prefix=/tools                  \
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

./configure --prefix=/tools          \
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

 ./configure --prefix=/tools \
    --libdir=/tools/lib/libfakeroot \
    --disable-static \
    --with-ipc=sysv
make
make install
install -dm0755 /tools/etc/ld.so.conf.d/
echo '/tools/lib/libfakeroot' > /tools/etc/ld.so.conf.d/fakeroot.conf

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

./configure --prefix=/tools   \
            --disable-doc     \
            --disable-shared  \
            --sysconfdir=/tools/etc \
            --localstatedir=/tools/var
make
make install

cd ..
rm -rf pacman-5.0.2

##################################
### archlinux-keyring-20210902 ###
##################################

tar xf archlinux-keyring-20210902.tar.gz
cd archlinux-keyring-20210902

make PREFIX=/tools install

cd ..
rm -rf archlinux-keyring-20210903

#################
### popt-1.18 ###
#################

tar xf popt-1.18.tar.gz
cd popt-1.18

./configure --prefix=/tools --disable-static &&
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
./configure --prefix=/tools    \
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

../configure --prefix=/tools         \
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
gunzip -v /tools/share/info/libext2fs.info.gz
install-info --dir-file=/tools/share/info/dir /tools/share/info/libext2fs.info

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

./configure --prefix=/tools          \
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
make NO_ARLIB=1 LIBDIR=/tools/lib BINDIR=/toolsr/bin SBINDIR=/tools/sbin install

cd ..
rm -rf keyutils-1.6.1

###################
### berkeley-db ###
###################
 
tar xf db-5.3.28.tar.gz
cd db-5.3.28

sed -i 's/\(__atomic_compare_exchange\)/\1_db/' src/dbinc/atomic.h
cd build_unix                        &&
../dist/configure --prefix=/tools    \
                  --enable-compat185 \
                  --enable-dbm       \
                  --disable-static   \
                  --enable-cxx       &&
make

make docdir=/tools/share/doc/db-5.3.28 install &&
chown -v -R root:root                          \
      /tools/bin/db_*                          \
      /tools/include/db{,_185,_cxx}.h          \
      /tools/lib/libdb*.{so,la}                \
      /tools/share/doc/db-5.3.28
      
cd ../..
rm -rf db-5.3.28

##################
### cyrus-sasl ###
##################

tar xf cyrus-sasl-2.1.27.tar.gz
cd cyrus-sasl-2.1.27

patch -Np1 -i ../cyrus-sasl-2.1.27-doc_fixes-1.patch
./configure --prefix=/tools      \
            --sysconfdir=/etc    \
            --enable-auth-sasldb \
            --with-dbpath=/var/lib/sasl/sasldb2 \
            --with-sphinx-build=no              \
            --with-saslauthd=/var/run/saslauthd &&
make -j1
make install &&
install -v -dm755                          /tools/share/doc/cyrus-sasl-2.1.27/html &&
install -v -m644  saslauthd/LDAP_SASLAUTHD /tools/share/doc/cyrus-sasl-2.1.27      &&
install -v -m644  doc/legacy/*.html        /tools/share/doc/cyrus-sasl-2.1.27/html &&
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

./configure --prefix=/tools   \
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
```

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

