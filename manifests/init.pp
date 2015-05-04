# == Class: vmware
#
# Manage vmware
#
class vmware (
  $manage_repo               = 'USE_DEFAULTS',
  $repo_base_url             = 'http://packages.vmware.com/tools/esx',
  $esx_version               = 'latest',
  $gpgkey_url                = 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
  $proxy_host                = 'absent',
  $proxy_port                = '8080',
  $prefer_open_vm_tools      = true,
  $manage_tools_nox_package  = true,
  $manage_tools_x_package    = 'USE_DEFAULTS',
  $tools_nox_package_name    = 'USE_DEFAULTS',
  $tools_x_package_name      = 'USE_DEFAULTS',
  $tools_nox_package_ensure  = 'present',
  $tools_x_package_ensure    = 'present',
){

  validate_string($repo_base_url)
  validate_string($esx_version)
  validate_string($gpgkey_url)
  validate_string($proxy_host)
  validate_string($proxy_port)
  validate_string($tools_nox_package_ensure)
  validate_string($tools_nox_package_name)
  validate_string($tools_x_package_ensure)
  validate_string($tools_x_package_name)


  if $::virtual == 'vmware' {

    if is_string($prefer_open_vm_tools) == true {
      $prefer_open_vm_tools_real = str2bool($prefer_open_vm_tools)
    } else {
      validate_bool($prefer_open_vm_tools)
      $prefer_open_vm_tools_real = $prefer_open_vm_tools
    }

    # OSs that have open-vm-tools
    case $::operatingsystem {
      'RedHat', 'CentOS': {
        $_use_open_vm_tools = $::lsbmajdistrelease >= 7
      }
      'SLED', 'SLES': {
        $_use_open_vm_tools = $::lsbmajdistrelease >= 12
      }
      'OpenSuSE': {
        $_use_open_vm_tools = $::lsbmajdistrelease >= 12
      }
      'Ubuntu': {
        if $prefer_open_vm_tools_real == true {
          # include Ubuntu 12.04
          $_use_open_vm_tools = $::lsbmajdistrelease >= 12
        } else {
          # skip Ubuntu 12.04
          $_use_open_vm_tools = $::lsbmajdistrelease > 12
        }
      }
      default: {
          fail("The vmware module is not supported on ${::operatingsystem}")
      }
    }

    if $_use_open_vm_tools == true {
      $_tools_nox_package_name_default = 'open-vm-tools'

      case $::operatingsystem {
        'RedHat', 'CentOS': {
          $_tools_x_package_name_default = 'open-vm-tools-desktop'
        }
        'SLES', 'SLES', 'OpenSuSE': {
          $_tools_x_package_name_default = 'open-vm-tools-gui'
        }
        'Ubuntu': {
          $_tools_x_package_name_default = 'open-vm-toolbox'
        }
        default: {
          fail("The vmware module is not supported on ${::operatingsystem}")
        }
      }
    } else { # assume vmware-tools exists for OS
      $_tools_nox_package_name_default = 'vmware-tools-esx-nox'
      $_tools_x_package_name_default   = 'vmware-tools-esx'
    }

    if $manage_repo == 'USE_DEFAULTS' {
      if $_use_open_vm_tools {
        $manage_repo_real = false
      } else {
        $manage_repo_real = true
      }
    } else {
      if is_string($manage_repo) == true {
        $manage_repo_real = str2bool($manage_repo)
      } else {
        validate_bool($manage_repo)
        $manage_repo_real = $manage_repo
      }
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

    if $manage_repo_real == true {

      case $::operatingsystem {
        'RedHat', 'CentOS': {

          if $proxy_host == 'absent' {
            $_proxy = undef
          } else {
            $_proxy = "http://${proxy_host}:${proxy_port}"
          }

          yumrepo { 'vmware-osps':
            baseurl  => "${repo_base_url}/${esx_version}/rhel${::operatingsystemmajrelease}/${::architecture}",
            enabled  => 1,
            gpgcheck => 1,
            gpgkey   => $gpgkey_url,
            proxy    => $_proxy,
          }
        }

        'SLED', 'SLES', 'OpenSuSE': {
          include zypprepo

          if $proxy_host != 'absent' {
            fail("The vmware::proxy_host parameter is not supported on ${::operatingsystem}")
          }

          case $::operatingsystemrelease {
            /^10./: {
              $_suseos = '10'
            }
            default: {
              $_suseos = $::operatingsystemrelease
            }
          }

          zypprepo { 'vmware-osps':
            enabled     => 1,
            autorefresh => 0,
            baseurl     => "${repo_base_url}/${esx_version}/sles${_suseos}/${::architecture}",
            path        => '/',
            type        => 'yum',
            gpgcheck    => 1,
            gpgkey      => $gpgkey_url,
          }
        }
        'Ubuntu': {

          if $proxy_host == 'absent' {
            include apt
          } else {
            # will only work if apt is not already defined elsewhere
            class { 'apt':
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
        default: {
          fail("The vmware module is not supported on ${::operatingsystem}")
        }
      }
    }

    if $tools_nox_package_name == 'USE_DEFAULTS' {
      $tools_nox_package_name_real = $_tools_nox_package_name_default
    } else {
      $tools_nox_package_name_real = $tools_nox_package_name
    }

    if $tools_x_package_name == 'USE_DEFAULTS' {
      $tools_x_package_name_real = $_tools_x_package_name_default
    } else {
      $tools_x_package_name_real = $tools_x_package_name
    }

    if $manage_tools_nox_package_real == true or $manage_tools_x_package_real == true {
      exec { 'Remove vmware tools script installation':
        path    => '/usr/bin/:/etc/vmware-tools/',
        onlyif  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        command => 'installer.sh uninstall',
      }
      if $manage_tools_nox_package_real == true {
        Exec['Remove vmware tools script installation'] -> Package[$tools_nox_package_name_real]
      }
      if $manage_tools_x_package_real == true {
        Exec['Remove vmware tools script installation'] -> Package[$tools_x_package_name_real]
      }
    }

    if $manage_tools_nox_package_real == true {
      package { $tools_nox_package_name_real:
        ensure => $tools_nox_package_ensure,
      }
    }

    if $manage_tools_x_package_real == true {
      package { $tools_x_package_name_real:
        ensure => $tools_x_package_ensure,
      }
    }
  }
}
