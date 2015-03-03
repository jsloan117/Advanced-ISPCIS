#!/bin/bash
#======================================================================================================================================================================================================
# Name:			Advanced-ISPCIS.sh
# By:			Jonathan M. Sloan <jsloan@macksarchive.com>
# Date:			03-01-2015
# Purpose:		Install OpenVZ, ISPConfig-3.X, OpenVZ-CP and Templates (32bit & 64bit tested)
# Version:		2.4.9.8
# Info:			Customized install available for ISPConfig. (The partial install has not been tested yet!)
# Software:		APF, BFD, OpenVZ, OpenVZ Web Panel, Roundcube, Munin, Monit, OSSEC, OSSEC Web UI, Authy, DUO Security
# Templates:	Possible to choose from 5 different OS Templates and automatically import then into the ISPConfig DB.
#======================================================================================================================================================================================================
# Scripts that are automatically created: 1) authy_useradd.sh (used to add users to authy 2-factor authentication) 2) enable_dkim.sh (used to create dkim keys and spf records on a per domain basis.
# These records are inserted into their DNS zone via ISPConfig's database) 3) email_backup.sh (used to backup all email accounts on local system. Obtains list of emails via ISPConfig's database)
# Plan on installing Horde, nagios, check_mk, pnp4nagios, in next release 2.5 (Think I'm going to have to split up some of this code because the script is growing very large!)

set -ae

status="$?"
prog=$(echo $(basename $0))
prog_conf=${prog/.sh/.conf}
prog_pass=${prog/.sh/.passwords}

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
# NOTES: The archived packages need to be .tar.xx format NOT ZIP! Safest/Best use .tar.gz format
# Be sure to remove the #!md5hash part from the URL of phpmyadmin_url variable (This only applies when copying a new version from site), MUST USE .tar.gz format! OR SCRIPT WILL FAIL!!
# phpMyAdmin version 4.2.3 requires MySQL 5.5

if [[ $(uname -p) = x86_64 ]]; then

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
awstats_url='http://prdownloads.sourceforge.net/awstats/awstats-7.3-1.noarch.rpm'
phpmyadmin_url='http://sourceforge.net/projects/phpmyadmin/files/phpMyAdmin/4.2.2/phpMyAdmin-4.2.2-all-languages.tar.gz/download'
openvz_repo='http://ftp.openvz.org/openvz.repo'
openvz_key='http://ftp.openvz.org/RPM-GPG-Key-OpenVZ'
openvz_cp='http://ovz-web-panel.googlecode.com/svn/installer/ai.sh'
apf_url='http://www.rfxn.com/downloads/apf-current.tar.gz'
bfd_url='http://www.rfxn.com/downloads/bfd-current.tar.gz'
ossec_url='https://github.com/ossec/ossec-hids/archive/2.8.1.tar.gz'
ossec_wui_url='https://github.com/ossec/ossec-wui/archive/master.zip'
authy_ssl_url='https://raw.github.com/authy/authy-ssh/master/authy-ssh'
duo_security_url='https://dl.duosecurity.com/duo_unix-latest.tar.gz'
automysqlbackup_url='http://sourceforge.net/projects/automysqlbackup/files/AutoMySQLBackup/AutoMySQLBackup%20VER%203.0/automysqlbackup-v3.0_rc6.tar.gz/download'
roundcubemail_url='http://sourceforge.net/projects/roundcubemail/files/roundcubemail/1.1.0/roundcubemail-1.1.0-complete.tar.gz/download'
munin_url='http://sourceforge.net/projects/munin/files/stable/2.0.25/munin-2.0.25.tar.gz/download'
monit_url='http://mmonit.com/monit/dist/monit-5.11.tar.gz'

##########################
### Password Variables ###
##########################
# These are optional set here. Will automatically prompt for them later, ONLY SET mysql_pass if this is what your going to use when 'mysql-secure-installation' runs

pma_pass=""
mysql_pass=""
mailman_email=""
mailman_pass=""

########################################
### Source file containing variables ###
########################################

if [[ -f $HOME/$prog_conf ]]; then

    . $HOME/$prog_conf

fi

if [[ -z $accept_eula ]]; then # Accept the EULA or quit the script

  whiptail --backtitle "ISPConfig Advanced Installer" --title "EULA" --yesno --yes-button "I accept" --no-button "Quit" "I have created this script to make installing ISPConfig 3 a breeze, \
along with many extra items that you can choose to install later on. But I do not guarantee that it will absolutely work 100% perfectly for you every time. By Accepting the EULA you have been warned \
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

##########################################################
#### Get FTP Certificate Information to set variables ####
##########################################################

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
    read -ep "Install MySQL Server [y/n] [${tmp}]: " Install_MySQL
    Install_MySQL=${Install_MySQL:-${tmp}}
    echo "Install_MySQL=$Install_MySQL" >> $HOME/$prog_conf
