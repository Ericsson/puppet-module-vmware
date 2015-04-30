# puppet-module-vmware
===

[![Build Status](https://travis-ci.org/emahags/puppet-module-vmware.png?branch=master)](https://travis-ci.org/emahags/puppet-module-vmware)

Manage VMware - Install vmwaretools. Will remove vmware tools that has been installed from script if present. Will use open-vm-tools by default on RHEL 7+, SUSE 12+, and Ubuntu 12+, for all other the default is VMware OSP packages.

===

# Class `vmware`

## Parameters

manage_repo
-----------
Should repo file be managed?

- *Default*: default is set based on OS version

repo_base_url
---------------------
Base URL of mirror of packages.vmware.com/tools/esx.

- *Default*: http://packages.vmware.com/tools/esx

esx_version
-----------
Version of ESX (e.g. 5.1, 5.5, 5.5ep06) ... note, it is recommended to explicitly set the esx version rather than default to latest.

- *Default*: latest

gpgkey_url
----------
URL for VMware GPG key

- *Default*: http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub

proxy_host
----------
Hostname of web proxy (not supported on SUSE)

- *Default*: absent

proxy_port
----------
Port number of web proxy

- *Default*: 8080

prefer_open_vm_tools
-----------------
Prefer open-vm-tools over vmware-tools in the case that both are available (e.g. Ubuntu 12.04).

- *Default*: true

manage_tools_nox_package
------------------------
Should vmwaretools nox package be managed?

- *Default*: true

tools_nox_package_name
----------------------
Name of package for vmwaretools nox package.

- *Default*: default is set based on OS version

tools_nox_package_ensure
------------------------
String to pass to ensure attribute for the vmwaretools nox package.

- *Default*: 'present'

manage_tools_x_package
----------------------
Should vmwaretools x package be managed?

- *Default*: based on if X is installed or not.

tools_x_package_name
--------------------
Name of package for vmwaretools x package.

- *Default*: default is set based on OS version

tools_x_package_ensure
----------------------
String to pass to ensure attribute for the vmwaretools x package.

- *Default*: 'present'
