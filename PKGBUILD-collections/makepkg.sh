cd /usr/src
pkgname=
pkgver=
mkdir -p "${pkgname}/${pkgver}"
cd "${pkgname}/${pkgver}"
cat > PKGBUILD << "EOF"
pkgname=""
pkgver=''
source=("")
md5sums=('')
install="${pkgname}.install"
pkgrel='1'
pkgdesc=""
arch=('x86_64')
url="https://www."
license=('')
#prepare() {
#}
build() {
cd "${pkgname}-${pkgver}"
./configure --prefix=/
make
}
#check() {
#cd "${pkgname}-${pkgver}"
#make check 2>&1 | tee ../../${pkgname}-${pkgver}-test.log
#}
package() {
    cd "${pkgname}-${pkgver}"
    make DESTDIR=${pkgdir} install
}
EOF

cat > "${pkgname}.install"  << "EOF"
post_install() {
rm -rf /usr/src/${pkgname}/${pkgver}/pkg
rm -rf /usr/src/${pkgname}/${pkgver}/src
rm -v /usr/src/${pkgname}/${pkgver}/${pkgname}-${pkgver}.tar.z
mv -v /usr/src/${pkgname}/${pkgver}/${pkgname}-${pkgver}-1-x86_64.pkg.tar.gz /var/cache/pacman/pkg"
}
EOF
sed -e "s/\${pkgname}/$pkgname/g" -i "${pkgname}.install"
sed -e "s/\${pkgver}/$pkgver/g" -i "${pkgname}.install"
#sed -e "s/\${pkgname}/$pkgname/g" -i "PKGBUILD"
#sed -e "s/\${pkgver}/$pkgver/g" -i "PKGBUILD"
