require 'spec_helper'
require 'spec_functions'

describe 'vmware' do
  # By default rspec-puppet-facts only provide facts for x86_64 architectures.
  all = {
    hardwaremodels: ['x86_64', 'i386']
  }

  # test only the latest version of each OS family
  latest = {
    supported_os: [
      {
        'operatingsystem'        => 'CentOS',
        'operatingsystemrelease' => ['8'],
      },
      {
        'operatingsystem'        => 'RedHat',
        'operatingsystemrelease' => ['8'],
      },
      {
        'operatingsystem'        => 'SLES',
        'operatingsystemrelease' => ['15'],
      },
      {
        'operatingsystem'        => 'Ubuntu',
        'operatingsystemrelease' => ['20.04'],
      },
    ],
  }

  redhat = {
    supported_os: [
      {
        'operatingsystem'        => 'RedHat',
        'operatingsystemrelease' => ['5', '6', '7', '8'],
      },
      {
        'operatingsystem'        => 'CentOS',
        'operatingsystemrelease' => ['5', '6', '7', '8'],
      },
    ],
  }

  suse11 = {
    supported_os: [
      {
        'operatingsystem'        => 'SLES',
        'operatingsystemrelease' => ['11'],
      },
    ],
  }

  ubuntu = {
    supported_os: [
      {
        'operatingsystem'        => 'Ubuntu',
        'operatingsystemrelease' => ['12.04', '14.04', '16.04', '18.04', '20.04'],
      },
    ],
  }

  on_supported_os(all).sort.each do |os, facts|
    # these function calls mimic the hiera data, they are sourced in from spec/spec_functions.rb
    default_open_vm_tools_exist = default_open_vm_tools_exist(facts)
    service_name = service_name(facts)
    service_path = service_path(facts)
    service_provider = service_provider(facts)
    tools_nox_package_name = tools_nox_package_name(facts)
    tools_x_package_name = tools_x_package_name(facts)
    working_kernel_release = working_kernel_release(facts)

    context "on #{os} with Facter #{facts[:facterversion]} and Puppet #{facts[:puppetversion]} with module default values" do
      [true, false].each do |has_x|
        context "when X is installed is #{has_x}" do
          let(:facts) { facts.merge({ vmware_has_x: has_x }) }

          it { is_expected.to compile.with_all_deps }

          # repository management
          case facts[:os]['family']
          when 'RedHat', 'CentOS'
            if default_open_vm_tools_exist == false

              it do
                is_expected.to contain_class('vmware::repo::redhat').only_with(
                  {
                    'repo_base_url' => 'http://packages.vmware.com/tools/esx',
                    'gpgkey_url'    => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
                    'esx_version'   => 'latest',
                  },
                )
              end

              it do
                is_expected.to contain_yumrepo('vmware-osps').only_with(
                  {
                    'baseurl'  => "http://packages.vmware.com/tools/esx/latest/rhel#{facts[:os]['release']['major']}/#{facts[:os]['architecture']}",
                    'descr'    => 'VMware Tools OSPs',
                    'enabled'  => '1',
                    'gpgcheck' => '1',
                    'gpgkey'   => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
                    'proxy'    => nil,
                  },
                )
              end
            else
              it { is_expected.not_to contain_yumrepo('vmware-osps') }
            end
          when 'Suse'
            if default_open_vm_tools_exist == false
              suse_repo_architecture = if facts[:os]['architecture'] == 'x86_64'
                                         'x86_64'
                                       else
                                         'i586'
                                       end

              it { is_expected.to contain_class('zypprepo') }

              # TODO: check the URL - module creates:
              # http://packages.vmware.com/tools/esx/latest/sles11.3/x86_64
              # but that is not availabel, instead this URL is available
              # https://packages.vmware.com/tools/esx/latest/sles11sp0/x86_64
              it do
                is_expected.to contain_class('vmware::repo::suse').only_with(
                  {
                    'repo_base_url' => 'http://packages.vmware.com/tools/esx',
                    'gpgkey_url'    => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
                    'esx_version'   => 'latest',
                  },
                )
              end

              it do
                is_expected.to contain_zypprepo('vmware-osps').only_with(
                  {
                    'enabled'     => '1',
                    'autorefresh' => '0',
                    'baseurl'     => "http://packages.vmware.com/tools/esx/latest/sles#{facts[:os]['release']['full']}/#{suse_repo_architecture}",
                    'path'        => '/',
                    'type'        => 'yum',
                    'gpgcheck'    => '1',
                    'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
                  },
                )
              end
            else
              it { is_expected.not_to contain_zypprepo('vmware-osps') }
            end
          when 'Debian'
            it { is_expected.not_to contain_class('vmware::repo::debian') }
            it { is_expected.not_to contain_class('apt') }
            it { is_expected.not_to contain_apt__key('vmware') }
            it { is_expected.not_to contain_apt__source('vmware-osps') }
          end

          # package management
          if has_x == true
            it { is_expected.to contain_package(tools_x_package_name).only_with_ensure('present') }
            # rubocop:disable Style/RepeatedExample
            it { is_expected.to contain_package(tools_nox_package_name).only_with_ensure('present') }
            # rubocop:enable Style/RepeatedExample

            it do
              is_expected.to contain_exec('Remove vmware tools script installation').only_with(
                {
                  'path'    => '/usr/bin/:/etc/vmware-tools/',
                  'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                  'command' => 'installer.sh uninstall',
                  'before'  => [ "Package[#{tools_nox_package_name}]", "Package[#{tools_x_package_name}]" ],
                },
              )
            end
          else
            it { is_expected.not_to contain_package(tools_x_package_name) }
            # rubocop:disable Style/RepeatedExample
            it { is_expected.to contain_package(tools_nox_package_name).only_with_ensure('present') }
            # rubocop:enable Style/RepeatedExample

            it do
              is_expected.to contain_exec('Remove vmware tools script installation').only_with(
                {
                  'path'    => '/usr/bin/:/etc/vmware-tools/',
                  'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                  'command' => 'installer.sh uninstall',
                  'before'  => [ "Package[#{tools_nox_package_name}]" ],
                },
              )
            end
          end

          # service management
          case facts[:os]['family']
          when 'Debian'
            if default_open_vm_tools_exist == true
              it do
                is_expected.to contain_service(service_name).only_with(
                  {
                    'hasstatus' => false,
                    'status'    => '/bin/ps -ef | /bin/grep -i "vmtoolsd" | /bin/grep -v "grep"',
                    'ensure'    => 'running',
                    'require'   => "Package[#{tools_nox_package_name}]",
                  },
                )
              end
            else
              it do
                is_expected.to contain_service(service_name).only_with(
                  {
                    'hasstatus' => false,
                    'status'    => '/bin/ps -ef | /bin/grep -i "vmtoolsd" | /bin/grep -v "grep"',
                    'provider'  => service_provider,
                    'path'      => service_path,
                    'ensure'    => 'running',
                    'require'   => "Package[#{tools_nox_package_name}]",
                  },
                )
              end
            end
          else
            if default_open_vm_tools_exist == true
              it do
                is_expected.to contain_service(service_name).only_with(
                  {
                    'ensure'  => 'running',
                    'require' => "Package[#{tools_nox_package_name}]",
                  },
                )
              end
            else
              it do
                is_expected.to contain_service(service_name).only_with(
                  {
                    'start'    => "#{service_path}/vmware-tools-services start",
                    'stop'     => "#{service_path}/vmware-tools-services stop",
                    'status'   => "#{service_path}/vmware-tools-services status",
                    'provider' => service_provider,
                    'path'     => service_path,
                    'ensure'   => 'running',
                    'require'  => "Package[#{tools_nox_package_name}]",
                  },
                )
              end

            end
          end

          # configuration management
          it do
            is_expected.to contain_file('vmtools_conf').only_with(
              {
                'ensure'  => 'file',
                'path'    => '/etc/vmware-tools/tools.conf',
                'require' => "Package[#{tools_nox_package_name}]",
              },
            )
          end

          it do
            is_expected.to contain_ini_setting('/etc/vmware-tools/tools.conf [vmtools] disable-tools-version').only_with(
              {
                'ensure'  => 'present',
                'path'    => '/etc/vmware-tools/tools.conf',
                'notify'  => "Service[#{service_name}]",
                'require' => 'File[vmtools_conf]',
                'section' => 'vmtools',
                'setting' => 'disable-tools-version',
                'value'   => 'true',
              },
            )
          end

          ini_vmbackup_value = if facts[:kernelrelease] >= working_kernel_release
                                 'true'
                               else
                                 'false'
                               end

          it do
            is_expected.to contain_ini_setting('/etc/vmware-tools/tools.conf [vmbackup] enableSyncDriver').only_with(
              {
                'ensure'  => 'present',
                'path'    => '/etc/vmware-tools/tools.conf',
                'notify'  => "Service[#{service_name}]",
                'require' => 'File[vmtools_conf]',
                'section' => 'vmbackup',
                'setting' => 'enableSyncDriver',
                'value'   => ini_vmbackup_value,
              },
            )
          end
        end
      end
    end
  end

  # test parameters
  on_supported_os(latest).sort.each do |os, facts|
    context "on #{os} with manage_repo set to true" do
      let(:facts) { facts.merge({ vmware_has_x: true }) }
      let(:params) { { manage_repo: true } }

      it do
        is_expected.to contain_class("vmware::repo::#{facts[:os]['family'].downcase}").only_with(
          {
            'repo_base_url' => 'http://packages.vmware.com/tools/esx',
            'gpgkey_url'    => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
            'esx_version'   => 'latest',
          },
        )
      end

      case facts[:os]['family']
      when 'RedHat'
        it do
          is_expected.to contain_yumrepo('vmware-osps').only_with(
            {
              'baseurl'  => 'http://packages.vmware.com/tools/esx/latest/rhel8/x86_64',
              'descr'    => 'VMware Tools OSPs',
              'enabled'  => 1,
              'gpgcheck' => 1,
              'gpgkey'   => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
            },
          )
        end
      when 'Suse'
        it { is_expected.to contain_class('zypprepo') }
        it do
          is_expected.to contain_zypprepo('vmware-osps').only_with(
            {
              'enabled'     => 1,
              'autorefresh' => 0,
              'baseurl'     => 'http://packages.vmware.com/tools/esx/latest/sles15.2/x86_64',
              'path'        => '/',
              'type'        => 'yum',
              'gpgcheck'    => 1,
              'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
            },
          )
        end
      when 'Debian'
        it { is_expected.to contain_class('apt') }
        it do
          is_expected.to contain_apt__key('vmware').with(
            {
              'id'     => 'C0B5E0AB66FD4949',
              'source' => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
            },
          )
        end
        it do
          is_expected.to contain_apt__source('vmware-osps').with(
            {
              'location' => 'http://packages.vmware.com/tools/esx/latest/ubuntu',
              'release'  => 'focal',
              'repos'    => 'main',
              'include'  => {
                'src' => false,
              },
            },
          )
        end
      end
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    context "on #{os} with manage_repo set to false" do
      let(:facts) { facts }
      let(:params) { { manage_repo: false } }

      it { is_expected.not_to contain_class("vmware::repo::#{facts[:os]['family'].downcase}") }

      case facts[:os]['family']
      when 'RedHat'
        it { is_expected.not_to contain_yumrepo('vmware-osps') }
      when 'Suse'
        it { is_expected.not_to contain_class('zypprepo') }
        it { is_expected.not_to contain_zypprepo('vmware-osps') }
      when 'Debian'
        it { is_expected.not_to contain_class('apt') }
        it { is_expected.not_to contain_apt__key('vmware') }
        it { is_expected.not_to contain_apt__source('vmware-osps') }
      end
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    context "on #{os} with service_name set to test and manage_repo set to true" do
      let(:facts) { facts }
      let(:params) do
        {
          manage_repo:  true,
          service_name: 'test',
        }
      end

      it { is_expected.to contain_service('test') }
      it { is_expected.to contain_ini_setting('/etc/vmware-tools/tools.conf [vmbackup] enableSyncDriver').with_notify('Service[test]') }
      it { is_expected.to contain_ini_setting('/etc/vmware-tools/tools.conf [vmtools] disable-tools-version').with_notify('Service[test]') }
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    tools_nox_package_name = tools_nox_package_name(facts)
    tools_x_package_name = tools_x_package_name(facts)

    context "on #{os} with manage_tools_x_package set to true" do
      let(:facts) { facts }
      let(:params) { { manage_tools_x_package: true } }

      it { is_expected.to contain_package(tools_x_package_name) }
      it { is_expected.to contain_exec('Remove vmware tools script installation').with_before([ "Package[#{tools_nox_package_name}]", "Package[#{tools_x_package_name}]" ]) }
    end

    context "on #{os} with manage_tools_x_package set to false" do
      let(:facts) { facts }
      let(:params) { { manage_tools_x_package: false } }

      it { is_expected.not_to contain_package(tools_x_package_name) }
      it { is_expected.to contain_exec('Remove vmware tools script installation').with_before([ "Package[#{tools_nox_package_name}]" ]) }
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    service_name = service_name(facts)

    context "on #{os} with tools_nox_package_name set to test" do
      let(:facts) { facts }
      let(:params) { { tools_nox_package_name: 'nox_package' } }

      it { is_expected.to contain_package('nox_package') }
      it { is_expected.to contain_exec('Remove vmware tools script installation').with_before([ 'Package[nox_package]' ]) }
      it { is_expected.to contain_service(service_name).with_require('Package[nox_package]') }
      it { is_expected.to contain_file('vmtools_conf').with_require('Package[nox_package]') }
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    tools_nox_package_name = tools_nox_package_name(facts)

    context "on #{os} with tools_x_package_name set to test when manage_tools_x_package is true" do
      let(:facts) { facts }
      let(:params) do
        {
          tools_x_package_name:   'x_package',
          manage_tools_x_package: true
        }
      end

      it { is_expected.to contain_package('x_package') }
      it { is_expected.to contain_exec('Remove vmware tools script installation').with_before([ "Package[#{tools_nox_package_name}]", 'Package[x_package]' ]) }
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    context "on #{os} with repo_base_url set to https://test.tld when manage_repo is true" do
      let(:facts) { facts }
      let(:params) do
        {
          repo_base_url: 'https://test.tld',
          manage_repo:    true
        }
      end

      it { is_expected.to contain_class("vmware::repo::#{facts[:os]['family'].downcase}").with_repo_base_url('https://test.tld') }

      case facts[:os]['family']
      when 'RedHat'
        it { is_expected.to contain_yumrepo('vmware-osps').with_baseurl('https://test.tld/latest/rhel8/x86_64') }
      when 'Suse'
        it { is_expected.to contain_zypprepo('vmware-osps').with_baseurl('https://test.tld/latest/sles15.2/x86_64') }
      when 'Debian'
        it { is_expected.to contain_apt__source('vmware-osps').with_location('https://test.tld/latest/ubuntu') }
      end
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    context "on #{os} with gpgkey_url set to https://test.tld/test.pub when manage_repo is true" do
      let(:facts) { facts }
      let(:params) do
        {
          gpgkey_url:  'https://test.tld/test.pub',
          manage_repo: true
        }
      end

      it { is_expected.to contain_class("vmware::repo::#{facts[:os]['family'].downcase}").with_gpgkey_url('https://test.tld/test.pub') }

      case facts[:os]['family']
      when 'RedHat'
        it { is_expected.to contain_yumrepo('vmware-osps').with_gpgkey('https://test.tld/test.pub') }
      when 'Suse'
        it { is_expected.to contain_zypprepo('vmware-osps').with_gpgkey('https://test.tld/test.pub') }
      when 'Debian'
        it { is_expected.to contain_apt__key('vmware').with_source('https://test.tld/test.pub') }
      end
    end
  end

  on_supported_os(ubuntu).sort.each do |os, facts|
    tools_x_package_name = tools_x_package_name(facts)

    context "on #{os} with prefer_open_vm_tools set to false when manage_tools_x_package is true" do
      let(:facts) { facts.merge({ vmware_has_x: true }) }
      let(:params) do
        {
          prefer_open_vm_tools:   false,
          manage_tools_x_package: true,
        }
      end

      if facts[:os]['release']['full'] == '12.04'
        it { is_expected.not_to contain_package('open-vm-tools') }
        it { is_expected.to contain_package('vmware-tools-esx') }
        it { is_expected.to contain_package('vmware-tools-esx-nox') }
        it { is_expected.to contain_class('vmware::repo::debian') }
        it { is_expected.to contain_apt__key('vmware') }
        it { is_expected.to contain_apt__source('vmware-osps') }
        it { is_expected.to contain_exec('Remove vmware tools script installation').with_before(['Package[vmware-tools-esx-nox]', 'Package[vmware-tools-esx]']) }
        it { is_expected.to contain_service('vmware-tools-services') }
      else
        it { is_expected.to contain_package('open-vm-tools') }
        it { is_expected.not_to contain_package('vmware-tools-esx') }
        it { is_expected.not_to contain_package('vmware-tools-esx-nox') }
        it { is_expected.not_to contain_class('vmware::repo::debian') }
        it { is_expected.not_to contain_apt__key('vmware') }
        it { is_expected.not_to contain_apt__source('vmware-osps') }
        it { is_expected.to contain_exec('Remove vmware tools script installation').with_before([ 'Package[open-vm-tools]', "Package[#{tools_x_package_name}]" ]) }
        it { is_expected.not_to contain_service('vmware-tools-services') }
      end
    end
  end

  on_supported_os(all).sort.each do |os, facts|
    default_open_tools_x_package = default_open_tools_x_package(facts)

    context "on #{os} with force_open_vm_tools set to true when manage_tools_x_package is true" do
      let(:facts) { facts.merge({ vmware_has_x: true }) }
      let(:params) do
        {
          force_open_vm_tools:    true,
          manage_tools_x_package: true,
        }
      end

      it { is_expected.to contain_package('open-vm-tools') }
      it { is_expected.not_to contain_package('vmware-tools-esx') }
      it { is_expected.not_to contain_package('vmware-tools-esx-nox') }
      it { is_expected.not_to contain_class('vmware::repo::debian') }
      it { is_expected.not_to contain_apt__key('vmware') }
      it { is_expected.not_to contain_apt__source('vmware-osps') }
      it { is_expected.to contain_exec('Remove vmware tools script installation').with_before([ 'Package[open-vm-tools]', "Package[#{default_open_tools_x_package}]" ]) }
      it { is_expected.not_to contain_service('vmware-tools-services') }
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    service_name = service_name(facts)

    context "on #{os} with manage_service set to false" do
      let(:facts) { facts }
      let(:params) { { manage_service: false } }

      it { is_expected.not_to contain_service(service_name) }
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    tools_nox_package_name = tools_nox_package_name(facts)

    context "on #{os} with manage_tools_nox_package set to false" do
      let(:facts) { facts }
      let(:params) { { manage_tools_nox_package: false } }

      it { is_expected.not_to contain_package(tools_nox_package_name) }
      it { is_expected.not_to contain_exec('Remove vmware tools script installation') }
      it { is_expected.not_to contain_service('vmware-tools-services') }
      # vmtools_conf  must not contain the nox package as dependency
      it { is_expected.to contain_file('vmtools_conf').with_require(nil) }
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    context "on #{os} with esx_version set to 2.42 when manage_repo is true" do
      let(:facts) { facts }
      let(:params) do
        {
          esx_version: '2.42',
          manage_repo: true,
        }
      end

      it { is_expected.to contain_class("vmware::repo::#{facts[:os]['family'].downcase}").with_esx_version('2.42') }

      case facts[:os]['family']
      when 'RedHat'
        it { is_expected.to contain_yumrepo('vmware-osps').with_baseurl("http://packages.vmware.com/tools/esx/2.42/rhel#{facts[:os]['release']['major']}/#{facts[:os]['architecture']}") }
      when 'Suse'
        it { is_expected.to contain_zypprepo('vmware-osps').with_baseurl("http://packages.vmware.com/tools/esx/2.42/sles#{facts[:os]['release']['full']}/x86_64") }
      when 'Debian'
        it { is_expected.to contain_apt__source('vmware-osps').with_location('http://packages.vmware.com/tools/esx/2.42/ubuntu') }
      end
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    context "on #{os} with tools_conf_path set to /etc/test" do
      let(:facts) { facts }
      let(:params) { { tools_conf_path: '/etc/test' } }

      it { is_expected.to contain_file('vmtools_conf').with_path('/etc/test') }
      it { is_expected.to contain_ini_setting('/etc/test [vmtools] disable-tools-version').with_path('/etc/test') }
      it { is_expected.to contain_ini_setting('/etc/test [vmbackup] enableSyncDriver').with_path('/etc/test') }
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    [true, false].each do |value|
      context "on #{os} with disable_tools_version set to #{value}" do
        let(:facts) { facts }
        let(:params) { { disable_tools_version: value } }

        it { is_expected.to contain_ini_setting('/etc/vmware-tools/tools.conf [vmtools] disable-tools-version').with_value(value.to_s) }
      end
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    [true, false].each do |value|
      context "on #{os} with enable_sync_driver set to #{value}" do
        let(:facts) { facts }
        let(:params) { { enable_sync_driver: value } }

        it { is_expected.to contain_ini_setting('/etc/vmware-tools/tools.conf [vmbackup] enableSyncDriver').with_value(value.to_s) }
      end
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    tools_nox_package_name = tools_nox_package_name(facts)

    ['absent', 'latest', 'present', 'purged', '2.4.2'].each do |value|
      context "on #{os} with tools_nox_package_ensure set to #{value}" do
        let(:facts) { facts }
        let(:params) { { tools_nox_package_ensure: value } }

        it { is_expected.to contain_package(tools_nox_package_name).only_with_ensure(value) }
      end
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    tools_x_package_name = tools_x_package_name(facts)

    ['absent', 'latest', 'present', 'purged', '2.4.2'].each do |value|
      context "on #{os} with tools_x_package_ensure set to #{value} when manage_tools_x_package is true" do
        let(:facts) { facts }
        let(:params) do
          {
            tools_x_package_ensure: value,
            manage_tools_x_package: true,
          }
        end

        it { is_expected.to contain_package(tools_x_package_name).only_with_ensure(value) }
      end
    end
  end

  # testing open-vm-tools existence and naming on different OS versions
  on_supported_os(all).sort.each do |os, facts|
    default_open_tools_x_package = default_open_tools_x_package(facts)
    default_open_vm_tools_exist = default_open_vm_tools_exist(facts)
    default_service_name_open = default_service_name_open(facts)

    context "on #{os} open tools are available is #{default_open_vm_tools_exist}" do
      let(:facts) { facts }
      let(:params) { { manage_tools_x_package: true } }

      if default_open_vm_tools_exist == true
        it { is_expected.to contain_package('open-vm-tools') }
        it { is_expected.to contain_package(default_open_tools_x_package) }
        it { is_expected.to contain_service(default_service_name_open) }
      else
        it { is_expected.to contain_package('vmware-tools-esx') }
        it { is_expected.to contain_package('vmware-tools-esx-nox') }
        it { is_expected.to contain_service('vmware-tools-services') }
      end
    end
  end

  describe 'on Suse open-vm-tools are available since 11.4' do
    on_supported_os(suse11).sort.each do |_os, facts|
      context 'on Suse 11.3 VMware OPS are used' do
        # need to specify all (at least needed) values for os hash to be available after merge()
        suse113 = {
          os: {
            architecture: 'x86_64',
            family: 'Suse',
            name: 'SLED',
            release: {
              full: '11.3',
              major: '11',
              minor: '3',
            }
          }
        }

        let(:facts) { facts.merge(suse113) }
        let(:params) { { manage_tools_x_package: true } }

        # open-vm-tools
        it { is_expected.not_to contain_package('open-vm-tools') }
        it { is_expected.not_to contain_package('open-vm-tools-desktop') }
        it { is_expected.not_to contain_service('vmtoolsd') }
        # VMware OPS
        it { is_expected.to contain_class('vmware::repo::suse') }
        it { is_expected.to contain_zypprepo('vmware-osps') }
        it { is_expected.to contain_package('vmware-tools-esx-nox') }
        it { is_expected.to contain_package('vmware-tools-esx') }
        it { is_expected.to contain_service('vmware-tools-services') }
      end
    end

    on_supported_os(suse11).sort.each do |_os, facts|
      context 'on Suse 11.4 open-vm-tools are used' do
        # need to specify all (at least needed) values for os hash to be available after merge()
        suse114 = {
          os: {
            architecture: 'x86_64',
            family: 'Suse',
            name: 'SLED',
            release: {
              full: '11.4',
              major: '11',
              minor: '4',
            }
          }
        }

        let(:facts) { facts.merge(suse114) }
        let(:params) { { manage_tools_x_package: true } }

        # open-vm-tools
        it { is_expected.to contain_package('open-vm-tools') }
        it { is_expected.to contain_package('open-vm-tools-desktop') }
        it { is_expected.to contain_service('vmtoolsd').with_require('Package[open-vm-tools]') }
        # VMware OPS
        it { is_expected.not_to contain_class('vmware::repo::suse') }
        it { is_expected.not_to contain_zypprepo('vmware-osps') }
        it { is_expected.not_to contain_package('vmware-tools-esx-nox') }
        it { is_expected.not_to contain_package('vmware-tools-esx') }
        it { is_expected.not_to contain_service('vmware-tools-services') }
      end
    end
  end

  describe 'on RedHat open-vm-tools are available since 7' do
    on_supported_os(redhat).sort.each do |os, facts|
      context "on #{os}" do
        let(:facts) { facts }
        let(:params) { { manage_tools_x_package: true } }

        if facts[:os]['release']['major'].to_i < 7
          # open-vm-tools
          it { is_expected.not_to contain_package('open-vm-tools') }
          it { is_expected.not_to contain_package('open-vm-tools-desktop') }
          it { is_expected.not_to contain_service('vmtoolsd') }
          # VMware OPS
          it { is_expected.to contain_class('vmware::repo::redhat') }
          it { is_expected.to contain_yumrepo('vmware-osps') }
          it { is_expected.to contain_package('vmware-tools-esx-nox') }
          it { is_expected.to contain_package('vmware-tools-esx') }
          it { is_expected.to contain_service('vmware-tools-services') }
        else
          # open-vm-tools
          it { is_expected.to contain_package('open-vm-tools') }
          it { is_expected.to contain_package('open-vm-tools-desktop') }
          it { is_expected.to contain_service('vmtoolsd') }
          # VMware OPS
          it { is_expected.not_to contain_class('vmware::repo::redhat') }
          it { is_expected.not_to contain_yumrepo('vmware-osps') }
          it { is_expected.not_to contain_package('vmware-tools-esx-nox') }
          it { is_expected.not_to contain_package('vmware-tools-esx') }
          it { is_expected.not_to contain_service('vmware-tools-services') }
        end
      end
    end
  end

  on_supported_os(latest).sort.each do |os, facts|
    default_service_name_open = default_service_name_open(facts)
    context "on #{os} the service name is #{default_service_name_open}" do
      let(:facts) { facts }
      let(:params) { { manage_service: true } }

      it { is_expected.to contain_service(default_service_name_open) }
    end
  end
end
