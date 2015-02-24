# == Class: vmware
#
# Manage vmware
#
class vmware (
  $manage_repo_package       = true,
  $manage_tools_nox_package  = true,
  $manage_tools_kmod_package = true,
  $manage_tools_x_package    = 'USE_DEFAULTS',
  $repo_package_name         = 'vmwaretools-repo',
  $tools_nox_package_name    = 'vmware-tools-esx-nox',
  $tools_kmod_package_name   = 'vmware-tools-esx-kmods',
  $tools_x_package_name      = 'vmware-tools-esx',
  $repo_package_ensure       = 'present',
  $tools_nox_package_ensure  = 'present',
  $tools_kmod_package_ensure = 'present',
  $tools_x_package_ensure    = 'present',
){

  validate_string($repo_package_name)
  validate_string($repo_package_ensure)
  validate_string($tools_nox_package_ensure)
  validate_string($tools_nox_package_name)
  validate_string($tools_x_package_ensure)
  validate_string($tools_x_package_name)
  validate_string($tools_kmod_package_ensure)
  validate_string($tools_kmod_package_name)

  if $::virtual == 'vmware' {
    if is_string($manage_repo_package) == true {
      $manage_repo_package_real = str2bool($manage_repo_package)
    } else {
      validate_bool($manage_repo_package)
      $manage_repo_package_real = $manage_repo_package
    }

    if is_string($manage_tools_nox_package) == true {
      $manage_tools_nox_package_real = str2bool($manage_tools_nox_package)
    } else {
      validate_bool($manage_tools_nox_package)
      $manage_tools_nox_package_real = $manage_tools_nox_package
    }

    if $::vmware_has_x == 'true' and $manage_tools_x_package == 'USE_DEFAULTS' {
      $manage_tools_x_package_real = true
    } elsif $::vmware_has_x == 'false' and $manage_tools_x_package == 'USE_DEFAULTS' {
      $manage_tools_x_package_real = false
    } else {
      if is_string($manage_tools_x_package) == true {
        $manage_tools_x_package_real = str2bool($manage_tools_x_package)
      } else {
        validate_bool($manage_tools_x_package)
        $manage_tools_x_package_real = $manage_tools_x_package
      }
    }

    if is_string($manage_tools_kmod_package) == true {
      $manage_tools_kmod_package_real = str2bool($manage_tools_kmod_package)
    } else {
      validate_bool($manage_tools_kmod_package)
      $manage_tools_kmod_package_real = $manage_tools_kmod_package
    }

    if $manage_repo_package_real == true {
      package { $repo_package_name:
        ensure => $repo_package_ensure,
      }
    }

    if $manage_tools_nox_package_real == true or $manage_tools_x_package_real == true or $manage_tools_kmod_package_real == true {
      exec { 'Remove vmware tools script installation':
        path => '/usr/bin/:/etc/vmware-tools/',
        onlyif => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        command => 'installer.sh uninstall',
      }
      if $manage_tools_nox_package_real == true {
        Exec['Remove vmware tools script installation'] -> Package[$tools_nox_package_name]
      }
      if $manage_tools_x_package_real == true {
        Exec['Remove vmware tools script installation'] -> Package[$tools_x_package_name]
      }
      if $manage_tools_kmod_package_real == true {
        Exec['Remove vmware tools script installation'] -> Package[$tools_kmod_package_name]
      }
    }

    if $manage_tools_nox_package_real == true {
      package { $tools_nox_package_name:
        ensure => $tools_nox_package_ensure,
      }
      if $manage_repo_package_real == true {
        Package[$repo_package_name] -> Package[$tools_nox_package_name]
      }
    }

    if $manage_tools_x_package_real == true {
      package { $tools_x_package_name:
        ensure => $tools_x_package_ensure,
      }
      if $manage_repo_package_real == true {
        Package[$repo_package_name] -> Package[$tools_x_package_name]
      }
    }

    if $manage_tools_kmod_package_real == true {
      package { $tools_kmod_package_name:
        ensure => $tools_kmod_package_ensure,
      }
      if $manage_repo_package_real == true {
        Package[$repo_package_name] -> Package[$tools_kmod_package_name]
      }
    }
  }
}
