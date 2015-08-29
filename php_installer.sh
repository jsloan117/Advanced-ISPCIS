#!/bin/bash
#======================================================================================================================================================================================================
# Name:                 php-instaler.sh
# By:                   Jonathan M. Sloan <jsloan@macksarchive.com>
# Date:                 08-29-2015
# Purpose:              Install multiple versions of php both fpm and fcgi supported
# Version:              1.3
# This Script will Download 3 additional versions of PHP. The versions are 5.4.44, 5.5.28, 5.6.12. Will setup and install each version of php with php-fpm or php-cgi support
# Not compiled with PgSQL support, to enable add '--with-pdo-pgsql' and '--with-pgsql' to the compiling php function. This would require you to install Postgres
#======================================================================================================================================================================================================

status="$?"
ver='1.3'

declare -a my_php_versions=('5.4.44' '5.5.28' '5.6.12')
declare -a my_php_type=('fcgi' 'fpm')

print_usage(){
clear; cat<<USAGE
This script will install 1 of 3 php versions and type at a time
      Usage: ${0##*/} version: $ver
USAGE
}

make_dirs () {
echo -e "\nMaking directories now. \n"

[[ ! -d /usr/local/src/php5-build ]] && mkdir -p /usr/local/src/php5-build

if [[ $phptype = ${my_php_type[1]} ]]; then

[[ ! -d /opt/php-$phpversion ]] && mkdir -p /opt/php-$phpversion

elif [[ $phptype = ${my_php_type[0]} ]]; then

[[ ! -d /opt/phpfcgi-$phpversion ]] && mkdir -p /opt/phpfcgi-$phpversion

fi

echo -e "Done! \n"
}

download_php_versions () {
cd /usr/local/src/php5-build

if [[ ! -f php-$phpversion.tar.gz ]]; then

    echo -e "Downloading PHP version: $phpversion now. \n"

    wget -q http://us1.php.net/distributions/php-$phpversion.tar.gz -O php-$phpversion.tar.gz

    echo -e "Done! \n"

fi
}

extract_tars () {
if [[ ! -d php-$phpversion ]]; then

    echo -e "Extracting php-$phpversion.tar.gz now. \n"

    tar -xaf php-$phpversion.tar.gz

    echo -e "Done! \n"

fi
}

compile_php_version () {
cd php-$phpversion

echo -e "\nStarting to compile php-$phpversion now. \n\n"

if [[ $phptype = ${my_php_type[1]} ]]; then

  if [[ $phpversion = '5.4.44' ]]; then

    ./configure --prefix=/opt/php-$phpversion --with-zlib-dir --with-freetype-dir --enable-mbstring --with-libxml-dir=/usr --enable-soap --enable-calendar --with-curl --with-mcrypt \
--with-zlib --with-gd --disable-rpath --enable-inline-optimization --with-bz2 --with-zlib --enable-sockets --enable-sysvsem --enable-sysvshm --enable-pcntl --enable-mbregex --with-mhash \
--enable-zip --with-pcre-regex --with-mysql --with-pdo-mysql --with-mysqli --with-jpeg-dir=/usr --with-png-dir=/usr --enable-gd-native-ttf --with-openssl --with-fpm-user=apache \
--with-fpm-group=apache --with-libdir=lib64 --enable-ftp --with-imap --with-imap-ssl --with-kerberos --with-gettext --enable-fpm

  else

    ./configure --prefix=/opt/php-$phpversion --with-zlib-dir --with-freetype-dir --enable-mbstring --with-libxml-dir=/usr --enable-soap --enable-calendar --with-curl \
--with-mcrypt --with-zlib --with-gd --disable-rpath --enable-inline-optimization --with-bz2 --with-zlib --enable-sockets --enable-sysvsem --enable-sysvshm --enable-pcntl \
--enable-mbregex --enable-exif --enable-bcmath --with-mhash --enable-zip --with-pcre-regex --with-mysql --with-pdo-mysql --with-mysqli --with-jpeg-dir=/usr --with-png-dir=/usr \
--enable-gd-native-ttf --with-openssl --with-fpm-user=apache --with-fpm-group=apache --with-libdir=/lib64 --enable-ftp --with-imap \
--with-imap-ssl --with-kerberos --with-gettext --with-xmlrpc --with-xsl --enable-opcache --enable-fpm

  fi

make
make install

echo -e "\n\nDone! \n"

echo -e "Setting up php.ini, php-fpm.conf \n"

cp /usr/local/src/php5-build/php-$phpversion/php.ini-production /opt/php-$phpversion/lib/php.ini
cp /opt/php-$phpversion/etc/php-fpm.{conf.default,conf}

chown -R root:root /opt/php-$phpversion

sed -i "s/^;pid \= \(.*\)/pid \= \/var\/run\/php-fpm\/php-$phpversion-fpm.pid/g" /opt/php-$phpversion/etc/php-fpm.conf
sed -i "s/^user \= \(.*\)/user \= apache/g" /opt/php-$phpversion/etc/php-fpm.conf
sed -i "s/^group \= \(.*\)/group \= apache/g" /opt/php-$phpversion/etc/php-fpm.conf
sed -i "s/^;error_log \= \(.*\)/error_log \= \/var\/log\/php-fpm\/php-$phpversion-error_log/g" /opt/php-$phpversion/etc/php-fpm.conf

if [[ $phpversion = ${my_php_versions[0]} ]]; then

    sed -i "s/^listen \= \(.*\)/listen \= 127.0.0.1:8997/g" /opt/php-$phpversion/etc/php-fpm.conf

elif [[ $phpversion = ${my_php_versions[1]} ]]; then

    sed -i "s/^listen \= \(.*\)/listen \= 127.0.0.1:8998/g" /opt/php-$phpversion/etc/php-fpm.conf

elif [[ $phpversion = ${my_php_versions[2]} ]]; then

    sed -i "s/^listen \= \(.*\)/listen \= 127.0.0.1:8999/g" /opt/php-$phpversion/etc/php-fpm.conf

fi

sed -i "s/^;include=\(.*\)/include=\/opt\/php-$phpversion\/etc\/pool.d\/*.conf/g" /opt/php-$phpversion/etc/php-fpm.conf

[[ ! -d /opt/php-$phpversion/etc/pool.d ]] && mkdir -p /opt/php-$phpversion/etc/pool.d

echo -e "Done! \n"

create_init_script

elif [[ $phptype = ${my_php_type[0]} ]]; then

  if [[ $phpversion = '5.4.44' ]]; then

    ./configure --prefix=/opt/phpfcgi-$phpversion --with-zlib-dir --with-freetype-dir --enable-mbstring --with-libxml-dir=/usr --enable-soap --enable-calendar --with-curl --with-mcrypt \
--with-zlib --with-gd --disable-rpath --enable-inline-optimization --with-bz2 --with-zlib --enable-sockets --enable-sysvsem --enable-sysvshm --enable-pcntl --enable-mbregex --with-mhash \
--enable-zip --with-pcre-regex --with-mysql --with-pdo-mysql --with-mysqli --with-jpeg-dir=/usr --with-png-dir=/usr --enable-gd-native-ttf --with-openssl --with-fpm-user=apache \
--with-fpm-group=apache --with-libdir=lib64 --enable-ftp --with-imap --with-imap-ssl --with-kerberos --with-gettext --enable-cgi


  else

    ./configure --prefix=/opt/phpfcgi-$phpversion --with-zlib-dir --with-freetype-dir --enable-mbstring --with-libxml-dir=/usr --enable-soap --enable-calendar --with-curl \
--with-mcrypt --with-zlib --with-gd --disable-rpath --enable-inline-optimization --with-bz2 --with-zlib --enable-sockets --enable-sysvsem --enable-sysvshm --enable-pcntl \
--enable-mbregex --enable-exif --enable-bcmath --with-mhash --enable-zip --with-pcre-regex --with-mysql --with-pdo-mysql --with-mysqli --with-jpeg-dir=/usr --with-png-dir=/usr \
--enable-gd-native-ttf --with-openssl --with-fpm-user=apache --with-fpm-group=apache --with-libdir=/lib64 --enable-ftp --with-imap \
--with-imap-ssl --with-kerberos --with-gettext --with-xmlrpc --with-xsl --enable-opcache --enable-cgi

  fi

make
make install

cp /usr/local/src/php5-build/php-$phpversion/php.ini-production /opt/phpfcgi-$phpversion/lib/php.ini

chown -R root:root /opt/phpfcgi-$phpversion

fi
}

create_init_script () {
echo -e "Creating $phpversion init file now. \n"

if [[ ! -f /etc/init.d/php-$phpversion-fpm ]]; then

cat <<EOF > /etc/init.d/php-$phpversion-fpm
#! /bin/sh
### BEGIN INIT INFO
# Provides:          php-$phpversion-fpm
# Required-Start:    \$all
# Required-Stop:     \$all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts php-$phpversion-fpm
# Description:       starts the PHP FastCGI Process Manager daemon
### END INIT INFO
php_fpm_BIN=/opt/php-$phpversion/sbin/php-fpm
php_fpm_CONF=/opt/php-$phpversion/etc/php-fpm.conf
php_fpm_PID=/var/run/php-fpm/php-$phpversion-fpm.pid
php_opts="--fpm-config \$php_fpm_CONF"
wait_for_pid () {
        try=0
        while test \$try -lt 35 ; do
                case "\$1" in
                        'created')
                        if [ -f "\$2" ] ; then
                                try=''
                                break
                        fi
                        ;;
                        'removed')
                        if [ ! -f "\$2" ] ; then
                                try=''
                                break
                        fi
                        ;;
                esac
                echo -n .
                try=\`expr \$try + 1\`
                sleep 1
        done
}
case "\$1" in
        start)
                echo -n "Starting php-fpm "
                \$php_fpm_BIN \$php_opts
                if [ "\$?" != 0 ] ; then
                        echo " failed"
                        exit 1
                fi
                wait_for_pid created \$php_fpm_PID
                if [ -n "\$try" ] ; then
                        echo " failed"
                        exit 1
                else
                        echo " done"
                fi
        ;;
        stop)
                echo -n "Gracefully shutting down php-fpm "
                if [ ! -r \$php_fpm_PID ] ; then
                        echo "warning, no pid file found - php-fpm is not running ?"
                        exit 1
                fi
                kill -QUIT \`cat \$php_fpm_PID\`
                wait_for_pid removed \$php_fpm_PID
                if [ -n "\$try" ] ; then
                        echo " failed. Use force-exit"
                        exit 1
                else
                        echo " done"
                       echo " done"
                fi
        ;;
        force-quit)
                echo -n "Terminating php-fpm "
                if [ ! -r \$php_fpm_PID ] ; then
                        echo "warning, no pid file found - php-fpm is not running ?"
                        exit 1
                fi
                kill -TERM \`cat \$php_fpm_PID\`
                wait_for_pid removed \$php_fpm_PID
                if [ -n "\$try" ] ; then
                        echo " failed"
                        exit 1
                else
                        echo " done"
                fi
        ;;
        restart)
                \$0 stop
                \$0 start
        ;;
        reload)
                echo -n "Reload service php-fpm "
                if [ ! -r \$php_fpm_PID ] ; then
                        echo "warning, no pid file found - php-fpm is not running ?"
                        exit 1
                fi
                kill -USR2 \`cat \$php_fpm_PID\`
                echo " done"
        ;;
        *)
                echo "Usage: \$0 {start|stop|force-quit|restart|reload}"
                exit 1
        ;;
esac
EOF

fi

echo -e "Done! \n"

chmod 755 /etc/init.d/php-$phpversion-fpm
chkconfig --levels 35 php-$phpversion-fpm on

echo -e "Starting php-$phpversion now. \n"

service php-$phpversion-fpm start

echo -e "\nPHP version: $phpversion was successfully installed in /opt/php-$phpversion \n"
}

if [[ $# -ne 0 || $1 = '--help' ]]; then

    print_usage

else

    if [[ $status -eq 0 ]]; then

        clear; echo ""; read -ep "What php version do you want to install? ($(echo ${my_php_versions[@]} | sed "s/ /|/g")): " phpversion ; echo ""
        read -ep "What php type do you want to use? ($(echo ${my_php_type[@]} | sed "s/ /|/g")): " phptype ; echo ""

        yum -y install bzip2-devel libpng-devel libjpeg-turbo-devel libc-client-devel libmcrypt-devel libxslt-devel
        make_dirs
        download_php_versions
        extract_tars
        compile_php_version

    fi

fi
exit 0
