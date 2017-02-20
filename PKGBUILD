pkgname=decrypt
pkgver=0.5.2
pkgrel=1
pkgdesc="Decryption script"
arch=('any')
license=('AGPL3')
depends=('cryptsetup')
changelog=CHANGELOG
install=decrypt.install
source=(
	'${pkgname}::git+ssh://git@git.groulx.tech/decrypt#branch=master'
	'decrypt-hook.hook'
	'decrypt-hook.install'
)

sha256sums=(
	'SKIP'
	'5e68d897247952ac786c0032f94b4ecd5c6903316820a37c38092c8fc2087863'
	'fc9aa12e7a4d9cc6ef51c149d0c045300f2bcd92c11a949be17208f2748ce24a'
)


prepare() {
	cd ${srcdir}/${pkgname}
	git checkout ${pkgver}
}

package() {

  	# Install last known script with service
  	install -Dm 755 "${srcdir}/decrypt.sh" "${pkgdir}/usr/lib/initcpio/hooks/decrypt.sh"
  	install -Dm 755 "${srcdir}/decrypt-hook.install" "${pkgdir}/usr/lib/initcpio/install/decrypt"
 	install -Dm 755 "${srcdir}/decrypt-hook.hook" "${pkgdir}/usr/lib/initcpio/hooks/decrypt"
}

