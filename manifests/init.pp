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
#   !!!FIXME!!! Description is wrong
#   Service provider, based on package type, `service` for open-vm-tools, `init` for OSP.
#   Default values:
#   - Ubuntu: init
#   - others: redhat
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
#   Enable vmtools sync driver on snapshots.  Use `undef` to automatically enable on non-buggy systems or set to `true` or `false` to override.
#   See KB2038606 (http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2038606)
#   https://access.redhat.com/solutions/484303
#
# @param working_kernel_release
#   First non-buggy kernel version for sync driver.
#
# @param default_service_name_open
#   Used for default values only. If you want to specifiy the service name use $service_name instead.
#   Default service name for open source VM tools. which is used when open source VM tools are available.
#   Defaults values:
#   - Ubuntu: open-vm-tools
#   - others: vmtoolsd
#
# @param default_open_vm_tools_exist
#   Used for module default values only. If you want to enforce using VMware OSP tools/packages, use $tools_nox_package_name and $tools_x_package_name instead.
#   OS specific defaults if open source VM tools are available.
#   Default value is `true` with exceptions for the following OS versions:
#   - RedHat 6 and older: `false`
#   - SLED/SLES 11.3 and older: `false`
#   - OpenSuSE 11: `false`
#
# @param default_open_tools_x_package
#   Used for modules default values only. If you want to specify the package name use $tools_x_package_name instead.
#   OS specific defaults for the package name of open source VMware tools.
#   Default values:
#   - OpenSuSE: `open-vm-tools-gui`
#   - Ubuntu 14.04 and below: `open-vm-toolbox`
#   - others: `open-vm-tools-desktop`
#
class vmware (
  Stdlib::Absolutepath $service_path,
  String[1]            $working_kernel_release,
  String[1]            $service_provider,
  String[1]            $default_service_name_open,
  String[1]            $default_open_tools_x_package,
  Boolean              $default_open_vm_tools_exist,
  Optional[Boolean]    $manage_repo                   = undef,
  Optional[String[1]]  $service_name                  = undef,
  Optional[Boolean]    $manage_tools_x_package        = undef,
  Optional[String[1]]  $tools_nox_package_name        = undef,
  Optional[String[1]]  $tools_x_package_name          = undef,
  Stdlib::HTTPUrl      $repo_base_url                 = 'http://packages.vmware.com/tools/esx',
  Stdlib::HTTPUrl      $gpgkey_url                    = 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
  Boolean              $prefer_open_vm_tools          = true,
  Boolean              $force_open_vm_tools           = false,
  Boolean              $manage_service                = true,
  Boolean              $manage_tools_nox_package      = true,
  Boolean              $disable_tools_version         = true,
  String[1]            $esx_version                   = 'latest',
  Optional[Boolean]    $proxy_host                    = undef,
  Integer[0, 65535]    $proxy_port                    = 8080,
  String[1]            $tools_nox_package_ensure      = 'present',
  String[1]            $tools_x_package_ensure        = 'present',
  Stdlib::Absolutepath $tools_conf_path               = '/etc/vmware-tools/tools.conf',
  Optional[Boolean]    $enable_sync_driver            = undef,
){

  if $::virtual == 'vmware' {
    if $force_open_vm_tools == true {
      $_use_open_vm_tools = true
    } elsif $prefer_open_vm_tools == false and "${facts['os']['name']}-${facts['os']['release']['major']}" == 'Ubuntu-12.04' {
      $_use_open_vm_tools = false
    } else {
      $_use_open_vm_tools = $default_open_vm_tools_exist
    }

    if $_use_open_vm_tools == true {
      $_tools_nox_package_name_default = 'open-vm-tools'
      $_tools_x_package_name_default   = $default_open_tools_x_package
      $manage_repo_real                = pick($manage_repo, false)
      $service_name_real               = pick($service_name, $default_service_name_open)
    } else { # assume vmware-tools exists for OS
      $_tools_nox_package_name_default = 'vmware-tools-esx-nox'
      $_tools_x_package_name_default   = 'vmware-tools-esx'
      $manage_repo_real                = pick($manage_repo, true)
      $service_name_real               = pick($service_name, 'vmware-tools-services')
    }

    $tools_nox_package_name_real = pick($tools_nox_package_name, $_tools_nox_package_name_default)
    $tools_x_package_name_real   = pick($tools_x_package_name,   $_tools_x_package_name_default)
    $enable_sync_driver_real     = pick($enable_sync_driver,     versioncmp($::kernelrelease, $working_kernel_release) >= 0)

    case $::vmware_has_x {
      true:    { $manage_tools_x_package_real = pick($manage_tools_x_package, true) }
      default: { $manage_tools_x_package_real = pick($manage_tools_x_package, false) }
    }

    if $manage_repo_real == true {
      case $::operatingsystem {
        'RedHat', 'CentOS': {
          if $proxy_host == undef {
            $_proxy = undef
          } else {
            $_proxy = "http://${proxy_host}:${proxy_port}"
          }

          yumrepo { 'vmware-osps':
            baseurl  => "${repo_base_url}/${esx_version}/rhel${facts['os']['release']['major']}/${::architecture}",
            descr    => 'VMware Tools OSPs',
            enabled  => 1,
            gpgcheck => 1,
            gpgkey   => $gpgkey_url,
            proxy    => $_proxy,
          }
        }
        'SLED', 'SLES', 'OpenSuSE': {
          include ::zypprepo

          if $proxy_host != undef {
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
        default: {
          fail("The vmware module is not supported on ${::operatingsystem}")
        }
      }
    }

    if $manage_tools_nox_package == true {
      package { $tools_nox_package_name_real:
        ensure => $tools_nox_package_ensure,
      }
      Exec['Remove vmware tools script installation'] -> Package[$tools_nox_package_name_real]
      $_require_manage_tools_nox_package = "Package[${tools_nox_package_name_real}]"
    } else {
      $_require_manage_tools_nox_package = undef
    }

    if $manage_tools_x_package_real == true {
      package { $tools_x_package_name_real:
        ensure => $tools_x_package_ensure,
      }
      Exec['Remove vmware tools script installation'] -> Package[$tools_x_package_name_real]
    }

    if $manage_tools_nox_package == true or $manage_tools_x_package_real == true {
      exec { 'Remove vmware tools script installation':
        path    => '/usr/bin/:/etc/vmware-tools/',
        onlyif  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        command => 'installer.sh uninstall',
      }
    }

    if $manage_service == true {
      $_notify_ini_setting = "Service[${service_name_real}]"
      # workaround for Ubuntu which does not provide the service status
      if $::operatingsystem == 'Ubuntu' {
        Service[$service_name_real] {
          hasstatus => false,
          status    => '/bin/ps -ef | /bin/grep -i "vmtoolsd" | /bin/grep -v "grep"',
        }
      }

      if ! $_use_open_vm_tools {
        # For non-Ubuntu systems we need to specify the location of of the scripts
        # to ensure the start script is found on the non-standard locations.
        if $::operatingsystem != 'Ubuntu' {
          Service[$service_name_real] {
            start  =>  "${service_path}vmware-tools-services start",
            stop   =>  "${service_path}vmware-tools-services stop",
            status =>  "${service_path}vmware-tools-services status",
          }
        }
        Service[$service_name_real] {
          provider => $service_provider,
          path     => $service_path,
        }
      }

      service { $service_name_real:
        ensure  => 'running',
        require => $_require_manage_tools_nox_package,
      }
    } else {
      $_notify_ini_setting = undef
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
      'vmtools'  => { 'disable-tools-version' => bool2str($disable_tools_version), },
      'vmbackup' => { 'enableSyncDriver'      => bool2str($enable_sync_driver_real), },
    }
    create_ini_settings($vmtools_settings, $vmtools_defaults)
  }
}