fi; echo ""

if [[ -z $Install_Mail ]]; then
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
pma_url=${phpmyadmin_url%/*}
pma_file=${pma_url##*/}
pma_extdir=$(echo ${pma_file##*/} | sed 's/.tar.gz//g')
automysql_url=${automysqlbackup_url%/*}
automysql_file=${automysql_url##*/}
roundcube_url=${roundcubemail_url%/*}
roundcube_file=${roundcube_url##*/}
muninurl=${munin_url%/*}
munin_file=${muninurl##*/}

########################
### Helper Functions ###
########################

create_ftp_cert () { # Generate certificate for pure-ftpd
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

##########################
### Software Functions ###
##########################

Install_Basic_Tools () {
yum -y -q install system-config-{firewall,network}-tui nano ntfs-3g mc vim man wget yum-utils xinetd \
ntsysv curl-devel at jwhois perl-XML-LibXML perl-XML-SAX pam-devel openssl-devel aspell aspell-devel

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

    echo "SELINUX=disabled" > /etc/selinux/selinux

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
_os[1]='http://download.openvz.org/template/precreated/debian-7.0-x86_64.tar.gz'
_os[2]='http://download.openvz.org/template/precreated/scientific-6-x86_64.tar.gz'
_os[3]='http://download.openvz.org/template/precreated/suse-13.1-x86_64.tar.gz'
_os[4]='http://download.openvz.org/template/precreated/ubuntu-14.04-x86_64.tar.gz'


clear && echo -e "Please choose a OS to download for OpenVZ, Import SQL code, or Exit. [1-7] \n"
echo -e "Please download all OSes you want first, then Import the SQL code for those OSes into MySQL. (Importing should only be ran once!) \n"

select os in CentOS-6-x64 Debian-7-x64 Scientific-6-x64 Suse-13.1-x64 Ubunutu-14.04-x64 Import_SQL quit; do

    case $os in

        CentOS-6-x64)

            wget -P /vz/template/cache ${_os[0]} ;;

        Debian-7-x64)

            wget -P /vz/template/cache ${_os[1]} ;;

        Scientific-6-x64)

            wget -P /vz/template/cache ${_os[2]} ;;

        Suse-13.1-x64)

            wget -P /vz/template/cache ${_os[3]} ;;

        Ubunutu-14.04-x64)

            wget -P /vz/template/cache ${_os[4]} ;;

        Import_SQL)

            Import_Template_Code ;;

        quit)

            echo -e "\nExiting now. \n" && exit 0 ;;

    esac

done
}

