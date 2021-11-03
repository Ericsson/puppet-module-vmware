# Manage repository of VMware Tools packages and related options on RedHat and CentOS.
# Will use Puppetlabs yumrepo_core module to add the given repository to allow
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
class vmware::repo::redhat (
  Stdlib::HTTPUrl      $repo_base_url                 = 'http://packages.vmware.com/tools/esx',
  Stdlib::HTTPUrl      $gpgkey_url                    = 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
  String[1]            $esx_version                   = 'latest',
  Optional[Boolean]    $proxy_host                    = undef,
  Integer[0, 65535]    $proxy_port                    = 8080,
) {

  if $proxy_host == undef {
    $_proxy = undef
  } else {
    $_proxy = "http://${proxy_host}:${proxy_port}"
  }

  yumrepo { 'vmware-osps':
    baseurl  => "${repo_base_url}/${esx_version}/rhel${facts['os']['release']['major']}/${facts['os']['architecture']}",
    descr    => 'VMware Tools OSPs',
    enabled  => 1,
    gpgcheck => 1,
    gpgkey   => $gpgkey_url,
    proxy    => $_proxy,
  }
}
