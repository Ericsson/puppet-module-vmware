# puppet-module-vmware
===

[![Build Status](https://travis-ci.org/emahags/puppet-module-vmware.png?branch=master)](https://travis-ci.org/emahags/puppet-module-vmware)

Manage VMware - Install vmwaretools. Will remove vmware tools that has been installed from script if present.

===

# Class `vmware`

## Parameters

manage_repo_package
-------------------
Should repo package be managed? Contains the vmware repo and key.

- *Default*: true

repo_package_name
-----------------
Name of repo package. Please note that this needs to be built manually, there is no premade package.

- *Default*: 'vmwaretools-repo'

repo_package_ensure
-------------------
String to pass to ensure attribute for the repo package.

- *Default*: 'present'

manage_tools_nox_package
--------------------
Should vmwaretools nox package be managed?

- *Default*: true

tools_nox_package_name
------------------
Name of package for vmwaretools nox package.

- *Default*: vmware-tools-esx-nox

tools_nox_package_ensure
--------------------
String to pass to ensure attribute for the vmwaretools nox package.

- *Default*: 'present'

manage_tools_x_package
--------------------
Should vmwaretools x package be managed?

- *Default*: based on if X is installed or not.

tools_x_package_name
------------------
Name of package for vmwaretools x package.

- *Default*: vmware-tools-esx

tools_x_package_ensure
--------------------
String to pass to ensure attribute for the vmwaretools x package.

- *Default*: 'present'

manage_tools_kmod_package
--------------------
Should vmwaretools kmod package be managed?

- *Default*: true

tools_kmod_package_name
------------------
Name of package for vmwaretools kmod package.

- *Default*: vmware-tools-esx-kmods

tools_kmod_package_ensure
--------------------
String to pass to ensure attribute for the vmwaretools kmod package.

- *Default*: 'present'
