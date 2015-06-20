#!/bin/sh

PROJECT=$1
GITDIR=../..
LOGDIR=$GITDIR/../log
SRC=$GITDIR/../debian/source
DEBIAN=$HOME/debian
REPO=$DEBIAN/repo
STABLE=$REPO/dists/stable/non-free/binary-amd64
TESTING=$REPO/dists/testing/non-free/binary-amd64
UNSTABLE=$REPO/dists/unstable/non-free/binary-amd64
GIT="git -C $GITDIR"

mkdir -p $SRC $LOGDIR $STABLE $TESTING $UNSTABLE

[ ! -x /usr/local/bin/git ] && (echo "Debe instalar Git"; exit 1)

ISGIT=`$GIT rev-parse --is-inside-work-tree`

if [ "x$ISGIT" != "xtrue" ]; then
    echo "Debe existir el repositorio"
    exit 1
fi


log () {
    echo "`date \"+%Y-%m-%d %H:%M:%S \"` $*" >> $LOGDIR/buildpkg.log
}


clean_source () {
    rm -rf $SRC/*
}


extract () {
    $GIT archive --format=tar --prefix=var/www/$PROJECT/ $1 \
	| tar -C $SRC -xf -
}


control () {
    mkdir -p $SRC/DEBIAN
    VERSION=`$GIT describe | head -1 | awk -F '-' '{print $1}' | sed 's/^v//'`
    cat - <<EOF > $SRC/DEBIAN/control
Package: $PROJECT
Version: $VERSION
Architecture: all
Depends: apache2, libapache2-mod-php5, php5-apcu, php5-gd, php5-json, php5-mcrypt, php5-mysql, php5-xsl, php-fpdf, libxml2
Maintainer: Alberto Mijares <amijares@mcs.com.ve>
Description: Inmobilia.com website
 El Portal Inmobiliario de America Latina
 Desarrollado por: strappinc.com
EOF
}

makedeb () {
    dpkg-deb -b $SRC $STABLE
}


update_stable () {
    dpkg-scanpackages $REPO | sed 's-/home/amijares/debian/repo/--' | gzip -9c > $STABLE/Packages.gz
}


debian_stable () {
    log "Iniciando creacion de Paquete Debian"
    clean_source || log "No pude limpiar"
    log "Ya esta limpio"
    extract "master" || log "No pude extraer"
    log "Fuentes extraidas"
    control || "No pude crear controles"
    log "Control Creado"
    makedeb || log "No pude construir"
    log "Paquete creado"
    update_stable
    log "Repo actualizado"
}

debian_stable
