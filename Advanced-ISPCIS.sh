#!/bin/bash
#=========================================================================================================================================
# Name:         Advanced-ISPCIS.sh
# By:           Jonathan M. Sloan <jsloan@macksarchive.com>
# Date:         09-29-2015
# Purpose:      Install ISPConfig-3.X, OpenVZ, OpenVZ-CP and Templates (32bit & 64bit tested) < - Need to retest
# Version:      2.5.9
# Info:         Customized install available for ISPConfig. (The partial install has not been tested yet!) < - Need to test
# Software:     APF, BFD, OpenVZ, OpenVZ Web Panel, Roundcube, Munin, Monit, OSSEC, OSSEC Web UI, Authy, DUO Security
#               Horde Webmail, Nagios, PNP4Nagios, Check_MK, Collectd, Awstats-FTP and Mail Statistics. Using MariaDB as MySQL replacement
# OS Templates: Possible to choose from 5 different OS Templates and automatically import then into the ISPConfig DB.
#               Centos 6-x64, Centos-7-x64, Debian-8-x64, Suse-13.2-x64, Ubunutu-15.04-x64
#=========================================================================================================================================

set -ae

status="$?"
prog=$(echo $(basename $0))
prog_conf=${prog/.sh/.conf}
prog_pass=${prog/.sh/.passwords}
arch=$(uname -p)

# Are you root?
if [[ $(id -un) != root ]]; then

    echo -e "\nScript must be ran by root user! \n" && exit 1

fi

# Checks if OS is CentOS version 6.x
if [[ ! -f /etc/centos-release ]]; then

    echo -e "\n$prog only supports CentOS 6.x currently! \n" && exit 1

elif ! (grep -q "^CentOS release 6.[0-9] (Final)" /etc/centos-release); then

    echo -e "\nDetected OS is not CentOS version 6.x! \n" && exit 1

fi

##########################
### Software Variables ###
##########################
# NOTES: The archived packages need to be .tar.xx format NOT ZIP! Safest/Best use .tar.gz format.

if [[ $arch = x86_64 ]]; then

    epel_pkg="http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
    rpmforge_pkg='http://pkgs.repoforge.org/rpmforge-elease/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm'
    mod_pagespeed='https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_x86_64.rpm'

else

    epel_pkg='http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'
    rpmforge_pkg='http://pkgs.repoforge.org/rpmforge-elease/rpmforge-release-0.5.3-1.el6.rf.i686.rpm'
    mod_pagespeed='https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_i386.rpm'

fi

ispconfig_url='http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz'
epel_key='http://fedoraproject.org/static/0608B895.txt'
rpmforge_key='http://apt.sw.be/RPM-GPG-KEY.dag.txt'
suphp_url='http://www.suphp.org/download/suphp-0.7.2.tar.gz'
mod_ruby_url='http://fossies.org/unix/www/apache_httpd_modules/mod_ruby-1.3.0.tar.gz'
jailkit_url='http://olivier.sessink.nl/jailkit/jailkit-2.17.tar.gz'
awstats_url='http://prdownloads.sourceforge.net/awstats/awstats-7.4-1.noarch.rpm'
phpmyadmin_url='https://files.phpmyadmin.net/phpMyAdmin/4.5.0.2/phpMyAdmin-4.5.0.2-all-languages.tar.gz'
openvz_repo='http://ftp.openvz.org/openvz.repo'
openvz_key='http://ftp.openvz.org/RPM-GPG-Key-OpenVZ'
openvz_cp='http://ovz-web-panel.googlecode.com/svn/installer/ai.sh'
apf_url='http://www.rfxn.com/downloads/apf-current.tar.gz'
bfd_url='http://www.rfxn.com/downloads/bfd-current.tar.gz'
ossec_url='https://github.com/ossec/ossec-hids/archive/2.8.2.tar.gz'
ossec_wui_url='https://github.com/ossec/ossec-wui/archive/master.zip'
authy_ssl_url='https://raw.github.com/authy/authy-ssh/master/authy-ssh'
duo_security_url='https://dl.duosecurity.com/duo_unix-latest.tar.gz'
automysqlbackup_url='http://sourceforge.net/projects/automysqlbackup/files/AutoMySQLBackup/AutoMySQLBackup%20VER%203.0/automysqlbackup-v3.0_rc6.tar.gz/download'
roundcubemail_url='https://downloads.sourceforge.net/project/roundcubemail/roundcubemail/1.1.3/roundcubemail-1.1.3-complete.tar.gz'
monit_url='https://mmonit.com/monit/dist/monit-5.14.tar.gz'
nagios_url='http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-3.5.1.tar.gz'
nagios_plugins_url='http://www.nagios-plugins.org/download/nagios-plugins-2.1.1.tar.gz'
pnp4nagios_url='http://sourceforge.net/projects/pnp4nagios/files/PNP-0.6/pnp4nagios-0.6.25.tar.gz/download'
check_mk_url='https://mathias-kettner.de/download/check_mk-1.2.6p9.tar.gz'
collectd_url='https://collectd.org/files/collectd-5.5.0.tar.gz'
#maldetect_url='http://www.rfxn.com/downloads/maldetect-current.tar.gz' # Not in use at the moment

##########################
### Password Variables ###
##########################
# These are optional set here. Will automatically prompt for them later. ONLY SET 'mysql_pass' if this is what your going to use when 'mysql-secure-installation' runs later.

pma_pass=""
mysql_pass=""
mailman_email=""
mailman_pass=""

#############################
### Source in config file ###
#############################

if [[ -f $HOME/$prog_conf ]]; then

    . $HOME/$prog_conf

fi

if [[ -z $accept_eula ]]; then # Accept the EULA or quit the script

  whiptail --backtitle "ISPConfig Advanced Installer" --title "EULA" --yesno --yes-button "I accept" --no-button "Quit" "I have created this script to make installing ISPConfig 3 a breeze. \
Not only can you install ISPConfig3, but many extra items that you can install after ISPConfig. I do not guarantee that this will absolutely work 100% perfectly for you every time. By Accepting the EULA you have been warned \
and I'm not responsible for any damage or loss of data.\n\nScript made by: Jonathan S." 12 110

    if [[ $status = 0 ]]; then

      echo accept_eula=y > $HOME/$prog_conf

    else

      exit

    fi

  chmod 600 $HOME/$prog_conf

fi

#######################################################
### Get NIC, HOST, DOMAIN, and TIMEZONE Information ###
#######################################################

get_sys_info () {
clear
if [[ -z $MY_NIC ]]; then # Set Network Interface Card
    ifconfig; echo ""
    tmp='eth0'
    read -ep "Enter your Network card [${tmp}]: " MY_NIC
    MY_NIC=${MY_NIC:-${tmp}}
    echo "MY_NIC=$MY_NIC" >> $HOME/$prog_conf
fi; clear

if [[ -z $MY_HOST ]]; then # Set Host Name
    tmp='myhost'
    read -ep "Enter server host name [${tmp}]: " MY_HOST
    MY_HOST=${MY_HOST:-${tmp}}
    echo "MY_HOST=$MY_HOST" >> $HOME/$prog_conf
fi; echo ""

if [[ -z $MY_DOMAIN ]]; then # Set Domain Name
    tmp='mydomain.tld'
    read -ep "Enter server domain name [${tmp}]: " MY_DOMAIN
    MY_DOMAIN=${MY_DOMAIN:-${tmp}}
    echo "MY_DOMAIN=$MY_DOMAIN" >> $HOME/$prog_conf
fi; echo ""

if [[ -z $timezone ]]; then # Set Time Zone
    tmp='Eastern'
    read -ep "Enter your Time Zone [${tmp}]: " timezone
    timezone=${timezone:-${tmp}}
    echo "timezone=$timezone" >> $HOME/$prog_conf
fi; echo ""
}

########################################################
### Get FTP Certificate Information to set variables ###
########################################################

get_ftp_cert_info () {
if [[ -z $country ]]; then # Set Country
    tmp='US'
    read -ep "Please enter your country if different [${tmp}]: " country
    country=${country:-${tmp}}
    echo "country=$country" >> $HOME/$prog_conf
fi; echo ""

if [[ -z $state ]]; then # Set state
    tmp='STATE'
    read -ep "Please enter your state [${tmp}]: " state
    state=${state:-${tmp}}
    echo "state=$state" >> $HOME/$prog_conf
fi; echo ""

if [[ -z $city ]]; then # Set city
    tmp='CITY'
    read -ep "Please enter your city [${tmp}]: " city
    city=${city:-${tmp}}
    echo "city=$(echo $city | sed -e "s/^/'/g" -e "s/$/'/g")" >> $HOME/$prog_conf
fi; echo ""

if [[ -z $company ]]; then # Set company Name
    tmp=$MY_DOMAIN
    read -ep "Please enter your company [${tmp}]: " company
    company=${company:-${tmp}}
    echo "company=$company" >> $HOME/$prog_conf
fi; echo ""

if [[ -z $department ]]; then # Set department
    tmp='FTP server'
    read -ep "Please enter your department if different [${tmp}]: " department
    department=${department:-${tmp}}
    echo "department=$(echo $department | sed -e "s/^/'/g" -e "s/$/'/g")" >> $HOME/$prog_conf
fi; echo ""

if [[ -z $fqdn ]]; then # Set fqdn of FTP Server
    tmp=ftp.$MY_DOMAIN
    read -ep "Please enter your server name if you want it to be different. [${tmp}]: " fqdn;
    fqdn=${fqdn:-${tmp}}
    echo "fqdn=$fqdn" >> $HOME/$prog_conf
fi; echo "";

if [[ -z $email_address ]]; then # Set email_address on FTP Cert
    tmp=admin@$MY_DOMAIN
    read -ep "Please enter your email address if you want it to be different. [${tmp}]: " email_address
    email_address=${email_address:-${tmp}}
    echo "email_address=$email_address" >> $HOME/$prog_conf
fi; echo ""
}

############################################
#### ask User which services to install ####
############################################

ask_install_services () {
if [[ -z $Install_OpenVZ ]]; then
    tmp='y'
    read -ep "Install OpenVZ virtualization software [y/n] [${tmp}]: " Install_OpenVZ
    Install_OpenVZ=${Install_OpenVZ:-${tmp}}
    echo "Install_OpenVZ=$Install_OpenVZ" >> $HOME/$prog_conf
fi; echo ""

if [[ $Install_OpenVZ = 'y' && -z $Install_OpenVZ_CP ]]; then
    read -ep "Install OpenVZ Web Panel [y/n] [${tmp}]: " Install_OpenVZ_CP
    Install_OpenVZ_CP=${Install_OpenVZ_CP:-${tmp}}
    echo "Install_OpenVZ_CP=$Install_OpenVZ_CP" >> $HOME/$prog_conf
fi; echo ""

if [[ -z $Install_Web ]]; then
    read -ep "Install Apache Web Server [y/n] [${tmp}]: " Install_Web
    Install_Web=${Install_Web:-${tmp}}
    echo "Install_Web=$Install_Web" >> $HOME/$prog_conf
fi; echo ""

if [[ -z $Install_DNS ]]; then
    read -ep "Install Bind Name Server [y/n] [${tmp}]: " Install_DNS
    Install_DNS=${Install_DNS:-${tmp}}
    echo "Install_DNS=$Install_DNS" >> $HOME/$prog_conf
fi; echo ""

if [[ -z $Install_MySQL ]]; then
    read -ep "Install MariaDB Server [y/n] [${tmp}]: " Install_MySQL
    Install_MySQL=${Install_MySQL:-${tmp}}
    echo "Install_MySQL=$Install_MySQL" >> $HOME/$prog_conf
fi; echo ""

if [[ $Install_MySQL = y && -z $MariaDB_Version ]]; then
    tmp='5'
    read -ep "Which MariaDB Version? [5/10] [${tmp}]: " MariaDB_Version
    MariaDB_Version=${MariaDB_Version:-${tmp}}
    echo "MariaDB_Version=$MariaDB_Version" >> $HOME/$prog_conf

fi; echo ""

if [[ -z $Install_Mail ]]; then
    tmp='y'
    read -ep "Install Mail Server [y/n] [${tmp}]: " Install_Mail
    Install_Mail=${Install_Mail:-${tmp}}
    echo "Install_Mail=$Install_Mail" >> $HOME/$prog_conf
fi; echo ""

if [[ -z $Install_FTP ]]; then
    read -ep "Install PureFTPd FTP Server [y/n] [${tmp}]: " Install_FTP
    Install_FTP=${Install_FTP:-${tmp}}
    echo "Install_FTP=$Install_FTP" >> $HOME/$prog_conf
fi; echo ""

if [[ $Install_FTP = y ]]; then

    get_ftp_cert_info

fi

if [[ -z $Install_Quota ]]; then
    tmp='y'
    read -ep "Install Quota: Setup quota's for users [y/n] [${tmp}]: " Install_Quota;
    Install_Quota=${Install_Quota:-${tmp}}
    echo "Install_Quota=$Install_Quota" >> $HOME/$prog_conf
fi; echo "";

if [[ -z $Install_Mailman ]]; then
    read -ep "Install Mailman: Mailing List Manager [y/n] [${tmp}]: " Install_Mailman;
    Install_Mailman=${Install_Mailman:-${tmp}}
    echo "Install_Mailman=$Install_Mailman" >> $HOME/$prog_conf
fi; echo "";

if [[ -z $Install_Jailkit ]]; then
    read -ep "Install JailKit: Setup chrooted environments for users [y/n] [${tmp}]: " Install_Jailkit;
    Install_Jailkit=${Install_Jailkit:-${tmp}}
    echo "Install_Jailkit=$Install_Jailkit" >> $HOME/$prog_conf
fi; echo "";
}

get_sys_info

ask_install_services

