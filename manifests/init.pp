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
#   Boolean to choose if repository for VMware tools should be managed.
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
#   Version of ESX (e.g. 5.1, 5.5, 5.5ep06).
#   Used together with repo_base_url and client facts to build the URL used to manage the VMware tools packages.
#   Note, it is recommended to explicitly set the ESX version rather than defaulting to latest.
#   Only used when parameter $manage_repo is active.
#
# @param manage_service
#   Boolean to choose if service for VMware tools should be managed.
#
# @param service_name
#   Service name of VMware tools to manage.
#   Only used when parameter $manage_service is active.
#
# @param service_provider
#   The specific backend to use for the VMware tools service resource.
#   It should not be necessary to use this parameter. Use at your own risk.
#   Only used when parameter $manage_service is active and OSP packages of VMware tools are used.
#   Default values:
#   - Ubuntu: init
#   - others: redhat
#
# @param service_path
#   The search path for finding init scripts of VMware tools service.
#   Only used when parameter $manage_service is active and OSP packages of VMware tools are used.
#   Default values:
#     RedHat 5: `/etc/init.d`
#     Suse: `/etc/init.d`
#     others: `/etc/vmwre-tools/init`
#
# @param prefer_open_vm_tools
#   Boolean to prefer usage of Open VM Tools over VMware OSP packages in the case that both are available.
#   Only useable on Ubuntu 12.04, other cases will be silently ignored.
#
# @param force_open_vm_tools
#   Boolean to force usage of Open VM Tools over VMware OSP packages.
#   This option is suitable in cases where EPEL is available for EL systems.
#
# @param manage_tools_nox_package
#   Boolean if VM tools packages for command line clients (NOX) should be managed.
#   If set to true VMware tools that might have been installed manually or from scripts will be removed.
#
# @param tools_nox_package_name
#   Name of package for vmwaretools nox package.
#   Only used when parameter $manage_tools_nox_package is active.
#
# @param tools_nox_package_ensure
#   String to pass to ensure attribute for the vmwaretools nox package.
#   Use 'present', 'latest' or a string with a specific version number to install or 'absent', 'purged' to remove package.
#   Only used when parameter $manage_tools_nox_package is active.
#
# @param manage_tools_x_package
#   Boolean if VM tools packages for X-Windows/GUI clients (X) should be managed.
#   If set to true VMware tools that might have been installed manually or from scripts will be removed.
#
# @param tools_x_package_name
#   Name of package for vmwaretools x package.
#   Only used when parameter $manage_tools_x_package is active.
#
# @param tools_x_package_ensure
#   String to pass to ensure attribute for the vmwaretools x package.
#   Use 'present', 'latest' or a string with a specific version number to install or 'absent', 'purged' to remove package.
#   Only used when parameter $manage_tools_x_package is active.
#
# @param tools_conf_path
#   Absolute path to vmware-tools configuration file.
#
# @param disable_tools_version
#   Disable tools version reporting to vSphere.
#
# @param enable_sync_driver
#   Enable vmtools sync driver on snapshots.  Use `undef` to automatically enable on non-buggy systems or set to `true` or `false`
#   to override.
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
#   Used for module default values only. If you want to enforce using VMware OSP tools/packages, use $tools_nox_package_name and
#   $tools_x_package_name instead.
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
  Stdlib::Absolutepath $tools_conf_path               = '/etc/vmware-tools/tools.conf',
  Optional[Boolean]    $enable_sync_driver            = undef,
  Variant[Enum['absent', 'latest', 'present', 'purged'], Pattern[/(\d+\.)+([\d-]+)/]] $tools_nox_package_ensure = 'present',
  Variant[Enum['absent', 'latest', 'present', 'purged'], Pattern[/(\d+\.)+([\d-]+)/]] $tools_x_package_ensure   = 'present',
) {
  if $facts['virtual'] == 'vmware' {
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
    $enable_sync_driver_real     = pick($enable_sync_driver,     versioncmp($facts['kernelrelease'], $working_kernel_release) >= 0)
    # remove trailing slash (if present) from $service_path for backward compatibility
    $_service_path_real = regsubst($service_path,'/$', '')

    case $facts['vmware_has_x'] {
      true:    { $manage_tools_x_package_real = pick($manage_tools_x_package, true) }
      default: { $manage_tools_x_package_real = pick($manage_tools_x_package, false) }
    }

    if $manage_repo_real == true {
      class { "vmware::repo::${facts['os']['family']}".downcase():
        repo_base_url => $repo_base_url,
        gpgkey_url    => $gpgkey_url,
        esx_version   => $esx_version,
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
      if $facts['os']['name'] == 'Ubuntu' {
        Service[$service_name_real] {
          hasstatus => false,
          status    => '/bin/ps -ef | /bin/grep -i "vmtoolsd" | /bin/grep -v "grep"',
        }
      }

      if $_use_open_vm_tools == false {
        # For non-Ubuntu systems we need to specify the location of of the scripts
        # to ensure the start script is found on the non-standard locations.
        if $facts['os']['name'] != 'Ubuntu' {
          Service[$service_name_real] {
            start  => "${_service_path_real}/vmware-tools-services start",
            stop   => "${_service_path_real}/vmware-tools-services stop",
            status => "${_service_path_real}/vmware-tools-services status",
          }
        }
        Service[$service_name_real] {
          provider => $service_provider,
          path     => $_service_path_real,
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
    inifile::create_ini_settings($vmtools_settings, $vmtools_defaults)
  }
}
