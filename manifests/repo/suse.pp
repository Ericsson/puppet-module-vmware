# Manage repository of VMware Tools packages and related options on Suse OS families.
# Will use Puppetlabs zypprepo module to add the given repository to allow
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
# @param esx_version
#   Version of ESX (e.g. 5.1, 5.5, 5.5ep06)
#   Note: it is recommended to explicitly set the esx version rather than default to latest.
#
class vmware::repo::suse (
  Stdlib::HTTPUrl $repo_base_url = 'http://packages.vmware.com/tools/esx',
  Stdlib::HTTPUrl $gpgkey_url    = 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
  String[1]       $esx_version   = 'latest',
) {
  assert_private()

  case $facts['os']['release']['major'] {
    '10':    { $_suseos = '10' }
    default: {
      if versioncmp($esx_version, '6.0') == 0 {
        $_suseos = "${facts['os']['release']['major']}sp${facts['os']['release']['minor']}"
      } else {
        $_suseos = $facts['os']['release']['full']
      }
    }
  }

  include zypprepo

  zypprepo { 'vmware-osps':
    enabled     => 1,
    autorefresh => 0,
    baseurl     => "${repo_base_url}/${esx_version}/sles${_suseos}/${facts['os']['architecture']}",
    path        => '/',
    type        => 'yum',
    gpgcheck    => 1,
    gpgkey      => $gpgkey_url,
  }
}
