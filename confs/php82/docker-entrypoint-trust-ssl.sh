#!/bin/sh
# После генерации сертификатов в контейнере ssl (rootCA в /ssl/) доверяем им для PHP/OpenSSL.
# См. README «Доверие к сертификатам центров сертификации для PHP и Nginx».
if [ -f /ssl/rootCA.cert.pem ]; then
	mkdir -p /usr/local/share/ca-certificates
	# Alpine update-ca-certificates учитывает только файлы с расширением .crt
	ln -sf /ssl/rootCA.cert.pem /usr/local/share/ca-certificates/bx-rootCA.crt
	if [ -f /ssl/intermediateCA.cert.pem ]; then
		ln -sf /ssl/intermediateCA.cert.pem /usr/local/share/ca-certificates/bx-intermediateCA.crt
	fi
	/usr/sbin/update-ca-certificates >/dev/null 2>&1 || true
fi
exec /usr/local/bin/docker-php-entrypoint "$@"
