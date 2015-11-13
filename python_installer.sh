#!/bin/bash
#=================================================================================================
# Name:                 python_instaler.sh
# By:                   Jonathan M. Sloan <jsloan@macksarchive.com>
# Date:                 11-12-2015
# Purpose:              Install multiple versions of python
# Version:              1.0
# This Script will Download 3 additional versions of Python. The versions are 2.7.10, 3.4.3, 3.5.0
#==================================================================================================

status="$?"
ver='1.0'

declare -a my_python_versions=('2.7.10' '3.4.3' '3.5.0')

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

if [[ $# -ne 0 || $1 = '--help' ]]; then

    print_usage

else

    if [[ $status -eq 0 ]]; then

        clear; echo ""; read -ep "What python version do you want to install? ($(echo ${my_python_versions[@]} | sed "s/ /|/g")): " pythonversion ; echo ""

        yum install -y -q zlib-dev openssl-devel sqlite-devel bzip2-devel > /dev/null 2>&1
        make_dirs
        download_python_versions
        extract_tars
        compile_python_versions
        make_symlinks

    fi

fi
