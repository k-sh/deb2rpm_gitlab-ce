#!/bin/bash

NAME="gitlab-ce"
TARGET="armv7hl"

URL=https://packages.gitlab.com
URL_RPI2=https://packages.gitlab.com/gitlab/raspberry-pi2

DEB_URLS=""

usage_exit() {
	echo "Usage:"
	echo "	$0 [<version>]"
	echo "	$0 --list|-l"
	echo "	$0 --help|-h"
	exit 0
}

LFLAG=false
VER=""
if [ $# -ge 1 ]; then
	if [ "x$1" == "x--help" ] || [ "x$1" == "x-h" ]; then
		usage_exit
	elif [ "x$1" == "x--list" ] || [ "x$1" == "x-l" ]; then
		LFLAG=true
	else
		VER="$1"
	fi
fi

i=1
while :; do
	deb_urls=$(curl -s ${URL_RPI2}?page=$i | grep "href=.*jessie.*gitlab-ce.*\.deb" | grep -v "rc[0-9]*" | sed -e 's:.*href="\([^"]*\)".*:\1:g')
	if [ -z "${deb_urls}" ]; then
		break
	fi
	DEB_URLS="${DEB_URLS} ${deb_urls}"
	i=$(expr $i + 1)
done

if [ ${LFLAG} == true ]; then
	for deb_url in ${DEB_URLS}; do
		deb_name="${deb_url##*/}"
		version=$(echo ${deb_name} | sed -e 's/^gitlab-ce_\([0-9]*\.[0-9]*\.[0-9]*\)+[0-9]*-\([A-Za-z0-9,.]*\)_.*deb/\1/g')
		echo ${version}
	done
else
	GFLAG=false
	for deb_url in ${DEB_URLS}; do
		deb_name="${deb_url##*/}"
		version=$(echo ${deb_name} | sed -e 's/^gitlab-ce_\([0-9]*\.[0-9]*\.[0-9]*\)+[0-9]*-\([A-Za-z0-9,.]*\)_.*deb/\1/g')
		url=$(echo "${URL}${deb_url}/download")
		if [ ! -z "${VER}" ]; then
			ver=$(echo ${version} | grep -w "^${VER}")
			echo $ver $version ${VER}
			if [ -z "${ver}" ]; then
				continue
			fi
		fi
		wget -O ${deb_name} ${url}
		GFLAG=true
		break
	done
	if [ ${GFLAG} == false ]; then
		echo "Error : Cannot find version (${VER})"
		echo "Please run the following command, and check versions:"
		echo "	$0 --list"
		exit 1
	fi
fi

