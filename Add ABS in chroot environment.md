# prepere
On the terminal of the host

    su - 

Makesure that the partition of chroot environment mount to /mnt/lfs

    lsblk

if already mounted the partition of chroot environment mount to /mnt/lfs, do chroot in the chroot environment
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
umount -lR /mnt/lfs/*
```

## Settings the filesystem
```
ln -sv /usr/bin /bin
ln -sv /tools/bin/{bash,cat,echo,env,pwd,stty,uname} /usr/bin
ln -sv /tools/bin/bash /usr/bin/sh
ln -sv /tools/bin/perl /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib
ln -sv /tools/lib /tools/usr/lib
ln -sv /tools/include /tools/usr/include
ln -sv /tools/include/ncursesw/ncurses.h /tools/include/
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

./configure --prefix=/usr
make
make check
make DESTDIR=/tools install

cd ..
rm -rf zlib-1.2.11

#################
### gmp-6.2.1 ###
#################

tar xf gmp-6.2.1.tar.xz
cd gmp-6.2.1

./configure --prefix=/usr    \
            --enable-cxx       \
            --disable-static   \
            --docdir=/share/doc/gmp-6.2.1
make
make check 2>&1 | tee gmp-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log

#	 197

make DESTDIR=/tools install

cd ..
rm -rf gmp-6.2.1

cd /usr/lib
ln -s /tools/lib/libgmp.la
ln -s /tools/lib/libgmp.so
cd $LFS/sources

##################
### mpfr-4.1.0 ###
##################

tar xf mpfr-4.1.0.tar.xz
cd mpfr-4.1.0

./configure --prefix=/usr        \
            --disable-static       \
            --enable-thread-safe   \
            --docdir=/share/doc/mpfr-4.1.0
make
make check
make DESTDIR=/tools install

cd ..
rm -rf mpfr-4.1.0

#################
### mpc-1.2.1 ###
#################

tar xf mpc-1.2.1.tar.gz
cd mpc-1.2.1

./configure --prefix=/usr    \
            --disable-static   \
            --docdir=/share/doc/mpc-1.2.1
make
make check
make DESTDIR=/tools install

cd ..
rm -rf mpc-1.2.1

#########################
### pkg-config-0.29.2 ###
#########################

tar xf pkg-config-0.29.2.tar.gz
cd pkg-config-0.29.2

./configure --prefix=/usr              \
            --with-internal-glib         \
            --disable-host-tool          \
            --docdir=/share/doc/pkg-config-0.29.2
make
make check
make DESTDIR=/tools install

cd ..
rm -rf pkg-config-0.29.2

##################
### attr-2.5.1 ###
##################

tar xf attr-2.5.1.tar.gz
cd attr-2.5.1

./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/share/doc/attr-2.5.1
make
make check
make DESTDIR=/tools install

cd ..
rm -rf attr-2.5.1

#################
### acl-2.3.1 ###
#################

tar xf acl-2.3.1.tar.xz
cd acl-2.3.1

./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/share/doc/acl-2.3.1
make
make DESTDIR=/tools install

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
make prefix=/tools lib=lib install
chmod -v 755 /tools/lib/lib{cap,psx}.so.2.53

cd ..
rm -rf libcap-2.53

###################
### psmisc-23.4 ###
###################

cd /tools/include
ln -s /tools/include/ncursesw/term.h
ln -s /tools/include/ncursesw/curses.h

cd $LFS/sources
tar xf psmisc-23.4.tar.xz
cd psmisc-23.4

./configure --prefix=/usr
make
make DESTDIR=/tools install
mv -v /tools/usr/bin/fuser   /tools/bin
mv -v /tools/usr/bin/killall /tools/bin

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

./configure --prefix=/usr
make
make check
make DESTDIR=/tools  install
ln -sv /tools/usr/bin/flex /tools/usr/bin/lex

cd ..
rm -rf flex-2.6.4

################
### bc-5.0.0 ###
################

cd $LFS/sources
tar xf bc-5.0.0.tar.xz
cd bc-5.0.0

CC=gcc ./configure --prefix=/usr -G -O3
make
make test
make DESTDIR=/tools install

cd ..
rm -rf bc-5.0.0

####################
### readline-8.1 ###
####################

tar xf readline-8.1.tar.gz
cd readline-8.1

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr    \
            --disable-static   \
            --with-curses      \
            --docdir=/share/doc/readline-8.1
make SHLIB_LIBS="-lncursesw"
make DESTDIR=/tools SHLIB_LIBS="-lncursesw" install
ldconfig

cd ..
rm -rf readline-8.1

################
### nano-5.8 ###
################

tar xf nano-5.8.tar.xz
cd nano-5.8

./configure --prefix=/usr           \
            --sysconfdir=/etc   \
            --enable-utf8             \
            --docdir=/share/doc/nano-5.8
make
make DESTDIR=/tools install

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
touch /usr/bin/passwd
sed -i 's/1000/999/' etc/useradd

./configure --prefix=/usr         \
            --sysconfdir=/etc \
            --with-group-name-max-length=32
make
make DESTDIR=/tools install
mkdir -p /etc/default
useradd -D --gid 999
pwconv
grpconv
sed -i 's/yes/no/' /etc/default/useradd

# passwd root

cd ..
rm -rf shadow-4.9

#################
### gdbm-1.20 ###
#################

tar xf gdbm-1.20.tar.gz
cd gdbm-1.20

./configure --prefix=/usr    \
            --disable-static   \
            --enable-libgdbm-compat
make
make DESTDIR=/tools install
make -k check

cd ..
rm -rf gdbm-1.20

#################
### gperf-3.1 ###
#################

tar xf gperf-3.1.tar.gz
cd gperf-3.1

./configure --prefix=/usr --docdir=/share/doc/gperf-3.1
make
make DESTDIR=/tools install

cd ..
rm -rf gperf-3.1

###################
### expat-2.4.1 ###
###################

tar xf expat-2.4.1.tar.xz
cd expat-2.4.1

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/share/doc/expat-2.4.1
make
make check
make DESTDIR=/tools install

cd ..
rm -rf expat-2.4.1

#####################
### inetutils-2.1 ###
#####################

tar xf inetutils-2.1.tar.xz
cd inetutils-2.1

./configure --prefix=/usr              \
            --bindir=/usr/bin          \
            --localstatedir=/usr/var   \
            --disable-logger           \
            --disable-whois            \
            --disable-rcp              \
            --disable-rexec            \
            --disable-rlogin           \
            --disable-rsh              \
            --disable-servers
make
make check
make DESTDIR=/tools install
mv -v /tools/{,s}bin/ifconfig

cd ..
rm -rf inetutils-2.1

################
### less-590 ###
################

tar xf less-590.tar.gz
cd less-590

./configure --prefix=/usr --sysconfdir=/tools/etc
make
make DESTDIR=/tools install

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
make check # FAIL: run-backtrace-native.sh
make -C libelf DESTDIR=/tools install
install -vm644 config/libelf.pc /tools/lib/pkgconfig
rm /tools/lib/libelf.a

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
make DESTDIR=/tools install

cd ..
rm -rf libffi-3.4.2

######################
### openssl-1.1.1l ###
######################

tar xf openssl-1.1.1l.tar.gz
cd openssl-1.1.1l

./config --prefix=/usr               \
         --openssldir=/etc/ssl       \
         --libdir=lib                \
         shared                      \
         zlib-dynamic
make
make test
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make DESTDIR=/tools MANSUFFIX=ssl install
mv -v /tools/usr/share/doc/openssl /tools/usr/share/doc/openssl-1.1.1l

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
./configure --prefix=/usr
make
make check
make DESTDIR=/tools install
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

##################
### zstd-1.5.0 ###
##################

tar xf zstd-1.5.0.tar.gz
cd zstd-1.5.0

make
make check
make prefix=/tools install
rm -v /tools/lib/libzstd.a

cd ..
rm -rf zstd-1.5.0

###############
### kmod-29 ###
###############

cd / && ln -s /tools/lib/pkgconfig && cd /sources

tar xf kmod-29.tar.xz
cd kmod-29

./configure --prefix=/usr                \
            --sysconfdir=/etc            \
            --with-xz                    \
            --with-zstd                  \
            --with-zlib
make
make DESTDIR=/tools install
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

./configure --prefix=/usr --disable-static &&
make
make check
make DESTDIR=/tools install

cd ..
rm -rf libtasn1-4.17.0

ldconfig -n /tools/lib

#####################
### libuv-v1.42.0 ###
#####################

cd /usr/bin && ln -s /tools/bin/autom4te && cd /sources
cd /usr/share && ln -s /tools/share/autoconf && cd /sources

tar xf libuv-v1.42.0.tar.gz
cd libuv-v1.42.0

sh autogen.sh
./configure --prefix=/usr --disable-static
make
make DESTDIR=/tools install

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
            --with-python=/tools/bin/python3 &&
make
make DESTDIR=/tools install

cd ..
rm -rf libxml2-2.9.12

######################
### nghttp2-1.44.0 ###
######################

tar xf nghttp2-1.44.0.tar.xz
cd nghttp2-1.44.0

./configure --prefix=/usr   \
            --disable-static  \
            --enable-lib-only \
            --docdir=/share/doc/nghttp2-1.44.0 &&
make
make DESTDIR=/tools install
cd ..
rm -rf nghttp2-1.44.0

###################
### make-ca-1.7 ###
###################

tar xf make-ca-1.7.tar.xz
cd make-ca-1.7

make install &&
install -vdm755 /etc/ssl/local
#/tools/sbin/make-ca -g

mv -v /usr/sbin/make-ca /tools/sbin
mv -v /usr/libexec/make-ca /tools/libexec/

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
/tools/sbin/make-ca -g

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
make DESTDIR=/tools install

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
make DESTDIR=/tools install

cd ..
rm -rf curl-7.78.0

########################
### libarchive-3.5.2 ###
########################

cd /usr/lib && ln -s /tools/usr/lib/libattr.so && cd /sources

tar xf libarchive-3.5.2.tar.xz
cd libarchive-3.5.2

./configure --prefix=/usr --disable-static &&
make
LC_ALL=C make check
make DESTDIR=/tools install

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
            --mandir=/share/man  \
            --no-system-jsoncpp  \
            --no-system-librhash \
            --docdir=/share/doc/cmake-3.21.2 &&
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
make check
make DESTDIR=/tools install

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
make DESTDIR=/tools install

cd ..
rm -rf libassuan-2.5.5

####################
### GPGME-1.16.0 ###
####################

ln -s /tools/lib/libgpg-error.{so,la} /usr/lib/
ln -s /tools/lib/libasshuan.{so.la} /usr/lib/

tar xf gpgme-1.16.0.tar.bz2
cd gpgme-1.16.0

sed 's/defined(__sun.*$/1/' -i src/posix-io.c
./configure --prefix=/usr --disable-gpg-test
make
make DESTDIR=/tools install

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
make DESTDIR=/tools install

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
make DESTDIR=/tools install

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
make DESTDIR=/tools install

cd ..
rm -rf libgcrypt-1.9.4

######################
### pinentry-1.2.0 ###
######################

tar xf pinentry-1.2.0.tar.bz2
cd pinentry-1.2.0

./configure --prefix=/usr --enable-pinentry-tty
make
make DESTDIR=/tools install

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
make DESTDIR=/tools install
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

./configure --prefix=/usr  \
            --disable-static \
            --docdir=/share/doc/libunistring-0.9.10
make
make check
make DESTDIR=/tools install

cd ..
rm -rf libunistring-0.9.10

####################
### GnuTLS-3.7.2 ###
####################

tar xf gnutls-3.7.2.tar.xz
cd gnutls-3.7.2

./configure --prefix=/usr                        \
            --docdir=/share/doc/gnutls-3.7.2 \
            --disable-guile \
            --disable-rpath \
            --with-default-trust-store-pkcs11="pkcs11:"
make
make check
make DESTDIR=/tools install

cd ..
rm -rf gnutls-3.7.2

####################
### GnuPG-2.2.29 ###
####################

tar xf gnupg-2.2.29.tar.bz2
cd gnupg-2.2.29

sed -e '/noinst_SCRIPTS = gpg-zip/c sbin_SCRIPTS += gpg-zip' \
    -i tools/Makefile.in

./configure --prefix=/usr            \
            --localstatedir=/var     \
            --sysconfdir=/etc        \
            --docdir=/share/doc/gnupg-2.2.29 &&
make
make -j17 check
make DESTDIR=/tools install

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
install -dm0755 /etc/ld.so.conf.d/
echo '/tools/lib/libfakeroot' > /etc/ld.so.conf.d/fakeroot.conf

cd ..
rm -rf fakeroot-1.26

################$$##
### pacman-5.0.2 ###
####################

ln -vs /tools/lib/libacl.{so,la} /usr/lib/
ln -vs /tools/lib/libexpat.{so,la} /usr/lib/
ln -vs /tools/lib/libxml2.{so,la} /usr/lib/
ln -vs /tools/lib/libnghttp2.{so,la} /usr/lib/

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
make DESTDIR=/tools install

cd ..
rm -rf pacman-5.0.2

##################################
### archlinux-keyring-20210902 ###
##################################

tar xf archlinux-keyring-20210902.tar.gz
cd archlinux-keyring-20210902

make PREFIX=/usr install

cd ..
rm -rf archlinux-keyring-20210902

#################
### popt-1.18 ###
#################

tar xf popt-1.18.tar.gz
cd popt-1.18

./configure --prefix=/usr --disable-static &&
make
make check
make DESTDIR=/tools install

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
./configure --prefix=/usr    \
            --disable-lz4      \
            --disable-xxhash   \
            --without-included-zlib &&
make
make check
make DESTDIR=/tools install

cd ..
rm -rf rsync-3.2.3
#############################
END
```

## BUILD (build-ABS.sh)
Ryzen2700x(8 core) takes about xx minuits.
```
cd /sources
chmod +x build-ABS.sh
./build-ABS.sh
```
## settings
```
ln -s /tools/usr/bin/gpg-agent /usr/bin/

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
## for using ABS
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