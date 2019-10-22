Name:           lxc-templates
Version:        LxcVersion
Release:        1%{?dist}
Summary:        Provides templates for LXC containers

License: 	LGPLv2+
URL:            https://linuxcontainers.org/
Source0:        https://linuxcontainers.org/downloads/lxc/lxc-templates-3.0.4.tar.gz

BuildRequires:  automake
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  rpmdevtools
BuildRequires:  git

%define debug_package %{nil}

%description
Provices templates for LXC containers


%prep
%autosetup


%build
%configure
%make_build


%install
rm -rf $RPM_BUILD_ROOT
%make_install

%files
# %license add-license-file-here
# %doc add-docs-here
/usr/share/lxc/config/alpine.common.conf
/usr/share/lxc/config/alpine.userns.conf
/usr/share/lxc/config/archlinux.common.conf
/usr/share/lxc/config/archlinux.userns.conf
/usr/share/lxc/config/centos.common.conf
/usr/share/lxc/config/centos.userns.conf
/usr/share/lxc/config/debian.common.conf
/usr/share/lxc/config/debian.userns.conf
/usr/share/lxc/config/fedora.common.conf
/usr/share/lxc/config/fedora.userns.conf
/usr/share/lxc/config/gentoo.common.conf
/usr/share/lxc/config/gentoo.moresecure.conf
/usr/share/lxc/config/gentoo.userns.conf
/usr/share/lxc/config/opensuse.common.conf
/usr/share/lxc/config/opensuse.userns.conf
/usr/share/lxc/config/openwrt.common.conf
/usr/share/lxc/config/oracle.common.conf
/usr/share/lxc/config/oracle.userns.conf
/usr/share/lxc/config/plamo.common.conf
/usr/share/lxc/config/plamo.userns.conf
/usr/share/lxc/config/sabayon.common.conf
/usr/share/lxc/config/sabayon.userns.conf
/usr/share/lxc/config/slackware.common.conf
/usr/share/lxc/config/slackware.userns.conf
/usr/share/lxc/config/sparclinux.common.conf
/usr/share/lxc/config/sparclinux.userns.conf
/usr/share/lxc/config/ubuntu-cloud.common.conf
/usr/share/lxc/config/ubuntu-cloud.lucid.conf
/usr/share/lxc/config/ubuntu-cloud.userns.conf
/usr/share/lxc/config/ubuntu.common.conf
/usr/share/lxc/config/ubuntu.lucid.conf
/usr/share/lxc/config/ubuntu.userns.conf
/usr/share/lxc/config/voidlinux.common.conf
/usr/share/lxc/config/voidlinux.userns.conf
/usr/share/lxc/templates/lxc-alpine
/usr/share/lxc/templates/lxc-altlinux
/usr/share/lxc/templates/lxc-archlinux
/usr/share/lxc/templates/lxc-centos
/usr/share/lxc/templates/lxc-cirros
/usr/share/lxc/templates/lxc-debian
/usr/share/lxc/templates/lxc-fedora
/usr/share/lxc/templates/lxc-fedora-legacy
/usr/share/lxc/templates/lxc-gentoo
/usr/share/lxc/templates/lxc-openmandriva
/usr/share/lxc/templates/lxc-opensuse
/usr/share/lxc/templates/lxc-oracle
/usr/share/lxc/templates/lxc-plamo
/usr/share/lxc/templates/lxc-pld
/usr/share/lxc/templates/lxc-sabayon
/usr/share/lxc/templates/lxc-slackware
/usr/share/lxc/templates/lxc-sparclinux
/usr/share/lxc/templates/lxc-sshd
/usr/share/lxc/templates/lxc-ubuntu
/usr/share/lxc/templates/lxc-ubuntu-cloud
/usr/share/lxc/templates/lxc-voidlinux

%changelog
* Tue Oct 22 2019 ubuntu
- 
