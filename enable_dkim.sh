#!/bin/bash
#==================================================================================================================================
# Name:                 enable_dkim.sh
# By:                   Jonathan M. Sloan <jsloan@macksarchive.com>
# Date:                 04-23-2015
# Purpose:              Used to enable DKIM and SPF for a domain within ISPConfig
# Version:              1.5
# Info:                 Creates DKIM keys and inserts DKIM/SPF records into the domains DNS zone file via mysql.
#                       Must use the local DNS Server as a resolver within /etc/resolv.conf (should be first choice for nameserver)
#==================================================================================================================================
if [[ $# -eq 0 ]]; then

    echo "Usage: $0 <domain> " && exit 1

fi

get_domaininfo=$(mktemp -p /tmp getdomaininfo.XXXXXX.sql)
domaininfo_file=$(mktemp -p /tmp domaininfo.XXXXX)
id_tmp=$(mktemp -p /tmp id.XXXXX)
zoneinfo_tmp=$(mktemp -p /tmp zone_data.XXXXX)
dkim_key_tmp=$(mktemp -p /tmp dkim_key.XXXXX)
mysql_pass=''
dkim_domains=$@
dkim_path=/var/db/dkim

for domain in $dkim_domains; do

  if [[ ! -f /var/named/pri.$domain ]]; then

    echo -e "\nNo DNS zone detected for $domain, exiting.\n" && exit

  fi

cat <<EOF > $get_domaininfo
USE dbispconfig;
SELECT * FROM \`dns_rr\` WHERE \`name\` = '$domain.' AND \`type\` = 'A';
EOF

mysql -u root -p"$mysql_pass" < $get_domaininfo | tail -n1 > $domaininfo_file

mysql -u root -p"$mysql_pass" <<EOF | grep -vw "id" > $id_tmp
USE dbispconfig;
SELECT \`id\` FROM \`dns_rr\` ORDER BY \`id\` DESC;
EOF

last_id=$(cat $id_tmp | head -n1)
_id=$(( $last_id + 1 ))
sys_userid=$(cat $domaininfo_file | awk -F"\\t" '{ print $2 }')
sys_groupid=$(cat $domaininfo_file | awk -F"\\t" '{ print $3 }')
sys_perm_user=$(cat $domaininfo_file | awk -F"\\t" '{ print $4 }')
sys_perm_group=$(cat $domaininfo_file | awk -F"\\t" '{ print $5 }')
sys_perm_other=$(cat $domaininfo_file | awk -F"\\t" '{ print $6 }')
server_id=$(cat $domaininfo_file | awk -F"\\t" '{ print $7 }')
zoneid=$(cat $domaininfo_file | awk -F"\\t" '{ print $8 }')
_type='TXT'
ttl='3600'
active='Y'
_IP=$(cat $domaininfo_file | awk -F"\\t" '{ print $11 }')
aux=$(cat $domaininfo_file | awk -F"\\t" '{ print $12 }')
stamp='NOW()'
serial=$(cat $domaininfo_file | awk -F"\\t" '{ print $16 }')
serial=$(( $serial + 1 ))
spf_id=$(( $_id + 1 ))
spf_record_data="\"v=spf1 mx a ptr ip4:$_IP/32 ~all\""

amavisd genrsa $dkim_path/$domain.key.pem
chown amavis:amavis $dkim_path/$domain.key.pem

echo -e "\nDKIM Key generated for $domain"

cat <<EOF >> /etc/amavisd/amavisd.conf

# DKIM-KEY for $domain
dkim_key('$domain', 'mail', '$dkim_path/$domain.key.pem');
@dkim_signature_options_bysender_maps = (
  { '.' => { ttl => 21*24*3600, c => 'relaxed/simple' } } );
EOF

echo -e "\nDKIM Key information inserted into amavisd.conf\n"

amavisd showkeys $domain > $dkim_key_tmp

k1=$(cat $dkim_key_tmp | tail -n6 | head -n1 | awk '{ print $0 }' | sed -e 's/ "//g' -e 's/"$//g')
k2=$(cat $dkim_key_tmp | tail -n5 | head -n1 | sed -e 's/ "//g' -e 's/"$//g' -e 's/ //g')
k3=$(cat $dkim_key_tmp | tail -n4 | head -n1 | sed -e 's/ "//g' -e 's/"$//g' -e 's/ //g')
k4=$(cat $dkim_key_tmp | tail -n3 | head -n1 | sed -e 's/ "//g' -e 's/"$//g' -e 's/ //g')
k5=$(cat $dkim_key_tmp | tail -n2 | head -n1 | sed -e 's/ "//g' -e 's/")$//g' -e 's/ //g')
record_name=$(cat $dkim_key_tmp | tail -n7 | head -n1 | awk '{ print $1 }')
key=$(echo $k1$k2$k3$k4$k5)

cat <<EOF > $zoneinfo_tmp
USE dbispconfig;
INSERT INTO \`dns_rr\` (\`id\`, \`sys_userid\`, \`sys_groupid\`, \`sys_perm_user\`, \`sys_perm_group\`, \`sys_perm_other\`, \`server_id\`, \`zone\`, \`name\`, \`type\`, \`data\`, \`aux\`, \`ttl\`, \`active\`, \`stamp\`, \`serial\`)
VALUES ('$_id','$sys_userid','$sys_groupid','$sys_perm_user','$sys_perm_group','$sys_perm_other','$server_id','$zoneid','$record_name','$_type','$key','$aux','$ttl','$active',$stamp,'$serial');
INSERT INTO \`dns_rr\` (\`id\`, \`sys_userid\`, \`sys_groupid\`, \`sys_perm_user\`, \`sys_perm_group\`, \`sys_perm_other\`, \`server_id\`, \`zone\`, \`name\`, \`type\`, \`data\`, \`aux\`, \`ttl\`, \`active\`, \`stamp\`, \`serial\`)
VALUES ('$spf_id','$sys_userid','$sys_groupid','$sys_perm_user','$sys_perm_group','$sys_perm_other','$server_id','$zoneid','$domain.','$_type','$spf_record_data','$aux','$ttl','$active',$stamp,'$serial');
FLUSH PRIVILEGES;
EOF

mysql -u root -p"$mysql_pass" < $zoneinfo_tmp
rm -f $id_tmp $domaininfo_file $zoneinfo_tmp $get_domaininfo $dkim_key_tmp

done

unset mysql_pass

service amavisd restart
service named restart

amavisd testkeys
exit 0
