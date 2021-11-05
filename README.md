# puppet-module-vmware

# Module description

Manage installation of VMware Tools and related options.
Will remove vmware tools that has been installed from script if present.
Will use open-vm-tools by default on RHEL 7+, SUSE 12+, and Ubuntu 12+,
for all other the default is VMware OSP packages.

# Compatibility

This module has been tested to work on the following systems with Puppet
versions 6 and 7 with the Ruby version associated with those releases.
This module aims to support the current and previous major Puppet versions.

 * RedHat/CentOS 5
 * RedHat/CentOS 6
 * RedHat/CentOS 7
 * RedHat/CentOS 8
 * Suse (SLED/SLES) 10
 * Suse (SLED/SLES) 11
 * Suse (SLED/SLES) 12
 * Suse (SLED/SLES) 15
 * OpenSuse 11
 * OpenSuse 12
 * Ubuntu 12.04 LTS
 * Ubuntu 14.04 LTS
 * Ubuntu 16.04 LTS
 * Ubuntu 18.04 LTS
 * Ubuntu 20.04 LTS

### Parameters

Documentation for parameters have been moved to [REFERENCE.md](REFERENCE.md) file.
