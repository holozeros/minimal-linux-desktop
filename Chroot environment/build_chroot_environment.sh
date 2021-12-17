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
../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=$LFS/lib   \
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
cp -rv usr/include/* /tools/include
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
      libc_cv_forced_unwind=yes          \
      libc_cv_c_cleanup=yes              \
      --with-headers=/tools/include      \
      libc_cv_slibdir=/tools/lib
make
make install
echo 'int main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep '/ld-linux'
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
cat > gcc11-fenv.patch << "EOF"
  GNU nano 5.9                  ../gcc11-fenv.patch                             
--- libstdc++-v3/include/c_compatibility/fenv.h 2021-07-28 15:55:09.292315320 +>
+++ ../fenv.h.custum    2021-12-09 16:23:23.135926080 +0900
@@ -26,15 +26,18 @@
  *  This is a Standard C++ Library header.
  */

+#include_next <fenv.h>
+
 #ifndef _GLIBCXX_FENV_H
 #define _GLIBCXX_FENV_H 1

 #pragma GCC system_header

 #include <bits/c++config.h>
-#if _GLIBCXX_HAVE_FENV_H
-# include_next <fenv.h>
-#endif
+
+//#if _GLIBCXX_HAVE_FENV_H
+//# include_next <fenv.h>
+//#endif

 #if __cplusplus >= 201103L
EOF
patch libstdc++-v3/include/c_compatibility/fenv.h < gcc11-fenv.patch 

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
######################
### binutils pass2 ###
######################
tar xf binutils-2.37.tar.xz 
cd binutils-2.37
mkdir -v build
cd       build
CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../configure                   \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot
make
make install
make -C ld clean
make -C ld LIB_PATH=/tools/lib:/lib
cp -v ld/ld-new /tools/bin
cd ../..
rm -rf  binutils-2.37
#################
### gcc pass2 ###
#################
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
    --enable-default-pie                           \
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
  #[Requesting program interpreter: /tools/lib/ld-linux.so.2]
rm -v dummy.c a.out
cd ../..
rm -rf gcc-11.2.0
###########
### tcl ###
###########
tar xf tcl8.6.11-src.tar.gz
cd tcl8.6.11
cd unix
./configure --prefix=/tools
make
make install
chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers
ln -sv tclsh8.6 /tools/bin/tclsh
cd ..
rm -rf tcl8.6.11
##############
### expect ###
##############
tar xf expect5.45.4.tar.gz 
cd expect5.45.4
cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure
./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include
make
make test
make SCRIPTS="" install
make test
cd ..
rm -rf expect5.45.4
###############
### dejagnu ###
###############
tar xf dejagnu-1.6.3.tar.gz 
cd dejagnu-1.6.3
./configure --prefix=/tools
make install
cd ..
rm -rf dejagnu-1.6.3
##########
### m4 ###
##########
tar xf m4-1.4.19.tar.xz 
cd m4-1.4.19
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
./configure --prefix=/tools
make make check
make install
cd ..
rm -rf m4-1.4.19
###############
### ncurses ###
###############
tar xf ncurses-6.2.tar.gz 
cd ncurses-6.2
sed -i s/mawk// configure
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite
make
make install
ln -s libncursesw.so /tools/lib/libncurses.so
cd ..
rm -rf ncurses-6.2
############
### bash ###
############
tar xf bash-5.1.8.tar.gz 
cd bash-5.1.8
./configure --prefix=/tools --without-bash-malloc
make
make test
make install
ln -sv bash /tools/bin/sh
cd ..
rm -rf bash-5.1.8
#############
### bison ###
#############
tar xf bison-3.7.6.tar.xz 
cd bison-3.7.6
./configure --prefix=/tools
make
make check
make install
cd ..
rm -rf bison-3.7.6
#############
### bzip2 ###
#############
tar xf bzip2-1.0.8.tar.gz 
cd bzip2-1.0.8
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/tools install
cp -v bzip2-shared /tools/bin/bzip2
cp -av libbz2.so* /tools/lib
ln -sv libbz2.so.1.0 /tools/lib/libbz2.so
cd ..
rm -rf bzip2-1.0.8
#################
### coreutils ###
#################
tar xf coreutils-8.32.tar.xz 
cd coreutils-8.32
./configure --prefix=/tools --enable-install-program=hostname
make
make RUN_EXPENSIVE_TESTS=yes check
make install
cd ..
rm -rf coreutils-8.32
#################
### diffutils ###
#################
tar xf diffutils-3.8.tar.xz 
cd diffutils-3.8
./configure --prefix=/tools
make
make check
make install
cd ..
rm -rf diffutils-3.8
############
### file ###
############
tar xf file-5.40.tar.gz 
cd file-5.40
./configure --prefix=/tools
make
make install
cd ..
rm -rf file-5.40
#################
### findutils ###
#################
tar xf findutils-4.8.0.tar.xz
cd findutils-4.8.0
./configure --prefix=/tools
make
make check
make install
cd ..
rm -rf findutils-4.8.0
############
### gawk ###
############
tar xf gawk-5.1.0.tar.xz 
cd gawk-5.1.0
./configure --prefix=/tools
make
make check
make install
cd ..
rm -rf gawk-5.1.0
###############
### gettext ###
###############
tar xf gettext-0.21.tar.xz 
cd gettext-0.21
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /tools/bin
cd ..
rm -rf gettext-0.21
############
### grep ###
############
tar xf grep-3.7.tar.xz 
cd grep-3.7
./configure --prefix=/tools
make
make check
make install
cd ..
rm -rf grep-3.7
############
### gzip ###
############
tar xf gzip-1.10.tar.xz 
cd gzip-1.10
./configure --prefix=/tools
make
make check
make install
cd ..
rm -rf gzip-1.10
############
### make ###
############
tar xf make-4.3.tar.gz 
cd make-4.3
./configure --prefix=/tools --without-guile
make
make check
make install
cd ..
rm -rf make-4.3
#############
### patch ###
#############
tar xf patch-2.7.6.tar.xz 
cd patch-2.7.6
./configure --prefix=/tools
make
make check
make install
cd ..
rm -rf patch-2.7.6
############
### perl ###
############
tar xf perl-5.34.0.tar.xz 
cd perl-5.34.0
sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth
cp -v perl cpan/podlators/scripts/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.34.0
cp -Rv lib/* /tools/lib/perl5/5.34.0
cd ..
rm -rf perl-5.34.0
##############
### python ###
##############
tar xf Python-3.9.6.tar.xz 
cd Python-3.9.6
sed -i '/def add_multiarch_paths/a \        return' setup.py
./configure --prefix=/tools --without-ensurepip
make
make install
cd ..
rm -rf Python-3.9.6
###########
### sed ###
###########
tar xf sed-4.8.tar.xz 
cd sed-4.8
./configure --prefix=/tools
make
make check
make install
cd ..
rm -rf sed-4.8
###########
### tar ###
###########
tar xf tar-1.34.tar.xz 
cd tar-1.34
./configure --prefix=/tools
make
make check
make install
cd ..
rm -rf tar-1.34
###############
### texinfo ###
###############
tar xf texinfo-6.8.tar.xz
cd texinfo-6.8
sed -e 's/__attribute_nonnull__/__nonnull/' \
    -i gnulib/lib/malloc/dynarray-skeleton.c
./configure --prefix=/tools
make
make check
make install
cd ..
rm -rf texinfo-6.8
##########
### xz ###
##########
tar xf xz-5.2.5.tar.xz
cd xz-5.2.5
./configure --prefix=/tools
make
make check
make install
cd ..
rm -rf xz-5.2.5
###############################
END
