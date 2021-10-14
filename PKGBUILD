pkgname=glibc
pkgver=2.34
pkgrel=1
pkgdesc="GNU C Library"
arch=('x86_64')
url="http://www.gnu.org/software/libc"
license=('GPL', 'LGPL')
backup=(etc/ld.so.conf)
source=(${pkgname}-${pkgver}.tar.xz
	glibc-2.34-fhs-1.patch
	nsswitch.conf
        locale.gen.txt
        locale-gen
#        lib32-glibc.conf
        sdt.h sdt-config.h
	ld.so.conf)

# install=glibc.install

prepare() {

  mkdir -p glibc-build

  [[ -d glibc-$pkgver ]] && ln -s glibc-$pkgver glibc 
  cd glibc


  # commit c3479fb7939898ec22c655c383454d6e8b982a67
  patch -p1 -i "$srcdir"/glibc-2.34-fhs-1.patch

  sed -e '/NOTIFY_REMOVED)/s/)/ \&\& data.attr != NULL)/' \
      -i "$srcdir"/glibc-2.34/sysdeps/unix/sysv/linux/mq_notify.c


}

build() {

  local _configure_flags=(
             --prefix=/usr              \
             --disable-werror                         \
             --enable-kernel=3.2                      \
             --enable-stack-protector=strong          \
             --with-headers=/tools/include            \
             libc_cv_slibdir=/tools/lib
  )
  cd "$srcdir/glibc-build"

  echo "slibdir=/usr/lib" >> configparms
  echo "rtlddir=/usr/lib" >> configparms
  echo "sbindir=/usr/bin" >> configparms
  echo "rootsbindir=/usr/bin" >> configparms

  # remove fortify for building libraries
  CPPFLAGS=${CPPFLAGS/-D_FORTIFY_SOURCE=2/}

  #
  CFLAGS=${CFLAGS/-fno-plt/}
  CXXFLAGS=${CXXFLAGS/-fno-plt/}
  LDFLAGS=${LDFLAGS/,-z,now/}

  "$srcdir/glibc/configure" \
      --libdir=/usr/lib \
      --libexecdir=/usr/lib \
      ${_configure_flags[@]}

  # build libraries with fortify disabled
  echo "build-programs=no" >> configparms
  make

  # re-enable fortify for programs
  sed -i "/build-programs=/s#no#yes#" configparms

  echo "CC += -D_FORTIFY_SOURCE=2" >> configparms
  echo "CXX += -D_FORTIFY_SOURCE=2" >> configparms
  make

  # build info pages manually for reprducibility
  make info

  # re-enable fortify for programs
  sed -i "/build-programs=/s#no#yes#" configparms

  echo "CC += -D_FORTIFY_SOURCE=2" >> configparms
  echo "CXX += -D_FORTIFY_SOURCE=2" >> configparms

  make

###################
### 32bit multi ###
###################
# cd "$srcdir/lib32-glibc-build"
#  export CC="gcc -m32 -mstackrealign"
#  export CXX="g++ -m32 -mstackrealign"

#  echo "slibdir=/usr/lib32" >> configparms
#  echo "rtlddir=/usr/lib32" >> configparms
#  echo "sbindir=/usr/bin" >> configparms
#  echo "rootsbindir=/usr/bin" >> configparms

  # remove fortify for building libraries
#  CPPFLAGS=${CPPFLAGS/-D_FORTIFY_SOURCE=2/}
#  CFLAGS=${CFLAGS/-fno-plt/}
#  CXXFLAGS=${CXXFLAGS/-fno-plt/}

#  "$srcdir/glibc/configure" \
#      --host=i686-pc-linux-gnu \
#      --libdir=/usr/lib32 \
#      --libexecdir=/usr/lib32 \
#      ${_configure_flags[@]}

  # build libraries with fortify disabled
#  echo "build-programs=no" >> configparms
#  make

}

#check() {
#  cd glibc-build

  # remove fortify in preparation to run test-suite
#  sed -i '/FORTIFY/d' configparms

  # some failures are "expected"
#  make check || true
#}

