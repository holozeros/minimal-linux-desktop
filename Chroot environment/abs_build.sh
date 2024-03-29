cat > abs_build.sh << "END"
#######################
### libstdc++ pass2 ###
#######################
cd /sources
tar xf gcc-11.2.0.tar.xz
cd gcc-11.2.0
cat > fenv.h << "EOF"
#include_next <fenv.h>
#ifndef _GLIBCXX_FENV_H
#define _GLIBCXX_FENV_H 1
#pragma GCC system_header
#include <bits/c++config.h>
//#if _GLIBCXX_HAVE_FENV_H
//# include_next <fenv.h>
//#endif
#if __cplusplus >= 201103L
#if _GLIBCXX_USE_C99_FENV_TR1
#undef feclearexcept
#undef fegetexceptflag
#undef feraiseexcept
#undef fesetexceptflag
#undef fetestexcept
#undef fegetround
#undef fesetround
#undef fegetenv
#undef feholdexcept
#undef fesetenv
#undef feupdateenv
namespace std
{
  // types
  using ::fenv_t;
  using ::fexcept_t;

  // functions
  using ::feclearexcept;
  using ::fegetexceptflag;
  using ::feraiseexcept;
  using ::fesetexceptflag;
  using ::fetestexcept;
  using ::fegetround;
  using ::fesetround;
  using ::fegetenv;
  using ::feholdexcept;
  using ::fesetenv;
  using ::feupdateenv;
} // namespace
#endif // _GLIBCXX_USE_C99_FENV_TR1
#endif // C++11
#endif // _GLIBCXX_FENV_H
EOF
cp ../fenv.h libstdc++-v3/include/c_compatibility/fenv.h
ln -s gthr-posix.h libgcc/gthr-default.h
mkdir -v build
cd       build
../libstdc++-v3/configure            \
    CXXFLAGS="-g -O2 -D_GNU_SOURCE"  \
    --prefix=/tools                  \
    --disable-multilib               \
    --disable-nls                    \
    --host=$(uname -m)-pc-linux-gnu  \
    --disable-libstdcxx-pch
make
make install
cd ../..
rm -rf gcc-11.2.0
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
#############
### bisom ###
#############
tar xf bison-3.7.6.tar.xz 
cd bison-3.7.6
./configure --prefix=/tools
make
make install
cd ..
rm -rf bison-3.7.6
###################
### perl-5.34.0 ###
###################
tar xf perl-5.34.0.tar.xz
cd perl-5.34.0
sh Configure -des                                          \
             -Dprefix=/tools                               \
             -Dvendorprefix=/tools                         \
             -Dprivlib=/tools/lib/perl5/5.34/core_perl     \
             -Darchlib=/tools/lib/perl5/5.34/core_perl     \
             -Dsitelib=/tools/lib/perl5/5.34/site_perl     \
             -Dsitearch=/tools/lib/perl5/5.34/site_perl    \
             -Dvendorlib=/tools/lib/perl5/5.34/vendor_perl \
             -Dvendorarch=/tools/lib/perl5/5.34/vendor_perl
make
make install
cd ..
rm -rf perl-5.34.0
##############
### python ###
##############
tar xf Python-3.9.6.tar.xz 
cd Python-3.9.6
./configure --prefix=/tools \
            --enable-shared \
            --without-ensurepip
make
make install
cd ..
rm -rf Python-3.9.6
###############
### texinfo ###
###############
tar xf texinfo-6.8.tar.xz 
cd texinfo-6.8
sed -e 's/__attribute_nonnull__/__nonnull/' \
    -i gnulib/lib/malloc/dynarray-skeleton.c
./configure --prefix=/tools --without-perl
make
make install
cd ..
rm -rf texinfo-6.8
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
#############
### bzip2 ###
#############
tar xf bzip2-1.0.8.tar.gz 
cd bzip2-1.0.8
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
mwke
make PREFIX=/tools install
cp -av libbz2.so.* /tppls/lib
ln -sv libbz2.so.1.0.8 /tools/lib/libbz2.so
cp -v bzip2-shared /tools/bin/bzip2
for i in /tools/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /tools/lib/libbz2.a
cd ..
rm -rf bzip2-1.0.8
##########
### xz ###
##########
tar xf xz-5.2.5.tar.xz 
cd xz-5.2.5
./configure --prefix=/tools  \
            --host=x86_64-pc-linux-gnu \
            --disable-static
make
make check
make install
cd ..
rm -rf xz-5.2.5
#########################
### util-linux-2.37.2 ###
#########################
tar xf util-linux-2.37.2.tar.xz
cd util-linux-2.37.2
mkdir -pv /tools/var/lib/hwclock
mkdir -pv /tools/run
./configure ADJTIME_PATH=/tools/var/lib/hwclock/adjtime    \
            --prefix=/tools      \
            --with-sysroot=/tools  \
            --libdir=/tools/lib    \
            --docdir=/tools/share/doc/util-linux-2.37.2 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            --without-systemd    \
            runstatedir=/tools/run
make
make install
cd ..
rm -rf util-linux-2.37.2
####################
### check-0.15.2 ###
####################
tar xf check-0.15.2.tar.gz
cd check-0.15.2
./configure --prefix=/tools --disable-static
make
make check
make install
cd ..
rm -rf check-0.15.2
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
     --with-system-libdir=/tools/lib        \
     --with-system-includedir=/tools/include
