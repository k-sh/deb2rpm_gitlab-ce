#!/bin/bash

NAME="gitlab-ce"
TARGET="armv7hl"

SPECTEMP="./gitlab_ce.spec.template"

usage_exit(){
	echo "Usage:"
	echo "	$0 <deb_package> <spec_template>"
	exit 1
}
check_exist_command() {
	which $1 >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Cannot find $1"
		exit 2
	fi
}

# check argument (debian package)
[ $# -ne 2 ] && usage_exit
[ ! -f $1 ] && usage_exit
file $1 | grep "Debian binary package" >/dev/null 2>&1
[ $? -ne 0 ] && usage_exit
DEB="${1##*/}"
VERSION=$(echo ${DEB} | sed -e "s/^${NAME}_\([0-9]*\.[0-9]*\.[0-9]*\)+[0-9]*-\([A-Za-z0-9,.]*\)_.*deb/\1/g")
RELEASE=$(echo ${DEB} | sed -e "s/^${NAME}_\([0-9]*\.[0-9]*\.[0-9]*\)+[0-9]*-\([A-Za-z0-9,.]*\)_.*deb/\2/g")
[ "x${VERSION}" == "x" ] || [ "x${VERSION}" == "x${DEB}" ] && usage_exit

check_exist_command mktemp
check_exist_command alien
check_exist_command rpmbuild

DIR="$(mktemp -d /tmp/gitlab.XXXXXX)"

cp -rp ${DEB} ${DIR}/${DEB}

SPEC="${NAME}-${VERSION}.spec"
cat ${SPECTEMP} | \
sed -e "s/@@VERSION@@/${VERSION}/g" | \
sed -e "s/@@RELEASE@@/${RELEASE}/g" > ${DIR}/${SPEC}

pushd ${DIR}
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