package_glibc() {
  pkgdesc='GNU C Library'
  depends=('linux-api-headers>=4.10' tzdata filesystem)
  optdepends=('gd: for memusagestat')
  install=glibc.install
  backup=(etc/gai.conf
          etc/locale.gen
          etc/nscd.conf)

  install -dm755 "$pkgdir/etc"
  touch "$pkgdir/etc/ld.so.conf"

  make -C glibc-build install_root="$pkgdir" install
  rm -f "$pkgdir"/etc/ld.so.{cache,conf}

  # Shipped in tzdata
  rm -f "$pkgdir"/usr/bin/{tzselect,zdump,zic}

  cd glibc

  install -dm755 "$pkgdir"/usr/lib/{locale,systemd/system,tmpfiles.d}
  install -m644 nscd/nscd.conf "$pkgdir/etc/nscd.conf"
  install -m644 nscd/nscd.service "$pkgdir/usr/lib/systemd/system"
  install -m644 nscd/nscd.tmpfiles "$pkgdir/usr/lib/tmpfiles.d/nscd.conf"
  install -dm755 "$pkgdir/var/db/nscd"

  install -m644 posix/gai.conf "$pkgdir"/etc/gai.conf

  install -m755 "$srcdir/locale-gen" "$pkgdir/usr/bin"

  # Create /etc/locale.gen
  install -m644 "$srcdir/locale.gen.txt" "$pkgdir/etc/locale.gen"
  sed -e '1,3d' -e 's|/| |g' -e 's|\\| |g' -e 's|^|#|g' \
    "$srcdir/glibc/localedata/SUPPORTED" >> "$pkgdir/etc/locale.gen"

  if check_option 'debug' n; then
    find "$pkgdir"/usr/bin -type f -executable -exec strip $STRIP_BINARIES {} + 2> /dev/null || true
    find "$pkgdir"/usr/lib -name '*.a' -type f -exec strip $STRIP_STATIC {} + 2> /dev/null || true

    # Do not strip these for gdb and valgrind functionality, but strip the rest
    find "$pkgdir"/usr/lib \
      -not -name 'ld-*.so' \
      -not -name 'libc-*.so' \
      -not -name 'libpthread-*.so' \
      -not -name 'libthread_db-*.so' \
      -name '*-*.so' -type f -exec strip $STRIP_SHARED {} + 2> /dev/null || true
  fi

  # Provide tracing probes to libstdc++ for exceptions, possibly for other
  # libraries too. Useful for gdb's catch command.
  install -Dm644 "$srcdir/sdt.h" "$pkgdir/usr/include/sys/sdt.h"
  install -Dm644 "$srcdir/sdt-config.h" "$pkgdir/usr/include/sys/sdt-config.h"

  # Provided by libxcrypt; keep the old shared library for backwards compatibility
  rm -f "$pkgdir"/usr/include/crypt.h "$pkgdir"/usr/lib/libcrypt.{a,so}
}


###################
### 32bit multi ###
###################
#package_lib32-glibc() {
#  pkgdesc='GNU C Library (32-bit)'
#  depends=("glibc=$pkgver")
#  options+=('!emptydirs')

#  cd lib32-glibc-build

#  make install_root="$pkgdir" install
#  rm -rf "$pkgdir"/{etc,sbin,usr/{bin,sbin,share},var}

  # We need to keep 32 bit specific header files
#  find "$pkgdir/usr/include" -type f -not -name '*-32.h' -delete

  # Dynamic linker
#  install -d "$pkgdir/usr/lib"
#  ln -s ../lib32/ld-linux.so.2 "$pkgdir/usr/lib/"

  # Add lib32 paths to the default library search path
#  install -Dm644 "$srcdir/lib32-glibc.conf" "$pkgdir/etc/ld.so.conf.d/lib32-glibc.conf"

  # Symlink /usr/lib32/locale to /usr/lib/locale
#  ln -s ../lib/locale "$pkgdir/usr/lib32/locale"

#  if check_option 'debug' n; then
#    find "$pkgdir"/usr/lib32 -name '*.a' -type f -exec strip $STRIP_STATIC {} + 2> /dev/null || true
#    find "$pkgdir"/usr/lib32 \
#      -not -name 'ld-*.so' \
#      -not -name 'libc-*.so' \
#      -not -name 'libpthread-*.so' \
#      -not -name 'libthread_db-*.so' \
#      -name '*-*.so' -type f -exec strip $STRIP_SHARED {} + 2> /dev/null || true
#  fi

  # Provided by lib32-libxcrypt; keep the old shared library for backwards compatibility
#  rm -f "$pkgdir"/usr/lib32/libcrypt.{a,so}
#}
