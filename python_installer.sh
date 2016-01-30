#!/bin/bash
#=================================================================================================
# Name:                 python_instaler.sh
# By:                   Jonathan M. Sloan <jsloan@macksarchive.com>
# Date:                 01-29-2016
# Purpose:              Install multiple versions of python
# Version:              1.1
# This Script will Download 3 additional versions of Python. The versions are 2.7.11, 3.4.4, 3.5.1
#==================================================================================================
# ChangeLog:
# 1.0 -> 1.1: updated versions, added get_pip function

status="$?"
ver='1.1'

declare -a my_python_versions=('2.7.11' '3.4.4' '3.5.1')

print_usage(){
clear; cat<<USAGE
This script will install 1 of 3 python versions at a time

      Usage: ${0##*/}
      Version: $ver

USAGE
}

make_dirs () {
echo -e "\nMaking directories now. \n"

[[ ! -d /usr/local/src/python-build ]] && mkdir -p /usr/local/src/python-build

echo -e "Done! \n"
}

download_python_versions () {
cd /usr/local/src/python-build

if [[ ! -f Python-$pythonversion.tgz ]]; then

    echo -e "Downloading Python version: $pythonversion now. \n"

    wget -q https://www.python.org/ftp/python/$pythonversion/Python-$pythonversion.tgz -O Python-$pythonversion.tgz

    echo -e "Done! \n"

fi
}

extract_tars () {
if [[ ! -d Python-$pythonversion ]]; then

    echo -e "Extracting Python-$pythonversion.tgz now. \n"

    tar -xaf Python-$pythonversion.tgz

    echo -e "Done! \n"

fi
}

compile_python_versions () {
cd Python-$pythonversion

./configure --prefix=/usr/local &&  make && make altinstall
}

make_symlinks () {
local python_version=$(echo $pythonversion | cut -d. -f1,2)

ln -s /usr/local/bin/python$python_version /usr/bin/python$python_version
}

get_pip () {
local pip_url='https://bootstrap.pypa.io/get-pip.py'

curl -S -O $pip_url

/usr/bin/python$python_version get-pip.py

rm -f get-pip.py
}

if [[ $# -ne 0 || $1 = '--help' ]]; then

    print_usage

else

    if [[ $status -eq 0 ]]; then

        clear; echo ""; read -ep "What python version do you want to install? ($(echo ${my_python_versions[@]} | sed "s/ /|/g")): " pythonversion ; echo ""
        read -ep "Do you want to instal pip as well? " yesno

        yum install -y -q zlib-dev openssl-devel sqlite-devel bzip2-devel
        make_dirs
        download_python_versions
        extract_tars
        compile_python_versions
        make_symlinks

        if [[ $yesno = 'yes' ]]; then

          get_pip

        fi

    fi

fi
