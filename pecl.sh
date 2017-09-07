#!/bin/bash
#
# @author Philip Bergman <pbergman@live>
#
# A replacement for the php pecl installer, because it hasn't have native 
# support for the possibility to easely switch between different php versions.
#
# exmaple:
#   
#   ./pecl.sh oci8-1.4.10 -v5.6 -o"--with-oci8=instantclient,/opt/oracle/instantclient"
#

function cleanup {
    if [ -n "$APPLICATION" ] && [ -d "/tmp/$APPLICATION" ]; then 
        rm -rf /tmp/$APPLICATION
    fi
}

function usage {
    echo "usage: ${0##*/} [package] [-h] [-v <PHP_VERSION>] [-o <CONFIGURE_OPTIONS>]"
    echo ""
    echo "options:"
    echo "   -h, --help                 Print this helper"
    echo "   -v, --php-version          Set the php version [default: 5.6]"
    echo "   -o, --configure-options    Add extra options for the configure command"
    exit -2 
}

if [ -z "$1" ]; then
    usage;
fi

APPLICATION=$1
PHP_VERSION=5.6
CONFIGURE_OPTIONS=""
trap cleanup EXIT INT TERM

OPTS=`getopt -o o:fhv: --long configure-options:,force,help,php-version: -n 'parse-options' -- "$@"`
eval set -- "$OPTS"

while true ; do
    case "$1" in
        -h|--help) usage; ;;
        -v|--php-version) PHP_VERSION=$2 ; shift 2;;
        -o|--configure-options) CONFIGURE_OPTIONS=$2 ; shift 2;;
        --) shift ; break ;;
        *) echo "Unsupported option \"$1\"" ; exit 1 ;;
    esac
done

CONFIGURE_OPTIONS="--with-php-config=php-config${PHP_VERSION} ${CONFIGURE_OPTIONS}"

echo "Building php extension $APPLICATION from PHP $PHP_VERSION"

if [ -d "/tmp/$APPLICATION" ]; then
    rm -rf /tmp/$APPLICATION
fi

mkdir /tmp/$APPLICATION \
    && cd /tmp/$APPLICATION \
    && wget https://pecl.php.net/get/$APPLICATION -qO- | tar --strip-components=1 -zxf - \
    && phpize${PHP_VERSION} \
    && ./configure ${CONFIGURE_OPTIONS} \
    && make clean \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && sudo make -j$(getconf _NPROCESSORS_ONLN) install
