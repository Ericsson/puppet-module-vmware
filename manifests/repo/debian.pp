# Manage repository of VMware Tools packages and related options on Ubuntu.
# Will use Puppetlabs apt module to add the given repository to allow
# installation of VMware Tools packages.
#
# This class is not intended to be used directly by other modules or node definitions.
#
# @param repo_base_url
#   Base URL of mirror of packages.vmware.com/tools/esx.
#
# @param gpgkey_url
#   URL for VMware GPG key. Defaults to http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub.
#
# @param esx_version
#   Version of ESX (e.g. 5.1, 5.5, 5.5ep06). Note, it is recommended to explicitly set the esx version rather than default to latest.
#
# @param proxy_host
#   Hostname of web proxy (not supported on SUSE).
#
# @param proxy_port
#   Port number of web proxy.
#
class vmware::repo::debian (
  Stdlib::HTTPUrl      $repo_base_url                 = 'http://packages.vmware.com/tools/esx',
  Stdlib::HTTPUrl      $gpgkey_url                    = 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
  String[1]            $esx_version                   = 'latest',
  Optional[Boolean]    $proxy_host                    = undef,
  Integer[0, 65535]    $proxy_port                    = 8080,
){

  if $proxy_host == undef {
    include ::apt
  } else {
    # will only work if apt is not already defined elsewhere
    class { '::apt':
      proxy_host => $proxy_host,
      proxy_port => '8080',
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
