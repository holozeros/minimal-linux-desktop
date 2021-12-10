cat > abs_build.sh << "END"
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
make prefix=/tools lib=lib sysconfdir=/tools/etc SBINDIR=/tools/sbin PAM_CAP=no
make test PAM_CAP=no
make prefix=/tools lib=lib sysconfdir=/tools/etc SBINDIR=/tools/sbin install PAM_CAP=no
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
ping -c 3 google.com
################
### less-590 ###
################
tar xf less-590.tar.gz
cd less-590
./configure --prefix=/usr --sysconfdir=/etc
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
sed -i '/INSTALL_LIBS/s/libcrypto.a//' Makefile
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
echo '/usr/lib/libfakeroot' > /etc/ld.so.conf.d/fakeroot.conf
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
