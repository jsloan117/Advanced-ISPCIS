#!/bin/bash
#=========================================================================
# Name:                 email_backup.sh
# By:                   Jonathan M. Sloan <jsloan@macksarchive.com>
# Date:                 07-24-2015
# Purpose:              Used to backup all email accounts in ISPCONFIG 3 DB
# Version:              1.2
#=========================================================================

PATH=/sbin:/bin:/usr/sbin:/usr/bin
maildir_path=/var/vmail
backupbase=/backup/email_accts
tmp_file=$(mktemp -p /tmp email_addresses.XXXXXX)
tmp_file2=$(mktemp -p /tmp email_backup_started.XXXXXX)
MAIL_FROM=backups@domain.com
MAIL_TO=admin@domain.com
mysql_pass=''
send_mail='no' # yes or no options
backuplog=/var/log/emailbackups.log
tmpwatch -m 30d $backupbase/ # Keeps 30 day of backups by default

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

sendmaillog () {
mailx -s "Email Backup Completed" -r "$MAIL_FROM" "$MAIL_TO" <<EOF
$(cat $tmp_file2)
EOF
}

if [[ $send_mail = 'yes' ]]; then

  sendmaillog

elif [[ $send_mail = 'no' ]]; then

  cat $tmp_file2 >> $backuplog

fi

rm -f $tmp_file $tmp_file2
exit 0
