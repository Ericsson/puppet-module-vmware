# Manage repository of VMware Tools packages and related options on Ubuntu.
# Will use Puppetlabs apt module to add the given repository to allow
# installation of VMware Tools packages.
#
# This class is not intended to be used directly by other modules or node definitions.
#
# @param repo_base_url
#   Base URL of repository for VMware tools packages.
#   Only used when parameter $manage_repo is active.
#
# @param gpgkey_url
#   URL for the GPG key with which packages of VMware tools repository are signed.
#   Only used when parameter $manage_repo is active.
#
# @param proxy_host
#   URL of a proxy server that should be used when accessing the VMware tools repositories.
#   Not supported on Suse OS families.
#   Only used when parameter $manage_repo is active.
#
# @param proxy_port
#   Proxy port of a proxy server that should be used when accessing the VMware tools repositories.
#   Not supported on Suse OS families.
#   Only used when parameter $manage_repo is active.
#
# @param esx_version
#   Version of ESX (e.g. 5.1, 5.5, 5.5ep06).
#   Used together with repo_base_url and client facts to build the URL used to manage the VMware tools packages.
#   Note, it is recommended to explicitly set the ESX version rather than defaulting to latest.
#   Only used when parameter $manage_repo is active.
#
class vmware::repo::debian (
  Stdlib::HTTPUrl        $repo_base_url = 'http://packages.vmware.com/tools/esx',
  Stdlib::HTTPUrl        $gpgkey_url    = 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
  String[1]              $esx_version   = 'latest',
  Optional[Stdlib::Host] $proxy_host    = undef,
  Stdlib::Port           $proxy_port    = 8080,
){

  if $proxy_host == undef {
    include ::apt
  } else {
    # will only work if apt is not already defined elsewhere
    class { '::apt':
      proxy_host => $proxy_host,
      proxy_port => $proxy_port,
    }
  }

  apt::key { 'vmware':
    key        => 'C0B5E0AB66FD4949',
    key_source => $gpgkey_url,
  }

  apt::source { 'vmware-osps':
    location    => "${repo_base_url}/${esx_version}/ubuntu",
    release     => $::lsbdistcodename,
    repos       => 'main',
    include_src => false,
  }
}