make
make install
ln -sr /tools/bin/pkgconf /tools/bin/pkg-config
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
make prefix=/tools lib=lib sysconfdir=/tools/etc SBINDIR=/tools/sbin
make test
make prefix=/tools lib=lib sysconfdir=/tools/etc SBINDIR=/tools/sbin install
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
cd ..
rm -rf readline-8.1
ldconfig
################
### nano-5.8 ###
################
tar xf nano-5.8.tar.xz
cd nano-5.8
./configure --prefix=/tools             \
            --sysconfdir=/tools/etc         \
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
make check
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
touch /tools/bin/passwd
sed -i 's/1000/999/' etc/useradd
./configure --prefix=/tools         \
            --sysconfdir=/etc \
            --with-group-name-max-length=32
make
make install
mkdir -p /etc/default
/tools/sbin/useradd -D --gid 999
/tools/sbin/pwconv
/tools/sbin/grpconv
sed -i 's/yes/no/' /etc/default/useradd
cd ..
rm -rf shadow-4.9
/tools/bin/passwd root
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
            --bindir=/tools/bin        \
            --localstatedir=/tools/var \
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
mv -v /tools/{,s}bin/ifconfig
cd ..
rm -rf inetutils-2.1
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
make check # FAIL: run-backtrace-native.sh
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
         --openssldir=/tools/etc/ssl       \
         --libdir=lib                      \
         shared                            \
         zlib-dynamic
make
make test
sed -i '/INSTALL_LIBS/s/libcrypto.a//' Makefile
make MANSUFFIX=ssl install
mv -v /tools/share/doc/openssl /tools/share/doc/openssl-1.1.1l
cd ..
rm -rf openssl-1.1.1l
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
            --sysconfdir=/tools/etc      \
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
./configure --prefix=/tools     \
            --disable-static  \
            --enable-lib-only \
            --docdir=/tools/share/doc/nghttp2-1.44.0
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
install -vdm755 /tools/etc/ssl/local
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
      -Dtrust_paths=/tools/etc/pki/anchors
ninja
ninja test
ninja install &&
ln -sfv /tools/libexec/p11-kit/trust-extract-compat \
        /tools/bin/update-ca-certificates
ln -sfv ./pkcs11/p11-kit-trust.so /tools/lib/libnssckbi.so
cd ../..
rm -rf p11-kit-0.24.0
/tools/usr/sbin/make-ca -g
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
            --with-ca-path=/tools/etc/ssl/certs &&
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
./configure --prefix=/tools   \
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
            --localstatedir=/tools/var     \
            --sysconfdir=/tools/etc
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
echo '/usr/lib/libfakeroot' > /tools/etc/ld.so.conf.d/fakeroot.conf
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
tar xf archlinux-keyring-20211028.tar.gz
cd archlinux-keyring-20211028
make PREFIX=/tools install
cd ..
rm -rf archlinux-keyring-20211028
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
./configure --prefix=/tools   \
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
../configure --prefix=/tools     \
             --sysconfdir=/tools/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make
make check
make install
rm -fv /tools/lib/{libcom_err,libe2p,libext2fs,libss}.a
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
            --sysconfdir=/tools/etc  \
            --localstatedir=/tools/var/lib \
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
make NO_ARLIB=1                      \
     LIBDIR=/tools/lib               \
     BINDIR=/tools/bin               \
     SBINDIR=/tools/sbin             \
     INCLUDEDIR=/tools/include       \
     SYSCONFDIR=/tools/etc           \
     SHAREDIR=/tools/share/keyutils  \
     MANDIR=/tools/share/man         \
     install
cd ..
rm -rf keyutils-1.6.1
###################
### berkeley-db ###
###################
tar xf db-5.3.28.tar.gz
cd db-5.3.28
sed -i 's/\(__atomic_compare_exchange\)/\1_db/' src/dbinc/atomic.h
cd build_unix                        &&
../dist/configure --prefix=/tools      \
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
###################
### grof-1.22.4 ###
###################
tar xf groff-1.22.4.tar.gz
cd groff-1.22.4
PAGE=letter ./configure --prefix=/tools
make -j1
make install
cd ..
rm -rf groff-1.22.4
##################
### cyrus-sasl ###
##################
tar xf cyrus-sasl-2.1.27.tar.gz
cd cyrus-sasl-2.1.27
patch -Np1 -i ../cyrus-sasl-2.1.27-doc_fixes-1.patch
./configure --prefix=/tools      \
            --sysconfdir=/tools/etc    \
            --enable-auth-sasldb \
            --with-dbpath=/tools/var/lib/sasl/sasldb2 \
            --with-sphinx-build=no              \
            --with-saslauthd=/tools/var/run/saslauthd &&
make -j1
make install &&
install -v -dm755                          /tools/share/doc/cyrus-sasl-2.1.27/html &&
install -v -m644  saslauthd/LDAP_SASLAUTHD /tools/share/doc/cyrus-sasl-2.1.27      &&
install -v -m644  doc/legacy/*.html        /tools/share/doc/cyrus-sasl-2.1.27/html &&
install -v -dm700 /tools/var/lib/sasl
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
            --sysconfdir=/tools/etc \
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
