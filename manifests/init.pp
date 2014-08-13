# == Class: vmware
#
# Manage vmware
#
class vmware (
  $manage_repo_package = true,
  $repo_package_name   = 'vmwaretools-repo',
  $repo_package_ensure = 'present',
  $manage_tools_package = true,
  $tools_package_name = 'USE_DEFAULTS',
  $tools_package_ensure = 'present',
){

  if $::virtual == 'vmware' {
    if $tools_package_name == 'USE_DEFAULTS' {
      if $::vmware_has_x == 'true' {
        $tools_package_name_real = ['vmware-tools-esx',
                                    'vmware-tools-esx-nox',
                                    'vmware-tools-esx-kmods',]
      } else {
        $tools_package_name_real = ['vmware-tools-esx-nox',
                                    'vmware-tools-esx-kmods',]
      }
    } else {
        if type($tools_package_name) == 'String' or type($tools_package_name) == 'Array' {
          $tools_package_name_real = $tools_package_name
        } else {
          fail('vmware::tools_package_name must be a string or an array.')
        }
    }

    if type($manage_repo_package) == 'string' {
      $manage_repo_package_real = str2bool($manage_repo_package)
    } else {
      validate_bool($manage_repo_package)
      $manage_repo_package_real = $manage_repo_package
    }

    if type($manage_tools_package) == 'string' {
      $manage_tools_package_real = str2bool($manage_tools_package)
    } else {
      validate_bool($manage_tools_package)
      $manage_tools_package_real = $manage_tools_package
    }

    if $manage_repo_package_real == true {
      validate_string($repo_package_name)
      validate_string($repo_package_ensure)

      package { $repo_package_name:
        ensure => $repo_package_ensure,
      }
    }

    if $manage_tools_package_real == true {
      validate_string($tools_package_ensure)

      exec { 'Remove vmware tools script installation':
        path => '/usr/bin/:/etc/vmware-tools/',
        onlyif => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        command => 'installer.sh uninstall',
        before => Package[$tools_package_name_real],
      }

      package { $tools_package_name_real:
        ensure => $tools_package_ensure,
      }
    }

    if $manage_repo_package_real == true and $manage_tools_package_real == true {
      Package[$repo_package_name] -> Package[$tools_package_name_real]
    }
  }
}
