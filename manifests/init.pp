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
  $manage_service            = true,
  $service_name              = 'USE_DEFAULTS',
  $service_provider          = 'USE_DEFAULTS',
  $service_path              = 'USE_DEFAULTS',
  $manage_tools_nox_package  = true,
  $manage_tools_x_package    = 'USE_DEFAULTS',
  $tools_nox_package_name    = 'USE_DEFAULTS',
  $tools_x_package_name      = 'USE_DEFAULTS',
  $tools_nox_package_ensure  = 'present',
  $tools_x_package_ensure    = 'present',
  $tools_conf_path           = '/etc/vmware-tools/tools.conf',
  $disable_tools_version     = true,
  $enable_sync_driver        = 'auto',
  $working_kernel_release    = 'USE_DEFAULTS',
){

  validate_string($repo_base_url)
  validate_string($esx_version)
  validate_string($gpgkey_url)
  validate_string($proxy_host)
  validate_string($proxy_port)
  validate_string($service_name)
  validate_string($tools_nox_package_ensure)
  validate_string($tools_nox_package_name)
  validate_string($tools_x_package_ensure)
  validate_string($tools_x_package_name)
  validate_absolute_path($tools_conf_path)

  if is_bool($::vmware_has_x) == true {
    $vmware_has_x_bool = $::vmware_has_x
  } else {
    $vmware_has_x_bool = str2bool($::vmware_has_x)
  }

  $lsbmajdistrelease_int = 0 + $::lsbmajdistrelease

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
        $_use_open_vm_tools = $lsbmajdistrelease_int >= 7
      }
      'SLED', 'SLES': {
        $_use_open_vm_tools = $lsbmajdistrelease_int >= 12
      }
      'OpenSuSE': {
        $_use_open_vm_tools = $lsbmajdistrelease_int >= 12
      }
      'Ubuntu': {
        if $prefer_open_vm_tools_real == true {
          # include Ubuntu 12.04
          $_use_open_vm_tools = $lsbmajdistrelease_int >= 12
        } else {
          # skip Ubuntu 12.04
          $_use_open_vm_tools = $lsbmajdistrelease_int > 12
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
          $_service_name_default         = 'vmtoolsd'
        }
        'SLED', 'SLES': {
          $_tools_x_package_name_default = 'open-vm-tools-desktop'
          $_service_name_default         = 'vmtoolsd'
        }
        'OpenSuSE': {
          $_tools_x_package_name_default = 'open-vm-tools-gui'
          $_service_name_default         = 'vmtoolsd'
        }
        'Ubuntu': {
          $_tools_x_package_name_default = 'open-vm-toolbox'
          $_service_name_default         = 'open-vm-tools'
        }
        default: {
          fail("The vmware module is not supported on ${::operatingsystem}")
        }
      }
    } else { # assume vmware-tools exists for OS
      $_tools_nox_package_name_default = 'vmware-tools-esx-nox'
      $_tools_x_package_name_default   = 'vmware-tools-esx'
      $_service_name_default           = 'vmware-tools-services'
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

    if $vmware_has_x_bool == true and $manage_tools_x_package == 'USE_DEFAULTS' {
      $manage_tools_x_package_real = true
    } elsif $vmware_has_x_bool == false and $manage_tools_x_package == 'USE_DEFAULTS' {
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
            baseurl  => "${repo_base_url}/${esx_version}/rhel${lsbmajdistrelease_int}/${::architecture}",
            descr    => 'VMware Tools OSPs',
            enabled  => 1,
            gpgcheck => 1,
            gpgkey   => $gpgkey_url,
            proxy    => $_proxy,
          }
        }

        'SLED', 'SLES', 'OpenSuSE': {
          include ::zypprepo

          if $proxy_host != 'absent' {
            fail("The vmware::proxy_host parameter is not supported on ${::operatingsystem}")
          }

          case $::operatingsystemrelease {
            /^10./: {
              $_suseos = '10'
            }
            default: {
              if versioncmp($esx_version, '6.0') == 0 {
                $_suseos = regsubst($::operatingsystemrelease, '\.', 'sp')
              } else {
                $_suseos = $::operatingsystemrelease
              }
            }
          }
          case $::architecture {
            /^i386/: {
              $architecture_real = 'i586'
            }
            default: {
              $architecture_real = $::architecture
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
        'Ubuntu': {

          if $proxy_host == 'absent' {
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

    if is_bool($manage_service) == true {
      $manage_service_real = $manage_service
    } else {
      $manage_service_real = str2bool($manage_service)
    }

    if $service_name == 'USE_DEFAULTS' {
      $service_name_real = $_service_name_default
    } else {
      $service_name_real = $service_name
    }

    if $manage_service_real == true {
      # workaround for Ubuntu which does not provide the service status
      if $::operatingsystem == 'Ubuntu' {
        Service[$service_name_real] {
          hasstatus => false,
          status    => '/bin/ps -ef | /bin/grep -i "vmtoolsd" | /bin/grep -v "grep"',
        }
      }

      if ! $_use_open_vm_tools {
        if $service_provider == 'USE_DEFAULTS' {
          $service_provider_real = 'init'
        } else {
          $service_provider_real = $service_provider
        }
        if $service_path == 'USE_DEFAULTS' {
          if $::osfamily == 'Suse' or ($::osfamily == 'RedHat' and $lsbmajdistrelease_int == 5) {
            $service_path_real = '/etc/init.d/'
          } else {
            $service_path_real = '/etc/vmware-tools/init/'
          }
        } else {
          $service_path_real = $service_path
        }
        Service[$service_name_real] {
          provider => $service_provider_real,
          path     => $service_path_real,
        }
      }

      service { $service_name_real:
        ensure  => 'running',
        require => Package[$tools_nox_package_name_real],
      }
    }


    if is_bool($disable_tools_version) == true {
      $_disable_tools_version = $disable_tools_version
    } else {
      $_disable_tools_version = str2bool($disable_tools_version)
    }
    if $_disable_tools_version == true {
      $_disable_tools_version_string = 'true' # lint:ignore:quoted_booleans
    } else {
      $_disable_tools_version_string = 'false' # lint:ignore:quoted_booleans
    }

    if $enable_sync_driver == 'auto' {

      if $working_kernel_release == 'USE_DEFAULTS' {
        case $::operatingsystem {
          'RedHat', 'CentOS': {
            $_working_kernel_release = '2.6.32-358'
          }
          default: {
            $_working_kernel_release = '2.6.35-22'
          }
        }
      } else {
        $_working_kernel_release = $working_kernel_release
      }

      if (versioncmp("${::kernelrelease}", "${_working_kernel_release}") >= 0) { # lint:ignore:only_variable_string
        $_enable_sync_driver_string = 'true' # lint:ignore:quoted_booleans
      } else {
        $_enable_sync_driver_string = 'false' # lint:ignore:quoted_booleans
      }

    } else {

      if is_bool($enable_sync_driver) == true {
        $_enable_sync_driver = $enable_sync_driver
      } else {
        $_enable_sync_driver = str2bool($enable_sync_driver)
      }
      if $_enable_sync_driver == true {
        $_enable_sync_driver_string = 'true' # lint:ignore:quoted_booleans
      } else {
        $_enable_sync_driver_string = 'false' # lint:ignore:quoted_booleans
      }

    }

    file { 'vmtools_conf':
      ensure  => present,
      path    => $tools_conf_path,
      require => Package[$tools_nox_package_name_real],
    }

    $vmtools_defaults = {
      'ensure'  => present,
      'path'    => $tools_conf_path,
      'notify'  => Service[$service_name_real],
      'require' => File['vmtools_conf'],
    }
    $vmtools_settings = {
      'vmtools'  => { 'disable-tools-version' => $_disable_tools_version_string, },
      'vmbackup' => { 'enableSyncDriver'      => $_enable_sync_driver_string, },
    }
    create_ini_settings($vmtools_settings, $vmtools_defaults)
  }
}
