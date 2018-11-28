# puppet-module-vmware
===

[![Build Status](https://travis-ci.org/gillarkod/puppet-module-vmware.png?branch=master)](https://travis-ci.org/gillarkod/puppet-module-vmware)

Manage VMware - Install vmwaretools. Will remove vmware tools that has been installed from script if present. Will use open-vm-tools by default on RHEL 7+, SUSE 12+, and Ubuntu 12+, for all other the default is VMware OSP packages.

===

# Class `vmware`

## Compatibility
This module has been tested to work on the following systems with Puppet v3
with and without the future parser and Puppet v4 versions 4.2 and newer.
These Puppet versions has been tested in combination with Ruby versions 1.8.7,
1.9.3, 2.0.0 and 2.1.0.

Puppet 4.0 and Puppet 4.1 unsupported because of issues with inifile.
See https://tickets.puppetlabs.com/browse/MODULES-2867 for more information.

* Ubuntu
* RHEL/CentOS
* OpenSuSE
* SLE

## Parameters

manage_repo
-----------
Should repo file be managed?

- *Default*: default is set based on OS version

repo_base_url
---------------------
Base URL of mirror of packages.vmware.com/tools/esx.

- *Default*: http://packages.vmware.com/tools/esx

manage_service
--------------
If vmwaretools service should be managed (boolean)

- *Default*: true

service_name
------------
Service name to manage (string).

- *Default*: 'USE_DEFAULTS', based on OS platform

service_provider
----------------
Service provider

- *Default*: 'USE_DEFAULTS', based on package type, "service" for open-vm-tools, "init" for OSP

service_path
------------
Path to service init files

- *Default*: 'USE_DEFAULTS', "/etc/vmware-tools/init/", only applicable for "init" service provider

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

force_open_vm_tools
-------------------
Force open-vm-tools over vmware-tools. Using this option is suitable in cases where EPEL is available for EL systems.

- *Default*: false

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

tools_conf_path
---------------
Path to vmware-tools configuration file.

- *Default*: /etc/vmware-tools/tools.conf

disable_tools_version
---------------------
Disable tools version reporting to vSphere.

- *Default*: true

enable_sync_driver
------------------
Enable vmtools sync driver on snapshots.  'true', 'false', 'auto' to enable on non-buggy systems

See KB2038606 (http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2038606)
https://access.redhat.com/solutions/484303

- *Default*: 'auto'

working_kernel_release
---------------------
First non-buggy kernel version for sync driver.

- *Default*: 'USE_DEFAULTS'
