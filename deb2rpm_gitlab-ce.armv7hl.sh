#!/bin/bash

NAME="gitlab-ce"
TARGET="armv7hl"

SPECTEMP="./gitlab_ce.spec.template"

URL="https://packages.gitlab.com"
URL_CENT="https://packages.gitlab.com/gitlab/gitlab-ce?filter=rpms"

usage_exit(){
	echo "Usage:"
	echo "	$0 <deb_package>"
	exit 1
}
check_exist_command() {
	which $1 >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Cannot find $1"
		exit 2
	fi
}
get_same_ver_cent_rpm() {
	version=$1
	release=$2
	i=1
	while :; do
		rpm_urls=$(curl -s "${URL_CENT}&page=$i" | grep "href=.*gitlab-ce.*el7.*\.rpm" | grep -v "rc[0-9]*" | sed -e 's:.*href="\([^"]*\)".*:\1:g')
		if [ -z "${rpm_urls}" ]; then
			break
		fi
		for rpm_url in ${rpm_urls}; do
			tmp=$(echo ${rpm_url} | grep "gitlab-ce-${version}.*${release}.*\.rpm")
			if [ ! -z "${tmp}" ]; then
				echo "${URL}${rpm_url}/download"
				return
			fi
		done
		i=$(expr $i + 1)
	done
}
get_spec_header() {
	rpm=$1
	version=$(rpm -qip ${rpm} | awk '$1=="Version" {print $3}')
	release=$(rpm -qip ${rpm} | awk '$1=="Release" {print $3}' | sed -e 's/.el7//g')
	cat << _EOF
%define _prefix /

Name:    gitlab-ce
Version: ${version}
Release: ${release}%{?dist}
Vendor:  Omnibus <omnibus@getchef.com>
URL:     https://about.gitlab.com/
Summary: GitLab Community Edition and GitLab CI (including NGINX, Postgres, Redis)
License: unkown
Group: default
Packager: k-sh
Prefix:   %{_prefix}
AutoReqProv: no

%define _rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%{_target_cpu}.rpm

%description
GitLab Community Edition and GitLab CI (including NGINX, Postgres, Redis)

_EOF
}
get_spec_scripts() {
	rpm=$1
	if [ ! -z "${rpm}" ]; then
		rpm -qp --scripts ${rpm} | \
		sed -e 's:preinstall scriptlet (using /bin/sh)\::%pre:g' | \
		sed -e 's:postinstall scriptlet (using /bin/sh)\::%post:g' | \
		sed -e 's:postuninstall scriptlet (using /bin/sh)\::%postun:g' | \
		sed -e 's:posttrans scriptlet (using /bin/sh)\::%posttrans:g'
	fi
}
get_spec_files() {
	cat << _EOF

%files
%dir %{_prefix}opt/gitlab/
"%{_prefix}opt/gitlab/*"
_EOF
}

# check argument (debian package)
[ $# -ne 1 ] && usage_exit
[ ! -f $1 ] && usage_exit
file $1 | grep "Debian binary package" >/dev/null 2>&1
[ $? -ne 0 ] && usage_exit
DEB="${1##*/}"
VERSION=$(echo ${DEB} | sed -e "s/^${NAME}_\([0-9]*\.[0-9]*\.[0-9]*\)[^0-9].*-\([A-Za-z0-9,.]*\)_.*deb/\1/g")
RELEASE=$(echo ${DEB} | sed -e "s/^${NAME}_\([0-9]*\.[0-9]*\.[0-9]*\)[^0-9].*-\([A-Za-z0-9,.]*\)_.*deb/\2/g")
echo "VERSION=${VERSION}"
echo "RELEASE=${RELEASE}"
[ "x${VERSION}" == "x" ] || [ "x${VERSION}" == "x${DEB}" ] && usage_exit

check_exist_command mktemp
check_exist_command alien
check_exist_command rpmbuild

DIR="$(mktemp -d /tmp/gitlab.XXXXXX)"

cp -rp ${DEB} ${DIR}/${DEB}

pushd ${DIR}

SPEC="${NAME}-${VERSION}.spec"
RPM=$(get_same_ver_cent_rpm ${VERSION} ${RELEASE})
echo ${RPM}
get_spec_header ${RPM}  >  ${DIR}/${SPEC}
get_spec_scripts ${RPM} >> ${DIR}/${SPEC}
get_spec_files ${RPM}   >> ${DIR}/${SPEC}

alien --to-rpm --target=${TARGET} -k --scripts -g ${DEB}

BUILDROOT=$(find ${DIR} -maxdepth 1 -mindepth 1 -type d -name "${NAME}-${VERSION}*")
if [ "x${BUILDROOT}" == "x" ]; then
	echo "Cannot find BUILDROOT"
	exit 3
fi
rm -f ${BUILDROOT}/${NAME}*.spec
rpmbuild -bb --target=${TARGET} --buildroot=${BUILDROOT} --define="_rpmdir ${DIR}" --rmspec ${DIR}/${SPEC}

popd

mv ${DIR}/*.rpm .
rm -rf ${DIR}

