#!/bin/bash
#=========================================================================
# Name:                 email_backup.sh
# By:                   Jonathan M. Sloan <jsloan@macksarchive.com>
# Date:                 03-01-2015
# Purpose:              Used to backup all email accounts on the system
# Version:              1.1
#=========================================================================

PATH=/sbin:/bin:/usr/sbin:/usr/bin
maildir_path=/var/vmail
backupbase=/backup/email_accts
tmp_file=$(mktemp -p /tmp email_addresses.XXXXXX)
tmp_file2=$(mktemp -p /tmp email_backup_started.XXXXXX)
MAIL_FROM=backups@domain.com
MAIL_TO=admin@domain.com
mysql_pass=''

if [[ ! -d $maildir_path ]]; then

    echo -e "It appears $maildir_path does not exist on $(hostname -f). Please check to ensure mail is setup. \n" && exit 5

fi

mysql -u root -p"$mysql_pass" <<EOF | grep -vw "email" > $tmp_file
USE dbispconfig;
SELECT \`email\` FROM \`mail_user\`;
EOF
unset mysql_pass

if [[ ! -s $tmp_file ]]; then

    echo -e "There appears to be no email accounts found on $(hostname -f). Please check ISPConfig Control Panel. \n" && exit 10

fi

for emailacct in $(cat $tmp_file); do

    domain=$(echo $emailacct | awk -F'@' '{ print $2 }')
    user=$(echo $emailacct | awk -F'@' '{ print $1 }')
    backupdir=$backupbase/$domain/$user

    [[ ! -d $backupdir ]] && mkdir -p $backupdir

    echo -e "$emailacct backup has started: $(date +%F-%X)" >> $tmp_file2
    tar -zcf $backupdir/"$emailacct"_"$(date +%F | sed 's|-||g')".tar.gz $maildir_path/$domain/$user > /dev/null 2>&1
    echo -e "$emailacct backup has finshed: $(date +%F-%X)" >> $tmp_file2
    md5sum $backupdir/"$emailacct"_"$(date +%F | sed 's|-||g')".tar.gz >> $tmp_file2
    echo "" >> $tmp_file2

done

mailx -s "Email Backup Completed" -r "$MAIL_FROM" "$MAIL_TO" <<EOF
$(cat $tmp_file2)
EOF

rm -f $tmp_file $tmp_file2
exit 0
