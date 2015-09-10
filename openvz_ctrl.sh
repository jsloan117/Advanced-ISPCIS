#!/bin/bash
# Used to manage  openvz containers
# version: 1.4

status="$?"

list_vz_containers () {
local ctid="$1"

if [[ -z $ctid ]]; then

    vzlist -a

else

    vzlist -a "$ctid"

fi
}

list_templates () {
local ostemplates=$(ls -lh /vz/template/cache | tail -n+2 | awk '{ print $9 }' | sed 's|.tar.gz$||g')

for temp in "$ostemplates"; do

    echo "$temp"

done
}

list_conf_files () {
local conftemplate=$(ls -lh /etc/vz/conf/ | tail -n+2 | awk '{ print $9 }' | sed -e 's|^ve-||g' -e 's|.conf-sample$||g' | grep -vE "*.conf*")

for conf in "$conftemplate"; do

    echo "$conf"

done
}

create_vz_container () {
local ctid="$1"
local ostemplate="$2"
local conftemplate="$3"
local hostname="$4"
local ipadd="$5"
local nameservers="$6"

[[ -z "$conftemplate" ]] && conftemplate='basic'

if [[ -z "$hostname" || -z "$ipadd" ]]; then

    echo -e "\nMust supply a hostname and IP address to the virtual machine. \n" && exit 1

elif [[ -n "$hostname" && -n "$ipadd" ]]; then

    vzctl create "$ctid" --ostemplate "$ostemplate" --config "$conftemplate" --hostname "$hostname" --ipadd "$ipadd"

fi
[[ -n "$nameservers" ]] && set_vz_parameters "$ctid" "nameserver" "$nameservers"
control_container "$ctid" "start"
}

delete_vz_container () {
local ctid="$1"

control_container "$ctid" "stop"
control_container "$ctid" "destroy"
}

set_vz_parameters () {
local ctid="$1"
local parameter="$2" # hostname, ipadd, nameserver, onboot, userpasswd
local value="$3" # Value

if [[ "$parameter" = 'name' ]]; then

    vzctl set "$ctid" --name "$value" --save
    [[ ! -L /etc/vz/names/"$value" ]] && ln -vs ../../../etc/vz/conf/"$ctid".conf /etc/vz/names/"$value"

else

    vzctl set "$ctid" --"$parameter" "$value" --save

fi
}

control_container () {
local ctid="$1"
local action="$2" # start, stop, restart, status values

vzctl "$action" "$ctid"
}

disable_container () {
local ctid="$1"
local action="$2"

if [[ "$action" = 'yes' ]]; then

    suspend_container "$ctid" "suspend"
    set_vz_parameters "$ctid" "disabled" "yes"

elif [[ "$action" = 'no' ]]; then

    set_vz_parameters "$ctid" "disabled" "no"
    suspend_container "$ctid" "restore"

fi
}

suspend_container () {
local ctid="$1"
local action="$2"

if [[ "$action" = 'suspend' ]]; then

    vzctl chkpnt "$ctid" --dumpfile /vz/dump/"$ctid".dump

elif [[ "$action" = 'restore' ]]; then

    vzctl restore "$ctid" --dumpfile /vz/dump/"$ctid".dump

fi
}

change_ctid_number () {
local confdir='/etc/vz/conf'
local privatedatadir='/vz/private'
local rootdatadir='/vz/root'
local ctid="$1"
local newnumber="$2"

suspend_container "$ctid" "suspend"
mv "$confdir/$ctid.conf" "$confdir/$newnumber.conf"
mv "$privatedatadir/$ctid" "$privatedatadir/$newnumber"
mv "$rootdatadir/$ctid" "$rootdatadir/$newnumber"
sed -i "s/VE_ROOT=\"\(.*\)\"/VE_ROOT=\"\/vz\/root\/$newnumber\"/g" "$confdir/$newnumber.conf"
sed -i "s/VE_PRIVATE=\"\(.*\)\"/VE_PRIVATE=\"\/vz\/private\/$newnumber\"/g" "$confdir/$newnumber.conf"
vzctl restore "$newnumber" --dumpfile /vz/dump/"$ctid".dump
[[ "$status" = '0' ]] && rm -fv /vz/dump/"$ctid".dump || echo -e "Restore failed... \n"
}

