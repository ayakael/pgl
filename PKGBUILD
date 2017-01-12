pkgname=decrypt
pkgver=0.5.1
pkgrel=4
pkgdesc="Decryption script"
arch=('any')
license=('MIT')
depends=('cryptsetup')
changelog=changelog
install=decrypt.install
source=(
'binaries/decrypt.sh'
'initcpio/archlinux/decrypt.hook'
'initcpio/archlinux/decrypt.install'
)

package() {

  	# Install last known script with service
 	install -Dm 755 "${srcdir}/decrypt.hook" "${pkgdir}/usr/lib/initcpio/hooks/decrypt"
  	install -Dm 755 "${srcdir}/decrypt.sh" "${pkgdir}/usr/lib/initcpio/hooks/decrypt.sh"
  	install -Dm 755 "${srcdir}/decrypt.install" "${pkgdir}/usr/lib/initcpio/install/decrypt"

  	# Add copywrite header to all files
	for i in $(find ${pkgdir}/* -type f -not -name ".PKGINFO" -not -name ".BUILDINFO" -not -name ".MTREE"); do
  		echo "#
# Author Antoine Martin
# Copyright (c) $(date +%Y) Antoine Martin <antoine.martin@protonmail.com>
# Release v${pkgver}-${pkgrel} ${pkgname}
#
$(cat "${i}")
" > ${i}
	done
}