MY_HOSTNAME=$MY_HOST.$MY_DOMAIN
MY_IP=$(ifconfig $MY_NIC | grep -w inet | cut -d: -f2 | awk '{ print $1 }')
pma_file=${phpmyadmin_url##*/}
pma_extdir=$(echo $pma_file | sed 's/.tar.gz//g')
automysql_url=${automysqlbackup_url%/*}
automysql_file=${automysql_url##*/}
roundcube_file=${roundcubemail_url##*/}
nagios_file=${nagios_url##*/}
nagios_plugins_file=${nagios_plugins_url##*/}
pnp4nagiosurl=${pnp4nagios_url%/*}
pnp4nagios_file=${pnp4nagiosurl##*/}
check_mk_file=${check_mk_url##*/}
collectd_file=${collectd_url##*/}

create_ftp_cert () {
cert_info() {
echo $country
echo $state
echo $city
echo $company
echo $department
echo $fqdn
echo $email_address
}

if [[ $# -eq 0 ]]; then

    echo $"Usage: $(basename $0) filename [...]" && exit 0

fi

for cert in $@; do

    PEM1=$(/bin/mktemp /tmp/openssl.XXXXXX)
    PEM2=$(/bin/mktemp /tmp/openssl.XXXXXX)
    trap "rm -f $PEM1 $PEM2" SIGINT
	cert_info | /usr/bin/openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout $PEM1 -out $PEM2 2> /dev/null
    cat $PEM1 > $cert
    echo ""   >> $cert
    cat $PEM2 >> $cert
    rm -f $PEM1 $PEM2

done
}

init_service () {
local servname=$1
local state=$2
chkconfig --levels 35 $servname $state
}

ctrl_service () {
local servname=$1
local action=$2
service $servname $action
}

getfiles () {
local file=$1
local url=$2
wget -O /tmp/$file $url
}

extract_tars () {
[[ -z $1 || ! -f $1 ]] && exit 999 || local f=$1
[[ -n $2 && ! -d $2 ]] && exit 999 || local d=$2
[[ -n $d ]] && tar -xaf $f -C $d || tar -xaf $f
}

Install_Basic_Tools () {
yum -y -q install system-config-{firewall,network}-tui nano ntfs-3g mc vim man wget yum-utils xinetd \
ntsysv curl-devel at jwhois perl-XML-LibXML perl-XML-SAX pam-devel openssl-devel aspell aspell-devel aspell-en

init_service xinetd on
ctrl_service xinetd start; echo ""
}

Install_APF () {
if [[ -x '/usr/local/sbin/apf' ]]; then

    echo -e "\nIt appears that APF has already installed. \n" && exit 10

fi

getfiles ${apf_url##*/} $apf_url
extract_tars /tmp/${apf_url##*/} /tmp

local apf_extdir=/tmp/$(ls -l /tmp | awk '{ print $9 }' | grep "^apf-[.0-9]" | awk -F'-' '{ printf "%s-%s-%s\n", $1, $2, $3 }')
local apf_conf_file=/etc/apf/conf.apf

cd $apf_extdir
sh install.sh; echo ""

# Make changes to firewall, and open ports ISPConfig to work correctly
sed -i "s/^RAB=\(.*\)/RAB=\"1\"/g" $apf_conf_file
sed -i "s/^RAB_PSCAN_LEVEL=\(.*\)/RAB_PSCAN_LEVEL=\"3\"/g" $apf_conf_file
sed -i "s/^BLK_IDENT=\(.*\)/BLK_IDENT=\"1\"/g" $apf_conf_file
sed -i "s/^SYSCTL_SYN=\(.*\)/SYSCTL_SYN=\"1\"/g" $apf_conf_file
sed -i "s/^SYSCTL_ROUTE=\(.*\)/SYSCTL_ROUTE=\"1\"/g" $apf_conf_file
sed -i "s/^SYSCTL_LOGMARTIANS=\(.*\)/SYSCTL_LOGMARTIANS=\"1\"/g" $apf_conf_file
sed -i "s/^SET_FASTLOAD=\(.*\)/SET_FASTLOAD=\"1\"/g" $apf_conf_file
sed -i "s/^SYSCTL_SYNCOOKIES=\(.*\)/SYSCTL_SYNCOOKIES=\"0\"/g" $apf_conf_file

if [[ $Install_OpenVZ_CP = 'y' ]]; then

    sed -i "s/^IG_TCP_CPORTS=\(.*\)/IG_TCP_CPORTS=\"20,21,22,25,53,80,110,143,443,993,995,3000,8080,8081\"/g" $apf_conf_file

else

    sed -i "s/^IG_TCP_CPORTS=\(.*\)/IG_TCP_CPORTS=\"20,21,22,25,53,80,110,143,443,993,995,8080,8081\"/g" $apf_conf_file

fi

sed -i "s/^IG_UDP_CPORTS=\(.*\)/IG_UDP_CPORTS=\"20,21,53\"/g" $apf_conf_file
sed -i "s/^DLIST_PHP=\(.*\)/DLIST_PHP=\"1\"/g" $apf_conf_file
sed -i "s/^DLIST_SPAMHAUS=\(.*\)/DLIST_SPAMHAUS=\"1\"/g" $apf_conf_file
sed -i "s/^DLIST_DSHIELD=\(.*\)/DLIST_DSHIELD=\"1\"/g" $apf_conf_file
sed -i "s/^LOG_DROP=\(.*\)/LOG_DROP=\"1\"/g" $apf_conf_file
sed -i "s/^DEVEL_MODE=\(.*\)/DEVEL_MODE=\"0\"/g" $apf_conf_file

if [[ -z $mysql_pass ]]; then

    read -esp "MySQL root password: " mysql_pass

fi

# Disable Firewall inside of ISPConfig
cat <<EOF | mysql -u root -p"$mysql_pass"
UPDATE \`dbispconfig\`.\`firewall\` SET \`active\` = 'n' WHERE \`firewall\`.\`firewall_id\` = 1;
EOF

init_service bastille-firewall off
ctrl_service bastille-firewall stop; echo ""

init_service apf on
ctrl_service apf start; echo ""

rm -rf /tmp/apf-*
echo -e "APF has been installed and configured. \n"; unset mysql_pass
}

Install_BFD () {
if [[ -x '/usr/local/sbin/bfd' ]]; then

    echo -e "\nIt appears that BFD has already installed. \n" && exit 10

fi

getfiles ${bfd_url##*/} $bfd_url
extract_tars /tmp/${bfd_url##*/} /tmp
PUB_IP=$(wget -q -O - checkip.dyndns.org | awk -F":" '{ print $2 }' | sed -e "s/^ //g" | awk -F"<" '{ print $1 }')

local bfd_extdir=/tmp/$(ls -l /tmp | awk '{ print $9 }' | grep "^bfd-[.0-9]" | awk -F'-' '{ printf "%s-%s-%s\n", $1, $2, $3 }')

cd $bfd_extdir
sh install.sh; echo ""

sed -i "s/^EMAIL_ALERTS=\(.*\)/EMAIL_ALERTS=\"1\"/g" /usr/local/bfd/conf.bfd
echo -e "localhost\n$MY_IP\n$PUB_IP\n" >> /usr/local/bfd/ignore.hosts

rm -rf /tmp/bfd-*
echo -e "BFD has been installed and configured to send email alerts. \n"
}

Install_Virtualization () {
clear
Install_Basic_Tools

wget -P /etc/yum.repos.d $openvz_repo

rpm --import $openvz_key

# Update system kernel first, before installing OpenVZ kernel (This helps keep the OpenVZ the 1st choice in boot order)
yum -y -q update kernel

# Install OpenVZ Kernel
yum -y -q install vzkernel

# Check for OpenVZ kernel in '/boot/grub/menu.lst' file
if ! (grep -q "^title OpenVZ" /boot/grub/menu.lst); then

    echo -e "It appears that the OpenVZ Kernel was not found in '/boot/grub/menu.lst'. \n" && exit 99

fi

# Changes SELINUX state to disabled
if [[ ! -f '/etc/selinux/config' ]]; then

    echo "SELINUX=disabled" > /etc/selinux/config

else

    sed -i 's/^SELINUX=\(.*\)/SELINUX=disabled/g' /etc/selinux/config

fi

# Check whether or not you want to opt out of vzstats http://openvz.org/Vzstats
if [[ -z $optout ]]; then
    tmp='n'
    read -ep "Do you wish to opt-out of vzstats? http://openvz.org/Vzstats [y/n] [${tmp}]: " optout
    optout=${optout:-${tmp}}
    echo "optout=$optout" >> $HOME/$prog_conf
fi; echo "";

if [[ $optout = 'y' ]]; then

    touch /etc/vz/vzstats-disable

fi

# Install OpenVZ tools NOTE: According to http://openvz.org/Quick_installation if vzctl version >= 4.4 no need to do manual configure of /etc/sysctl.conf (Which means we should not have to!)
yum -y -q install vzctl vzquota ploop

# Enable and set NEIGHBOUR_DEVS=all
sed -i "s/^#NEIGHBOUR_DEVS=\(.*\)/NEIGHBOUR_DEVS=all/g" /etc/vz/vz.conf

sed -i "s/net.ipv4.ip_forward = \(.*\)/net.ipv4.ip_forward = 1/g" /etc/sysctl.conf
echo "net.ipv6.conf.default.forwarding = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.proxy_arp = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.conf
sed -i "s/kernel.sysrq = \(.*\)/kernel.sysrq = 1/g" /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
sysctl -p 

# Disable IPTABLES here
service iptables save
ctrl_service iptables stop
init_service iptables off

mv /etc/hosts /etc/hosts.bak; echo ""

# Insert your IP, Host, fqdn into hosts file
echo "$MY_IP   $MY_HOSTNAME $MY_HOST" > /etc/hosts

# Put localhost info back into hosts file
cat <<'EOF' >> /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF

# Set script to automatically run on reboot
echo "if [[ -x $HOME/$prog ]]; then bash $HOME/$prog; fi" >> $HOME/.bashrc

# This tells us that we've already rebooted the system and can finish getting ready to install ISPConfig
touch /tmp/sys-prep.done

# sed 's/options nf_conntrack ip_conntrack_disable_ve0=1/options nf_conntrack ip_conntrack_disable_ve0=0/g' /etc/modprobe.d/openvz.conf

echo -e "\nOpenVZ has been installed, we will continue the installation process once rebooted and logged back in. (As root!) \n"
read -ep "Ready to reboot? [y/n] " yn; echo ""

case "$yn" in

    n|N|no|No|NO)

        echo -e "\nExiting now.. The System Needs to be Restarted ASAP to load new OpenVZ kernel. \n" && exit 5 ;;

    y|Y|Yes|yes|YES)

        reboot && exit 0 ;;

esac
}

Install_Virtualization_CP () {
getfiles ${openvz_cp##*/} $openvz_cp

sh /tmp/${openvz_cp##*/}; echo "" # Run OpenVZ Control Panel Installer Script

echo -e "\nEnabling SSL for OpenVZ Web Panel now. \n" && sed -i "s/^SSL=\(.*\)/SSL=on/g" /etc/owp.conf

init_service owp on
ctrl_service owp restart; echo ""

rm -f /tmp/${openvz_cp##*/}
mv /tmp/ovz-web-panel.log $HOME/ && chmod 600 $HOME/ovz-web-panel.log
}

Download_OpenVZ_Templates () {
if [[ ! -d '/vz' ]]; then

    echo -e "\nSorry but you must first install OpenVZ to download OS Templates for ISPConfig. \n" && exit 99

fi

# Operating Systems Array
_os[0]='http://download.openvz.org/template/precreated/centos-6-x86_64.tar.gz'
_os[1]='http://download.openvz.org/template/precreated/centos-7-x86_64.tar.gz'
_os[2]='http://download.openvz.org/template/precreated/debian-8.0-x86_64.tar.gz'
_os[3]='http://download.openvz.org/template/precreated/suse-13.2-x86_64.tar.gz'
_os[4]='http://download.openvz.org/template/precreated/ubuntu-15.04-x86_64.tar.gz'


clear && echo -e "Please choose a OS to download for OpenVZ, Import SQL code, or Exit. [1-7] \n"
echo -e "Please download all OSes you want first, then Import the SQL code for those OSes into MySQL. (Importing using this script should only be ran once!) \n"

select os in CentOS-6-x64 CentOS-7-x64 Debian-8-x64 Suse-13.2-x64 Ubunutu-15.04-x64 Import_SQL quit; do

    case $os in

        CentOS-6-x64)

            wget -P /vz/template/cache ${_os[0]} ;;

        CentOS-7-x64)

            wget -P /vz/template/cache ${_os[1]} ;;

        Debian-8-x64)

            wget -P /vz/template/cache ${_os[2]} ;;

        Suse-13.2-x64)

            wget -P /vz/template/cache ${_os[3]} ;;

        Ubunutu-15.04-x64)

            wget -P /vz/template/cache ${_os[4]} ;;

        Import_SQL)

            Import_Template_Code ;;

        quit)

            echo -e "\nExiting now. \n" && exit 0 ;;

    esac

done
}

Import_Template_Code () { # The vm manager inside of ISPConfig does not appear to work correct (start/stop) wise atm? (Testing still)
if [[ -z $mysql_pass ]]; then

    read -esp "MySQL root password: " mysql_pass

fi
if [[ -f '/vz/template/cache/debian-8.0-x86_64.tar.gz' ]]; then
cat <<EOF | mysql -u root -p"$mysql_pass"
USE dbispconfig;
UPDATE \`dbispconfig\`.\`openvz_ostemplate\` SET \`template_name\`
= 'Debian 8 x 64', \`template_file\` = 'debian-8.0-x86_64',
\`description\` = 'Debian 8 x 64' WHERE
\`openvz_ostemplate\`.\`ostemplate_id\` = 1;
EOF
fi
if [[ -f '/vz/template/cache/centos-6-x86_64.tar.gz' ]]; then
cat <<EOF | mysql -u root -p"$mysql_pass"
USE dbispconfig;
INSERT INTO \`dbispconfig\`.\`openvz_ostemplate\` (\`ostemplate_id\`,
\`sys_userid\`, \`sys_groupid\`, \`sys_perm_user\`, \`sys_perm_group\`,
\`sys_perm_other\`, \`template_name\`, \`template_file\`, \`server_id\`,
\`allservers\`, \`active\`, \`description\`) VALUES (NULL, '1', '1',
'riud', 'riud', '', 'CentOS 6 x64', 'centos-6-x86_64', '1', 'y',
'y', 'CentOS 6 x64');
EOF
fi
if [[ -f '/vz/template/cache/centos-7-x86_64.tar.gz' ]]; then
cat <<EOF | mysql -u root -p"$mysql_pass"
USE dbispconfig;
INSERT INTO \`dbispconfig\`.\`openvz_ostemplate\` (\`ostemplate_id\`,
\`sys_userid\`, \`sys_groupid\`, \`sys_perm_user\`, \`sys_perm_group\`,
\`sys_perm_other\`, \`template_name\`, \`template_file\`, \`server_id\`,
\`allservers\`, \`active\`, \`description\`) VALUES (NULL, '1', '1',
'riud', 'riud', '', 'CentOS 7 x64', 'centos-7-x86_64', '1', 'y',
'y', 'CentOS 7 x64');
EOF
fi
if [[ -f '/vz/template/cache/suse-13.2-x86_64.tar.gz' ]]; then
cat <<EOF | mysql -u root -p"$mysql_pass"
USE dbispconfig;
INSERT INTO \`dbispconfig\`.\`openvz_ostemplate\` (\`ostemplate_id\`,
\`sys_userid\`, \`sys_groupid\`, \`sys_perm_user\`, \`sys_perm_group\`,
\`sys_perm_other\`, \`template_name\`, \`template_file\`, \`server_id\`,
\`allservers\`, \`active\`, \`description\`) VALUES (NULL, '1', '1',
'riud', 'riud', '', 'Suse 13.2 x64', 'suse-13.2-x86_64', '1', 'y',
'y', 'Suse 13.2 x64');
EOF
fi
if [[ -f '/vz/template/cache/ubuntu-15.04-x86_64.tar.gz' ]]; then
cat <<EOF | mysql -u root -p"$mysql_pass"
USE dbispconfig;
INSERT INTO \`dbispconfig\`.\`openvz_ostemplate\` (\`ostemplate_id\`,
\`sys_userid\`, \`sys_groupid\`, \`sys_perm_user\`, \`sys_perm_group\`,
\`sys_perm_other\`, \`template_name\`, \`template_file\`, \`server_id\`,
\`allservers\`, \`active\`, \`description\`) VALUES (NULL, '1', '1',
'riud', 'riud', '', 'Ubuntu 15.04 x64', 'ubuntu-15.04-x86_64', '1', 'y',
'y', 'Ubuntu 15.04 x64');
EOF
fi; unset mysql_pass;
}

Main () {
clear; cat <<EOF
What would you like to do? [1-5]

Download_OS_Templates: Choose from 5 different OSes to download for ISPConfig. Imports downloaded OSes into ISPConfig DB to use.

Extras: Extra installers menu

Security: Security related installers menu

Monitoring: Monitering related installers menu

quit -- Exits 

EOF

select choice in Download_OS_Templates Extras Security Monitoring quit; do

	case $choice in

        Download_OS_Templates)

            Download_OpenVZ_Templates ;;

        Extras)

            Extras_Menu ;;

        Security)

            Security_Menu ;;

        Monitoring)

            Monitoring_Menu ;;

         quit)

            unset mysql_pass && echo -e "\nExiting now per your request \n" && exit 0 ;;

	esac

done
}

Install_Extra_Apache_Modz () {
cat <<EOF
Installing a few apache modules for security, mod_{security, evasive, bw, limitipconn} we disabled mod_security from phpMyAdmin to prevent problems.
If you wish to have mod_security protect phpMyAdmin edit this file '/etc/httpd/conf.d/phpMyAdmin.conf'.
We will enable mailing of each blocked dos attack from mod_evasive. Email we'll use is root@$MY_DOMAIN.
We also set a 25 MaxConnection per IP Global limit using mod_limitipconn '/etc/httpd/conf.d/limitipconn.conf'.
EOF

yum -y -q install mod_security mod_security_crs mod_evasive mod_bw mod_limitipconn; echo ""
getfiles ${mod_pagespeed##*/} $mod_pagespeed
yum -y -q install /tmp/${mod_pagespeed##*/}

mv /etc/httpd/conf.d/limitipconn.{conf,disable}
mv /etc/httpd/conf.d/mod_security.{conf,disable}

cat <<'EOF' > /etc/httpd/conf.d/limitipconn.conf
# This module will not function unless mod_status is loaded and the
# "ExtendedStatus On" directive is set. So load only if mod_status is too.
<IfModule mod_status.c>

    # This is always needed
    ExtendedStatus On

    # mod_limitipconn configuration
    LoadModule limitipconn_module modules/mod_limitipconn.so

    # A global default configuration doesn't make much sense. See the README
    # from the mod_limitipconn package for configuration examples.

    <IfModule mod_limitipconn.c>
        # Set a server-wide limit of 25 simultaneous downloads per IP,
        # no matter what.
        MaxConnPerIP 25
    </IfModule>
</IfModule>
EOF

sed -i "s/#DOSEmailNotify      you@yourdomain.com/DOSEmailNotify      root@$MY_DOMAIN/g" /etc/httpd/conf.d/mod_evasive.conf

ctrl_service httpd restart; echo ""
rm -f /tmp/${mod_pagespeed##*/}
}

Upgrade_Awstats () {
local domain=$(echo $MY_DOMAIN | awk -F'.' '{ printf "%s\\\\.%s\n", $1, $2 }')

mv /etc/awstats /etc/awstats_bak
mv /etc/httpd/conf.d/awstats.conf /etc/httpd/conf.d/awstats.conf.bak

yum -y -q install $awstats_url

ln -sT ../../usr/local/awstats /usr/share/awstats
cp -p /usr/local/awstats/tools/httpd_conf /etc/httpd/conf.d/awstats.conf
mv /etc/awstats/awstats.model.conf /etc/awstats/awstats.model.conf.bak
cp -p /etc/awstats_bak/awstats.$MY_HOSTNAME.conf /etc/awstats
cp -p /etc/awstats_bak/awstats.model.conf /etc/awstats
ln -s ../../etc/awstats/awstats.model.conf /etc/awstats/awstats.conf

[[ ! -d /var/lib/awstats ]] && mkdir -pv /var/lib/awstats

sed -i 's/local/share/g' /etc/httpd/conf.d/awstats.conf
sed -i "s/^LogFile=\"\(.*\)\"/LogFile=\"\/var\/log\/ispconfig\/httpd\/$MY_HOSTNAME\/access.log\"/g" /etc/awstats/awstats.$MY_HOSTNAME.conf
sed -i "s/^SkipHosts=\"\(.*\)\"/SkipHosts=\"REGEX\[^192\\\\.168\\\\.\] REGEX\[^10\\\\.\] REGEX\[^172\\\\.16\\\\.\]\"/g" /etc/awstats/awstats.$MY_HOSTNAME.conf
sed -i "s/^SkipHosts=\"\(.*\)\"/SkipHosts=\"REGEX\[^192\\\\.168\\\\.\] REGEX\[^10\\\\.\] REGEX\[^172\\\\.16\\\\.\]\"/g" /etc/awstats/awstats.model.conf
sed -i "s/DefaultFile=\(.*\)/DefaultFile=\"awsindex.html index.php index.html\"/g" /etc/awstats/awstats.model.conf
sed -i "s/^SiteDomain=\(.*\)/SiteDomain=\"localhost.localdomain\"/g" /etc/awstats/awstats.model.conf
sed -i "s/^HostAliases=\(.*\)/HostAliases=\"localhost 127.0.0.1\"/g" /etc/awstats/awstats.model.conf

ctrl_service httpd stop && ctrl_service httpd start

echo -e "\nYou will want to double check all paths to awstats inside of ISPConfig and correct them if needed. \n"

perl /usr/share/awstats/tools/awstats_updateall.pl now -configdir=/etc/awstats
}

Fix_vhost_Awstats () { # ONLY TO BE RAN AFTER ENABLING IN ISPCONFIG
local subdomain=""

read -ep "You must enable Awstats first before running this! Have you done this for a domain you wish to proceed with?" yesno

if [[ $yesno = 'yes' ]]; then

  :

else

  echo -e "\nYou must enable awstats for your domain. \n" && exit 10

fi

find /var/www -maxdepth 1 -type l -exec ls -l {} \; | awk '{ printf "%s => %s\n", $9, $11 }'; echo -e "\n\n" # This shows symbolic links in /var/www

if [[ -z $C_Domain ]]; then

    read -ep "Please enter a domain name [${MY_DOMAIN}]: " C_Domain
    C_Domain="${C_Domain:-${MY_DOMAIN}}"

fi

if [[ ! -e /var/www/$C_Domain ]]; then

    echo -e "\nThat domain does not exist! \n" && unset C_Domain && exit 15

fi

if [[ ! -f /etc/awstats/awstats.$C_Domain.conf ]]; then

    echo -e "\nNo AWStats configuration file found. Exiting now! \n" && exit 20

fi

local userhome=$(ls -ld /var/www/$C_Domain | awk '{ printf "%s\n", $11 }' | sed 's/\/$//g')
read -ep "If this is a subdomain, please enter that part only now. Example sub.domain.com you would enter 'sub' only " subdomain

if [[ -n $subdomain ]]; then

    local statspath=\"$userhome/$subdomain/stats\"

else

    local statspath=\"$userhome/web/stats\"

fi

sed -i "s/^LogFile=\"\(.*\)\"/LogFile=\"\/var\/log\/ispconfig\/httpd\/$C_Domain\/access.log\"/g" /etc/awstats/awstats.$C_Domain.conf
echo -e "\nDirData=$statspath" >> /etc/awstats/awstats.$C_Domain.conf
echo "DefaultFile=\"awsindex.html index.php index.html\"" >> /etc/awstats/awstats.$C_Domain.conf

perl /usr/share/awstats/wwwroot/cgi-bin/awstats.pl -update -config=$C_Domain -configdir=/etc/awstats
perl /usr/share/awstats/wwwroot/cgi-bin/awstats.pl -config=$C_Domain -output -staticlinks > $(echo $statspath | sed -e "s/^\"//g" -e "s/$\"//g" )/awsindex.html
}

Awstats_FTP_Stats () {
[[ -f /etc/awstats/awstats.model.conf ]] && cp -p /etc/awstats/awstats.model.conf /etc/awstats/awstats.ftp.conf
sed -i "s/^LogFile=\(.*\)/LogFile=\"\/var\/log\/pure-ftpd\/pureftpd.log\"/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^LogType=\(.*\)/LogType=F/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^LogFormat=\(.*\)/LogFormat=\"%host %logname %time1 %method %url %code %bytesd\"/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^NotPageList=\(.*\)/NotPageList=\"\"/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^LevelForBrowsersDetection=\(.*\)/LevelForBrowsersDetection=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^LevelForOSDetection=\(.*\)/LevelForOSDetection=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^LevelForRefererAnalyze=\(.*\)/LevelForRefererAnalyze=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^LevelForRobotsDetection=\(.*\)/LevelForRobotsDetection=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^LevelForWormsDetection=\(.*\)/LevelForWormsDetection=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^LevelForSearchEnginesDetection=\(.*\)/LevelForSearchEnginesDetection=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowLinksOnUrl=\(.*\)/ShowLinksOnUrl=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowMenu=\(.*\)/ShowMenu=1/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowSummary=\(.*\)/ShowSummary=UVHB/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowMonthStats=\(.*\)/ShowMonthStats=UVHB/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowDaysOfMonthStats=\(.*\)/ShowDaysOfMonthStats=HB/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowDaysOfWeekStats=\(.*\)/ShowDaysOfWeekStats=HB/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowHoursStats=\(.*\)/ShowHoursStats=HB/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowDomainsStats=\(.*\)/ShowDomainsStats=HB/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowHostsStats=\(.*\)/ShowHostsStats=HBL/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowAuthenticatedUsers=\(.*\)/ShowAuthenticatedUsers=HBL/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowRobotsStats=\(.*\)/ShowRobotsStats=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowEMailSenders=\(.*\)/ShowEMailSenders=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowEMailReceivers=\(.*\)/ShowEMailReceivers=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowSessionsStats=\(.*\)/ShowSessionsStats=1/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowPagesStats=\(.*\)/ShowPagesStats=PBEX/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowFileTypesStats=\(.*\)/ShowFileTypesStats=HB/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowFileSizesStats=\(.*\)/ShowFileSizesStats=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowBrowsersStats=\(.*\)/ShowBrowsersStats=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowOSStats=\(.*\)/ShowOSStats=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowOriginStats=\(.*\)/ShowOriginStats=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowKeyphrasesStats=\(.*\)/ShowKeyphrasesStats=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowKeywordsStats=\(.*\)/ShowKeywordsStats=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowMiscStats=\(.*\)/ShowMiscStats=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowHTTPErrorsStats=\(.*\)/ShowHTTPErrorsStats=0/g" /etc/awstats/awstats.ftp.conf
sed -i "s/^ShowSMTPErrorsStats=\(.*\)/ShowSMTPErrorsStats=0/g" /etc/awstats/awstats.ftp.conf
perl /usr/share/awstats/wwwroot/cgi-bin/awstats.pl -update -config=ftp -configdir=/etc/awstats
}

Awstats_MAIL_Stats () {
[[ -f /etc/awstats/awstats.model.conf ]] && cp -p /etc/awstats/awstats.model.conf /etc/awstats/awstats.mail.conf
sed -i "s/^LogFile=\(.*\)/LogFile=\"\/usr\/share\/awstats\/tools\/maillogconvert.pl standard < \/var\/log\/maillog |\"/g" /etc/awstats/awstats.mail.conf
sed -i "s/^LogType=\(.*\)/LogType=M/g" /etc/awstats/awstats.mail.conf
sed -i "s/^LogFormat=\(.*\)/LogFormat=\"%time2 %email %email_r %host %host_r %method %url %code %bytesd\"/g" /etc/awstats/awstats.mail.conf
sed -i "s/^LevelForBrowsersDetection=\(.*\)/LevelForBrowsersDetection=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^LevelForOSDetection=\(.*\)/LevelForOSDetection=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^LevelForRefererAnalyze=\(.*\)/LevelForRefererAnalyze=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^LevelForRobotsDetection=\(.*\)/LevelForRobotsDetection=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^LevelForWormsDetection=\(.*\)/LevelForWormsDetection=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^LevelForSearchEnginesDetection=\(.*\)/LevelForSearchEnginesDetection=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^LevelForFileTypesDetection=\(.*\)/LevelForFileTypesDetection=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowMenu=\(.*\)/ShowMenu=1/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowSummary=\(.*\)/ShowSummary=HB/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowMonthStats=\(.*\)/ShowMonthStats=HB/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowDaysOfMonthStats=\(.*\)/ShowDaysOfMonthStats=HB/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowDaysOfWeekStats=\(.*\)/ShowDaysOfWeekStats=HB/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowHoursStats=\(.*\)/ShowHoursStats=HB/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowDomainsStats=\(.*\)/ShowDomainsStats=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowHostsStats=\(.*\)/ShowHostsStats=HBL/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowAuthenticatedUsers=\(.*\)/ShowAuthenticatedUsers=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowRobotsStats=\(.*\)/ShowRobotsStats=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowEMailSenders=\(.*\)/ShowEMailSenders=HBML/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowEMailReceivers=\(.*\)/ShowEMailReceivers=HBML/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowSessionsStats=\(.*\)/ShowSessionsStats=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowPagesStats=\(.*\)/ShowPagesStats=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowFileTypesStats=\(.*\)/ShowFileTypesStats=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowFileSizesStats=\(.*\)/ShowFileSizesStats=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowBrowsersStats=\(.*\)/ShowBrowsersStats=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowOSStats=\(.*\)/ShowOSStats=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowOriginStats=\(.*\)/ShowOriginStats=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowKeyphrasesStats=\(.*\)/ShowKeyphrasesStats=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowKeywordsStats=\(.*\)/ShowKeywordsStats=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowMiscStats=\(.*\)/ShowMiscStats=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowHTTPErrorsStats=\(.*\)/ShowHTTPErrorsStats=0/g" /etc/awstats/awstats.mail.conf
sed -i "s/^ShowSMTPErrorsStats=\(.*\)/ShowSMTPErrorsStats=1/g" /etc/awstats/awstats.mail.conf
perl /usr/share/awstats/wwwroot/cgi-bin/awstats.pl -update -config=mail -configdir=/etc/awstats
}

Upgrade_phpMyAdmin () { # Does not upgrade the phpMyAdmin DATABASE
read -ep "Please enter a base directory [${HOME}]: " base_dir
local base_dir=${base_dir:-${HOME}}
local backupdir=$base_dir/pma_backup

[[ ! -d $backupdir ]] && mkdir -p $backupdir
chown -R root:root $backupdir
chmod 700 $backupdir

mv /usr/share/phpMyAdmin/config.inc.php $backupdir/config.inc.php.sym
mv /usr/share/phpMyAdmin $backupdir/pma_old

getfiles $pma_file $phpmyadmin_url
extract_tars /tmp/$pma_file /tmp

mv /tmp/$pma_extdir /usr/share/phpMyAdmin
mv $backupdir/config.inc.php.sym /usr/share/phpMyAdmin/config.inc.php

chown -R root:root /usr/share/phpMyAdmin

rm -rf /usr/share/phpMyAdmin/setup
rm -f /tmp/$pma_file; echo -e "\nThe upgrade of phpMyAdmin has been completed! Restarting apache now to finish. \nPlease remove $backupdir/pma_old directory once upgrade verified successfully! \n"
ctrl_service httpd restart
}

Monitoring_essentials () {
cat <<EOF
We are going to install performance, system monitoring, network related tools now.
This includes 'Performance Tools', smartmontools, hddtemp, lm_sensors, atop, iptraf, openswan, arpwatch, iptstate, mrtg, rrd-tool, stunnel, vtun.
EOF

yum -y -q groupinstall "Performance Tools"
yum -y -q install smartmontools hddtemp lm_sensors atop iptraf lm_sensors-devel liboping-devel libatasmart libatasmart-devel iptables-devel
yum -y -q install openswan openswan-doc arpwatch iptstate mrtg stunnel vtun rrdtool rrdutils rrdtool-perl rrdtool-php rrdtool-doc rrdtool-devel

init_service arpwatch on
ctrl_service arpwatch start

init_service atop on
ctrl_service atop start

init_service smartd on
ctrl_service smartd start

init_service hddtemp on
ctrl_service hddtemp start

sensors-detect

init_service lm_sensors on
ctrl_service lm_sensors start
}

Extras_Menu () {
clear; cat <<EOF
What would you like to do? [1-9]

Apache_Extras - Used to install mod_{security, security_crs, evasive, bw, limitipconn}

System_Awstats - Used to upgrade Awstats

vhost_Awstats - Used to fix Awstats configuration on a per vhost basis

phpMyAdmin_upgrader - Used to upgrade to the latest version of phpMyAdmin

AutoMySQLBackup - Used to install AutoMySQLBackup on the system

Extra_Tools - Install some extra performance and basic system monitoring related tools

Roundcube - Install Roundcube system wide

HordeWM - Install Horde WebMail system wide

quit -- Exits 

EOF

select choice in Apache_Extras System_Awstats vhost_Awstats phpMyAdmin_upgrader AutoMySQLBackup Extra_Tools Roundcube HordeWM quit; do

    case $choice in

        Apache_Extras)

            Install_Extra_Apache_Modz  ;;

        System_Awstats)

            Upgrade_Awstats ;;

        vhost_Awstats)

            Fix_vhost_Awstats ;;

        phpMyAdmin_upgrader)

            Upgrade_phpMyAdmin ;;

        AutoMySQLBackup)

            Install_AutoMySQLBackup ;;

        Extra_Tools)

            Monitoring_essentials ;;

        Roundcube)

            Install_Roundcube ;;

        HordeWM)

            Install_HordeWM ;;

        quit)

            unset mysql_pass && echo -e "\nExiting now per your request \n" && exit 0 ;;

    esac

done
}

Security_Menu () {
clear; cat <<EOF
What would you like to do? [1-9]

APF: Installs APF - Advanced Policy Firewall: Used in place of ISPConfig's firewall.

BFD: Installs BFD - Brute Force Detection: Monitors services for brute force attempts and uses APF to deny attackers by default.

OSSEC - Install OSSEC HIDS

OSSEC-WUI - Install OSSEC-WUI for OSSEC

Authy - Install Authy two factor authentication

Duo_Security - Install Duo Security two factor authentication

Enable-DKIM - Enables DKIM support to ISPConfig via amavisd

Clamscanning_PureFTPd - Enable Clamav Scanning for PureFTPd

quit -- Exits

EOF

select choice in APF BFD OSSEC OSSEC-WUI Authy Duo_Security Enable-DKIM Clamscanning_PureFTPd quit; do

    case $choice in

        APF)

            Install_APF ;;

        BFD)

            Install_BFD ;;

        OSSEC)

            Install_OSSEC ;;

        OSSEC-WUI)

            Install_OSSEC_WUI ;;

        Authy)

            Install_Authy ;;

        Duo_Security)

            Install_Duo_Security ;;

        Enable-DKIM)

            Enable_DKIM ;;

        Clamscanning_PureFTPd)

            Enable_Clamscanning_PureFTPd ;;

        quit)

            unset mysql_pass && echo -e "\nExiting now per your request \n" && exit 0 ;;

    esac

done
}

Monitoring_Menu () {
clear; cat <<EOF
What would you like to do? [1-10]

Munin -- Installs munin graphing utility

Monit -- Installs monit monitoring

Nagios -- Installs Nagios moniting suite

PNP4Nagios -- Installs pnp4nagios graphing suite

Check_MK -- Installs check_mk an addon for nagios

AWstats_FTP -- Creates and enables FTP statistics

Awstats_MAIL -- Creates and enables Mail statistics

Collectd -- Creates rrd graphs of systems related statistics

NewRelic -- A remote monitoring service for your server

quit -- Exits 

EOF

select choice in Munin Monit Nagios PNP4Nagios Check_MK AWstats_FTP Awstats_MAIL Collectd NewRelic quit; do

    case $choice in

        Munin)

            Install_Munin ;;

        Monit)

            Install_Monit ;;

        Nagios)

            Install_Nagios ;;

        PNP4Nagios)

            Install_PNP4Nagios ;;

        Check_MK)

            Install_CheckMK ;;

        AWstats_FTP)

            Awstats_FTP_Stats ;;

        Awstats_MAIL)

            Awstats_MAIL_Stats ;;

        Collectd)

            Install_Collectd ;;

         NewRelic)

            Install_NewRelic ;;

        quit)

            echo -e "\nExiting now per your request \n" && exit 0 ;;

    esac

done
}

Install_OSSEC () {
#local ossec_dir=$(echo ${ossec_url##*/} | sed "s/.tar.gz$//g")
if [[ -x /var/ossec/bin/ossec-execd || -x /var/ossec/bin/ossec-monitord || -x /opt/ossec/bin/ossec-execd ]]; then

    echo -e "\nIt appears ossec has already been installed on your system. \n" && exit 1

fi

getfiles ${ossec_url##*/} $ossec_url
extract_tars /tmp/${ossec_url##*/} /tmp

cd /tmp/ossec-hids-*
cd src; make setdb; cd .. # Enables Database support for ossec
bash install.sh

init_service ossec on
ctrl_service ossec start

echo -e "\nOSSEC has been installed, this script might be of use to use!! '/var/ossec/bin/util.sh' assuming you kept default install directory. \n Documentation: http://ossec-docs.readthedocs.org/en/latest/index.html \n\n"
rm -rf /tmp/ossec-hids-* /tmp/${ossec_url##*/}
}

Install_OSSEC_WUI () {
if [[ -d /usr/share/ossec-wui ]]; then

    echo -e "\nIt appears that ossec-wui is located at /usr/share/ossec-wui already \n" && exit 1

fi

getfiles ${ossec_wui_url##*/} $ossec_wui_url
unzip /tmp/${ossec_wui_url##*/} -d /tmp

rm -f /tmp/${ossec_wui_url##*/}
mv /tmp/ossec-wui-* /usr/share/ossec-wui
cd /usr/share/ossec-wui
bash setup.sh

chown -R root:root /usr/share/ossec-wui
chmod 770 /var/ossec/tmp
chgrp apache /var/ossec/tmp

cat <<EOF > /etc/httpd/conf.d/ossec-wui.conf
Alias /ossec-wui /usr/share/ossec-wui

<Directory "/usr/share/ossec-wui">
AuthUserFile /usr/share/ossec-wui/.htpasswd
AuthName "Restricted Access"
Require valid-user
AuthType Basic

<Files *.sh>
  deny from all
</Files>

<Files ossec_conf.php>
  deny from all
</Files>

<Files .*>
  deny from all
</Files>
Order Deny,Allow
Deny from ALL
Allow from ALL
</Directory>
EOF

ctrl_service httpd stop && ctrl_service httpd start

rm -f /tmp/${ossec_wui_url##*/}
echo -e "\nThe script should have taken care of everything you needed to be setup. If not read this file => /usr/share/ossec-wui/README \n"
}

Install_Authy () {
local tmp_user=root
local tmp_cc=1
if [[ -x /usr/local/bin/authy-ssh || -x /usr/bin/authy-ssh ]]; then

    echo -e "\nIt appears that authy-ssh has already installed. \n" && exit 1

fi

isValidPhoneNum () {
case $1 in

    "" | *[!0-9-]* | *[!0-9])

        return 1 ;;

esac

local IFS='-'
set -- $1

[[ $# -eq 3 ]] && [[ ${#1} -eq 3 ]] && [[ ${#2} -eq 3 ]] && [[ ${#3} -eq 4 ]]
}

read -ep "Please visit https://www.authy.com/signup and sign up for a free account and get a API-KEY. Do you have a API-KEY? [y/n]: " yesno

if [[ $yesno = n || $yesno = no || $yesno = "" ]]; then

    echo -e "\nPlease visit https://www.authy.com/products/ssh for more information. \n" && exit 1

fi

echo -e "\nThese prompts for information regarding to the first user you will protect. root by default \n"

read -ep "Please enter your User Name [${tmp_user}]: " a_user

local a_user=${a_user:-${tmp_user}}; echo ""

read -ep "Please enter your Email Address [${email_address}]: " a_email

local a_email=${a_email:-${email_address}}; echo ""

read -ep "Please enter your country-code [${tmp_cc}]: " a_ccode

local a_code=${a_code:-${tmp_cc}}; echo ""

read -ep "Please enter your (include the dashes) Cell Phone Number: " a_phone

if isValidPhoneNum $a_phone; then

    local a_phone=${a_phone}

else

    echo -e "\nThe number $a_phone is not correct. Ex: 123-456-7890 \n" && exit 1

fi

getfiles ${authy_ssl_url##*/} $authy_ssl_url

sudo bash /tmp/${authy_ssl_url##*/} install /usr/local/bin

/usr/local/bin/authy-ssh enable $a_user $a_email $a_ccode $a_phone
/usr/local/bin/authy-ssh test

ctrl_service sshd restart

rm -f /tmp/${authy_ssl_url##*/}
echo -e "\nAuthy-SSH has been installed and configured you can add more user's using ~/authy_useradd.sh or login as $a_user to test now. \n"
}

Install_Duo_Security () {
if [[ -x /usr/sbin/login_duo ]]; then

    echo -e "\nIt appears that duo-security has already installed. \n" && exit 1

fi

read -ep "Please visit https://signup.duosecurity.com/ and sign up for a free account and get a API-KEY. Do you have a API-KEY? [y/n]: " yesno

if [[ $yesno = n || $yesno = no || $yesno = "" ]]; then

    echo -e "\nPlease visit https://www.duosecurity.com/docs/duounix for more information. \n" && exit 1

fi

yum -y -q install openssl-devel pam-devel

getfiles ${duo_security_url##*/} $duo_security_url
extract_tars /tmp/${duo_security_url##*/} /tmp

local duo_dir=$(ls -l /tmp | awk '{ print $9 }' | grep "^duo_unix-[.0-9]" | awk '{ printf "%s\n", $1 }')
cd /tmp/$duo_dir

./configure --with-pam --prefix=/usr && make && make install

echo -e "\n\n"
read -ep "About to open configuration file to enter information. Press ENTER to continue. " enter

vim /etc/duo/login_duo.conf

echo -e "\nAdding configuration settings to sshd_config. \n"
echo "ForceCommand /usr/sbin/login_duo" >> /etc/ssh/sshd_config
echo "PermitTunnel no" >> /etc/ssh/sshd_config
echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
echo -e "Almost done configuring sshd for Duo Security two-factor authentication! Please restart the sshd service afterwards to enable. \n"

cd; rm -rf /tmp/duo_unix-*
echo -e "Enroll Device with below link. \n"

/usr/sbin/login_duo
}

Install_AutoMySQLBackup () {
if [[ -x /usr/local/bin/automysqlbackup || -x /usr/bin/automysqlbackup ]]; then

    echo -e "\nIt appears automysqlbackup has already been installed. \n" && exit 1

fi

getfiles $automysql_file $automysqlbackup_url
mkdir -p $HOME/automysql
extract_tars /tmp/$automysql_file $HOME/automysql

cd $HOME/automysql
./install.sh
rm -rf $HOME/automysql /tmp/$automysql_file
echo -e "\nAutoMySQLBackup has been installed. You will need to setup it up to do your bidding this might help. http://www.howtoforge.com/creating-mysql-backups-with-automysqlbackup \n"
echo -e "Should add 'performance_schema' to the excluded DB's to backup \n"
}

Enable_DKIM () {
[[ ! -d /var/db/dkim ]] && mkdir -p /var/db/dkim/
ln -s /etc/amavisd/amavisd.conf /etc/amavisd.conf
PUB_IP=$(wget -q -O - checkip.dyndns.org | awk -F":" '{ print $2 }' | sed -e "s/^ //g" | awk -F"<" '{ print $1 }')

cat <<EOF >> /etc/amavisd/amavisd.conf


# Amavisd DKIM Keys

@mynetworks = qw(127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 $PUB_IP/32);  # list your internal networks

\$enable_dkim_verification = 1;
\$enable_dkim_signing = 1;

EOF

ctrl_service amavisd restart

[[ ! -d /scripts ]] && mkdir -p /scripts
echo -e "Downloading my scripts to enable dkim on a per domain basis, email backup and openvz control scripts. \n"
git clone --progress https://github.com/jsloan117/Advanced-ISPCIS.git /scripts # Downloads this script, enable_dkim script, and email_backup script, and openvz_ctrl script
}

Install_Roundcube () {
if [[ -z $roundcube_password ]]; then

  tmp=$(tr -dc '[:alnum:]' < /dev/urandom | head -c30 | sha512sum | head -c30)
  read -p "MySQL roundcube user password [${tmp}]:" roundcube_password
  roundcube_password=${roundcube_password:-${tmp}}
  echo "MySQL roundcube: ${roundcube_password}" >> $prog_pass

fi

if [ -z $mysql_pass ]; then
  read -p "MySQL root password []:" mysql_pass
fi

getfiles $roundcube_file $roundcubemail_url

extract_tars /tmp/$roundcube_file /tmp

rm -f /tmp/$roundcube_file
mv /tmp/roundcubemail-* /usr/share/roundcube

[[ ! -d /etc/roundcube ]] && mkdir -p /etc/roundcube
[[ ! -d /var/log/roundcube ]] && mkdir -p /var/log/roundcube
chown root:root -R /usr/share/roundcube
chgrp apache /var/log/roundcube

cat <<'EOF' > /etc/httpd/conf.d/roundcube.conf
#
# Roundcube is a webmail package written in PHP.
#

Alias /roundcube /usr/share/roundcube

<Directory /usr/share/roundcube>
  Order Deny,Allow
  Deny from All
  Allow from All
  Options -Indexes
  AllowOverride All
</Directory>

<Directory /usr/share/roundcube/config>
  Order Deny,Allow
  Deny from All
</Directory>

<Directory /usr/share/roundcube/temp>
  Order Deny,Allow
  Deny from All
</Directory>

<Directory /usr/share/roundcube/logs>
  Order Deny,Allow
  Deny from All
</Directory>

# Enable SSL Below
<Directory /usr/share/roundcube>
  RewriteEngine  on
  RewriteCond    %{HTTPS} !=on
  RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
</Directory>
EOF

cat <<EOF > /etc/roundcube/config.inc.php
<?php

/* Local configuration for Roundcube Webmail */

// ----------------------------------
// SQL DATABASE
// ----------------------------------
// Database connection string (DSN) for read+write operations
// Format (compatible with PEAR MDB2): db_provider://user:password@host/database
// Currently supported db_providers: mysql, pgsql, sqlite, mssql or sqlsrv
// For examples see http://pear.php.net/manual/en/package.database.mdb2.intro-dsn.php
// NOTE: for SQLite use absolute path: 'sqlite:////full/path/to/sqlite.db?mode=0646'
\$config['db_dsnw'] = 'mysql://roundcube:$roundcube_password@localhost/roundcube';

// ----------------------------------
// IMAP
// ----------------------------------
// The mail host chosen to perform the log-in.
// Leave blank to show a textbox at login, give a list of hosts
// to display a pulldown menu or set one host as string.
// To use SSL/TLS connection, enter hostname with prefix ssl:// or tls://
// Supported replacement variables:
// %n - hostname (\$_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname \$_SERVER['HTTP_HOST'] without the first part)
// %s - domain name after the '@' from e-mail address provided at login screen
// For example %n = mail.domain.tld, %t = domain.tld
// WARNING: After hostname change update of mail_host column in users table is
//          required to match old user data records with the new host.
\$config['default_host'] = 'localhost';

// ----------------------------------
// SMTP
// ----------------------------------
// SMTP server host (for sending mails).
// To use SSL/TLS connection, enter hostname with prefix ssl:// or tls://
// If left blank, the PHP mail() function is used
// Supported replacement variables:
// %h - user's IMAP hostname
// %n - hostname (\$_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname \$_SERVER['HTTP_HOST'] without the first part)
// %z - IMAP domain (IMAP hostname without the first part)
// For example %n = mail.domain.tld, %t = domain.tld
\$config['smtp_server'] = 'localhost';

// SMTP port (default is 25; use 587 for STARTTLS or 465 for the
// deprecated SSL over SMTP (aka SMTPS))
\$config['smtp_port'] = 25;

// SMTP username (if required) if you use %u as the username Roundcube
// will use the current username for login
\$config['smtp_user'] = '%u';

// SMTP password (if required) if you use %p as the password Roundcube
// will use the current user's password for login
\$config['smtp_pass'] = '%p';

// provide an URL where a user can get support for this Roundcube installation
// PLEASE DO NOT LINK TO THE ROUNDCUBE.NET WEBSITE HERE!
;\$config['support_url'] = '';

// e.g. array( 'localhost:11211', '192.168.1.12:11211', 'unix:///var/tmp/memcached.sock' );
// check client IP in session authorization
\$config['ip_check'] = true;

// this key is used to encrypt the users imap password which is stored
// in the session record (and the client cookie if remember password is enabled).
// please provide a string of exactly 24 chars.
\$config['des_key'] = '$(tr -dc '[:alnum:]' < /dev/urandom | head -c30 | sha512sum | head -c24)';

// ----------------------------------
// PLUGINS
// ----------------------------------
// List of active plugins (in plugins/ directory)
\$config['plugins'] = array();

// Set the spell checking engine. Possible values:
// - 'googie'  - the default
// - 'pspell'  - requires the PHP Pspell module and aspell installed
// - 'enchant' - requires the PHP Enchant module
// - 'atd'     - install your own After the Deadline server or check with the people at http://www.afterthedeadline.com before using their API
// Since Google shut down their public spell checking service, you need to
// connect to a Nox Spell Server when using 'googie' here. Therefore specify the 'spellcheck_uri'
\$config['spellcheck_engine'] = 'enchant';

// use this folder to store log files (must be writeable for apache user)
// This is used by the 'file' log driver.
\$config['log_dir'] = '/var/log/roundcube';

// use this folder to store temp files (must be writeable for apache user)
\$config['temp_dir'] = '/var/tmp';

// expire files in temp_dir after 48 hours
// possible units: s, m, h, d, w
\$config['temp_dir_ttl'] = '8h';

// log driver:  'syslog' or 'file'.
\$config['log_driver'] = 'file';

// Log sent messages to <log_dir>/sendmail or to syslog
\$config['smtp_log'] = true;

// Log successful/failed logins to <log_dir>/userlogins or to syslog
\$config['log_logins'] = true;

// Log session authentication errors to <log_dir>/session or to syslog
\$config['log_session'] = true;
?>
EOF

chgrp apache /etc/roundcube/config.inc.php
chmod 640 /etc/roundcube/config.inc.php
ln -s /etc/roundcube/config.inc.php /usr/share/roundcube/config/config.inc.php

cat <<EOF | mysql -u root -p$mysql_pass
USE mysql;
CREATE USER 'roundcube'@'localhost' IDENTIFIED BY '$roundcube_password';
GRANT USAGE ON *.* TO 'roundcube'@'localhost' IDENTIFIED BY '$roundcube_password';
CREATE DATABASE IF NOT EXISTS \`roundcube\`;
GRANT ALL PRIVILEGES ON \`roundcube\`.* TO 'roundcube'@'localhost';
FLUSH PRIVILEGES;
EOF

mysql -u root -p$mysql_pass 'roundcube' < /usr/share/roundcube/SQL/mysql.initial.sql

ctrl_service httpd restart
rm -rf /usr/share/roundcube/installer; unset roundcube_password
}

Install_HordeWM () {
if [[ -z $hordewm_password ]]; then

  tmp=$(tr -dc '[:alnum:]' < /dev/urandom | head -c30 | sha512sum | head -c30)
  read -p "Horde webmail user password [${tmp}]: " hordewm_password
  hordewm_password=${hordewm_password:-${tmp}}
  echo "Horde webmail User: hordeadm" >> $prog_pass
  echo "Horde webmail password: ${hordewm_password}" >> $prog_pass

fi

pear channel-discover pear.horde.org
pear install horde/horde_role
pear run-scripts horde/horde_role
pear install -a -B horde/webmail

# MySQL Code to create Horde's database
cat <<EOF | mysql -u root -p$mysql_pass
CREATE USER 'hordeadm'@'localhost' IDENTIFIED BY '$hordewm_password';
GRANT USAGE ON *.* TO 'hordeadm'@'localhost' IDENTIFIED BY '$hordewm_password';
CREATE DATABASE IF NOT EXISTS \`hordewmdb\`;
GRANT ALL PRIVILEGES ON \`hordewmdb\`.* TO 'hordeadm'@'localhost';
EOF

# MySQL Database needs to be created before the below command is ran
echo -e "\nYou will need the below information to proceed\n"
echo "Horde DB: hordewmdb"
echo "Horde DB User: hordeadm"
echo -e "MySQL Socket: /var/lib/mysql/mysql.sock \n"

webmail-install

[[ ! -d /etc/horde ]] && mkdir -p /etc/horde
[[ ! -d /var/log/horde ]] && mkdir -p /var/log/horde
mv /usr/share/horde/config /etc/horde
ln -sT /etc/horde/config /usr/share/horde/config
chown -R root.apache /etc/horde/config
chmod 770 /etc/horde/config
find /etc/horde/config -type f -exec chmod 660 {} \;
find /etc/horde/config -type d -exec chmod 770 {} \;

cat <<'EOF' > /etc/httpd/conf.d/hordewm.conf
#
# Horde Webmail is a webmail package written in PHP.
#

Alias /horde /usr/share/horde

<Directory /usr/share/horde>
  Order Deny,Allow
  Deny from All
  Allow from All
  Options -Indexes
  AllowOverride All
</Directory>

<Directory /usr/share/horde/config>
  Order Deny,Allow
  Deny from All
</Directory>

# Enable SSL Below
<Directory /usr/share/horde>
  RewriteEngine  on
  RewriteCond    %{HTTPS} !=on
  RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
</Directory>
EOF

ctrl_service httpd restart; unset hordewm_password
}

Install_Munin () {
if [[ -z $munin_password ]]; then

  tmp=$(tr -dc '[:alnum:]' < /dev/urandom | head -c30 | sha512sum | head -c30)
  read -ep "Munin user password [${tmp}]:" munin_password
  munin_password=${munin_password:-${tmp}}
  echo "Munin User: muninadmin" >> $prog_pass
  echo "Munin password: ${munin_password}" >> $prog_pass

fi

yum -y -q install munin-node munin munin-cgi munin-common munin-netip-plugins
htpasswd -b -mc /etc/munin/munin-htpasswd muninadmin "$munin_password"

sed -i "s/    #ServerName \(.*\)/    ServerName munin.$MY_HOSTNAME/g" /etc/httpd/conf.d/munin-cgi.conf
sed -i "s/    #ServerAlias munin/    ServerAlias munin.$MY_DOMAIN/g" /etc/httpd/conf.d/munin-cgi.conf
sed -i "s/    #ServerAdmin  \(.*\)/    ServerAdmin  admin@$MY_HOSTNAME/g" /etc/httpd/conf.d/munin-cgi.conf
sed -i "s/    ErrorLog  \(.*\)/    ErrorLog  \/var\/log\/httpd\/munin.$MY_HOSTNAME-error.log/g" /etc/httpd/conf.d/munin-cgi.conf
sed -i "s/    CustomLog  \(.*\)/    CustomLog  \/var\/log\/httpd\/munin.$MY_HOSTNAME-access.log combined/g" /etc/httpd/conf.d/munin-cgi.conf

ctrl_service httpd restart
init_service munin-node on
ctrl_service munin-node start; unset tmp munin_password
}

Install_Monit () {
getfiles ${monit_url##*/} $monit_url
extract_tars /tmp/${monit_url##*/} /tmp
cd /tmp/monit-*
./configure --enable-optimized
make
make install
mv /usr/local/bin/monit /usr/bin
[[ ! -d /etc/monit.d ]] && mkdir -p /etc/monit.d

cat <<EOF > /etc/monit.conf
###############################################################################
## Monit control file
###############################################################################
##
## Comments begin with a '#' and extend through the end of the line. Keywords
## are case insensitive. All path's MUST BE FULLY QUALIFIED, starting with '/'.
##
## Below you will find examples of some frequently used statements. For
## information about the control file and a complete list of statements and
## options, please have a look in the Monit manual.
##
##
###############################################################################
## Global section
###############################################################################
##
## Start Monit in the background (run as a daemon):
#
set daemon  60              # check services at 1-minute intervals
#   with start delay 240    # optional: delay the first check by 4-minutes (by
#                           # default Monit check immediately after Monit start)
#
#
## Set syslog logging with the 'daemon' facility. If the FACILITY option is
## omitted, Monit will use 'user' facility by default. If you want to log to
## a standalone log file instead, specify the full path to the log file
#
# set logfile syslog facility log_daemon
#
#
## Set the location of the Monit lock file which stores the process id of the
## running Monit instance. By default this file is stored in $HOME/.monit.pid
#
set pidfile /var/run/monit.pid
#
## Set the location of the Monit id file which stores the unique id for the
## Monit instance. The id is generated and stored on first Monit start. By
## default the file is placed in $HOME/.monit.id.
#
# set idfile /var/.monit.id
#
## Set the location of the Monit state file which saves monitoring states
## on each cycle. By default the file is placed in $HOME/.monit.state. If
## the state file is stored on a persistent filesystem, Monit will recover
## the monitoring state across reboots. If it is on temporary filesystem, the
## state will be lost on reboot which may be convenient in some situations.
#
# set statefile /var/.monit.state
#
## Set the list of mail servers for alert delivery. Multiple servers may be
## specified using a comma separator. If the first mail server fails, Monit
# will use the second mail server in the list and so on. By default Monit uses
# port 25 - it is possible to override this with the PORT option.
#
set mailserver mail.$MY_DOMAIN,
                localhost
#
#
## By default Monit will drop alert events if no mail servers are available.
## If you want to keep the alerts for later delivery retry, you can use the
## EVENTQUEUE statement. The base directory where undelivered alerts will be
## stored is specified by the BASEDIR option. You can limit the queue size
## by using the SLOTS option (if omitted, the queue is limited by space
## available in the back end filesystem).
#
# set eventqueue
#     basedir /var/monit  # set the base directory where events will be stored
#     slots 100           # optionally limit the queue size
#
#
## Send status and events to M/Monit (for more informations about M/Monit
## see http://mmonit.com/). By default Monit registers credentials with
## M/Monit so M/Monit can smoothly communicate back to Monit and you don't
## have to register Monit credentials manually in M/Monit. It is possible to
## disable credential registration using the commented out option below.
## Though, if safety is a concern we recommend instead using https when
## communicating with M/Monit and send credentials encrypted.
#
# set mmonit http://monit:monit@192.168.1.10:8080/collector
#     # and register without credentials     # Don't register credentials
#
#
## Monit by default uses the following format for alerts if the the mail-format
## statement is missing::
## --8<--
set mail-format {
     from: monit@\$HOST
     subject: monit alert --  \$EVENT \$SERVICE
     message: $EVENT Service \$SERVICE
                 Date:        \$DATE
                 Action:      \$ACTION
                 Host:        \$HOST
                 Description: \$DESCRIPTION

            Your faithful employee,
            Monit
}
## --8<--
##
## You can override this message format or parts of it, such as subject
## or sender using the MAIL-FORMAT statement. Macros such as $DATE, etc.
## are expanded at runtime. For example, to override the sender, use:
#
set mail-format { from: monit@$MY_DOMAIN }
#
#
## You can set alert recipients whom will receive alerts if/when a
## service defined in this file has errors. Alerts may be restricted on
## events by using a filter as in the second example below.
#
# set alert sysadm@foo.bar                       # receive all alerts
#
## Do not alert when Monit starts, stops or performs a user initiated action.
## This filter is recommended to avoid getting alerts for trivial cases.
#
# set alert your-name@your.domain not on { instance, action }
#
#
## Monit has an embedded HTTP interface which can be used to view status of
## services monitored and manage services from a web interface. The HTTP
## interface is also required if you want to issue Monit commands from the
## command line, such as 'monit status' or 'monit restart service' The reason
## for this is that the Monit client uses the HTTP interface to send these
## commands to a running Monit daemon. See the Monit Wiki if you want to
## enable SSL for the HTTP interface.
#
set httpd port 2812 and
    use address $MY_IP
    allow admin:$(tr -dc '[:alnum:]' < /dev/urandom | head -c30 | sha512sum | head -c10)

###############################################################################
## Services
###############################################################################
##
## Check general system resources such as load average, cpu and memory
## usage. Each test specifies a resource, conditions and the action to be
## performed should a test fail.
#
check system $MY_HOSTNAME
    if loadavg (1min) > 4 then alert
    if loadavg (5min) > 2 then alert
    if memory usage > 75% then alert
    if swap usage > 25% then alert
    if cpu usage (user) > 70% then alert
    if cpu usage (system) > 30% then alert
    if cpu usage (wait) > 20% then alert
#
#
## Check if a file exists, checksum, permissions, uid and gid. In addition
## to alert recipients in the global section, customized alert can be sent to
## additional recipients by specifying a local alert handler. The service may
## be grouped using the GROUP option. More than one group can be specified by
## repeating the 'group name' statement.
#
#  check file apache_bin with path /usr/local/apache/bin/httpd
#    if failed checksum and
#       expect the sum 8f7f419955cefa0b33a2ba316cba3659 then unmonitor
#    if failed permission 755 then unmonitor
#    if failed uid root then unmonitor
#    if failed gid root then unmonitor
#    alert security@foo.bar on {
#           checksum, permission, uid, gid, unmonitor
#        } with the mail-format { subject: Alarm! }
#    group server
#
#
## Check that a process is running, in this case Apache, and that it respond
## to HTTP and HTTPS requests. Check its resource usage such as cpu and memory,
## and number of children. If the process is not running, Monit will restart
## it by default. In case the service is restarted very often and the
## problem remains, it is possible to disable monitoring using the TIMEOUT
## statement. This service depends on another service (apache_bin) which
## is defined above.
#
#  check process apache with pidfile /usr/local/apache/logs/httpd.pid
#    start program = "/etc/init.d/httpd start" with timeout 60 seconds
#    stop program  = "/etc/init.d/httpd stop"
#    if cpu > 60% for 2 cycles then alert
#    if cpu > 80% for 5 cycles then restart
#    if totalmem > 200.0 MB for 5 cycles then restart
#    if children > 250 then restart
#    if loadavg(5min) greater than 10 for 8 cycles then stop
#    if failed host www.tildeslash.com port 80 protocol http
#       and request "/somefile.html"
#    then restart
#    if failed port 443 type tcpssl protocol http
#       with timeout 15 seconds
#    then restart
#    if 3 restarts within 5 cycles then timeout
#    depends on apache_bin
#    group server
#
#
## Check filesystem permissions, uid, gid, space and inode usage. Other services,
## such as databases, may depend on this resource and an automatically graceful
## stop may be cascaded to them before the filesystem will become full and data
## lost.
#
#  check filesystem datafs with path /dev/sdb1
#    start program  = "/bin/mount /data"
#    stop program  = "/bin/umount /data"
#    if failed permission 660 then unmonitor
#    if failed uid root then unmonitor
#    if failed gid disk then unmonitor
#    if space usage > 80% for 5 times within 15 cycles then alert
#    if space usage > 99% then stop
#    if inode usage > 30000 then alert
#    if inode usage > 99% then stop
#    group server
#
#
## Check a file's timestamp. In this example, we test if a file is older
## than 15 minutes and assume something is wrong if its not updated. Also,
## if the file size exceed a given limit, execute a script
#
#  check file database with path /data/mydatabase.db
#    if failed permission 700 then alert
#    if failed uid data then alert
#    if failed gid data then alert
#    if timestamp > 15 minutes then alert
#    if size > 100 MB then exec "/my/cleanup/script" as uid dba and gid dba
#
#
## Check directory permission, uid and gid.  An event is triggered if the
## directory does not belong to the user with uid 0 and gid 0.  In addition,
## the permissions have to match the octal description of 755 (see chmod(1)).
#
#  check directory bin with path /bin
#    if failed permission 755 then unmonitor
#    if failed uid 0 then unmonitor
#    if failed gid 0 then unmonitor
#
#
## Check a remote host availability by issuing a ping test and check the
## content of a response from a web server. Up to three pings are sent and
## connection to a port and an application level network check is performed.
#
#  check host myserver with address 192.168.1.1
#    if failed ping then alert
#    if failed port 3306 protocol mysql with timeout 15 seconds then alert
#    if failed port 80 protocol http
#       and request /some/path with content = "a string"
#    then alert
#
#
###############################################################################
## Includes
###############################################################################
##
## It is possible to include additional configuration parts from other files or
## directories.
#
include /etc/monit.d/*
#
EOF

cat <<'EOF' > /etc/init.d/monit
#!/bin/bash
#
# Init file for Monit system monitor
# Written by Stewart Adam <s.adam@diffingo.com>
# based on script by Dag Wieers <dag@wieers.com>.
#
# chkconfig: - 98 02
# description: Utility for monitoring services on a Unix system
#
# processname: monit
# config: /etc/monit.conf
# pidfile: /var/run/monit.pid
# Short-Description: Monit is a system monitor

# Source function library.
. /etc/init.d/functions

### Default variables
CONFIG="/etc/monitrc"
pidfile="/var/run/monit.pid"
prog="monit"

# Check if requirements are met
[ -x /usr/bin/monit ] || exit 1
[ -r "$CONFIG" ] || exit 1

RETVAL=0

start() {
        echo -n $"Starting $prog: "
        daemon $prog
        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && touch /var/lock/subsys/$prog
        return $RETVAL
}

stop() {
        echo -n $"Shutting down $prog: "
        killproc -p ${pidfile}
        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/$prog
        return $RETVAL
}

restart() {
        stop
        start
}

reload() {
        echo -n $"Reloading $prog: "
        monit -c "$CONFIG" reload
        RETVAL=$?
        echo
        return $RETVAL
}

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        restart
        ;;
  reload)
        reload
        ;;
  condrestart)
        [ -e /var/lock/subsys/$prog ] && restart
        RETVAL=$?
        ;;
  status)
        status $prog
        RETVAL=$?
        ;;
  *)
        echo $"Usage: $0 {start|stop|restart|reload|condrestart|status}"
        RETVAL=1
esac

exit $RETVAL
EOF

chmod 600 /etc/monit.conf
chmod 755 /etc/init.d/monit
ln -s /etc/monit.conf /etc/monitrc
rm -rf /tmp/monit-*

init_service monit on
ctrl_service monit start
echo -e "\nYou will need to open up port 2812 inside of the firewall to access monit. \n"
}

Install_Collectd () {
if [[ -z $collectd_password ]]; then

  tmp=$(tr -dc '[:alnum:]' < /dev/urandom | head -c30 | sha512sum | head -c30)
  read -ep "Collectd user password [${tmp}]:" collectd_password
  collectd_password=${collectd_password:-${tmp}}
  echo "Collectd User: cgpadm" >> $prog_pass
  echo "Collectd password: ${collectd_password}" >> $prog_pass

fi

htpasswd -b -mc /etc/httpd/htpasswd_files/collectd-htpasswd cgpadm "$collectd_password"
yum -y -q install libnotify python-devel libgcrypt-devel
getfiles $collectd_file $collectd_url
extract_tars /tmp/$collectd_file /tmp
cd /tmp/collectd-*
./configure --sbindir=/usr/sbin --sysconfdir=/etc
make all install
cp -p contrib/fedora/init.d-collectd /etc/init.d/collectd
chmod 755 /etc/init.d/collectd
[[ ! -d /var/lib/collectd/rrd ]] && mkdir -p /var/lib/collectd/rrd
sed -i "s/^#Hostname \(.*\)/Hostname    \"$MY_HOSTNAME\"/g" /etc/collectd.conf
sed -i "s/^#FQDNLookup \(.*\)/FQDNLookup    true/g" /etc/collectd.conf
sed -i "s/^#BaseDir \(.*\)/BaseDir    \"\/var\/lib\/collectd\/rrd\"/g" /etc/collectd.conf
sed -i "s/^#PIDFile \(.*\)/PIDFile    \"\/var\/run\/collectd.pid\"/g" /etc/collectd.conf
sed -i "s/^#PluginDir \(.*\)/PluginDir    \"\/opt\/collectd\/lib\/collectd\"/g" /etc/collectd.conf
sed -i "s/^#TypesDB     \"\/opt\/collectd\/share\/collectd\/types.db\"/TypesDB     \"\/opt\/collectd\/share\/collectd\/types.db\"/g" /etc/collectd.conf
chkconfig --add collectd
init_service collectd on
ctrl_service collectd start

cd /var/www/html
git clone --progress https://github.com/pommi/CGP /var/www/html/cgp
chown -R root.apache /var/www/html/cgp
chmod 750 /var/www/html/cgp

if [[ ! -f /etc/httpd/conf.d/collectdwebpanel.conf ]]; then
cat <<'EOF' > /etc/httpd/conf.d/collectdwebpanel.conf
#
# Collectd Web Panel -- Used to view rrd graphs
#

Alias /cdwp /var/www/html/cgp
Alias /collectdwebpanel /var/www/html/cgp

<Directory /var/www/html/cgp>
  AuthUserFile /etc/httpd/htpasswd_files/collectd-htpasswd
  AuthName "Collectd Web Panel Login"
  AuthType Basic
  Require valid-user
  Order Deny,Allow
  Deny from All
  Allow from localhost
  Options -Indexes
  AllowOverride All
</Directory>

<Directory /var/www/html/cgp>
  RewriteEngine  on
  RewriteCond    %{HTTPS} !=on
  RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
</Directory>
EOF
fi
ctrl_service httpd restart; unset collectd_password
}

Install_NewRelic () {
read -p "Please enter your license key for NewRelic " licensekey

if [[ $arch = x86_64 ]]; then

    rpm -Uvh https://yum.newrelic.com/pub/newrelic/el5/x86_64/newrelic-repo-5-3.noarch.rpm

else

    rpm -Uvh https://yum.newrelic.com/pub/newrelic/el5/i386/newrelic-repo-5-3.noarch.rpm

fi

yum install newrelic-sysmond
nrsysmond-config --set license_key="$licensekey"
init_service newrelic-sysmond on
ctrl_service newrelic-sysmond start
}

Install_Nagios () {
if [[ -z $nagios_password ]]; then

  tmp=$(tr -dc '[:alnum:]' < /dev/urandom | head -c30 | sha512sum | head -c30)
  read -ep "Nagios user password [${tmp}]:" nagios_password
  nagios_password=${nagios_password:-${tmp}}
  echo "Nagios User: nagiosadmin" >> $prog_pass
  echo "Nagios password: ${nagios_password}" >> $prog_pass

fi

useradd -rm -s /bin/bash nagios
passwd nagios
groupadd nagcmd
usermod -a -G nagcmd nagios
usermod -a -G nagcmd apache
getfiles $nagios_file $nagios_url
getfiles $nagios_plugins_file $nagios_plugins_url
extract_tars /tmp/$nagios_file /tmp
extract_tars /tmp/$nagios_plugins_file /tmp
cd /tmp/nagios
./configure --with-command-group=nagcmd
make all
make install
make install-init
make install-config
make install-commandmode
make install-webconf
make install-exfoliation
cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/
chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers
sed -i "s/nagios@localhost/root@$MYDOMAIN/g" /usr/local/nagios/etc/objects/contacts.cfg
htpasswd -b -mc /usr/local/nagios/etc/htpasswd nagiosadmin $nagios_password
mv /usr/local/nagios/etc/htpasswd /usr/local/nagios/etc/htpasswd.users
cd /tmp/nagios-plugins-2.1.1
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make
make install
chkconfig --add nagios
init_service nagios on
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
ctrl_service httpd restart
ctrl_service nagios start
rm -rf /tmp/nagios*; unset nagios_password
}

Install_PNP4Nagios () {
getfiles $pnp4nagios_file $pnp4nagios_url
extract_tars /tmp/$pnp4nagios_file /tmp
cd /tmp/pnp4nagios*
./configure
make all
#make install
make fullinstall
mv /usr/local/pnp4nagios/etc/rra.cfg-sample /usr/local/pnp4nagios/etc/rra.cfg
mv /usr/local/nagios/etc/nagios.cfg /usr/local/nagios/etc/nagios.cfg.bck

cat <<'EOF' > /usr/local/nagios/etc/nagios.cfg
##############################################################################
#
# NAGIOS.CFG - Sample Main Config File for Nagios 3.5.1
#
# Read the documentation for more information on this configuration
# file.  I've provided some comments here, but things may not be so
# clear without further explanation.
#
# Last Modified: 12-14-2008
#
##############################################################################


# LOG FILE
# This is the main log file where service and host events are logged
# for historical purposes.  This should be the first option specified
# in the config file!!!

log_file=/usr/local/nagios/var/nagios.log

 

# OBJECT CONFIGURATION FILE(S)
# These are the object configuration files in which you define hosts,
# host groups, contacts, contact groups, services, etc.
# You can split your object definitions across several config files
# if you wish (as shown below), or keep them all in a single config file.

# You can specify individual object config files as shown below:
cfg_file=/usr/local/nagios/etc/objects/commands.cfg
cfg_file=/usr/local/nagios/etc/objects/contacts.cfg
cfg_file=/usr/local/nagios/etc/objects/timeperiods.cfg
cfg_file=/usr/local/nagios/etc/objects/templates.cfg

# Definitions for monitoring the local (Linux) host
cfg_file=/usr/local/nagios/etc/objects/localhost.cfg

# Definitions for monitoring a Windows machine
#cfg_file=/usr/local/nagios/etc/objects/windows.cfg

# Definitions for monitoring a router/switch
#cfg_file=/usr/local/nagios/etc/objects/switch.cfg

# Definitions for monitoring a network printer
#cfg_file=/usr/local/nagios/etc/objects/printer.cfg


# You can also tell Nagios to process all config files (with a .cfg
# extension) in a particular directory by using the cfg_dir
# directive as shown below:

#cfg_dir=/usr/local/nagios/etc/servers
#cfg_dir=/usr/local/nagios/etc/printers
#cfg_dir=/usr/local/nagios/etc/switches
#cfg_dir=/usr/local/nagios/etc/routers




# OBJECT CACHE FILE
# This option determines where object definitions are cached when
# Nagios starts/restarts.  The CGIs read object definitions from
# this cache file (rather than looking at the object config files
# directly) in order to prevent inconsistencies that can occur
# when the config files are modified after Nagios starts.

object_cache_file=/usr/local/nagios/var/objects.cache



# PRE-CACHED OBJECT FILE
# This options determines the location of the precached object file.
# If you run Nagios with the -p command line option, it will preprocess
# your object configuration file(s) and write the cached config to this
# file.  You can then start Nagios with the -u option to have it read
# object definitions from this precached file, rather than the standard
# object configuration files (see the cfg_file and cfg_dir options above).
# Using a precached object file can speed up the time needed to (re)start
# the Nagios process if you've got a large and/or complex configuration.
# Read the documentation section on optimizing Nagios to find our more
# about how this feature works.

precached_object_file=/usr/local/nagios/var/objects.precache



# RESOURCE FILE
# This is an optional resource file that contains $USERx$ macro
# definitions. Multiple resource files can be specified by using
# multiple resource_file definitions.  The CGIs will not attempt to
# read the contents of resource files, so information that is
# considered to be sensitive (usernames, passwords, etc) can be
# defined as macros in this file and restrictive permissions (600)
# can be placed on this file.

resource_file=/usr/local/nagios/etc/resource.cfg



# STATUS FILE
# This is where the current status of all monitored services and
# hosts is stored.  Its contents are read and processed by the CGIs.
# The contents of the status file are deleted every time Nagios
#  restarts.

status_file=/usr/local/nagios/var/status.dat



# STATUS FILE UPDATE INTERVAL
# This option determines the frequency (in seconds) that
# Nagios will periodically dump program, host, and
# service status data.

status_update_interval=10



# NAGIOS USER
# This determines the effective user that Nagios should run as.
# You can either supply a username or a UID.

nagios_user=nagios



# NAGIOS GROUP
# This determines the effective group that Nagios should run as.
# You can either supply a group name or a GID.

nagios_group=nagios



# EXTERNAL COMMAND OPTION
# This option allows you to specify whether or not Nagios should check
# for external commands (in the command file defined below).  By default
# Nagios will *not* check for external commands, just to be on the
# cautious side.  If you want to be able to use the CGI command interface
# you will have to enable this.
# Values: 0 = disable commands, 1 = enable commands

check_external_commands=1



# EXTERNAL COMMAND CHECK INTERVAL
# This is the interval at which Nagios should check for external commands.
# This value works of the interval_length you specify later.  If you leave
# that at its default value of 60 (seconds), a value of 1 here will cause
# Nagios to check for external commands every minute.  If you specify a
# number followed by an "s" (i.e. 15s), this will be interpreted to mean
# actual seconds rather than a multiple of the interval_length variable.
# Note: In addition to reading the external command file at regularly
# scheduled intervals, Nagios will also check for external commands after
# event handlers are executed.
# NOTE: Setting this value to -1 causes Nagios to check the external
# command file as often as possible.

#command_check_interval=15s
command_check_interval=-1



# EXTERNAL COMMAND FILE
# This is the file that Nagios checks for external command requests.
# It is also where the command CGI will write commands that are submitted
# by users, so it must be writeable by the user that the web server
# is running as (usually 'nobody').  Permissions should be set at the
# directory level instead of on the file, as the file is deleted every
# time its contents are processed.

command_file=/usr/local/nagios/var/rw/nagios.cmd



# EXTERNAL COMMAND BUFFER SLOTS
# This settings is used to tweak the number of items or "slots" that
# the Nagios daemon should allocate to the buffer that holds incoming
# external commands before they are processed.  As external commands
# are processed by the daemon, they are removed from the buffer.

external_command_buffer_slots=4096



# LOCK FILE
# This is the lockfile that Nagios will use to store its PID number
# in when it is running in daemon mode.

lock_file=/usr/local/nagios/var/nagios.lock



# TEMP FILE
# This is a temporary file that is used as scratch space when Nagios
# updates the status log, cleans the comment file, etc.  This file
# is created, used, and deleted throughout the time that Nagios is
# running.

temp_file=/usr/local/nagios/var/nagios.tmp



# TEMP PATH
# This is path where Nagios can create temp files for service and
# host check results, etc.

temp_path=/tmp



# EVENT BROKER OPTIONS
# Controls what (if any) data gets sent to the event broker.
# Values:  0      = Broker nothing
#         -1      = Broker everything
#         <other> = See documentation

event_broker_options=-1



# EVENT BROKER MODULE(S)
# This directive is used to specify an event broker module that should
# by loaded by Nagios at startup.  Use multiple directives if you want
# to load more than one module.  Arguments that should be passed to
# the module at startup are seperated from the module path by a space.
#
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# WARNING !!! WARNING !!! WARNING !!! WARNING !!! WARNING !!! WARNING
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
# Do NOT overwrite modules while they are being used by Nagios or Nagios
# will crash in a fiery display of SEGFAULT glory.  This is a bug/limitation
# either in dlopen(), the kernel, and/or the filesystem.  And maybe Nagios...
#
# The correct/safe way of updating a module is by using one of these methods:
#    1. Shutdown Nagios, replace the module file, restart Nagios
#    2. Delete the original module file, move the new module file into place, restart Nagios
#
# Example:
#
#   broker_module=<modulepath> [moduleargs]

#broker_module=/somewhere/module1.o
#broker_module=/somewhere/module2.o arg1 arg2=3 debug=0



# LOG ROTATION METHOD
# This is the log rotation method that Nagios should use to rotate
# the main log file. Values are as follows..
#       n       = None - don't rotate the log
#       h       = Hourly rotation (top of the hour)
#       d       = Daily rotation (midnight every day)
#       w       = Weekly rotation (midnight on Saturday evening)
#       m       = Monthly rotation (midnight last day of month)

log_rotation_method=d



# LOG ARCHIVE PATH
# This is the directory where archived (rotated) log files should be
# placed (assuming you've chosen to do log rotation).

log_archive_path=/usr/local/nagios/var/archives



# LOGGING OPTIONS
# If you want messages logged to the syslog facility, as well as the
# Nagios log file set this option to 1.  If not, set it to 0.

use_syslog=0



# NOTIFICATION LOGGING OPTION
# If you don't want notifications to be logged, set this value to 0.
# If notifications should be logged, set the value to 1.

log_notifications=1



# SERVICE RETRY LOGGING OPTION
# If you don't want service check retries to be logged, set this value
# to 0.  If retries should be logged, set the value to 1.

log_service_retries=1



# HOST RETRY LOGGING OPTION
# If you don't want host check retries to be logged, set this value to
# 0.  If retries should be logged, set the value to 1.

log_host_retries=1



# EVENT HANDLER LOGGING OPTION
# If you don't want host and service event handlers to be logged, set
# this value to 0.  If event handlers should be logged, set the value
# to 1.

log_event_handlers=1



# INITIAL STATES LOGGING OPTION
# If you want Nagios to log all initial host and service states to
# the main log file (the first time the service or host is checked)
# you can enable this option by setting this value to 1.  If you
# are not using an external application that does long term state
# statistics reporting, you do not need to enable this option.  In
# this case, set the value to 0.

log_initial_states=0



# EXTERNAL COMMANDS LOGGING OPTION
# If you don't want Nagios to log external commands, set this value
# to 0.  If external commands should be logged, set this value to 1.
# Note: This option does not include logging of passive service
# checks - see the option below for controlling whether or not
# passive checks are logged.

log_external_commands=1



# PASSIVE CHECKS LOGGING OPTION
# If you don't want Nagios to log passive host and service checks, set
# this value to 0.  If passive checks should be logged, set
# this value to 1.

log_passive_checks=1



# GLOBAL HOST AND SERVICE EVENT HANDLERS
# These options allow you to specify a host and service event handler
# command that is to be run for every host or service state change.
# The global event handler is executed immediately prior to the event
# handler that you have optionally specified in each host or
# service definition. The command argument is the short name of a
# command definition that you define in your host configuration file.
# Read the HTML docs for more information.

#global_host_event_handler=somecommand
#global_service_event_handler=somecommand



# SERVICE INTER-CHECK DELAY METHOD
# This is the method that Nagios should use when initially
# "spreading out" service checks when it starts monitoring.  The
# default is to use smart delay calculation, which will try to
# space all service checks out evenly to minimize CPU load.
# Using the dumb setting will cause all checks to be scheduled
# at the same time (with no delay between them)!  This is not a
# good thing for production, but is useful when testing the
# parallelization functionality.
#       n       = None - don't use any delay between checks
#       d       = Use a "dumb" delay of 1 second between checks
#       s       = Use "smart" inter-check delay calculation
#       x.xx    = Use an inter-check delay of x.xx seconds

service_inter_check_delay_method=s



# MAXIMUM SERVICE CHECK SPREAD
# This variable determines the timeframe (in minutes) from the
# program start time that an initial check of all services should
# be completed.  Default is 30 minutes.

max_service_check_spread=30



# SERVICE CHECK INTERLEAVE FACTOR
# This variable determines how service checks are interleaved.
# Interleaving the service checks allows for a more even
# distribution of service checks and reduced load on remote
# hosts.  Setting this value to 1 is equivalent to how versions
# of Nagios previous to 0.0.5 did service checks.  Set this
# value to s (smart) for automatic calculation of the interleave
# factor unless you have a specific reason to change it.
#       s       = Use "smart" interleave factor calculation
#       x       = Use an interleave factor of x, where x is a
#                 number greater than or equal to 1.

service_interleave_factor=s



# HOST INTER-CHECK DELAY METHOD
# This is the method that Nagios should use when initially
# "spreading out" host checks when it starts monitoring.  The
# default is to use smart delay calculation, which will try to
# space all host checks out evenly to minimize CPU load.
# Using the dumb setting will cause all checks to be scheduled
# at the same time (with no delay between them)!
#       n       = None - don't use any delay between checks
#       d       = Use a "dumb" delay of 1 second between checks
#       s       = Use "smart" inter-check delay calculation
#       x.xx    = Use an inter-check delay of x.xx seconds

host_inter_check_delay_method=s



# MAXIMUM HOST CHECK SPREAD
# This variable determines the timeframe (in minutes) from the
# program start time that an initial check of all hosts should
# be completed.  Default is 30 minutes.

max_host_check_spread=30



# MAXIMUM CONCURRENT SERVICE CHECKS
# This option allows you to specify the maximum number of
# service checks that can be run in parallel at any given time.
# Specifying a value of 1 for this variable essentially prevents
# any service checks from being parallelized.  A value of 0
# will not restrict the number of concurrent checks that are
# being executed.

max_concurrent_checks=0



# HOST AND SERVICE CHECK REAPER FREQUENCY
# This is the frequency (in seconds!) that Nagios will process
# the results of host and service checks.

check_result_reaper_frequency=10




# MAX CHECK RESULT REAPER TIME
# This is the max amount of time (in seconds) that  a single
# check result reaper event will be allowed to run before
# returning control back to Nagios so it can perform other
# duties.

max_check_result_reaper_time=30




# CHECK RESULT PATH
# This is directory where Nagios stores the results of host and
# service checks that have not yet been processed.
#
# Note: Make sure that only one instance of Nagios has access
# to this directory!

check_result_path=/usr/local/nagios/var/spool/checkresults




# MAX CHECK RESULT FILE AGE
# This option determines the maximum age (in seconds) which check
# result files are considered to be valid.  Files older than this
# threshold will be mercilessly deleted without further processing.

max_check_result_file_age=3600




# CACHED HOST CHECK HORIZON
# This option determines the maximum amount of time (in seconds)
# that the state of a previous host check is considered current.
# Cached host states (from host checks that were performed more
# recently that the timeframe specified by this value) can immensely
# improve performance in regards to the host check logic.
# Too high of a value for this option may result in inaccurate host
# states being used by Nagios, while a lower value may result in a
# performance hit for host checks.  Use a value of 0 to disable host
# check caching.

cached_host_check_horizon=15



# CACHED SERVICE CHECK HORIZON
# This option determines the maximum amount of time (in seconds)
# that the state of a previous service check is considered current.
# Cached service states (from service checks that were performed more
# recently that the timeframe specified by this value) can immensely
# improve performance in regards to predictive dependency checks.
# Use a value of 0 to disable service check caching.

cached_service_check_horizon=15



# ENABLE PREDICTIVE HOST DEPENDENCY CHECKS
# This option determines whether or not Nagios will attempt to execute
# checks of hosts when it predicts that future dependency logic test
# may be needed.  These predictive checks can help ensure that your
# host dependency logic works well.
# Values:
#  0 = Disable predictive checks
#  1 = Enable predictive checks (default)

enable_predictive_host_dependency_checks=1



# ENABLE PREDICTIVE SERVICE DEPENDENCY CHECKS
# This option determines whether or not Nagios will attempt to execute
# checks of service when it predicts that future dependency logic test
# may be needed.  These predictive checks can help ensure that your
# service dependency logic works well.
# Values:
#  0 = Disable predictive checks
#  1 = Enable predictive checks (default)

enable_predictive_service_dependency_checks=1



# SOFT STATE DEPENDENCIES
# This option determines whether or not Nagios will use soft state
# information when checking host and service dependencies. Normally
# Nagios will only use the latest hard host or service state when
# checking dependencies. If you want it to use the latest state (regardless
# of whether its a soft or hard state type), enable this option.
# Values:
#  0 = Don't use soft state dependencies (default)
#  1 = Use soft state dependencies

soft_state_dependencies=0



# TIME CHANGE ADJUSTMENT THRESHOLDS
# These options determine when Nagios will react to detected changes
# in system time (either forward or backwards).

#time_change_threshold=900



# AUTO-RESCHEDULING OPTION
# This option determines whether or not Nagios will attempt to
# automatically reschedule active host and service checks to
# "smooth" them out over time.  This can help balance the load on
# the monitoring server.
# WARNING: THIS IS AN EXPERIMENTAL FEATURE - IT CAN DEGRADE
# PERFORMANCE, RATHER THAN INCREASE IT, IF USED IMPROPERLY

auto_reschedule_checks=0



# AUTO-RESCHEDULING INTERVAL
# This option determines how often (in seconds) Nagios will
# attempt to automatically reschedule checks.  This option only
# has an effect if the auto_reschedule_checks option is enabled.
# Default is 30 seconds.
# WARNING: THIS IS AN EXPERIMENTAL FEATURE - IT CAN DEGRADE
# PERFORMANCE, RATHER THAN INCREASE IT, IF USED IMPROPERLY

auto_rescheduling_interval=30



# AUTO-RESCHEDULING WINDOW
# This option determines the "window" of time (in seconds) that
# Nagios will look at when automatically rescheduling checks.
# Only host and service checks that occur in the next X seconds
# (determined by this variable) will be rescheduled. This option
# only has an effect if the auto_reschedule_checks option is
# enabled.  Default is 180 seconds (3 minutes).
# WARNING: THIS IS AN EXPERIMENTAL FEATURE - IT CAN DEGRADE
# PERFORMANCE, RATHER THAN INCREASE IT, IF USED IMPROPERLY

auto_rescheduling_window=180



# SLEEP TIME
# This is the number of seconds to sleep between checking for system
# events and service checks that need to be run.

sleep_time=0.25



# TIMEOUT VALUES
# These options control how much time Nagios will allow various
# types of commands to execute before killing them off.  Options
# are available for controlling maximum time allotted for
# service checks, host checks, event handlers, notifications, the
# ocsp command, and performance data commands.  All values are in
# seconds.

service_check_timeout=60
host_check_timeout=30
event_handler_timeout=30
notification_timeout=30
ocsp_timeout=5
perfdata_timeout=5



# RETAIN STATE INFORMATION
# This setting determines whether or not Nagios will save state
# information for services and hosts before it shuts down.  Upon
# startup Nagios will reload all saved service and host state
# information before starting to monitor.  This is useful for
# maintaining long-term data on state statistics, etc, but will
# slow Nagios down a bit when it (re)starts.  Since its only
# a one-time penalty, I think its well worth the additional
# startup delay.

retain_state_information=1



# STATE RETENTION FILE
# This is the file that Nagios should use to store host and
# service state information before it shuts down.  The state
# information in this file is also read immediately prior to
# starting to monitor the network when Nagios is restarted.
# This file is used only if the retain_state_information
# variable is set to 1.

state_retention_file=/usr/local/nagios/var/retention.dat



# RETENTION DATA UPDATE INTERVAL
# This setting determines how often (in minutes) that Nagios
# will automatically save retention data during normal operation.
# If you set this value to 0, Nagios will not save retention
# data at regular interval, but it will still save retention
# data before shutting down or restarting.  If you have disabled
# state retention, this option has no effect.

retention_update_interval=60



# USE RETAINED PROGRAM STATE
# This setting determines whether or not Nagios will set
# program status variables based on the values saved in the
# retention file.  If you want to use retained program status
# information, set this value to 1.  If not, set this value
# to 0.

use_retained_program_state=1



# USE RETAINED SCHEDULING INFO
# This setting determines whether or not Nagios will retain
# the scheduling info (next check time) for hosts and services
# based on the values saved in the retention file.  If you
# If you want to use retained scheduling info, set this
# value to 1.  If not, set this value to 0.

use_retained_scheduling_info=1



# RETAINED ATTRIBUTE MASKS (ADVANCED FEATURE)
# The following variables are used to specify specific host and
# service attributes that should *not* be retained by Nagios during
# program restarts.
#
# The values of the masks are bitwise ANDs of values specified
# by the "MODATTR_" definitions found in include/common.h.
# For example, if you do not want the current enabled/disabled state
# of flap detection and event handlers for hosts to be retained, you
# would use a value of 24 for the host attribute mask...
# MODATTR_EVENT_HANDLER_ENABLED (8) + MODATTR_FLAP_DETECTION_ENABLED (16) = 24

# This mask determines what host attributes are not retained
retained_host_attribute_mask=0

# This mask determines what service attributes are not retained
retained_service_attribute_mask=0

# These two masks determine what process attributes are not retained.
# There are two masks, because some process attributes have host and service
# options.  For example, you can disable active host checks, but leave active
# service checks enabled.
retained_process_host_attribute_mask=0
retained_process_service_attribute_mask=0

# These two masks determine what contact attributes are not retained.
# There are two masks, because some contact attributes have host and
# service options.  For example, you can disable host notifications for
# a contact, but leave service notifications enabled for them.
retained_contact_host_attribute_mask=0
retained_contact_service_attribute_mask=0



# INTERVAL LENGTH
# This is the seconds per unit interval as used in the
# host/contact/service configuration files.  Setting this to 60 means
# that each interval is one minute long (60 seconds).  Other settings
# have not been tested much, so your mileage is likely to vary...

interval_length=60



# CHECK FOR UPDATES
# This option determines whether Nagios will automatically check to
# see if new updates (releases) are available.  It is recommend that you
# enable this option to ensure that you stay on top of the latest critical
# patches to Nagios.  Nagios is critical to you - make sure you keep it in
# good shape.  Nagios will check once a day for new updates. Data collected
# by Nagios Enterprises from the update check is processed in accordance
# with our privacy policy - see http://api.nagios.org for details.

check_for_updates=1



# BARE UPDATE CHECK
# This option deterines what data Nagios will send to api.nagios.org when
# it checks for updates.  By default, Nagios will send information on the
# current version of Nagios you have installed, as well as an indicator as
# to whether this was a new installation or not.  Nagios Enterprises uses
# this data to determine the number of users running specific version of
# Nagios.  Enable this option if you do not want this information to be sent.

bare_update_check=0



# AGGRESSIVE HOST CHECKING OPTION
# If you don't want to turn on aggressive host checking features, set
# this value to 0 (the default).  Otherwise set this value to 1 to
# enable the aggressive check option.  Read the docs for more info
# on what aggressive host check is or check out the source code in
# base/checks.c

use_aggressive_host_checking=0



# SERVICE CHECK EXECUTION OPTION
# This determines whether or not Nagios will actively execute
# service checks when it initially starts.  If this option is
# disabled, checks are not actively made, but Nagios can still
# receive and process passive check results that come in.  Unless
# you're implementing redundant hosts or have a special need for
# disabling the execution of service checks, leave this enabled!
# Values: 1 = enable checks, 0 = disable checks

execute_service_checks=1



# PASSIVE SERVICE CHECK ACCEPTANCE OPTION
# This determines whether or not Nagios will accept passive
# service checks results when it initially (re)starts.
# Values: 1 = accept passive checks, 0 = reject passive checks

accept_passive_service_checks=1



# HOST CHECK EXECUTION OPTION
# This determines whether or not Nagios will actively execute
# host checks when it initially starts.  If this option is
# disabled, checks are not actively made, but Nagios can still
# receive and process passive check results that come in.  Unless
# you're implementing redundant hosts or have a special need for
# disabling the execution of host checks, leave this enabled!
# Values: 1 = enable checks, 0 = disable checks

execute_host_checks=1



# PASSIVE HOST CHECK ACCEPTANCE OPTION
# This determines whether or not Nagios will accept passive
# host checks results when it initially (re)starts.
# Values: 1 = accept passive checks, 0 = reject passive checks

accept_passive_host_checks=1



# NOTIFICATIONS OPTION
# This determines whether or not Nagios will sent out any host or
# service notifications when it is initially (re)started.
# Values: 1 = enable notifications, 0 = disable notifications

enable_notifications=1



# EVENT HANDLER USE OPTION
# This determines whether or not Nagios will run any host or
# service event handlers when it is initially (re)started.  Unless
# you're implementing redundant hosts, leave this option enabled.
# Values: 1 = enable event handlers, 0 = disable event handlers

enable_event_handlers=1



# PROCESS PERFORMANCE DATA OPTION
# This determines whether or not Nagios will process performance
# data returned from service and host checks.  If this option is
# enabled, host performance data will be processed using the
# host_perfdata_command (defined below) and service performance
# data will be processed using the service_perfdata_command (also
# defined below).  Read the HTML docs for more information on
# performance data.
# Values: 1 = process performance data, 0 = do not process performance data

process_performance_data=1



# HOST AND SERVICE PERFORMANCE DATA PROCESSING COMMANDS
# These commands are run after every host and service check is
# performed.  These commands are executed only if the
# enable_performance_data option (above) is set to 1.  The command
# argument is the short name of a command definition that you
# define in your host configuration file.  Read the HTML docs for
# more information on performance data.

host_perfdata_command=process-host-perfdata
service_perfdata_command=process-service-perfdata



# HOST AND SERVICE PERFORMANCE DATA FILES
# These files are used to store host and service performance data.
# Performance data is only written to these files if the
# enable_performance_data option (above) is set to 1.

#host_perfdata_file=/tmp/host-perfdata
#service_perfdata_file=/tmp/service-perfdata



# HOST AND SERVICE PERFORMANCE DATA FILE TEMPLATES
# These options determine what data is written (and how) to the
# performance data files.  The templates may contain macros, special
# characters (\t for tab, \r for carriage return, \n for newline)
# and plain text.  A newline is automatically added after each write
# to the performance data file.  Some examples of what you can do are
# shown below.

#host_perfdata_file_template=[HOSTPERFDATA]\t$TIMET$\t$HOSTNAME$\t$HOSTEXECUTIONTIME$\t$HOSTOUTPUT$\t$HOSTPERFDATA$
#service_perfdata_file_template=[SERVICEPERFDATA]\t$TIMET$\t$HOSTNAME$\t$SERVICEDESC$\t$SERVICEEXECUTIONTIME$\t$SERVICELATENCY$\t$SERVICEOUTPUT$\t$SERVICEPERFDATA$



# HOST AND SERVICE PERFORMANCE DATA FILE MODES
# This option determines whether or not the host and service
# performance data files are opened in write ("w") or append ("a")
# mode. If you want to use named pipes, you should use the special
# pipe ("p") mode which avoid blocking at startup, otherwise you will
# likely want the defult append ("a") mode.

#host_perfdata_file_mode=a
#service_perfdata_file_mode=a



# HOST AND SERVICE PERFORMANCE DATA FILE PROCESSING INTERVAL
# These options determine how often (in seconds) the host and service
# performance data files are processed using the commands defined
# below.  A value of 0 indicates the files should not be periodically
# processed.

#host_perfdata_file_processing_interval=0
#service_perfdata_file_processing_interval=0



# HOST AND SERVICE PERFORMANCE DATA FILE PROCESSING COMMANDS
# These commands are used to periodically process the host and
# service performance data files.  The interval at which the
# processing occurs is determined by the options above.

#host_perfdata_file_processing_command=process-host-perfdata-file
#service_perfdata_file_processing_command=process-service-perfdata-file



# HOST AND SERVICE PERFORMANCE DATA PROCESS EMPTY RESULTS
# THese options determine wether the core will process empty perfdata
# results or not. This is needed for distributed monitoring, and intentionally
# turned on by default.
# If you don't require empty perfdata - saving some cpu cycles
# on unwanted macro calculation - you can turn that off. Be careful!
# Values: 1 = enable, 0 = disable

#host_perfdata_process_empty_results=1
#service_perfdata_process_empty_results=1


# OBSESS OVER SERVICE CHECKS OPTION
# This determines whether or not Nagios will obsess over service
# checks and run the ocsp_command defined below.  Unless you're
# planning on implementing distributed monitoring, do not enable
# this option.  Read the HTML docs for more information on
# implementing distributed monitoring.
# Values: 1 = obsess over services, 0 = do not obsess (default)

obsess_over_services=0



# OBSESSIVE COMPULSIVE SERVICE PROCESSOR COMMAND
# This is the command that is run for every service check that is
# processed by Nagios.  This command is executed only if the
# obsess_over_services option (above) is set to 1.  The command
# argument is the short name of a command definition that you
# define in your host configuration file. Read the HTML docs for
# more information on implementing distributed monitoring.

#ocsp_command=somecommand



# OBSESS OVER HOST CHECKS OPTION
# This determines whether or not Nagios will obsess over host
# checks and run the ochp_command defined below.  Unless you're
# planning on implementing distributed monitoring, do not enable
# this option.  Read the HTML docs for more information on
# implementing distributed monitoring.
# Values: 1 = obsess over hosts, 0 = do not obsess (default)

obsess_over_hosts=0



# OBSESSIVE COMPULSIVE HOST PROCESSOR COMMAND
# This is the command that is run for every host check that is
# processed by Nagios.  This command is executed only if the
# obsess_over_hosts option (above) is set to 1.  The command
# argument is the short name of a command definition that you
# define in your host configuration file. Read the HTML docs for
# more information on implementing distributed monitoring.

#ochp_command=somecommand



# TRANSLATE PASSIVE HOST CHECKS OPTION
# This determines whether or not Nagios will translate
# DOWN/UNREACHABLE passive host check results into their proper
# state for this instance of Nagios.  This option is useful
# if you have distributed or failover monitoring setup.  In
# these cases your other Nagios servers probably have a different
# "view" of the network, with regards to the parent/child relationship
# of hosts.  If a distributed monitoring server thinks a host
# is DOWN, it may actually be UNREACHABLE from the point of
# this Nagios instance.  Enabling this option will tell Nagios
# to translate any DOWN or UNREACHABLE host states it receives
# passively into the correct state from the view of this server.
# Values: 1 = perform translation, 0 = do not translate (default)

translate_passive_host_checks=0



# PASSIVE HOST CHECKS ARE SOFT OPTION
# This determines whether or not Nagios will treat passive host
# checks as being HARD or SOFT.  By default, a passive host check
# result will put a host into a HARD state type.  This can be changed
# by enabling this option.
# Values: 0 = passive checks are HARD, 1 = passive checks are SOFT

passive_host_checks_are_soft=0



# ORPHANED HOST/SERVICE CHECK OPTIONS
# These options determine whether or not Nagios will periodically
# check for orphaned host service checks.  Since service checks are
# not rescheduled until the results of their previous execution
# instance are processed, there exists a possibility that some
# checks may never get rescheduled.  A similar situation exists for
# host checks, although the exact scheduling details differ a bit
# from service checks.  Orphaned checks seem to be a rare
# problem and should not happen under normal circumstances.
# If you have problems with service checks never getting
# rescheduled, make sure you have orphaned service checks enabled.
# Values: 1 = enable checks, 0 = disable checks

check_for_orphaned_services=1
check_for_orphaned_hosts=1



# SERVICE FRESHNESS CHECK OPTION
# This option determines whether or not Nagios will periodically
# check the "freshness" of service results.  Enabling this option
# is useful for ensuring passive checks are received in a timely
# manner.
# Values: 1 = enabled freshness checking, 0 = disable freshness checking

check_service_freshness=1



# SERVICE FRESHNESS CHECK INTERVAL
# This setting determines how often (in seconds) Nagios will
# check the "freshness" of service check results.  If you have
# disabled service freshness checking, this option has no effect.

service_freshness_check_interval=60



# SERVICE CHECK TIMEOUT STATE
# This setting determines the state Nagios will report when a
# service check times out - that is does not respond within
# service_check_timeout seconds.  This can be useful if a
# machine is running at too high a load and you do not want
# to consider a failed service check to be critical (the default).
# Valid settings are:
# c - Critical (default)
# u - Unknown
# w - Warning
# o - OK

service_check_timeout_state=c



# HOST FRESHNESS CHECK OPTION
# This option determines whether or not Nagios will periodically
# check the "freshness" of host results.  Enabling this option
# is useful for ensuring passive checks are received in a timely
# manner.
# Values: 1 = enabled freshness checking, 0 = disable freshness checking

check_host_freshness=0



# HOST FRESHNESS CHECK INTERVAL
# This setting determines how often (in seconds) Nagios will
# check the "freshness" of host check results.  If you have
# disabled host freshness checking, this option has no effect.

host_freshness_check_interval=60




# ADDITIONAL FRESHNESS THRESHOLD LATENCY
# This setting determines the number of seconds that Nagios
# will add to any host and service freshness thresholds that
# it calculates (those not explicitly specified by the user).

additional_freshness_latency=15




# FLAP DETECTION OPTION
# This option determines whether or not Nagios will try
# and detect hosts and services that are "flapping".
# Flapping occurs when a host or service changes between
# states too frequently.  When Nagios detects that a
# host or service is flapping, it will temporarily suppress
# notifications for that host/service until it stops
# flapping.  Flap detection is very experimental, so read
# the HTML documentation before enabling this feature!
# Values: 1 = enable flap detection
#         0 = disable flap detection (default)

enable_flap_detection=1



# FLAP DETECTION THRESHOLDS FOR HOSTS AND SERVICES
# Read the HTML documentation on flap detection for
# an explanation of what this option does.  This option
# has no effect if flap detection is disabled.

low_service_flap_threshold=5.0
high_service_flap_threshold=20.0
low_host_flap_threshold=5.0
high_host_flap_threshold=20.0



# DATE FORMAT OPTION
# This option determines how short dates are displayed. Valid options
# include:
#       us              (MM-DD-YYYY HH:MM:SS)
#       euro            (DD-MM-YYYY HH:MM:SS)
#       iso8601         (YYYY-MM-DD HH:MM:SS)
#       strict-iso8601  (YYYY-MM-DDTHH:MM:SS)
#

date_format=us




# TIMEZONE OFFSET
# This option is used to override the default timezone that this
# instance of Nagios runs in.  If not specified, Nagios will use
# the system configured timezone.
#
# NOTE: In order to display the correct timezone in the CGIs, you
# will also need to alter the Apache directives for the CGI path
# to include your timezone.  Example:
#
#   <Directory "/usr/local/nagios/sbin/">
#      SetEnv TZ "Australia/Brisbane"
#      ...
#   </Directory>

#use_timezone=US/Mountain
#use_timezone=Australia/Brisbane




# P1.PL FILE LOCATION
# This value determines where the p1.pl perl script (used by the
# embedded Perl interpreter) is located.  If you didn't compile
# Nagios with embedded Perl support, this option has no effect.

p1_file=/usr/local/nagios/bin/p1.pl



# EMBEDDED PERL INTERPRETER OPTION
# This option determines whether or not the embedded Perl interpreter
# will be enabled during runtime.  This option has no effect if Nagios
# has not been compiled with support for embedded Perl.
# Values: 0 = disable interpreter, 1 = enable interpreter

enable_embedded_perl=1



# EMBEDDED PERL USAGE OPTION
# This option determines whether or not Nagios will process Perl plugins
# and scripts with the embedded Perl interpreter if the plugins/scripts
# do not explicitly indicate whether or not it is okay to do so. Read
# the HTML documentation on the embedded Perl interpreter for more
# information on how this option works.

use_embedded_perl_implicitly=1



# ILLEGAL OBJECT NAME CHARACTERS
# This option allows you to specify illegal characters that cannot
# be used in host names, service descriptions, or names of other
# object types.

illegal_object_name_chars=`~!$%^&*|'"<>?,()=



# ILLEGAL MACRO OUTPUT CHARACTERS
# This option allows you to specify illegal characters that are
# stripped from macros before being used in notifications, event
# handlers, etc.  This DOES NOT affect macros used in service or
# host check commands.
# The following macros are stripped of the characters you specify:
#       $HOSTOUTPUT$
#       $HOSTPERFDATA$
#       $HOSTACKAUTHOR$
#       $HOSTACKCOMMENT$
#       $SERVICEOUTPUT$
#       $SERVICEPERFDATA$
#       $SERVICEACKAUTHOR$
#       $SERVICEACKCOMMENT$

illegal_macro_output_chars=`~$&|'"<>



# REGULAR EXPRESSION MATCHING
# This option controls whether or not regular expression matching
# takes place in the object config files.  Regular expression
# matching is used to match host, hostgroup, service, and service
# group names/descriptions in some fields of various object types.
# Values: 1 = enable regexp matching, 0 = disable regexp matching

use_regexp_matching=0



# "TRUE" REGULAR EXPRESSION MATCHING
# This option controls whether or not "true" regular expression
# matching takes place in the object config files.  This option
# only has an effect if regular expression matching is enabled
# (see above).  If this option is DISABLED, regular expression
# matching only occurs if a string contains wildcard characters
# (* and ?).  If the option is ENABLED, regexp matching occurs
# all the time (which can be annoying).
# Values: 1 = enable true matching, 0 = disable true matching

use_true_regexp_matching=0



# ADMINISTRATOR EMAIL/PAGER ADDRESSES
# The email and pager address of a global administrator (likely you).
# Nagios never uses these values itself, but you can access them by
# using the $ADMINEMAIL$ and $ADMINPAGER$ macros in your notification
# commands.

admin_email=nagios@localhost
admin_pager=pagenagios@localhost



# DAEMON CORE DUMP OPTION
# This option determines whether or not Nagios is allowed to create
# a core dump when it runs as a daemon.  Note that it is generally
# considered bad form to allow this, but it may be useful for
# debugging purposes.  Enabling this option doesn't guarantee that
# a core file will be produced, but that's just life...
# Values: 1 - Allow core dumps
#         0 - Do not allow core dumps (default)

daemon_dumps_core=0



# LARGE INSTALLATION TWEAKS OPTION
# This option determines whether or not Nagios will take some shortcuts
# which can save on memory and CPU usage in large Nagios installations.
# Read the documentation for more information on the benefits/tradeoffs
# of enabling this option.
# Values: 1 - Enabled tweaks
#         0 - Disable tweaks (default)

use_large_installation_tweaks=0



# ENABLE ENVIRONMENT MACROS
# This option determines whether or not Nagios will make all standard
# macros available as environment variables when host/service checks
# and system commands (event handlers, notifications, etc.) are
# executed.  Enabling this option can cause performance issues in
# large installations, as it will consume a bit more memory and (more
# importantly) consume more CPU.
# Values: 1 - Enable environment variable macros (default)
#         0 - Disable environment variable macros

enable_environment_macros=1



# CHILD PROCESS MEMORY OPTION
# This option determines whether or not Nagios will free memory in
# child processes (processed used to execute system commands and host/
# service checks).  If you specify a value here, it will override
# program defaults.
# Value: 1 - Free memory in child processes
#        0 - Do not free memory in child processes

#free_child_process_memory=1



# CHILD PROCESS FORKING BEHAVIOR
# This option determines how Nagios will fork child processes
# (used to execute system commands and host/service checks).  Normally
# child processes are fork()ed twice, which provides a very high level
# of isolation from problems.  Fork()ing once is probably enough and will
# save a great deal on CPU usage (in large installs), so you might
# want to consider using this.  If you specify a value here, it will
# program defaults.
# Value: 1 - Child processes fork() twice
#        0 - Child processes fork() just once

#child_processes_fork_twice=1



# DEBUG LEVEL
# This option determines how much (if any) debugging information will
# be written to the debug file.  OR values together to log multiple
# types of information.
# Values:
#          -1 = Everything
#          0 = Nothing
#          1 = Functions
#          2 = Configuration
#          4 = Process information
#          8 = Scheduled events
#          16 = Host/service checks
#          32 = Notifications
#          64 = Event broker
#          128 = External commands
#          256 = Commands
#          512 = Scheduled downtime
#          1024 = Comments
#          2048 = Macros

debug_level=0



# DEBUG VERBOSITY
# This option determines how verbose the debug log out will be.
# Values: 0 = Brief output
#         1 = More detailed
#         2 = Very detailed

debug_verbosity=1



# DEBUG FILE
# This option determines where Nagios should write debugging information.

debug_file=/usr/local/nagios/var/nagios.debug



# MAX DEBUG FILE SIZE
# This option determines the maximum size (in bytes) of the debug file.  If
# the file grows larger than this size, it will be renamed with a .old
# extension.  If a file already exists with a .old extension it will
# automatically be deleted.  This helps ensure your disk space usage doesn't
# get out of control when debugging Nagios.

max_debug_file_size=1000000


# Load Livestatus Module
broker_module=/usr/lib/check_mk/livestatus.o /usr/local/nagios/var/rw/live
event_broker_options=-1
EOF

/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg # sanity check
mv /usr/local/nagios/etc/objects/commands.cfg /usr/local/nagios/etc/objects/commands.cfg.bck

cat <<'EOF' > /usr/local/nagios/etc/objects/commands.cfg
###############################################################################
# COMMANDS.CFG - SAMPLE COMMAND DEFINITIONS FOR NAGIOS 3.5.1
#
# Last Modified: 05-31-2007
#
# NOTES: This config file provides you with some example command definitions
#        that you can reference in host, service, and contact definitions.
#
#        You don't need to keep commands in a separate file from your other
#        object definitions.  This has been done just to make things easier to
#        understand.
#
###############################################################################


################################################################################
#
# SAMPLE NOTIFICATION COMMANDS
#
# These are some example notification commands.  They may or may not work on
# your system without modification.  As an example, some systems will require
# you to use "/usr/bin/mailx" instead of "/usr/bin/mail" in the commands below.
#
################################################################################


# 'notify-host-by-email' command definition
define command{
        command_name    notify-host-by-email
        command_line    /usr/bin/printf "%b" "***** Nagios *****\n\nNotification Type: $NOTIFICATIONTYPE$\nHost: $HOSTNAME$\nState: $HOSTSTATE$\nAddress: $HOSTADDRESS$\nInfo: $HOSTOUTPUT$\n\nDate/Time: $LONGDATETIME$\n" | /bin/mail -s "** $NOTIFICATIONTYPE$ Host Alert: $HOSTNAME$ is $HOSTSTATE$ **" $CONTACTEMAIL$
        }

# 'notify-service-by-email' command definition
define command{
        command_name    notify-service-by-email
        command_line    /usr/bin/printf "%b" "***** Nagios *****\n\nNotification Type: $NOTIFICATIONTYPE$\n\nService: $SERVICEDESC$\nHost: $HOSTALIAS$\nAddress: $HOSTADDRESS$\nState: $SERVICESTATE$\n\nDate/Time: $LONGDATETIME$\n\nAdditional Info:\n\n$SERVICEOUTPUT$\n" | /bin/mail -s "** $NOTIFICATIONTYPE$ Service Alert: $HOSTALIAS$/$SERVICEDESC$ is $SERVICESTATE$ **" $CONTACTEMAIL$
        }





################################################################################
#
# SAMPLE HOST CHECK COMMANDS
#
################################################################################


# This command checks to see if a host is "alive" by pinging it
# The check must result in a 100% packet loss or 5 second (5000ms) round trip
# average time to produce a critical error.
# Note: Five ICMP echo packets are sent (determined by the '-p 5' argument)

# 'check-host-alive' command definition
define command{
        command_name    check-host-alive
        command_line    $USER1$/check_ping -H $HOSTADDRESS$ -w 3000.0,80% -c 5000.0,100% -p 5
        }




################################################################################
#
# SAMPLE SERVICE CHECK COMMANDS
#
# These are some example service check commands.  They may or may not work on
# your system, as they must be modified for your plugins.  See the HTML
# documentation on the plugins for examples of how to configure command definitions.
#
# NOTE:  The following 'check_local_...' functions are designed to monitor
#        various metrics on the host that Nagios is running on (i.e. this one).
################################################################################

# 'check_local_disk' command definition
define command{
        command_name    check_local_disk
        command_line    $USER1$/check_disk -w $ARG1$ -c $ARG2$ -p $ARG3$
        }


# 'check_local_load' command definition
define command{
        command_name    check_local_load
        command_line    $USER1$/check_load -w $ARG1$ -c $ARG2$
        }


# 'check_local_procs' command definition
define command{
        command_name    check_local_procs
        command_line    $USER1$/check_procs -w $ARG1$ -c $ARG2$ -s $ARG3$
        }


# 'check_local_users' command definition
define command{
        command_name    check_local_users
        command_line    $USER1$/check_users -w $ARG1$ -c $ARG2$
        }


# 'check_local_swap' command definition
define command{
        command_name    check_local_swap
        command_line    $USER1$/check_swap -w $ARG1$ -c $ARG2$
        }


# 'check_local_mrtgtraf' command definition
define command{
        command_name    check_local_mrtgtraf
        command_line    $USER1$/check_mrtgtraf -F $ARG1$ -a $ARG2$ -w $ARG3$ -c $ARG4$ -e $ARG5$
        }


################################################################################
# NOTE:  The following 'check_...' commands are used to monitor services on
#        both local and remote hosts.
################################################################################

# 'check_ftp' command definition
define command{
        command_name    check_ftp
        command_line    $USER1$/check_ftp -H $HOSTADDRESS$ $ARG1$
        }


# 'check_hpjd' command definition
define command{
        command_name    check_hpjd
        command_line    $USER1$/check_hpjd -H $HOSTADDRESS$ $ARG1$
        }


# 'check_snmp' command definition
define command{
        command_name    check_snmp
        command_line    $USER1$/check_snmp -H $HOSTADDRESS$ $ARG1$
        }


# 'check_http' command definition
define command{
        command_name    check_http
        command_line    $USER1$/check_http -I $HOSTADDRESS$ $ARG1$
        }


# 'check_ssh' command definition
define command{
        command_name    check_ssh
        command_line    $USER1$/check_ssh -p 8822 $ARG1$ $HOSTADDRESS$
        }


# 'check_dhcp' command definition
define command{
        command_name    check_dhcp
        command_line    $USER1$/check_dhcp $ARG1$
        }


# 'check_ping' command definition
define command{
        command_name    check_ping
        command_line    $USER1$/check_ping -H $HOSTADDRESS$ -w $ARG1$ -c $ARG2$ -p 5
        }


# 'check_pop' command definition
define command{
        command_name    check_pop
        command_line    $USER1$/check_pop -H $HOSTADDRESS$ $ARG1$
        }


# 'check_imap' command definition
define command{
        command_name    check_imap
        command_line    $USER1$/check_imap -H $HOSTADDRESS$ $ARG1$
        }


# 'check_smtp' command definition
define command{
        command_name    check_smtp
        command_line    $USER1$/check_smtp -H $HOSTADDRESS$ $ARG1$
        }


# 'check_tcp' command definition
define command{
        command_name    check_tcp
        command_line    $USER1$/check_tcp -H $HOSTADDRESS$ -p $ARG1$ $ARG2$
        }


# 'check_udp' command definition
define command{
        command_name    check_udp
        command_line    $USER1$/check_udp -H $HOSTADDRESS$ -p $ARG1$ $ARG2$
        }


# 'check_nt' command definition
define command{
        command_name    check_nt
        command_line    $USER1$/check_nt -H $HOSTADDRESS$ -p 12489 -v $ARG1$ $ARG2$
        }



################################################################################
#
# SAMPLE PERFORMANCE DATA COMMANDS
#
# These are sample performance data commands that can be used to send performance
# data output to two text files (one for hosts, another for services).  If you
# plan on simply writing performance data out to a file, consider using the
# host_perfdata_file and service_perfdata_file options in the main config file.
#
################################################################################


# 'process-host-perfdata' command definition
#define command{
#       command_name    process-host-perfdata
#       command_line    /usr/bin/printf "%b" "$LASTHOSTCHECK$\t$HOSTNAME$\t$HOSTSTATE$\t$HOSTATTEMPT$\t$HOSTSTATETYPE$\t$HOSTEXECUTIONTIME$\t$HOSTOUTPUT$\t$HOSTPERFDATA$\n" >> /usr/local/nagios/var/host-perfdata.out
#       }


# 'process-service-perfdata' command definition
#define command{
#       command_name    process-service-perfdata
#       command_line    /usr/bin/printf "%b" "$LASTSERVICECHECK$\t$HOSTNAME$\t$SERVICEDESC$\t$SERVICESTATE$\t$SERVICEATTEMPT$\t$SERVICESTATETYPE$\t$SERVICEEXECUTIONTIME$\t$SERVICELATENCY$\t$SERVICEOUTPUT$\t$SERVICEPERFDATA$\n" >> /usr/local/nagios/var/service-perfdata.out
#       }
#

define command {
       command_name    process-service-perfdata
       command_line    /usr/bin/perl /usr/local/pnp4nagios/libexec/process_perfdata.pl
}

define command {
       command_name    process-host-perfdata
       command_line    /usr/bin/perl /usr/local/pnp4nagios/libexec/process_perfdata.pl -d HOSTPERFDATA
}
EOF

ctrl_service httpd restart
ctrl_service nagios restart
rm -rf /tmp/pnp4nagios* /usr/local/pnp4nagios/share/install.php
}

Install_CheckMK () {
getfiles $check_mk_file $check_mk_url
extract_tars /tmp/$check_mk_file /tmp
cd /tmp/check_mk-1.2.6p9
./setup.sh --yes
cd /usr/share/check_mk/agents
cp check_mk_agent.linux /usr/bin/check_mk_agent
cp xinetd.conf /etc/xinetd.d/check_mk
service xinetd restart
mv /etc/check_mk/main.mk /etc/check_mk/main.mk.bck
cat <<EOF > /etc/check_mk/main.mk
# Put your host names here
all_hosts = [ "$MY_HOSTNAME" ]
EOF
cmk -I
cmk -O
ctrl_service httpd restart
ctrl_service nagios restart
rm -rf /tmp/check_mk*
}

Enable_Clamscanning_PureFTPd () { # Enables ClamAV Scanning for PureFTPd and logs removed items to /var/log/pure-ftpd/ftp_removed.log
sed -i "s|#CallUploadScript yes|CallUploadScript yes|g" /etc/pure-ftpd/pure-ftpd.conf
echo "pure-uploadscript -B -r /etc/pure-ftpd/virus_check.sh" >> /etc/rc.local

cat <<'EOF' > /etc/pure-ftpd/virus_check.sh
#!/bin/sh
cs=$(which clamscan)
logfile="/var/log/pure-ftpd/ftp_removed.log"

$cs -r -l "$logfile" --remove "$1"
EOF

chmod 755 /etc/pure-ftpd/virus_check.sh
echo -e "\nReboot required to load script used for scanning.\n"
}

Sys_Prep_ISPConfig () {
Before_Reboot () {
clear

Install_Basic_Tools

# Disable IPTABLES here
service iptables save
ctrl_service iptables stop
init_service iptables off

mv /etc/hosts /etc/hosts.bak; echo ""

# Insert your IP, Host, fqdn into hosts file
echo "$MY_IP   $MY_HOSTNAME $MY_HOST" > /etc/hosts

# Put localhost info back into hosts file
cat <<'EOF' >> /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF

# Changes SELINUX state to disabled
if [[ ! -f /etc/selinux/config ]]; then

    echo "SELINUX=disabled" > /etc/selinux/selinux

else

    sed -i 's/SELINUX=\(.*\)/SELINUX=disabled/g' /etc/selinux/config

fi

echo "if [[ -x $HOME/$prog ]]; then bash $HOME/$prog; fi" >> $HOME/.bashrc # Set script to automatically run on reboot

# This tells us that we've already rebooted the system and can finish getting ready to install ISPConfig
touch /tmp/sys-prep.done

read -ep "Ready to reboot? [y/n] " yn; echo ""

case $yn in

	n|N|no|No)

        echo -e "\nExiting now.. Please reboot the system, before running script again.! \n" && exit 5 ;;

	y|Y|Yes|yes)

        reboot && exit 0 ;;

esac
}

Install_Repos () {
clear; sed -i "s/if \[\[ -x \\$HOME\/$prog \]\]; then bash \\$HOME\/$prog; fi//g" "$HOME/.bashrc" # Stop script from automatically running on reboot again

if [[ $Install_Web = y && $Install_MySQL = y ]]; then

    if [[ -z ${pma_pass} ]]; then # If phpMyAdmin's Control User's password is not set above, set it now

        tmp=$(tr -dc '[:alnum:]' < /dev/urandom | head -c30 | sha512sum | head -c30)
        read -esp "phpMyAdmin control user password [${tmp}]: " pma_pass
        pma_pass=${pma_pass:-${tmp}}
        echo "phpMyAdmin control user password: ${pma_pass}" > $HOME/$prog_pass

    fi

    echo -e "\n"; chmod 600 $HOME/$prog_pass

fi

if [[ $Install_Mailman = y ]]; then

    if [[ -z ${mailman_email} ]]; then # If Mailman's list email is not set above, set it now

        tmp=admin@$MY_DOMAIN
	    read -esp "Mailman's List Email Address [${tmp}]: " mailman_email
	    mailman_email=${mailman_email:-${tmp}}
	    echo "Mailman's List Email Address: ${mailman_email}" >> $HOME/$prog_pass

    fi; echo -e "\n"

    if [[ -z ${mailman_pass} ]]; then # If Mailman's list password is not set above, set it now

        tmp=$(tr -dc '[:alnum:]' < /dev/urandom | head -c30 | sha512sum | head -c30)
        read -esp "Mailman's List Password [${tmp}]: " mailman_pass
        mailman_pass=${mailman_pass:-${tmp}}
        echo "Mailman's List Password: ${mailman_pass}" >> $HOME/$prog_pass

    fi; echo -e "\n"

fi

getfiles RPM-GPG-KEY-EPEL-6 $epel_key
getfiles ${rpmforge_key##*/} $rpmforge_key

mv /tmp/RPM-GPG-KEY-EPEL-6 /etc/pki/rpm-gpg; echo ""
mv /tmp/${rpmforge_key##*/} /etc/pki/rpm-gpg

rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*

getfiles ${epel_pkg##*/} $epel_pkg
getfiles ${rpmforge_pkg##*/} $rpmforge_pkg

yum -y -q install /tmp/*.rpm

rm -f /tmp/*.rpm

yum -y -q install yum-priorities openssl yum-plugin-remove-with-leaves

sed -i '/enabled=1/ a\priority=10' /etc/yum.repos.d/epel.repo # Append priority of 10 to epel.repo file

clear; echo -e "Repos installed running 'yum clean all && yum makecache' \n"

yum -y -q clean all && yum -y -q makecache

echo -e "Updating and installing 'development tools' + cmake ccache now. \n"

yum -y -q update && yum -y -q groupinstall 'Development tools' && yum -y -q install cmake ccache; echo ""

echo -e "Done updating and installing 'development tools'."
}

Install_NTPd () {
rm -f /etc/localtime && ln -s /usr/share/zoneinfo/US/$timezone /etc/localtime; echo ""

yum -y -q install ntp ntp-doc ntpdate rkhunter fail2ban

sed -i 's/^logtarget \= \(.*\)$/logtarget \= \/var\/log\/fail2ban.log/g' /etc/fail2ban/fail2ban.conf
sed -i "s/dest=\(.*\)/dest=root@$MY_DOMAIN]/g" /etc/fail2ban/jail.conf

init_service fail2ban on
ctrl_service fail2ban start; echo ""

echo -e "Correcting our system clock now. \n"

init_service ntpd on
ntpdate pool.ntp.org || ntpdate pool.ntp.org; echo ""
ctrl_service ntpd start; echo ""
}

Set_Quota () {
yum -y -q install quota

cp -p /etc/fstab /etc/fstab.bak
sed -i "s/\/dev\/mapper\/vg_$MY_HOST-lv_root \/                       ext4    defaults        1 1/\/dev\/mapper\/vg_$MY_HOST-lv_root \/                       ext4    defaults,usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv0        1 1/g" /etc/fstab

mount -o remount / && quotacheck -avugm && quotaon -avug; echo ""
}

Install_Web_Server () {
yum -y -q install httpd httpd-devel httpd-tools mod_ssl mod_geoip GeoIP php-pecl-geoip perl-Geo-IP GeoIP-devel php php-cli php-mysql php-mbstring php-php-gettext php-devel php-gd php-imap \
php-ldap php-odbc php-pear php-xml php-xmlrpc php-pecl-apc php-mcrypt php-mssql php-snmp php-recode recode recode-devel \
php-pspell php-soap php-tidy ImageMagick libxml2-devel mod_fcgid php-intl php-fpm php-bcmath memcached libmemcached libmemcached-devel memcached-devel php-pecl-memcache*

sed -i 's/^error_reporting \= E_ALL \& ~E_DEPRECATED/error_reporting \= E_ALL \& ~E_NOTICE/g' /etc/php.ini
sed -i 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/g' /etc/php.ini
sed -i "s/^;date.timezone \=/date.timezone \= \'America\/Detroit\'/g" /etc/php.ini
sed -i 's/^short_open_tag \= \(.*\)/short_open_tag \= On/g' /etc/php.ini
sed -i "s/^expose_php \= \(.*\)/expose_php \= Off/g" /etc/php.ini
sed -i "s/^allow_url_fopen \= \(.*\)/allow_url_fopen \= Off/g" /etc/php.ini
sed -i "s/^allow_url_include \= \(.*\)/allow_url_include \= Off/g" /etc/php.ini
sed -i "s/^;error_log \= \/var\/log\/php-fpm\/error.log/error_log \= \/var\/log\/php-fpm\/error.log/g" /etc/php.ini
[[ ! -d /etc/httpd/htpasswd_files ]] && mkdir -p /etc/httpd/htpasswd_files

cd /usr/share/GeoIP
[[ -f GeoIP.dat ]] && mv GeoIP.dat GeoIP.dat_org
[[ -f GeoIPASNum.dat ]] && mv GeoIPASNum.dat GeoIPASNum.dat_org
[[ -f GeoLiteCity.dat ]] && mv GeoLiteCity.dat GeoLiteCity.dat_org
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
wget http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz
gunzip *.gz; cd
[[ -f /etc/httpd/conf.d/geoip.conf ]] && mv /etc/httpd/conf.d/geoip.conf /etc/httpd/conf.d/geoip.conf.bck

cat <<EOF > /etc/httpd/conf.d/geoip.conf
LoadModule geoip_module modules/mod_geoip.so

<IfModule mod_geoip.c>
  GeoIPEnable On
  GeoIPDBFile /usr/share/GeoIP/GeoIP.dat
  GeoIPDBFile /usr/share/GeoIP/GeoLiteCity.dat
  GeoIPDBFile /usr/share/GeoIP/GeoIPASNum.dat
</IfModule>
EOF

init_service memcached on
ctrl_service memcached start

init_service php-fpm on
ctrl_service php-fpm start; echo "";

init_service httpd on
ctrl_service httpd start; echo "";
}

Install_Mail_Server () {
yum -y -q install dovecot dovecot-mysql postfix getmail

init_service dovecot on
ctrl_service dovecot start; echo ""

init_service postfix on
ctrl_service postfix restart; echo ""
}

Install_MySQL_Server () {

if [[ $MariaDB_Version = 5 ]]; then

cat <<EOF > /etc/yum.repos.d/MariaDB55.repo
# MariaDB 5.5 CentOS repository list - created 2015-08-02 02:27 UTC
# http://mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/5.5/centos6-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

elif [[ $MariaDB_Version = 10 ]]; then

cat <<EOF > /etc/yum.repos.d/MariaDB10.repo
# MariaDB 10.0 CentOS repository list - created 2015-08-02 01:53 UTC
# http://mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.0/centos6-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

fi

yum -y -q install MariaDB-server MariaDB-client MariaDB-devel #mysql-utilities mysql-libs

mv /etc/my.cnf /etc/my.cnf.bak
cp -p /usr/share/mysql/my-large.cnf /etc/my.cnf

[[ ! -d /var/log/mysql ]] && mkdir -p /var/log/mysql && chown mysql:mysql /var/log/mysql && chmod 750 /var/log/mysql

sed -i '/^skip-external-locking/ a\bind-address \= 127.0.0.1' /etc/my.cnf
sed -i '/^skip-external-locking/ a\local-infile=0' /etc/my.cnf
sed -i '/^local-infile=0/ a\symbolic-links=0' /etc/my.cnf
sed -i '/^symbolic-links=0/ a\skip-show-database' /etc/my.cnf
sed -i '/^skip-show-database/ a\log_error=\/var\/log\/mysql\/mysql_error.log' /etc/my.cnf
sed -i '/^log_error=\/var\/log\/mysql\/mysql_error.log/ a\general_log=1' /etc/my.cnf
sed -i '/^general_log=1/ a\general_log_file=/var/log/mysql/mysqld.log' /etc/my.cnf

init_service mysql on
ctrl_service mysql start

clear; echo -e "Going to secure the MySQL installation, follow the prompts on screen. \nIf you choose to use the generated password for MySQL, then you will want to copy it for the next step when securing MySQL Installation. \n"

if [[ -z ${mysql_pass} ]]; then

    tmp=$(tr -dc '[:alnum:]' < /dev/urandom | head -c30 | sha512sum | head -c30)
    read -esp "MySQL root password: [${tmp}]: " mysql_pass
    mysql_pass=${mysql_pass:-${tmp}}
    echo "MySQL root password: ${mysql_pass}" >> $HOME/$prog_pass	

fi

mysql_secure_installation; echo ""
[[ ! -f $HOME/.my.cnf ]] && cat <<EOF > $HOME/.my.cnf
[client]
user=root
password=$mysql_pass
EOF
}

Install_phpMyAdmin () {
getfiles $pma_file $phpmyadmin_url

extract_tars /tmp/$pma_file /tmp

mv /tmp/$pma_extdir /usr/share/phpMyAdmin

[[ ! -d /etc/phpMyAdmin ]] && mkdir -p /etc/phpMyAdmin

# Create phpMyAdmin's webconf file
cat <<'CONF' > /etc/httpd/conf.d/phpMyAdmin.conf
# phpMyAdmin - Web based MySQL browser written in php
#
# Allows only localhost by default
#
# But allowing phpMyAdmin to anyone other than localhost should be considered
# dangerous unless properly secured by SSL

Alias /phpmyadmin /usr/share/phpMyAdmin
Alias /phpMyAdmin /usr/share/phpMyAdmin
Alias /mysqladmin /usr/share/phpMyAdmin

<Directory "/usr/share/phpMyAdmin">
	Order Deny,Allow
	Deny from ALL
	Allow from ALL
</Directory>

<Directory "/usr/share/phpMyAdmin/setup">
	Order Deny,Allow
	Deny from All
	Allow from 127.0.0.1
</Directory>

# These directories do not require access over HTTP - taken from the original
# phpMyAdmin upstream tarball
#
<Directory "/usr/share/phpMyAdmin/libraries">
    Order Deny,Allow
    Deny from All
    Allow from None
</Directory>

<Directory "/usr/share/phpMyAdmin/setup/lib">
    Order Deny,Allow
    Deny from All
    Allow from None
</Directory>

<Directory "/usr/share/phpMyAdmin/setup/frames">
    Order Deny,Allow
    Deny from All
    Allow from None
</Directory>

# This configuration prevents mod_security at phpMyAdmin directories from
# filtering SQL etc.  This may break your mod_security implementation.
#
<IfModule mod_security2.c>
<Directory "/usr/share/phpMyAdmin">
SecRuleEngine Off
#SecRuleInheritance Off
</Directory>
</IfModule>
CONF

# Create phpMyAdmin's conf file
cat <<EOF > /etc/phpMyAdmin/config.inc.php
<?php
\$i = 0;

/* Server: MySQL Manger [1] */
\$i++;
\$cfg['Servers'][\$i]['verbose'] = 'MySQL Manger';
\$cfg['Servers'][\$i]['host'] = 'localhost';
\$cfg['Servers'][\$i]['port'] = '';
\$cfg['Servers'][\$i]['socket'] = '';
\$cfg['Servers'][\$i]['connect_type'] = 'tcp';
\$cfg['Servers'][\$i]['extension'] = 'mysqli';
\$cfg['Servers'][\$i]['auth_type'] = 'http';
\$cfg['Servers'][\$i]['user'] = '';
\$cfg['Servers'][\$i]['password'] = '';
\$cfg['Servers'][\$i]['pmadb'] = 'phpmyadmin';
\$cfg['Servers'][\$i]['controluser'] = 'pmaadm';
\$cfg['Servers'][\$i]['controlpass'] = '$pma_pass';
\$cfg['Servers'][\$i]['bookmarktable'] = 'pma__bookmark';
\$cfg['Servers'][\$i]['relation'] = 'pma__relation';
\$cfg['Servers'][\$i]['userconfig'] = 'pma__userconfig';
\$cfg['Servers'][\$i]['users'] = 'pma__users';
\$cfg['Servers'][\$i]['usergroups'] = 'pma__usergroups';
\$cfg['Servers'][\$i]['navigationhiding'] = 'pma__navigationhiding';
\$cfg['Servers'][\$i]['table_info'] = 'pma__table_info';
\$cfg['Servers'][\$i]['column_info'] = 'pma__column_info';
\$cfg['Servers'][\$i]['history'] = 'pma__history';
\$cfg['Servers'][\$i]['recent'] = 'pma__recent';
\$cfg['Servers'][\$i]['favorite'] = 'pma__favorite';
\$cfg['Servers'][\$i]['table_uiprefs'] = 'pma__table_uiprefs';
\$cfg['Servers'][\$i]['tracking'] = 'pma__tracking';
\$cfg['Servers'][\$i]['table_coords'] = 'pma__table_coords';
\$cfg['Servers'][\$i]['pdf_pages'] = 'pma__pdf_pages';
\$cfg['Servers'][\$i]['designer_coords'] = 'pma__designer_coords';
\$cfg['Servers'][\$i]['savedsearches'] = 'pma__savedsearches';
\$cfg['Servers'][\$i]['central_columns'] = 'pma__central_columns';
\$cfg['ShowStats'] = true;
\$cfg['ShowServerInfo'] = true;
\$cfg['ShowChgPassword'] = false;
\$cfg['Servers'][\$i]['AllowRoot'] = TRUE;
\$cfg['Servers'][\$i]['AllowNoPassword'] = FALSE;
#\$cfg['UploadDir'] = '/var/lib/phpMyAdmin/upload';
#\$cfg['SaveDir'] = '/var/lib/phpMyAdmin/save';
\$cfg['blowfish_secret'] = '$(tr -dc '[:alnum:]' < /dev/urandom | head -c50 | sha512sum | head -c50)';
\$cfg['ForceSSL'] = true;
#\$cfg['CaptchaLoginPublicKey'] = '';
#\$cfg['CaptchaLoginPrivateKey'] = '';
#\$cfg['ShowPhpInfo'] = true;
\$cfg['Export']['compression'] = 'gzip';
\$cfg['DefaultLang'] = 'en';
\$cfg['ServerDefault'] = 1;
?>
EOF

# Fix permissions on phpMyAdmin's conf file
chown root:apache /etc/phpMyAdmin/config.inc.php
chmod 640 /etc/phpMyAdmin/config.inc.php

# Create phpMyAdmin's save/upload folder's and fix their ownership/permissions ( We do not enable this in the configuration )
#mkdir -p /var/lib/phpMyAdmin/{save,upload}
#chown root:apache /var/lib/phpMyAdmin/{save,upload}
#chmod 770 /var/lib/phpMyAdmin/{save,upload}

# Create Sym-Link to oldpath of conf file
ln -s ../../../etc/phpMyAdmin/config.inc.php /usr/share/phpMyAdmin/config.inc.php

rm -f /tmp/$pma_file

ctrl_service httpd restart

clear && echo -e "Importing SQL code into MySQL for phpMyAdmin. \n"

# Imports phpMyAdmin SQL code into MySQL
cat <<EOF | mysql -u root -p$mysql_pass
CREATE DATABASE IF NOT EXISTS \`phpmyadmin\`
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
USE phpmyadmin;

GRANT USAGE ON mysql.* TO 'pmaadm'@'localhost' IDENTIFIED BY '$pma_pass';
GRANT SELECT (
Host, User, Select_priv, Insert_priv, Update_priv, Delete_priv,
Create_priv, Drop_priv, Reload_priv, Shutdown_priv, Process_priv,
File_priv, Grant_priv, References_priv, Index_priv, Alter_priv,
Show_db_priv, Super_priv, Create_tmp_table_priv, Lock_tables_priv,
Execute_priv, Repl_slave_priv, Repl_client_priv
) ON mysql.user TO 'pmaadm'@'localhost';
GRANT SELECT ON mysql.db TO 'pmaadm'@'localhost';
GRANT SELECT ON mysql.host TO 'pmaadm'@'localhost';
GRANT SELECT (Host, Db, User, Table_name, Table_priv, Column_priv)
ON mysql.tables_priv TO 'pmaadm'@'localhost';

GRANT SELECT, INSERT, DELETE, UPDATE ON \`phpmyadmin\`.* TO 'pmaadm'@localhost;

CREATE TABLE IF NOT EXISTS \`pma__bookmark\` (
  \`id\` int(11) NOT NULL auto_increment,
  \`dbase\` varchar(255) NOT NULL default '',
  \`user\` varchar(255) NOT NULL default '',
  \`label\` varchar(255) COLLATE utf8_general_ci NOT NULL default '',
  \`query\` text NOT NULL,
  PRIMARY KEY  (\`id\`)
)
  COMMENT='Bookmarks'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__column_info\` (
  \`id\` int(5) unsigned NOT NULL auto_increment,
  \`db_name\` varchar(64) NOT NULL default '',
  \`table_name\` varchar(64) NOT NULL default '',
  \`column_name\` varchar(64) NOT NULL default '',
  \`comment\` varchar(255) COLLATE utf8_general_ci NOT NULL default '',
  \`mimetype\` varchar(255) COLLATE utf8_general_ci NOT NULL default '',
  \`transformation\` varchar(255) NOT NULL default '',
  \`transformation_options\` varchar(255) NOT NULL default '',
  PRIMARY KEY  (\`id\`),
  UNIQUE KEY \`db_name\` (\`db_name\`,\`table_name\`,\`column_name\`)
)
  COMMENT='Column information for phpMyAdmin'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__history\` (
  \`id\` bigint(20) unsigned NOT NULL auto_increment,
  \`username\` varchar(64) NOT NULL default '',
  \`db\` varchar(64) NOT NULL default '',
  \`table\` varchar(64) NOT NULL default '',
  \`timevalue\` timestamp NOT NULL,
  \`sqlquery\` text NOT NULL,
  PRIMARY KEY  (\`id\`),
  KEY \`username\` (\`username\`,\`db\`,\`table\`,\`timevalue\`)
)
  COMMENT='SQL history for phpMyAdmin'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__pdf_pages\` (
  \`db_name\` varchar(64) NOT NULL default '',
  \`page_nr\` int(10) unsigned NOT NULL auto_increment,
  \`page_descr\` varchar(50) COLLATE utf8_general_ci NOT NULL default '',
  PRIMARY KEY  (\`page_nr\`),
  KEY \`db_name\` (\`db_name\`)
)
  COMMENT='PDF relation pages for phpMyAdmin'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__recent\` (
  \`username\` varchar(64) NOT NULL,
  \`tables\` text NOT NULL,
  PRIMARY KEY (\`username\`)
)
  COMMENT='Recently accessed tables'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__table_uiprefs\` (
  \`username\` varchar(64) NOT NULL,
  \`db_name\` varchar(64) NOT NULL,
  \`table_name\` varchar(64) NOT NULL,
  \`prefs\` text NOT NULL,
  \`last_update\` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (\`username\`,\`db_name\`,\`table_name\`)
)
  COMMENT='Tables'' UI preferences'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__relation\` (
  \`master_db\` varchar(64) NOT NULL default '',
  \`master_table\` varchar(64) NOT NULL default '',
  \`master_field\` varchar(64) NOT NULL default '',
  \`foreign_db\` varchar(64) NOT NULL default '',
  \`foreign_table\` varchar(64) NOT NULL default '',
  \`foreign_field\` varchar(64) NOT NULL default '',
  PRIMARY KEY  (\`master_db\`,\`master_table\`,\`master_field\`),
  KEY \`foreign_field\` (\`foreign_db\`,\`foreign_table\`)
)
  COMMENT='Relation table'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__table_coords\` (
  \`db_name\` varchar(64) NOT NULL default '',
  \`table_name\` varchar(64) NOT NULL default '',
  \`pdf_page_number\` int(11) NOT NULL default '0',
  \`x\` float unsigned NOT NULL default '0',
  \`y\` float unsigned NOT NULL default '0',
  PRIMARY KEY  (\`db_name\`,\`table_name\`,\`pdf_page_number\`)
)
  COMMENT='Table coordinates for phpMyAdmin PDF output'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__table_info\` (
  \`db_name\` varchar(64) NOT NULL default '',
  \`table_name\` varchar(64) NOT NULL default '',
  \`display_field\` varchar(64) NOT NULL default '',
  PRIMARY KEY  (\`db_name\`,\`table_name\`)
)
  COMMENT='Table information for phpMyAdmin'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__designer_coords\` (
  \`db_name\` varchar(64) NOT NULL default '',
  \`table_name\` varchar(64) NOT NULL default '',
  \`x\` INT,
  \`y\` INT,
  \`v\` TINYINT,
  \`h\` TINYINT,
  PRIMARY KEY (\`db_name\`,\`table_name\`)
)
  COMMENT='Table coordinates for Designer'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__tracking\` (
  \`db_name\` varchar(64) NOT NULL,
  \`table_name\` varchar(64) NOT NULL,
  \`version\` int(10) unsigned NOT NULL,
  \`date_created\` datetime NOT NULL,
  \`date_updated\` datetime NOT NULL,
  \`schema_snapshot\` text NOT NULL,
  \`schema_sql\` text,
  \`data_sql\` longtext,
  \`tracking\` set('UPDATE','REPLACE','INSERT','DELETE','TRUNCATE','CREATE DATABASE','ALTER DATABASE','DROP DATABASE','CREATE TABLE','ALTER TABLE','RENAME TABLE','DROP TABLE','CREATE INDEX','DROP INDEX','CREATE VIEW','ALTER VIEW','DROP VIEW') default NULL,
  \`tracking_active\` int(1) unsigned NOT NULL default '1',
  PRIMARY KEY  (\`db_name\`,\`table_name\`,\`version\`)
)
  COMMENT='Database changes tracking for phpMyAdmin'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__userconfig\` (
  \`username\` varchar(64) NOT NULL,
  \`timevalue\` timestamp NOT NULL,
  \`config_data\` text NOT NULL,
  PRIMARY KEY  (\`username\`)
)
  COMMENT='User preferences storage for phpMyAdmin'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__users\` (
  \`username\` varchar(64) NOT NULL,
  \`usergroup\` varchar(64) NOT NULL,
  PRIMARY KEY (\`username\`,\`usergroup\`)
)
  COMMENT='Users and their assignments to user groups'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__usergroups\` (
  \`usergroup\` varchar(64) NOT NULL,
  \`tab\` varchar(64) NOT NULL,
  \`allowed\` enum('Y','N') NOT NULL DEFAULT 'N',
  PRIMARY KEY (\`usergroup\`,\`tab\`,\`allowed\`)
)
  COMMENT='User groups with configured menu items'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__navigationhiding\` (
  \`username\` varchar(64) NOT NULL,
  \`item_name\` varchar(64) NOT NULL,
  \`item_type\` varchar(64) NOT NULL,
  \`db_name\` varchar(64) NOT NULL,
  \`table_name\` varchar(64) NOT NULL,
  PRIMARY KEY (\`username\`,\`item_name\`,\`item_type\`,\`db_name\`,\`table_name\`)
)
  COMMENT='Hidden items of navigation tree'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__savedsearches\` (
  \`id\` int(5) unsigned NOT NULL auto_increment,
  \`username\` varchar(64) NOT NULL default '',
  \`db_name\` varchar(64) NOT NULL default '',
  \`search_name\` varchar(64) NOT NULL default '',
  \`search_data\` text NOT NULL,
  PRIMARY KEY  (\`id\`),
  UNIQUE KEY \`u_savedsearches_username_dbname\` (\`username\`,\`db_name\`,\`search_name\`)
)
  COMMENT='Saved searches'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__central_columns\` (
  \`db_name\` varchar(64) NOT NULL,
  \`col_name\` varchar(64) NOT NULL,
  \`col_type\` varchar(64) NOT NULL,
  \`col_length\` text,
  \`col_collation\` varchar(64) NOT NULL,
  \`col_isNull\` boolean NOT NULL,
  \`col_extra\` varchar(255) default '',
  \`col_default\` text,
  PRIMARY KEY (\`db_name\`,\`col_name\`)
)
  COMMENT='Central list of columns'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE IF NOT EXISTS \`pma__favorite\` (
  \`username\` varchar(64) NOT NULL,
  \`tables\` text NOT NULL,
  PRIMARY KEY (\`username\`)
)
  COMMENT='Favorite tables'
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

FLUSH PRIVILEGES;
EOF

mysql -u root -p$mysql_pass < /usr/share/phpMyAdmin/sql/upgrade_column_info_4_3_0+.sql

echo -e "Importing SQL code for phpMyAdmins completed."
rm -rf /usr/share/phpMyAdmin/setup && unset pma_pass; echo ""
}

Install_AV () {
yum -y -q install amavisd-new spamassassin clamav clamd unzip bzip2 unrar perl-DBD-mysql

sa-update
chkconfig --del clamd

init_service amavisd on
init_service clamd.amavisd on
init_service spamassassin on
init_service saslauthd on

freshclam; echo ""

ctrl_service amavisd start
ctrl_service clamd.amavisd start
ctrl_service spamassassin start
ctrl_service saslauthd start; echo ""
}

Compile_apache_modz () {
getfiles ${suphp_url##*/} $suphp_url

extract_tars /tmp/${suphp_url##*/} /tmp

cd /tmp/suphp-0.7.2

# Create needed configuration files to compile suPHP correctly
libtoolize --force && aclocal && autoheader && automake --force-missing --add-missing && autoconf

# Compile suPHP and Install
./configure --prefix=/usr --sysconfdir=/etc --with-apr=/usr/bin/apr-1-config --with-apxs=/usr/sbin/apxs --with-apache-user=apache --with-setid-mode=owner --with-logfile=/var/log/httpd/suphp_log && make && make install; echo ""

# Remove downloaded suPHP files
cd ../ && rm -rf suphp-0.7.2*

# Create suPHP webconf file
cat <<'EOF' > /etc/httpd/conf.d/suphp.conf
LoadModule suphp_module modules/mod_suphp.so
EOF

# Create suPHP conf file
cat <<'EOF' > /etc/suphp.conf
[global]
;Path to logfile
logfile=/var/log/httpd/suphp.log
;Loglevel
loglevel=info
;User Apache is running as
webserver_user=apache
;Path all scripts have to be in
docroot=/
;Path to chroot() to before executing script
;chroot=/mychroot
; Security options
allow_file_group_writeable=true
allow_file_others_writeable=false
allow_directory_group_writeable=true
allow_directory_others_writeable=false
;Check wheter script is within DOCUMENT_ROOT
check_vhost_docroot=true
;Send minor error messages to browser
errors_to_browser=false
;PATH environment variable
env_path=/bin:/usr/bin
;Umask to set, specify in octal notation
umask=0077
; Minimum UID
min_uid=100
; Minimum GID
min_gid=100

[handlers]
;Handler for php-scripts
x-httpd-suphp="php:/usr/bin/php-cgi"
;Handler for CGI-scripts
x-suphp-cgi="execute:!self"
EOF

# Install ruby, ruby-devel, ruby-docs, rubygems, mod_python
yum -y -q install ruby ruby-devel ruby-rdoc ruby-ri ruby-docs rubygems mod_python

getfiles ${mod_ruby_url##*/} $mod_ruby_url

extract_tars /tmp/${mod_ruby_url##*/} /tmp

cd /tmp/mod_ruby-1.3.0

# Compile and Instal mod_ruby module for Apache
./configure.rb --with-apr-includes=/usr/include/apr-1 && make && make install; echo ""

# Remove downloaded mod_ruby files
cd ../ && rm -rf mod_ruby-1.3.0*

# Creates mod_ruby webconf file
cat <<'EOF' > /etc/httpd/conf.d/ruby.conf
LoadModule ruby_module modules/mod_ruby.so
RubyAddPath /1.8
EOF

ctrl_service httpd restart; echo ""
}

Install_FTP_Server () {
yum -y -q install pure-ftpd

[[ ! -d /etc/ssl/private ]] && mkdir -p /etc/ssl/private || echo -e "Failed to make directory /etc/ssl/private \n"; echo ""
[[ ! -d /var/log/pureftpd ]] && mkdir -p /var/log/pureftpd || echo -e "Failed to make directory /var/log/pureftpd \n"

create_ftp_cert /etc/ssl/private/pure-ftpd.pem

chmod 600 /etc/ssl/private/pure-ftpd.pem

init_service pure-ftpd on
ctrl_service pure-ftpd start; echo ""
}

Install_DNS_Server () {
yum -y -q install bind bind-utils bind-devel bind-libs

mv /etc/sysconfig/named /etc/sysconfig/named.bak
mv /etc/named.conf /etc/named.conf.bak; echo ""

cat <<'EOF' > /etc/sysconfig/named
# BIND named process options
# ~~~~~~~~~~~~~~~~~~~~~~~~~~
# Currently, you can use the following options:
#
# ROOTDIR="/var/named/chroot"  --  will run named in a chroot environment.
#                            you must set up the chroot environment
#                            (install the bind-chroot package) before
#                            doing this.
#       NOTE:
#         Those directories are automatically mounted to chroot if they are
#         empty in the ROOTDIR directory. It will simplify maintenance of your
#         chroot environment.
#          - /var/named
#          - /etc/pki/dnssec-keys
#          - /etc/named
#          - /usr/lib64/bind or /usr/lib/bind (architecture dependent)
#
#         Those files are mounted as well if target file doesn't exist in
#         chroot.
#          - /etc/named.conf
#          - /etc/rndc.conf
#          - /etc/rndc.key
#          - /etc/named.rfc1912.zones
#          - /etc/named.dnssec.keys
#          - /etc/named.iscdlv.key
#
#       Don't forget to add "$AddUnixListenSocket /var/named/chroot/dev/log"
#       line to your /etc/rsyslog.conf file. Otherwise your logging becomes
#       broken when rsyslogd daemon is restarted (due update, for example).
#
# OPTIONS="whatever"     --  These additional options will be passed to named
#                            at startup. Don't add -t here, use ROOTDIR instead.
#
# KEYTAB_FILE="/dir/file"    --  Specify named service keytab file (for GSS-TSIG)
#
# DISABLE_ZONE_CHECKING  -- By default, initscript calls named-checkzone
#                           utility for every zone to ensure all zones are
#                           valid before named starts. If you set this option
#                           to 'yes' then initscript doesn't perform those
#                           checks.
EOF

cat <<'EOF' > /etc/named.conf
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
options {
        listen-on port 53 { any; };
        listen-on-v6 port 53 { any; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        allow-query     { any; };
        recursion no;
        allow-recursion { none; };
};
logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};
zone "." IN {
        type hint;
        file "named.ca";
};
include "/etc/named.conf.local";
EOF

touch /etc/named.conf.local

init_service named on
ctrl_service named start; echo ""
}

Install_Stats () {
yum -y -q install webalizer awstats perl-DateTime-Format-HTTP perl-DateTime-Format-Builder htmldoc
}

Compile_Jailkit () {
getfiles ${jailkit_url##*/} $jailkit_url
extract_tars /tmp/${jailkit_url##*/} /tmp

cd /tmp/jailkit-2.17

./configure && make && make install; echo ""

cd ../ && rm -rf jailkit-2.17*
}

Install_Mailman_Service () {
yum -y -q install mailman

# Create new mailing list
/usr/lib/mailman/bin/newlist -q mailman $mailman_email $mailman_pass; unset mailman_email mailman_pass

# Delete bottom portion of aliases files, don't worry we re-add it below
sed -i '/^# trap/,$d' /etc/aliases

# Add Mailman aliases to aliases file
cat <<EOF >> /etc/aliases
fail2ban:		root
denyhosts:		root

## mailman mailing list
mailman:              "|/usr/lib/mailman/mail/mailman post mailman"
mailman-admin:        "|/usr/lib/mailman/mail/mailman admin mailman"
mailman-bounces:      "|/usr/lib/mailman/mail/mailman bounces mailman"
mailman-confirm:      "|/usr/lib/mailman/mail/mailman confirm mailman"
mailman-join:         "|/usr/lib/mailman/mail/mailman join mailman"
mailman-leave:        "|/usr/lib/mailman/mail/mailman leave mailman"
mailman-owner:        "|/usr/lib/mailman/mail/mailman owner mailman"
mailman-request:      "|/usr/lib/mailman/mail/mailman request mailman"
mailman-subscribe:    "|/usr/lib/mailman/mail/mailman subscribe mailman"
mailman-unsubscribe:  "|/usr/lib/mailman/mail/mailman unsubscribe mailman"

# trap decode to catch security attacks
decode:         root

# Person who should get root's mail
root:          root@$MY_DOMAIN
EOF

ln -s ../../etc/aliases /etc/mailman/aliases; echo ""

newaliases
ctrl_service postfix restart; echo ""

cat <<'EOF' > /etc/httpd/conf.d/mailman.conf
#
#  httpd configuration settings for use with mailman.
#
ScriptAlias /mailman/ /usr/lib/mailman/cgi-bin/
ScriptAlias /cgi-bin/mailman/ /usr/lib/mailman/cgi-bin/
<Directory "/usr/lib/mailman/cgi-bin/">
    AllowOverride None
    Options ExecCGI
    Order Allow,Deny
    Allow from all
</Directory>

#Alias /pipermail/ /var/lib/mailman/archives/public/
Alias /pipermail /var/lib/mailman/archives/public/
<Directory "/var/lib/mailman/archives/public">
    Options Indexes MultiViews FollowSymLinks
    AllowOverride None
    Order Allow,Deny
    Allow from All
    AddDefaultCharset Off
</Directory>
# Uncomment the following line, to redirect queries to /mailman to the
# listinfo page (recommended).
# RedirectMatch ^/mailman[/]*$ /mailman/listinfo
EOF

ctrl_service httpd restart; echo ""
init_service mailman on
ctrl_service mailman start
}

Install_Webmail () {
yum -y -q install squirrelmail

mv /etc/squirrelmail/config.php /etc/squirrelmail/config.php.bak
mv /etc/squirrelmail/config_local.php /etc/squirrelmail/config_local.php.bak

# Create Squirrelmail conf file
cat <<'EOF' > /etc/squirrelmail/config.php
<?php

/**
 * SquirrelMail Configuration File
 * Created using the configure script, conf.pl
 */

global $version;
$config_version = '1.4.0';
$config_use_color = 1;

$org_name      = "SquirrelMail";
$org_logo      = SM_PATH . 'images/sm_logo.png';
$org_logo_width  = '308';
$org_logo_height = '111';
$org_title     = "SquirrelMail $version";
$signout_page  = '';
$frame_top     = '_top';

$provider_uri     = 'http://squirrelmail.org/';

$provider_name     = 'SquirrelMail';

$motd = "";

$squirrelmail_default_language = 'en_US';
$default_charset       = 'iso-8859-1';
$lossy_encoding        = false;

$domain                 = 'localhost';
$imapServerAddress      = 'localhost';
$imapPort               = 143;
$useSendmail            = true;
$smtpServerAddress      = 'localhost';
$smtpPort               = 25;
$sendmail_path          = '/usr/sbin/sendmail';
$sendmail_args          = '-i -t';
$pop_before_smtp        = false;
$pop_before_smtp_host   = '';
$imap_server_type       = 'dovecot';
$invert_time            = false;
$optional_delimiter     = 'detect';
$encode_header_key      = '';

$default_folder_prefix          = '';
$trash_folder                   = 'Trash';
$sent_folder                    = 'Sent';
$draft_folder                   = 'Drafts';
$default_move_to_trash          = true;
$default_move_to_sent           = true;
$default_save_as_draft          = true;
$show_prefix_option             = false;
$list_special_folders_first     = true;
$use_special_folder_color       = true;
$auto_expunge                   = true;
$default_sub_of_inbox           = false;
$show_contain_subfolders_option = false;
$default_unseen_notify          = 2;
$default_unseen_type            = 1;
$auto_create_special            = true;
$delete_folder                  = false;
$noselect_fix_enable            = false;

$data_dir                 = '/var/lib/squirrelmail/prefs/';
$attachment_dir           = '/var/spool/squirrelmail/attach/';
$dir_hash_level           = 0;
$default_left_size        = '150';
$force_username_lowercase = true;
$default_use_priority     = true;
$hide_sm_attributions     = false;
$default_use_mdn          = true;
$edit_identity            = true;
$edit_name                = true;
$hide_auth_header         = false;
$allow_thread_sort        = true;
$allow_server_sort        = true;
$allow_charset_search     = true;
$uid_support              = true;

$plugins[0] = 'delete_move_next';
$plugins[1] = 'squirrelspell';
$plugins[2] = 'newmail';

$theme_css = '';
$theme_default = 0;
$theme[0]['PATH'] = SM_PATH . 'themes/default_theme.php';
$theme[0]['NAME'] = 'Default';
$theme[1]['PATH'] = SM_PATH . 'themes/plain_blue_theme.php';
$theme[1]['NAME'] = 'Plain Blue';
$theme[2]['PATH'] = SM_PATH . 'themes/sandstorm_theme.php';
$theme[2]['NAME'] = 'Sand Storm';
$theme[3]['PATH'] = SM_PATH . 'themes/deepocean_theme.php';
$theme[3]['NAME'] = 'Deep Ocean';
$theme[4]['PATH'] = SM_PATH . 'themes/slashdot_theme.php';
$theme[4]['NAME'] = 'Slashdot';
$theme[5]['PATH'] = SM_PATH . 'themes/purple_theme.php';
$theme[5]['NAME'] = 'Purple';
$theme[6]['PATH'] = SM_PATH . 'themes/forest_theme.php';
$theme[6]['NAME'] = 'Forest';
$theme[7]['PATH'] = SM_PATH . 'themes/ice_theme.php';
$theme[7]['NAME'] = 'Ice';
$theme[8]['PATH'] = SM_PATH . 'themes/seaspray_theme.php';
$theme[8]['NAME'] = 'Sea Spray';
$theme[9]['PATH'] = SM_PATH . 'themes/bluesteel_theme.php';
$theme[9]['NAME'] = 'Blue Steel';
$theme[10]['PATH'] = SM_PATH . 'themes/dark_grey_theme.php';
$theme[10]['NAME'] = 'Dark Grey';
$theme[11]['PATH'] = SM_PATH . 'themes/high_contrast_theme.php';
$theme[11]['NAME'] = 'High Contrast';
$theme[12]['PATH'] = SM_PATH . 'themes/black_bean_burrito_theme.php';
$theme[12]['NAME'] = 'Black Bean Burrito';
$theme[13]['PATH'] = SM_PATH . 'themes/servery_theme.php';
$theme[13]['NAME'] = 'Servery';
$theme[14]['PATH'] = SM_PATH . 'themes/maize_theme.php';
$theme[14]['NAME'] = 'Maize';
$theme[15]['PATH'] = SM_PATH . 'themes/bluesnews_theme.php';
$theme[15]['NAME'] = 'BluesNews';
$theme[16]['PATH'] = SM_PATH . 'themes/deepocean2_theme.php';
$theme[16]['NAME'] = 'Deep Ocean 2';
$theme[17]['PATH'] = SM_PATH . 'themes/blue_grey_theme.php';
$theme[17]['NAME'] = 'Blue Grey';
$theme[18]['PATH'] = SM_PATH . 'themes/dompie_theme.php';
$theme[18]['NAME'] = 'Dompie';
$theme[19]['PATH'] = SM_PATH . 'themes/methodical_theme.php';
$theme[19]['NAME'] = 'Methodical';
$theme[20]['PATH'] = SM_PATH . 'themes/greenhouse_effect.php';
$theme[20]['NAME'] = 'Greenhouse Effect (Changes)';
$theme[21]['PATH'] = SM_PATH . 'themes/in_the_pink.php';
$theme[21]['NAME'] = 'In The Pink (Changes)';
$theme[22]['PATH'] = SM_PATH . 'themes/kind_of_blue.php';
$theme[22]['NAME'] = 'Kind of Blue (Changes)';
$theme[23]['PATH'] = SM_PATH . 'themes/monostochastic.php';
$theme[23]['NAME'] = 'Monostochastic (Changes)';
$theme[24]['PATH'] = SM_PATH . 'themes/shades_of_grey.php';
$theme[24]['NAME'] = 'Shades of Grey (Changes)';
$theme[25]['PATH'] = SM_PATH . 'themes/spice_of_life.php';
$theme[25]['NAME'] = 'Spice of Life (Changes)';
$theme[26]['PATH'] = SM_PATH . 'themes/spice_of_life_lite.php';
$theme[26]['NAME'] = 'Spice of Life - Lite (Changes)';
$theme[27]['PATH'] = SM_PATH . 'themes/spice_of_life_dark.php';
$theme[27]['NAME'] = 'Spice of Life - Dark (Changes)';
$theme[28]['PATH'] = SM_PATH . 'themes/christmas.php';
$theme[28]['NAME'] = 'Holiday - Christmas';
$theme[29]['PATH'] = SM_PATH . 'themes/darkness.php';
$theme[29]['NAME'] = 'Darkness (Changes)';
$theme[30]['PATH'] = SM_PATH . 'themes/random.php';
$theme[30]['NAME'] = 'Random (Changes every login)';
$theme[31]['PATH'] = SM_PATH . 'themes/midnight.php';
$theme[31]['NAME'] = 'Midnight';
$theme[32]['PATH'] = SM_PATH . 'themes/alien_glow.php';
$theme[32]['NAME'] = 'Alien Glow';
$theme[33]['PATH'] = SM_PATH . 'themes/dark_green.php';
$theme[33]['NAME'] = 'Dark Green';
$theme[34]['PATH'] = SM_PATH . 'themes/penguin.php';
$theme[34]['NAME'] = 'Penguin';

$default_use_javascript_addr_book = false;
$abook_global_file = '';
$abook_global_file_writeable = false;
$abook_global_file_listing = true;
$abook_file_line_length = 2048;

$addrbook_dsn = '';
$addrbook_table = 'address';

$prefs_dsn = '';
$prefs_table = 'userprefs';
$prefs_user_field = 'user';
$prefs_key_field = 'prefkey';
$prefs_val_field = 'prefval';
$addrbook_global_dsn = '';
$addrbook_global_table = 'global_abook';
$addrbook_global_writeable = false;
$addrbook_global_listing = false;

$no_list_for_subscribe = false;
$smtp_auth_mech = 'none';
$imap_auth_mech = 'login';
$smtp_sitewide_user = '';
$smtp_sitewide_pass = '';
$use_imap_tls = false;
$use_smtp_tls = false;
$session_name = 'SQMSESSID';
$only_secure_cookies     = true;
$disable_security_tokens = false;
$check_referrer          = '';

$config_location_base    = '';

@include SM_PATH . 'config/config_local.php';
EOF

# Create Squirrelmail local conf file
cat <<'EOF' > /etc/squirrelmail/config_local.php
<?php

/**
 * Local config overrides.
 *
 * You can override the config.php settings here.
 * Don't do it unless you know what you're doing.
 * Use standard PHP syntax, see config.php for examples.
 *
 * @copyright &copy; 2002-2006 The SquirrelMail Project Team
 * @license http://opensource.org/licenses/gpl-license.php GNU Public License
 * @version $Id$
 * @package squirrelmail
 * @subpackage config
 */

//$default_folder_prefix		= '';
?>
EOF

# Fix permissions on Squirrelmail's config_local.php files
chown root:apache /etc/squirrelmail/config_local.php
chmod 640 /etc/squirrelmail/config_local.php

# Fix permissions on Squirrelmail's config.php files
chown root:apache /etc/squirrelmail/config.php
chmod 640 /etc/squirrelmail/config.php; echo ""

ctrl_service httpd restart || (ctrl_service httpd stop && ctrl_service httpd start)
}

Install_ISPConfig () {
clear; echo -e "\nWe are finally, about to download and extract the latest version of the ISPConfig-3-Stable branch. \n"

getfiles ${ispconfig_url##*/} $ispconfig_url
extract_tars /tmp/${ispconfig_url##*/} /tmp

cd /tmp/ispconfig3_install/install

php -q install.php; echo ""

echo -e "Enabling ISPConfig Software repo. \n"
cat <<EOF | mysql -u root -p$mysql_pass
USE dbispconfig;
UPDATE \`dbispconfig\`.\`software_repo\` SET \`active\` = 'y' WHERE \`software_repo\`.\`software_repo_id\` = 1;
FLUSH PRIVILEGES;
EOF
}

After_ISPConfig_Install () {
if [[ $Install_Mailman = y ]]; then # Fix Mailman: Set Default Server Language to English

    sed -i "s/DEFAULT_SERVER_LANGUAGE \= \(.*\)/DEFAULT_SERVER_LANGUAGE \= \'en\'/g" /usr/lib/mailman/Mailman/mm_cfg.py
    ctrl_service mailman restart; echo ""

fi

if [[ $Install_Mail = y ]]; then # Fix Dovecot: Correct the path to dovecot-sql.conf

    sed -i 's/\/etc\/dovecot-sql.conf/\/etc\/dovecot\/dovecot-sql.conf/g' /etc/dovecot/dovecot.conf
    sed -i 's/#ssl_protocols \= !SSLv2 !SSLv3/ssl_protocols \= !SSLv2 !SSLv3/g' /etc/dovecot/conf.d/10-ssl.conf	
    sed -i "s/^mydestination \= \(.*\)/mydestination \= $MY_HOST, $MY_HOSTNAME, localhost, localhost.localdomain, localhost.$MY_DOMAIN, mail.$MY_DOMAIN/g" /etc/postfix/main.cf
#   Hardening Postfix Mail Server
    sed -i "s/smtpd_client_restrictions \= \(.*\)/smtpd_client_restrictions \= permit_mynetworks, permit_sasl_authenticated, reject_unknown_client_hostname, check_client_access mysql:\/etc\/postfix\/mysql-virtual_client.cf/g" /etc/postfix/main.cf
    sed -i "s/^smtpd_recipient_restrictions \= \(.*\)/smtpd_recipient_restrictions \= permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination, reject_unknown_recipient_domain, reject_rbl_client zen.spamhaus.org, reject_rbl_client cbl.abuseat.org, reject_rbl_client dnsbl.sorbs.net, check_recipient_access mysql:\/etc\/postfix\/mysql-virtual_recipient.cf/g" /etc/postfix/main.cf
    echo "strict_rfc821_envelopes = yes" >> /etc/postfix/main.cf
    echo "smtpd_helo_required = yes" >> /etc/postfix/main.cf
    echo "smtpd_helo_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_non_fqdn_helo_hostname, reject_invalid_helo_hostname" >> /etc/postfix/main.cf
    echo "smtpd_data_restrictions = reject_unauth_pipelining" >> /etc/postfix/main.cf
    echo "smtpd_delay_reject = yes" >> /etc/postfix/main.cf
    ctrl_service postfix restart; echo ""
    ctrl_service dovecot restart; echo ""

fi

if [[ $Install_FTP = y ]]; then # Fix PureFTPd: Re-enable TLS support

    sed -i 's/^# TLS  \(.*\)$/\TLS                      1/g' /etc/pure-ftpd/pure-ftpd.conf
    sed -i 's/^AltLog                     clf:\/var\/log\/pureftpd.log/AltLog                     clf:\/var\/log\/pureftpd\/pureftpd.log/g' /etc/pure-ftpd/pure-ftpd.conf
    sed -i "s/\/var\/log\/pureftpd.log/\/var\/log\/pureftpd\/pureftpd.log/g" /etc/logrotate.d/pure-ftpd
    ctrl_service pure-ftpd restart; echo ""

fi

if [[ $Install_Web = y ]]; then

    sed -i 's/SSLProtocol all -SSLv2/SSLProtocol all -SSLv2 -SSLv3/g' /etc/httpd/conf.d/ssl.conf
    ctrl_service httpd restart

fi

if [[ -x /sbin/bastille-netfilter ]]; then

    chkconfig --add bastille-firewall
    init_service bastille-firewall on
    ctrl_service bastille-firewall start; echo ""

fi

if [[ $Install_OpenVZ = n ]]; then # If you do not install OpenVZ, disable VServer inside of ISPConfig

cat <<EOF | mysql -u root -p$mysql_pass
USE dbispconfig;
UPDATE \`dbispconfig\`.\`server\` SET \`vserver_server\` = '0' WHERE \`server\`.\`server_id\` = 1;
FLUSH PRIVILEGES;
EOF

fi

cd ../../ && rm -rf ispconfig3_install/ && rm -rf ${ispconfig_url##*/} && rm -rf sys-prep.done; clear # Clean up after running the script

cat <<EOF
****************************************************************************************************************************************
** Congratulations installation has finished WOOT! This means we should have a fully functioning CentOS 6.x installed with ISPConfig. **
****************************************************************************************************************************************

Please do not forget to login at https://$MY_HOSTNAME:8080 or https://$MY_IP:8080 with user/pass = 'admin', and enable the firewall under 'System' => 'Firewall' => 'Add Firewall record'. (Edit the ports as needed before applying!)
After setting the firewall to active please add a client or reseller and add your domain under the 'Sites' => 'Website' => 'Add new website' section.
Then head over to 'Email' => 'Domain' => 'Add new Domain' and setup your Email domain there and create your real user under 'Email' => 'Email Mailbox' => 'Add new Mailbox' that you want the below two aliases to go to.
Create two email aliases for root@$MY_DOMAIN and admin@$MY_DOMAIN  under the 'Email' => 'Email Alias' => 'Add new Email alias'. (Else you will NOT get root's email!!)
Once those are set you can use the DNS wizard to generate your records, but you will need to manually add two new 'A' records for your ns1/ns2 servers. Then your DNS should be working for your domain.
EOF

read -esp "Press ENTER to continue " pause; echo ""
}

###########################
#### Calling Functions ####
###########################

if [[ ! -f /tmp/sys-prep.done ]]; then

    Before_Reboot

fi
    Install_Repos
    Install_NTPd
if [[ $Install_Quota = y ]]; then

    Set_Quota

fi
if [[ $Install_Web = y ]]; then

    Install_Web_Server

fi
if [[ $Install_Mail = y ]]; then

    Install_Mail_Server

fi
if [[ $Install_MySQL = y ]]; then

    Install_MySQL_Server

fi
if [[ $Install_Web = y && $Install_MySQL = y ]]; then

    Install_phpMyAdmin

fi
    Install_AV
if [[ $Install_Web = y ]]; then

    Compile_apache_modz
    Install_Stats

fi
if [[ $Install_FTP = y ]]; then

    Install_FTP_Server

fi
if [[ $Install_DNS = y ]]; then

    Install_DNS_Server

fi
if [[ $Install_Jailkit = y ]]; then

    Compile_Jailkit

fi
if [[ $Install_Mail = y && $Install_Mailman = y ]]; then

    Install_Mailman_Service

fi
if [[ $Install_Web = y && $Install_Mail = y && $Install_MySQL = y ]]; then

    Install_Webmail

fi
    Install_ISPConfig
    After_ISPConfig_Install
if [[ $Install_OpenVZ_CP = y && ! -d /opt/ovz-web-panel ]]; then

	Install_Virtualization_CP

fi
}

if [[ $Install_OpenVZ = n ]]; then

    if [[ ! -d /usr/local/ispconfig ]]; then

        Sys_Prep_ISPConfig

    fi

else

    if [[ ! -d /vz && ! -d /usr/local/ispconfig ]]; then

        Install_Virtualization

    elif [[ -d /vz && ! -d /usr/local/ispconfig ]]; then

        Sys_Prep_ISPConfig

    fi

fi
Main