migrate_container () {
local ctid="$1"
local destsvr="$2"
local sshport="$3"
[[ -z "$sshport" ]] && sshport='22'

echo -e "Please ensure that container: $ctid does NOT exist on the remote host: $destsvr! \n"
read -p "You must configure ssh-keys inbetween the source and destination servers for this to be successful. Have you done this? " yesno

if [[ "$yesno" = 'yes' || "$yesno" = 'y' ]]; then


    vzmigrate --ssh="-p$sshport" --rsync="-axvz --progress" "$destsvr" "$ctid"

else

    echo -e "\nExiting to setup keys \n" && exit 1

fi

if [[ "$status" = '0' ]]; then

    echo -e "\nMigration was successful\n"

else

    echo -e "\nError code: $status -- You may wish to man vzmigrate and check the exit code\n"

fi
}

create_snapshot () {
local ctid="$1"
local _date="$(date "+%F")"

vzctl snapshot "$ctid" --name "$ctid-$_date.snapshot"
}

delete_snapshot () {
local ctid="$1"
local uuid="$2"

vzctl snapshot-delete "$ctid" --id "$uuid"
}

list_snapshots () {
local ctid="$1"

vzctl snapshot-list "$ctid"
}

help_menu () {
local version='1.4'
local prog="$(echo $(basename $0))"

cat <<EOF
This script is used to manage openvz containers. You can list, create, delete, and set parameters of the virtual machine.
  $prog <[-l|--list] [-lt|--listtemplates] [-lc|--listconfs] [-cc|--create] [-d|--delete] [-s|--set] [-c|--control] [-dc|--lock]
         [-sc|--suspend] [-cn|--changenum] [-m|--migrate] [-cs|--createsnapshot] [-ds|--deletesnapshot] [-ls|--listsnapshot] [-h|--help]> <arguments>
  Examples: $prog -l 102
            $prog -cc 102 centos-6-x86_64
            $prog -s hostname hostname.domain.com
            $prog --set ipadd 192.168.2.102
            $prog -s nameserver "8.8.8.8"
            $prog -c 102 (start|stop|restart|status)
            $prog --lock 102 {yes|no)
            $prog --suspend 102 (suspend|restore)
            $prog -m 102 192.168.2.102 8822
            $prog --migrate 102 192.168.2.102
            $prog -cs 102
            $prog -ls 102
  version: $version
EOF
}

selection="$1"
 
case "$selection" in

  -l|--list)

    shift
    list_vz_containers "$1" ;;

  -lt|--listtemplates)

    list_templates "$1" ;;

  -lc|--listconfs)

    list_conf_files "$1" ;;

  -cc|--create)

    shift
    create_vz_container "$@" ;;

  -d|--delete)

    shift
    delete_vz_container "$1" ;;

  -s|--set)

    shift
    set_vz_parameters "$@" ;;

  -c|--control)

    shift
    control_container "$@" ;;

  -dc|--lock)

    shift
    disable_container "$@" ;;

  -sc|--suspend)

    shift
    suspend_container "$@" ;;

  -cn|--changenum)

    shift
    change_ctid_number "$@" ;;

  -m|--migrate)

    shift
    migrate_container "$@" ;;

  -cs|--createsnapshot)

    shift
    create_snapshot "$@" ;;

  -ds|--deletesnapshot)

    shift
    delete_snapshot "$@" ;;

  -ls|--listsnapshot)

    shift
    list_snapshots "$1" ;;

  -h|--help)

    help_menu ;;

  *)

    help_menu ;;

esac