Import_Template_Code () {
if [[ -z $mysql_pass ]]; then

    read -esp "MySQL root password: " mysql_pass

fi
if [[ -f '/vz/template/cache/debian-7.0-x86_64.tar.gz' ]]; then
cat <<EOF | mysql -u root -p"$mysql_pass"
USE dbispconfig;
UPDATE \`dbispconfig\`.\`openvz_ostemplate\` SET \`template_name\`
= 'Debian 7 x 64', \`template_file\` = 'debian-7.0-x86_64',
\`description\` = 'Debian 7 x 64' WHERE
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
if [[ -f '/vz/template/cache/suse-13.1-x86_64.tar.gz' ]]; then
cat <<EOF | mysql -u root -p"$mysql_pass"
USE dbispconfig;
INSERT INTO \`dbispconfig\`.\`openvz_ostemplate\` (\`ostemplate_id\`,
\`sys_userid\`, \`sys_groupid\`, \`sys_perm_user\`, \`sys_perm_group\`,
\`sys_perm_other\`, \`template_name\`, \`template_file\`, \`server_id\`,
\`allservers\`, \`active\`, \`description\`) VALUES (NULL, '1', '1',
'riud', 'riud', '', 'Suse 13.1 x64', 'suse-13.1-x86_64', '1', 'y',
'y', 'Suse 13.1 x64');
EOF
fi
if [[ -f '/vz/template/cache/ubuntu-14.04-x86_64.tar.gz' ]]; then
cat <<EOF | mysql -u root -p"$mysql_pass"
USE dbispconfig;
INSERT INTO \`dbispconfig\`.\`openvz_ostemplate\` (\`ostemplate_id\`,
\`sys_userid\`, \`sys_groupid\`, \`sys_perm_user\`, \`sys_perm_group\`,
\`sys_perm_other\`, \`template_name\`, \`template_file\`, \`server_id\`,
\`allservers\`, \`active\`, \`description\`) VALUES (NULL, '1', '1',
'riud', 'riud', '', 'Ubuntu 14.04 x64', 'ubuntu-14.04-x86_64', '1', 'y',
'y', 'Ubuntu 14.04 x64');
EOF
fi
if [[ -f '/vz/template/cache/scientific-6-x86_64.tar.gz' ]]; then
cat <<EOF | mysql -u root -p"$mysql_pass"
USE dbispconfig;
INSERT INTO \`dbispconfig\`.\`openvz_ostemplate\` (\`ostemplate_id\`,
\`sys_userid\`, \`sys_groupid\`, \`sys_perm_user\`, \`sys_perm_group\`,
\`sys_perm_other\`, \`template_name\`, \`template_file\`, \`server_id\`,
\`allservers\`, \`active\`, \`description\`) VALUES (NULL, '1', '1',
'riud', 'riud', '', 'Scientific 6 x64', 'scientific-6-x86_64', '1', 'y',
'y', 'Scientific 6 x64');
EOF
fi; unset mysql_pass;
}

_Menu () {
clear; cat <<EOF
What would you like to do? [1-6]

Download_OS_Templates: Choose from 5 different OSes to download for ISPConfig. Imports downloaded OSes into ISPConfig to use.

APF: Installs APF - Advanced Policy Firewall: Used in place of ISPConfig's firewall.

BFD: Installs BFD - Brute Force Detection: Monitors services for brute force attempts and uses APF to deny attackers by default.

Extras: Extra installs Menu

Security: Security related Menu

EOF

select choice in Download_OS_Templates APF BFD Extras Security quit; do

	case $choice in

		Download_OS_Templates)

            Download_OpenVZ_Templates ;;

		APF)

            Install_APF ;;

		BFD)

            Install_BFD ;;

		Extras)

            Extras_Menu ;;

		Security)

            Security_Menu ;;

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
getfiles mod-pagespeed-stable_current_x86_64.rpm $mod_pagespeed
yum -y -q install /tmp/mod-pagespeed-stable_current_x86_64.rpm

mv /etc/httpd/conf.d/limitipconn.conf /etc/httpd/conf.d/limitipconn.conf.bak
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
rm -f /tmp/mod-pagespeed-stable_current_x86_64.rpm
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
#sed -i "s/^HostAliases=\(.*\)/HostAliases=\"localhost 127.0.0.1 REGEX\[^www.$domain\$\]\"/g" /etc/awstats/awstats.model.conf

ctrl_service httpd stop && ctrl_service httpd start

echo -e "\nYou will want to double check all paths to awstats inside of ISPConfig and correct them if needed. \n"

perl /usr/share/awstats/tools/awstats_updateall.pl now -configdir=/etc/awstats
}

Fix_vhost_Awstats () { # ONLY TO BE RAN AFTER ENABLING IN ISPCONFIG # Used to fix ISPConfig Awstats on a per vhost basis
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

Upgrade_phpMyAdmin () { # Used to upgrade to the latest version of phpMyAdmin. This does not upgrade the phpMyAdmin DATABASE
read -ep "Please enter a base directory [${HOME}]: " base_dir
local base_dir=${base_dir:-${HOME}}
local backupdir=$base_dir/backup

[[ ! -d $backupdir ]] && mkdir -pv $backupdir
chown -R root:root $backupdir
chmod -R 700 $backupdir

mv /usr/share/phpMyAdmin/config.inc.php $backupdir/config.inc.php.sym
mv /usr/share/phpMyAdmin $backupdir/pma_old

getfiles $pma_file $phpmyadmin_url
extract_tars /tmp/$pma_file /tmp

mv /tmp/$pma_extdir /usr/share/phpMyAdmin
mv $backupdir/config.inc.php.sym /usr/share/phpMyAdmin/config.inc.php

#rm -rf "$backupdir/pma_old"; # Enable once verified it works
rm -rf /usr/share/phpMyAdmin/setup
rm -f /tmp/$pma_file; echo -e "\nThe upgrade of phpMyAdmin has been completed! Restarting apache now to finish. \nPlease remove $backupdir/pma_old directory once upgrade verified successfully! \n"
ctrl_service httpd stop && ctrl_service httpd start
}

Monitoring_essentials () {
cat <<EOF
We are going to install performance, system monitoring, network related tools now.
This includes 'Performance Tools', smartmontools, hddtemp, lm_sensors, atop, iptraf, openswan, arpwatch, iptstate, mrtg, rrd-tool, stunnel, vtun.
EOF

yum -y -q groupinstall "Performance Tools"
yum -y -q install smartmontools hddtemp lm_sensors atop iptraf
yum -y -q install openswan openswan-doc arpwatch iptstate mrtg stunnel vtun rrdtool rrdutils rrdtool-perl rrdtool-php rrdtool-doc rrdtool-devel

init_service arpwatch on
ctrl_service arpwatch start

init_service atop on
ctrl_service atop start

sensors-detect

init_service lm_sensors on
ctrl_service lm_sensors start

init_service smartd on
ctrl_service smartd start

init_service hddtemp on
ctrl_service hddtemp start
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

Munin -- Installs munin graphing utilitie

Monit -- Installs monit monitoring service

quit -- Exits 

EOF

select choice in Apache_Extras System_Awstats vhost_Awstats phpMyAdmin_upgrader AutoMySQLBackup Extra_Tools Roundcube Munin Monit quit; do

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

        Munin)

            Install_Munin ;;

        Monit)

            Install_Monit ;;

        quit)

            unset mysql_pass && echo -e "\nExiting now per your request \n" && exit 0 ;;

    esac

done
}

Security_Menu () {
clear; cat <<EOF
What would you like to do? [1-6]

OSSEC - Install OSSEC HIDS

OSSEC-WUI - Install OSSEC-WUI for OSSEC

Authy - Install Authy two factor authentication

Duo_Security - Install Duo Security two factor authentication

Enable-DKIM - Enables DKIM support to ISPConfig via amavisd

EOF

select choice in OSSEC OSSEC-WUI Authy Duo_Security Enable-DKIM quit; do

    case $choice in

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

        quit)

            unset mysql_pass && echo -e "\nExiting now per your request \n" && exit 0 ;;

    esac

done
}

###############################
### New Software Functions ####
###############################

Install_OSSEC () { # Tested Seems like only the server installation type works
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
unzip -q /tmp/${ossec_wui_url##*/}

mv $HOME/ossec-wui-master /usr/share/ossec-wui
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

cat <<EOF > ~/authy_useradd.sh
#===============================================================================================
# Name:         authy_useradd.sh
# By:           Jonathan M. Sloan <jsloan@macksarchive.com>
# Date:         08-30-2014
# Purpose:      Enable's a user of choice to be protected via authy two factor authentication
# Version:      1.3
# Info:         Will automatically prompt for user's email address, country-code, phone-number
#===============================================================================================
# ChangeLog: Cleaned up the check_exist function, and will exit w/ status code 1 if user exists.
# Added new "isValidPhoneNum" function to ensure user enters the correct format for number.
# New code to ensure new function works corretly.

set -e

bin_base="/usr/local/bin"
prog="authy-ssh"
protect_user="\$1"

if [[ ! -x \$bin_base/\$prog ]]; then

   echo -e "\\n\$bin_base/\$prog was not found on your system! \\n" && exit 1

fi

print_usage () {
echo -e "\\nUsage: \$0 { username } Ex: \$0 root \n"
}

isValidPhoneNum () {
case \$1 in

    "" | *[!0-9-]* | *[!0-9])

        return 1 ;;

esac

local IFS='-'
set -- \$1

[[ \$# -eq 3 ]] && [[ \${#1} -eq 3 ]] && [[ \${#2} -eq 3 ]] && [[ \${#3} -eq 4 ]]
}

check_exist () {
local chkuser=\$1
local userexistmessage="User: '%s' aleady protected by authy \n"

if grep -w ^user /usr/local/bin/authy-ssh.conf | awk -F"=" '{ print \$2 }' | awk -F":" '{ print \$1 }' | grep -wq \$chkuser; then

   printf "\$userexistmessage" "\$chkuser" && exit 1

fi
}

if [[ "\$#" -ne '1' ]]; then

   print_usage && exit 1

fi

check_exist "\$protect_user"

echo ""
read -ep "Please enter your Email Address: " a_email
read -ep "Please enter your Country-code: " a_ccode
read -ep "Please enter your (include the dashes) Cell Phone Number: " a_phone

if isValidPhoneNum \$a_phone; then

    a_phone=\${a_phone}

else

    echo -e "\nThe number \$a_phone is not correct. Ex: 123-456-7890 \n" && exit 1

fi
echo ""

\$bin_base/\$prog enable \$protect_user \$a_email \$a_ccode \$a_phone
exit 0
EOF

chown root:root $HOME/authy_useradd.sh
chmod 700 $HOME/authy_useradd.sh

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
}

Enable_DKIM () {
[[ ! -d /var/db/dkim ]] && mkdir -p /var/db/dkim/
ln -s /etc/amavisd/amavisd.conf /etc/amavisd.conf
PUB_IP=$(wget -q -O - checkip.dyndns.org | awk -F":" '{ print $2 }' | sed -e "s/^ //g" | awk -F"<" '{ print $1 }')

echo -e "\nGenerating enable_dkim.sh script this enables dkim support on a per domain basis"

cat <<EOFA > $HOME/enable_dkim.sh
#!/bin/bash
#==================================================================================================================================
# Name:                 enable_dkim.sh
# By:                   Jonathan M. Sloan <jsloan@macksarchive.com>
# Date:                 02-28-2015
# Purpose:              Used to enable DKIM and SPF for a domain within ISPConfig
# Version:              1.4
# Info:                 Creates DKIM keys and inserts DKIM/SPF records into the domains DNS zone file via mysql.
#                       Must use the local DNS Server as a resolver within /etc/resolv.conf (should be first choice for nameserver)
#==================================================================================================================================
if [[ \$# -eq 0 ]]; then

    echo "Must supply domain name as input" && exit 1

fi

get_domaininfo_sqlfile=\$(mktemp -p /tmp getdomaininfo.XXXXXX.sql)
domaininfo_file=\$(mktemp -p /tmp domaininfo.XXXXX)
id_tmp=\$(mktemp -p /tmp id.XXXXX)
zoneinfo_tmp=\$(mktemp -p /tmp zone_data.XXXXX)
dkim_key_tmp=\$(mktemp -p /tmp dkim_key.XXXXX)
mysql_pass='$mysql_pass'
dkim_domain=\$@
dkim_path=/var/db/dkim

for domain in \$dkim_domain; do

  if [[ ! -f /var/named/pri.\$domain ]]; then

    echo -e "\nNo DNS zone detected for \$domain, exiting.\n" && exit

  fi

cat <<EOF > \$get_domaininfo_sqlfile
USE dbispconfig;
SELECT * FROM \\\`dns_rr\\\` WHERE \\\`name\\\` = '\$domain.' AND \\\`type\\\` = 'A';
EOF

mysql -u root -p"\$mysql_pass" < \$get_domaininfo_sqlfile | tail -n1 > \$domaininfo_file

mysql -u root -p"\$mysql_pass" <<EOF | grep -vw "id" > \$id_tmp
USE dbispconfig;
SELECT \\\`id\\\` FROM \\\`dns_rr\\\` ORDER BY \\\`id\\\` DESC;
EOF

last_id=\$(cat \$id_tmp | head -n1)
_id=\$(( \$last_id + 1 ))
sys_userid=\$( cat \$domaininfo_file | awk -F"\\\\t" '{ print \$2 }')
sys_groupid=\$( cat \$domaininfo_file | awk -F"\\\\t" '{ print \$3 }')
sys_perm_user=\$( cat \$domaininfo_file | awk -F"\\\\t" '{ print \$4 }')
sys_perm_group=\$( cat \$domaininfo_file | awk -F"\\\\t" '{ print \$5 }')
sys_perm_other=\$( cat \$domaininfo_file | awk -F"\\\\t" '{ print \$6 }')
server_id=\$( cat \$domaininfo_file | awk -F"\\\\t" '{ print \$7 }')
zoneid=\$( cat \$domaininfo_file | awk -F"\\\\t" '{ print \$8 }')
_type='TXT'
ttl='3600'
active='Y'
_IP=\$( cat \$domaininfo_file | awk -F"\\\\t" '{ print \$11 }')
aux=\$( cat \$domaininfo_file | awk -F"\\\\t" '{ print \$12 }')
stamp='NOW()'
serial=\$( cat \$domaininfo_file | awk -F"\\\\t" '{ print \$16 }')
serial=\$(( \$serial + 1 ))
spf_id=\$(( \$_id + 1 ))
spf_record_data="\\"v=spf1 mx a ptr ip4:\$_IP/32 ~all\\""

amavisd genrsa \$dkim_path/\$domain.key.pem
chown amavis:amavis \$dkim_path/\$domain.key.pem

echo -e "\nDKIM Key generated for \$domain"

cat <<EOF >> /etc/amavisd/amavisd.conf

dkim_key('\$domain', 'mail', '\$dkim_path/\$domain.key.pem');
@dkim_signature_options_bysender_maps = (
  { '.' => { ttl => 21*24*3600, c => 'relaxed/simple' } } );
EOF

echo -e "\nDKIM Key information inserted into amavisd.conf\n"

amavisd showkeys \$domain > \$dkim_key_tmp

k1=\$(cat \$dkim_key_tmp | tail -n6 | head -n1 | awk '{ print \$0 }' | sed -e 's/ "//g' -e 's/"\$//g')
k2=\$(cat \$dkim_key_tmp | tail -n5 | head -n1 | sed -e 's/ "//g' -e 's/"\$//g' -e 's/ //g')
k3=\$(cat \$dkim_key_tmp | tail -n4 | head -n1 | sed -e 's/ "//g' -e 's/"\$//g' -e 's/ //g')
k4=\$(cat \$dkim_key_tmp | tail -n3 | head -n1 | sed -e 's/ "//g' -e 's/"\$//g' -e 's/ //g')
k5=\$(cat \$dkim_key_tmp | tail -n2 | head -n1 | sed -e 's/ "//g' -e 's/")\$//g' -e 's/ //g')
record_name=\$(cat \$dkim_key_tmp | tail -n7 | head -n1 | awk '{ print \$1 }')
key=\$(echo \$k1\$k2\$k3\$k4\$k5)

cat <<EOF > \$zoneinfo_tmp
USE dbispconfig;
INSERT INTO \\\`dns_rr\\\` (\\\`id\\\`, \\\`sys_userid\\\`, \\\`sys_groupid\\\`, \\\`sys_perm_user\\\`, \\\`sys_perm_group\\\`, \\\`sys_perm_other\\\`, \\\`server_id\\\`, \\\`zone\\\`, \\\`name\\\`, \\\`type\\\`, \\\`data\\\`, \\\`aux\\\`, \\\`ttl\\\`, \\\`active\\\`, \\\`stamp\\\`, \\\`serial\\\`)
VALUES ('\$_id','\$sys_userid','\$sys_groupid','\$sys_perm_user','\$sys_perm_group','\$sys_perm_other','\$server_id','\$zoneid','\$record_name','\$_type','\$key','\$aux','\$ttl','\$active',\$stamp,'\$serial');
INSERT INTO \\\`dns_rr\\\` (\\\`id\\\`, \\\`sys_userid\\\`, \\\`sys_groupid\\\`, \\\`sys_perm_user\\\`, \\\`sys_perm_group\\\`, \\\`sys_perm_other\\\`, \\\`server_id\\\`, \\\`zone\\\`, \\\`name\\\`, \\\`type\\\`, \\\`data\\\`, \\\`aux\\\`, \\\`ttl\\\`, \\\`active\\\`, \\\`stamp\\\`, \\\`serial\\\`)
VALUES ('\$spf_id','\$sys_userid','\$sys_groupid','\$sys_perm_user','\$sys_perm_group','\$sys_perm_other','\$server_id','\$zoneid','\$domain.','\$_type','\$spf_record_data','\$aux','\$ttl','\$active',\$stamp,'\$serial');
FLUSH PRIVILEGES;
EOF

mysql -u root -p"\$mysql_pass" < \$zoneinfo_tmp
rm -f \$id_tmp \$domaininfo_file \$zoneinfo_tmp \$get_domaininfo_sqlfile \$dkim_key_tmp

done

unset mysql_pass

service amavisd restart
service named restart

amavisd testkeys
exit 0
EOFA

chown root:root $HOME/enable_dkim.sh
chmod 700 $HOME/enable_dkim.sh

cat <<EOF >> /etc/amavisd/amavisd.conf


# Amavisd DKIM Keys

@mynetworks = qw(127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 $PUB_IP/32);  # list your internal networks

\$enable_dkim_verification = 1;
\$enable_dkim_signing = 1;

EOF
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
chown root:root -R /usr/share/roundcube
chmod 777 -R /usr/share/roundcube/temp/ 
chmod 777 -R /usr/share/roundcube/logs/

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

# this section makes Roundcube use https connections only, for this you
# need to have mod_ssl installed. If you want to use unsecure http
# connections, just remove this section:
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
rm -rf /usr/share/roundcube/installer
}

Install_Munin () {
if [[ -z $munin_password ]]; then

  tmp=$(tr -dc '[:alnum:]' < /dev/urandom | head -c30 | sha512sum | head -c30)
  read -p "Munin user password [${tmp}]:" munin_password
  munin_password=${munin_password:-${tmp}}
  echo "Munin User: muninadmin" >> $prog_pass
  echo "Munin password: ${munin_password}" >> $prog_pass

fi

yum -y -q install munin-node munin munin-cgi munin-common munin-netip-plugins
htpasswd -b -mc /etc/munin/munin-htpasswd muninadmin $munin_password

ctrl_service httpd restart
init_service munin-node on
ctrl_service munin-node start; unset tmp munin_password
}

Install_Monit () { # Need to open up port 2812 within the firewall
getfiles ${monit_url##*/} $monit_url
extract_tars /tmp/${monit_url##*/} $HOME/
cd $HOME/monit-*
./configure --enable-optimized; make; make install
mv /usr/local/bin/monit /usr/bin
[[ ! -d /etc/monit.d ]] && mkdir -p /etc/monit.d

cat <<EOF > /etc/monitrc
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

chmod 600 /etc/monitrc
chmod 755 /etc/init.d/monit
rm -rf /tmp/${monit_url##*/} $HOME/monit-*

init_service monit on
ctrl_service monit start
}

###############################
### Core Software Functions ###
###############################

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
clear
sed -i "s/if \[\[ -x \\$HOME\/$prog \]\]; then bash \\$HOME\/$prog; fi//g" "$HOME/.bashrc" # Stop script from automatically running on reboot again
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

rm -f /tmp/*.rpm; printf "\n"

yum -y -q install yum-priorities openssl yum-plugin-remove-with-leaves #yum-plugin-ps yum-plugin-verify yum-plugin-downloadonly

sed -i '/enabled=1/ a\priority=10' /etc/yum.repos.d/epel.repo # Append priority of 10 to epel.repo file

# Clean all + Make new cache and Update system + Install Dev Tools
clear; echo -e "Repos installed running 'yum clean all && yum makecache', to hopefully speed up downloading packages a bit. \n"

yum -y -q clean all && yum -y -q makecache

echo -e "Done making cash, wrong kind I mean cache sorry LOL. Updating and installing 'Dev Tools' + cmake ccache now. \n"

yum -y -q update && yum -y -q groupinstall 'Development tools' && yum -y -q install cmake ccache; echo ""

echo -e "Done updating and installing 'Dev Tools'."
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
yum -y -q install httpd httpd-devel httpd-tools mod_ssl GeoIP php-pecl-geoip perl-Geo-IP GeoIP-devel php php-mysql php-mbstring php-php-gettext php-devel php-gd php-imap \
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
yum -y -q install mysql-server mysql-utilities mysqltuner mysqlreport mytop mysql-devel mysql-libs

mv /etc/my.cnf /etc/my.cnf.bak
cp -p /usr/share/doc/mysql-server-*/my-large.cnf /etc/my.cnf

[[ ! -d /var/log/mysql ]] && mkdir -p /var/log/mysql && chown mysql:mysql /var/log/mysql && chmod 750 /var/log/mysql

sed -i '/^port            \= 3306/ a\bind-address \= 127.0.0.1' /etc/my.cnf
sed -i '/^bind-address \= 127.0.0.1/ a\#general_log_file=/var/log/mysql/mysqld_log' /etc/my.cnf
sed -i 's/^skip-locking/skip-external-locking/g' /etc/my.cnf
sed -i '/^skip-external-locking/ a\local-infile=0' /etc/my.cnf
sed -i '/^local-infile=0/ a\skip-show-database' /etc/my.cnf

echo -e "\n\n[mysqld_safe]" >> /etc/my.cnf
echo "log-error=/var/log/mysql/mysqld.log" >> /etc/my.cnf
echo "pid-file=/var/run/mysqld/mysqld.pid" >> /etc/my.cnf

init_service mysqld on
ctrl_service mysqld start

clear; echo -e "Going to secure our MySQL installation, follow the prompts on screen. \nIf you choose to use the generated password for MySQL, then you will want to copy it for the step when securing MySQL Installation. \n"

if [[ -z ${mysql_pass} ]]; then

    tmp=$(tr -dc '[:alnum:]' < /dev/urandom | head -c30 | sha512sum | head -c30)
    read -esp "MySQL root password: [${tmp}]: " mysql_pass
    mysql_pass=${mysql_pass:-${tmp}}
    echo "MySQL root password: ${mysql_pass}" >> $HOME/$prog_pass	

fi

mysql_secure_installation; echo ""
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
/*
* Generated configuration file
* Generated by: phpMyAdmin 4.1.7 setup script
* Date: Sun, 16 Feb 2014 00:11:09 -0500
*/

/* Servers configuration */
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
\$cfg['Servers'][\$i]['table_uiprefs'] = 'pma__table_uiprefs';
\$cfg['Servers'][\$i]['tracking'] = 'pma__tracking';
\$cfg['Servers'][\$i]['table_coords'] = 'pma__table_coords';
\$cfg['Servers'][\$i]['pdf_pages'] = 'pma__pdf_pages';
\$cfg['Servers'][\$i]['designer_coords'] = 'pma__designer_coords';
\$cfg['Servers'][\$i]['savedsearches'] = 'pma__savedsearches';

\$cfg['Servers'][\$i]['verbose_check'] = TRUE;        // set to FALSE if you know that your pma_* tables
                                                    // are up to date. This prevents compatibility
                                                    // checks and thereby increases performance.
\$cfg['Servers'][\$i]['AllowRoot']     = TRUE;        // whether to allow root login
\$cfg['Servers'][\$i]['AllowDeny']['order']           // Host authentication order, leave blank to not use
                                     = '';
\$cfg['Servers'][\$i]['AllowDeny']['rules']           // Host authentication rules, leave blank for defaults
                                     = array();
\$cfg['Servers'][\$i]['AllowNoPassword']              // Allow logins without a password. Do not change the FALSE
                                     = FALSE;       // default unless you're running a passwordless MySQL server

\$cfg['Servers'][\$i]['bs_garbage_threshold']         // Blobstreaming: Recommented default value from upstream
                                     = 50;          //   DEFAULT: '50'
\$cfg['Servers'][\$i]['bs_repository_threshold']      // Blobstreaming: Recommented default value from upstream
                                     = '32M';       //   DEFAULT: '32M'
\$cfg['Servers'][\$i]['bs_temp_blob_timeout']         // Blobstreaming: Recommented default value from upstream
                                     = 600;         //   DEFAULT: '600'
\$cfg['Servers'][\$i]['bs_temp_log_threshold']        // Blobstreaming: Recommented default value from upstream
                                     = '32M';       //   DEFAULT: '32M'

/* End of servers configuration */

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
#mkdir -pv /var/lib/phpMyAdmin/{save,upload}
#chown -v root:apache /var/lib/phpMyAdmin/{save,upload}
#chmod -v 770 /var/lib/phpMyAdmin/{save,upload}

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

FLUSH PRIVILEGES;
EOF

echo -e "Importing SQL code for phpMyAdmins completed."
rm -rf /usr/share/phpMyAdmin/setup && unset pma_pass; echo ""
}

Install_AV () {
yum -y -q install amavisd-new spamassassin clamav clamd unzip bzip2 unrar perl-DBD-mysql # Install Clamav, Spamassassin, Amavisd-new, Clamd, etc

sa-update # Update spamassassin, clamav + turn on + start amavisd, clamd.amavid, spamassassin, saslauthd services
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

init_service pure-ftpd on
ctrl_service pure-ftpd start; echo ""

sed -i 's/^# TLS  \(.*\)$/\TLS                      1/g' /etc/pure-ftpd/pure-ftpd.conf;

[[ ! -d /etc/ssl/private ]] && mkdir -p /etc/ssl/private || echo -e "Failed to make directory /etc/ssl/private \n"; echo ""

create_ftp_cert /etc/ssl/private/pure-ftpd.pem

chmod 600 /etc/ssl/private/pure-ftpd.pem; echo ""

ctrl_service pure-ftpd restart; echo ""
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
yum -y -q install webalizer awstats perl-DateTime-Format-HTTP perl-DateTime-Format-Builder
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
clear; echo -e "Now it is time to correct a few things after installing ISPConfig. \n"

if [[ $Install_Mailman = y ]]; then # Fix Mailman: Set Default Server Language to English

    sed -i "s/DEFAULT_SERVER_LANGUAGE \= \(.*\)/DEFAULT_SERVER_LANGUAGE \= \'en\'/g" /usr/lib/mailman/Mailman/mm_cfg.py
    ctrl_service "mailman" "restart"; echo ""

fi

if [[ $Install_Mail = y ]]; then # Fix Dovecot: Correct the path to dovecot-sql.conf

    sed -i 's/\/etc\/dovecot-sql.conf/\/etc\/dovecot\/dovecot-sql.conf/g' /etc/dovecot/dovecot.conf
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
    ctrl_service pure-ftpd restart; echo ""

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

cd ../../ && rm -rf ispconfig3_install/ && rm -rf ${ispconfig_url##*/} && rm -rf sys-prep.done; clear # Remove downloaded ISPConfig files

if [[ ! -f $HOME/email_backup.sh ]]; then
cat <<EOFA > $HOME/email_backup.sh
#!/bin/bash
#=========================================================================
# Name:                 email_backup.sh
# By:                   Jonathan M. Sloan <jsloan@macksarchive.com>
# Date:                 02-18-2015
# Purpose:              Used to backup all email accounts on the system
# Version:              1.0
#=========================================================================

PATH=/sbin:/bin:/usr/sbin:/usr/bin
maildir_path=/var/vmail
backupbase=/backup/email_accts
tmp_file=\$(mktemp -p /tmp email_addresses.XXXXXX)
tmp_file2=\$(mktemp -p /tmp email_backup_started.XXXXXX)
MAIL_FROM=backups@$domain
MAIL_TO=admin@$domain
mysql_pass='$mysql_pass'

if [[ ! -d \$maildir_path ]]; then

    echo -e "It appears \$maildir_path does not exist on \$(hostname -f). Please check to ensure mail is setup. \n" && exit 5

fi

mysql -u root -p"\$mysql_pass" <<EOF | grep -vw "email" > \$tmp_file
USE dbispconfig;
SELECT \\\`email\\\` FROM \\\`mail_user\\\`;
EOF
unset mysql_pass

if [[ ! -s \$tmp_file ]]; then

    echo -e "There appears to be no email accounts found on \$(hostname -f). Please check ISPConfig Control Panel. \n" && exit 10

fi

for emailacct in \$(cat \$tmp_file); do

    domain=\$(echo \$emailacct | awk -F'@' '{ print \$2 }')
    user=\$(echo \$emailacct | awk -F'@' '{ print \$1 }')
    backupdir=\$backupbase/\$domain/\$user

    [[ ! -d \$backupdir ]] && mkdir -p \$backupdir

    echo -e "\$emailacct backup has started: \$(date +%F-%X)" >> \$tmp_file2
    tar -zcf \$backupdir/"\$emailacct"_"\$(date +%F | sed 's|-||g')".tar.gz \$maildir_path/\$domain/\$user > /dev/null 2>&1
    echo -e "\$emailacct backup has finshed: \$(date +%F-%X)" >> \$tmp_file2
    md5sum \$backupdir/"\$emailacct"_"\$(date +%F | sed 's|-||g')".tar.gz >> \$tmp_file2
    echo "" >> \$tmp_file2

done

mailx -s "Email Backup Completed" -r "\$MAIL_FROM" "\$MAIL_TO" <<EOF
\$(cat \$tmp_file2)
EOF

rm -f \$tmp_file \$tmp_file2
exit 0
EOFA
fi

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
_Menu
