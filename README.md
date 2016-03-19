# deb2rpm_gitlab-ce
The tool of building the gitlab-ce RPM package from deb package

# Previous Arrangement
## Setup build environment.

```shell-session
# yum install rpm-build
```

## Setup the repository for Nux-Dextop
Install epel-release, and nux-dextop.

```shell-session
# rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
# rpm -ivh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
```

Change the settings.

```shell-session
# sed -e 's/$basearch/x86_64/g' /etc/yum.repos.d/epel.repo.org > /etc/yum.repos.d/epel.repo
# sed -e 's/$basearch/x86_64/g' /etc/yum.repos.d/nux-dextop.repo.org > /etc/yum.repos.d/nux-dextop.repo
```

Edit epel.repo.

```diff:/etc/yum.repos.d/epel.repo
  [epel-source]
  name=Extra Packages for Enterprise Linux 7 - x86_64 - Source
  #baseurl=http://download.fedoraproject.org/pub/epel/7/SRPMS
  mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=x86_64
  failovermethod=priority
- enabled=0
+ enabled=1
  gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
  gpgcheck=1
```

And, edit nux-dextop.repo.

```diff:/etc/yum.repos.d/nux-dextop.repo
  [nux-dextop-source]
  name=Nux.Ro RPMs for general desktop use - source
  baseurl=http://li.nux.ro/download/nux/dextop/el7/SRPMS
- enabled=0
+ enabled=1
  gpgcheck=1
  gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-nux.ro
  protect=0
```

## Install alien.

```shell-session
# yum install alien
```

# Buid RPM Package
Clone this github project, and run the following commands.

## Check the gitlab-ce versions.

```bash
$ ./download_gitlab-ce_deb.sh --list
```

## Download the debian package of Raspbian.

```bash
$ ./download_gitlab-ce_deb.sh
```

or

```bash
$ ./download_gitlab-ce_deb.sh <version>
```

## Make build

```bash
$ ./deb2rpm_gitlab-ce.armv7hl.sh <deb_package>
```

