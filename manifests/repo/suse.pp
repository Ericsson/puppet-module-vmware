# Manage repository of VMware Tools packages and related options on Suse OS families.
# Will use Puppetlabs zypprepo module to add the given repository to allow
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
class vmware::repo::suse (
  Stdlib::HTTPUrl      $repo_base_url                 = 'http://packages.vmware.com/tools/esx',
  Stdlib::HTTPUrl      $gpgkey_url                    = 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
  String[1]            $esx_version                   = 'latest',
  Optional[Boolean]    $proxy_host                    = undef,
  Integer[0, 65535]    $proxy_port                    = 8080,
) {

  include ::zypprepo

  if $proxy_host != undef {
    fail("The vmware::proxy_host parameter is not supported on ${facts['os']['family']} family")
  }

  case $facts['os']['release']['major'] {
    '10': {
      $_suseos = '10'
    }
    default: {
      if versioncmp($esx_version, '6.0') == 0 {
        $_suseos = "${facts['os']['release']['major']}sp${facts['os']['release']['minor']}"
      } else {
        $_suseos = $facts['os']['release']['full']
      }
    }
  }

  case $facts['os']['architecture'] {
    'i386': {
      $architecture_real = 'i586'
    }
    default: {
      $architecture_real = $facts['os']['architecture']
    }
  }

  zypprepo { 'vmware-osps':
    enabled     => 1,
    autorefresh => 0,
    baseurl     => "${repo_base_url}/${esx_version}/sles${_suseos}/${architecture_real}",
    path        => '/',
    type        => 'yum',
    gpgcheck    => 1,
    gpgkey      => $gpgkey_url,
  }
}
