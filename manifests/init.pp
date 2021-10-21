# Manage installation of VMware Tools and related options.
# Will remove vmware tools that has been installed from script if present.
# Will use open-vm-tools by default on RHEL 7+, SUSE 12+, and Ubuntu 12+,
# for all other the default is VMware OSP packages.
#
# @summary Manage installation of VMware Tools and related options.
#
# @example install VMware tools with all default settings
#   class { 'vmware': }
#
# @param manage_repo
#   If repo file should be managed.
#
# @param repo_base_url
#   Base URL of mirror of packages.vmware.com/tools/esx.
#
# @param manage_service
#   If vmwaretools service should be managed.
#
# @param service_name
#   Service name to manage.
#
# @param service_provider
#   Service provider, based on package type, `service` for open-vm-tools, `init` for OSP.
#
# @param service_path
#   Path to service init files. Only applicable for `init` service provider.
#   Default values:
#     RedHat 5: `/etc/init.d/`
#     Suse: `/etc/init.d/`
#     others: `/etc/vmwre-tools/init/`
#
# @param esx_version
#   Version of ESX (e.g. 5.1, 5.5, 5.5ep06). Note, it is recommended to explicitly set the esx version rather than default to latest.
#
# @param gpgkey_url
#   URL for VMware GPG key. Defaults to http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub.
#
# @param proxy_host
#   Hostname of web proxy (not supported on SUSE).
#
# @param proxy_port
#   Port number of web proxy.
#
# @param prefer_open_vm_tools
#   Prefer open-vm-tools over vmware-tools in the case that both are available (e.g. Ubuntu 12.04).
#
# @param force_open_vm_tools
#   Force open-vm-tools over vmware-tools. Using this option is suitable in cases where EPEL is available for EL systems.
#
# @param manage_tools_nox_package
#   If vmwaretools nox package should be managed.
#
# @param tools_nox_package_name
#   Name of package for vmwaretools nox package.
#
# @param tools_nox_package_ensure
#   String to pass to ensure attribute for the vmwaretools nox package.
#
# @param manage_tools_x_package
#   If vmwaretools x package should be managed.
#
# @param tools_x_package_name
#   Name of package for vmwaretools x package.
#
# @param tools_x_package_ensure
#   String to pass to ensure attribute for the vmwaretools x package.
#
# @param tools_conf_path
#   Path to vmware-tools configuration file.
#
# @param disable_tools_version
#   Disable tools version reporting to vSphere.
#
# @param enable_sync_driver
#   Enable vmtools sync driver on snapshots.  `true`, `false`, `auto` to enable on non-buggy systems.
#   See KB2038606 (http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2038606)
#   https://access.redhat.com/solutions/484303
#
# @param working_kernel_release
#   First non-buggy kernel version for sync driver.
#
class vmware (
  Stdlib::Absolutepath $service_path,
  String[1]            $working_kernel_release,
  $manage_repo               = 'USE_DEFAULTS',
  $repo_base_url             = 'http://packages.vmware.com/tools/esx',
  $esx_version               = 'latest',
  $gpgkey_url                = 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
  $proxy_host                = 'absent',
  $proxy_port                = 8080,
  $prefer_open_vm_tools      = true,
  $force_open_vm_tools       = false,
  $manage_service            = true,
  $service_name              = 'USE_DEFAULTS',
  $service_provider          = 'USE_DEFAULTS',
  $manage_tools_nox_package  = true,
  $manage_tools_x_package    = 'USE_DEFAULTS',
  $tools_nox_package_name    = 'USE_DEFAULTS',
  $tools_x_package_name      = 'USE_DEFAULTS',
  $tools_nox_package_ensure  = 'present',
  $tools_x_package_ensure    = 'present',
  $tools_conf_path           = '/etc/vmware-tools/tools.conf',
  $disable_tools_version     = true,
  $enable_sync_driver        = 'auto',
){

  # variable preparation
  $proxy_port_int = floor($proxy_port)
  $prefer_open_vm_tools_bool = str2bool($prefer_open_vm_tools)
  $force_open_vm_tools_bool = str2bool($force_open_vm_tools)
  $manage_service_bool = str2bool($manage_service)
  $manage_tools_nox_package_bool = str2bool($manage_tools_nox_package)
  $disable_tools_version_bool = str2bool($disable_tools_version)
  $vmware_has_x_bool = str2bool($::vmware_has_x)

  # variable validations
  if is_integer($proxy_port_int) == false { fail('vmware::proxy_port is not an integer') }

  if is_string($repo_base_url)            == false { fail('vmware::repo_base_url is not a string') }
  if is_string($gpgkey_url)               == false { fail('vmware::gpgkey_url is not a string') }
  if is_string($proxy_host)               == false { fail('vmware::proxy_host is not a string') }
  if is_string($service_name)             == false { fail('vmware::service_name is not a string') }
  if is_string($tools_nox_package_ensure) == false { fail('vmware::tools_nox_package_ensure is not a string') }
  if is_string($tools_nox_package_name)   == false { fail('vmware::tools_nox_package_name is not a string') }
  if is_string($tools_x_package_ensure)   == false { fail('vmware::tools_x_package_ensure is not a string') }
  if is_string($tools_x_package_name)     == false { fail('vmware::tools_x_package_name is not a string') }

  # esx_version can contain strings like '6.0' which is_string() falsely classifies as integer. So we use validate_string() instead
  validate_string($esx_version)

  validate_absolute_path($tools_conf_path)

  $osrelease_array = split($::operatingsystemrelease, '\.')
  $osmajrelease_int = 0 + $osrelease_array[0]

  if $::virtual == 'vmware' {

    if $force_open_vm_tools_bool == true {
      $_use_open_vm_tools = true
    } else {
      # OSs that have open-vm-tools
      case $::operatingsystem {
        'RedHat', 'CentOS': {
          $_use_open_vm_tools = $osmajrelease_int >= 7
        }
        'SLED', 'SLES': {
          $osminrelease_int = 0 + $osrelease_array[1]
          if $osmajrelease_int >= 12 {
            $_use_open_vm_tools = true
          } elsif $osmajrelease_int >= 11 and $osminrelease_int >= 4 {
            $_use_open_vm_tools = true
          }
          else {
            $_use_open_vm_tools = false
          }
        }
        'OpenSuSE': {
          $_use_open_vm_tools = $osmajrelease_int >= 12
        }
        'Ubuntu': {
          if $prefer_open_vm_tools_bool == true {
            # include Ubuntu 12.04
            $_use_open_vm_tools = $osmajrelease_int >= 12
          } else {
            # skip Ubuntu 12.04
            $_use_open_vm_tools = $osmajrelease_int > 12
          }
        }
        default: {
            fail("The vmware module is not supported on ${::operatingsystem}")
        }
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
          if $osmajrelease_int > 14 {
            $_tools_x_package_name_default = 'open-vm-tools-desktop'
          } else {
            $_tools_x_package_name_default = 'open-vm-toolbox'
          }
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
        $manage_repo_bool = false
      } else {
        $manage_repo_bool = true
      }
    } else {
      $manage_repo_bool = str2bool($manage_repo)
    }

    if $vmware_has_x_bool == true and $manage_tools_x_package == 'USE_DEFAULTS' {
      $manage_tools_x_package_bool = true
    } elsif $vmware_has_x_bool == false and $manage_tools_x_package == 'USE_DEFAULTS' {
      $manage_tools_x_package_bool = false
    } else {
      $manage_tools_x_package_bool = str2bool($manage_tools_x_package)
    }

    if $manage_repo_bool == true {

      case $::operatingsystem {
        'RedHat', 'CentOS': {

          if $proxy_host == 'absent' {
            $_proxy = undef
          } else {
            $_proxy = "http://${proxy_host}:${proxy_port_int}"
          }

          yumrepo { 'vmware-osps':
            baseurl  => "${repo_base_url}/${esx_version}/rhel${osmajrelease_int}/${::architecture}",
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

    if $manage_tools_nox_package_bool == true or $manage_tools_x_package_bool == true {
      exec { 'Remove vmware tools script installation':
        path    => '/usr/bin/:/etc/vmware-tools/',
        onlyif  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        command => 'installer.sh uninstall',
      }
      if $manage_tools_nox_package_bool == true {
        Exec['Remove vmware tools script installation'] -> Package[$tools_nox_package_name_real]
      }
      if $manage_tools_x_package_bool == true {
        Exec['Remove vmware tools script installation'] -> Package[$tools_x_package_name_real]
      }
    }

    if $manage_tools_nox_package_bool == true {
      package { $tools_nox_package_name_real:
        ensure => $tools_nox_package_ensure,
      }
      $_require_manage_tools_nox_package = "Package[${tools_nox_package_name_real}]"
    }
    else {
      $_require_manage_tools_nox_package = undef
    }

    if $manage_tools_x_package_bool == true {
      package { $tools_x_package_name_real:
        ensure => $tools_x_package_ensure,
      }
    }

    if $service_name == 'USE_DEFAULTS' {
      $service_name_real = $_service_name_default
    } else {
      $service_name_real = $service_name
    }

    if $manage_service_bool == true {
      $_notify_ini_setting = "Service[${service_name_real}]"
      # workaround for Ubuntu which does not provide the service status
      if $::operatingsystem == 'Ubuntu' {
        Service[$service_name_real] {
          hasstatus => false,
          status    => '/bin/ps -ef | /bin/grep -i "vmtoolsd" | /bin/grep -v "grep"',
        }
      }

      if ! $_use_open_vm_tools {
        if $service_provider == 'USE_DEFAULTS' {
          if $::operatingsystem == 'Ubuntu' {
            $service_provider_real = 'init'
          } else {
            # Default to redhat
            $service_provider_real = 'redhat'
          }
        } else {
          $service_provider_real = $service_provider
        }
        # For non-Ubuntu systems we need to specify the location of of the scripts
        # to ensure the start script is found on the non-standard locations.
        if $::operatingsystem != 'Ubuntu' {
          Service[$service_name_real] {
            start  =>  "${service_path}${_service_name_default} start",
            stop   =>  "${service_path}${_service_name_default} stop",
            status =>  "${service_path}${_service_name_default} status",
          }
        }
        Service[$service_name_real] {
          provider => $service_provider_real,
          path     => $service_path,
        }
      }

      service { $service_name_real:
        ensure  => 'running',
        require => $_require_manage_tools_nox_package,
      }
    }
    else {
      $_notify_ini_setting = undef
    }

    if $disable_tools_version_bool == true {
      $_disable_tools_version_bool = true
    } else {
      $_disable_tools_version_bool = false
    }

    if $enable_sync_driver == 'auto' {
      if (versioncmp("${::kernelrelease}", "${working_kernel_release}") >= 0) { # lint:ignore:only_variable_string
        $_enable_sync_driver_bool = true
      } else {
        $_enable_sync_driver_bool = false
      }

    } else {
      $_enable_sync_driver_bool = str2bool($enable_sync_driver)
    }

    file { 'vmtools_conf':
      ensure  => file,
      path    => $tools_conf_path,
      require => $_require_manage_tools_nox_package,
    }

    $vmtools_defaults = {
      'ensure'  => present,
      'path'    => $tools_conf_path,
      'notify'  => $_notify_ini_setting,
      'require' => File['vmtools_conf'],
    }
    $vmtools_settings = {
      'vmtools'  => { 'disable-tools-version' => bool2str($_disable_tools_version_bool), },
      'vmbackup' => { 'enableSyncDriver'      => bool2str($_enable_sync_driver_bool), },
    }
    create_ini_settings($vmtools_settings, $vmtools_defaults)
  }
}
