require 'spec_helper'
describe 'vmware' do
  # By default rspec-puppet-facts only provide facts for x86_64 architectures.
  # To be able to test Solaris we need to add 'i86pc' hardwaremodel.
  test_on = {
    hardwaremodels: ['x86_64', 'i386']
  }

  let(:specific_facts) do
    {
      esx_version: '6.0',
      virtual: 'vmware',
      vmware_has_x: 'false',
    }
  end

  on_supported_os(test_on).sort.each do |os, facts|
    context "on #{os} #{facts[:os]['release']['major']} with Facter #{facts[:facterversion]} and Puppet #{facts[:puppetversion]}" do
      let(:facts) { [facts, specific_facts].reduce(:merge) }

      it { is_expected.to compile.with_all_deps }

      case facts[:osfamily]
      when 'RedHat', 'CentOS'
        if facts[:os]['release']['major'].to_i < 7
          yumrepo_baseurl = "http://packages.vmware.com/tools/esx/latest/rhel#{facts[:os]['release']['major']}/#{facts[:os]['architecture']}"

          it do
            is_expected.to contain_yumrepo('vmware-osps').only_with(
              {
                'baseurl'  => yumrepo_baseurl,
                'descr'    => 'VMware Tools OSPs',
                'enabled'  => '1',
                'gpgcheck' => '1',
                'gpgkey'   => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
                'proxy'    => nil,
              },
            )
          end
        else
          # rubocop:disable Style/RepeatedExample
          it { is_expected.not_to contain_yumrepo('vmware-osps') }
          # rubocop:enable Style/RepeatedExample
        end
      when 'Suse'
        suse_repo_architecture = if facts[:os]['architecture'] == 'x86_64'
                                   'x86_64'
                                 else
                                   'i586'
                                 end

        if facts[:os]['release']['major'].to_i < 12
          it { is_expected.to contain_class('zypprepo') }

          # TODO: check the URL - module creates:
          # http://packages.vmware.com/tools/esx/latest/sles11.3/x86_64
          # but that is not availabel, instead this URL is available
          # https://packages.vmware.com/tools/esx/latest/sles11sp0/x86_64
          zypprepo_baseurl = "http://packages.vmware.com/tools/esx/latest/sles#{facts[:os]['release']['full']}/#{suse_repo_architecture}"
          it do
            is_expected.to contain_zypprepo('vmware-osps').only_with(
              {
                'enabled'     => '1',
                'autorefresh' => '0',
                'baseurl'     => zypprepo_baseurl,
                'path'        => '/',
                'type'        => 'yum',
                'gpgcheck'    => '1',
                'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
              },
            )
          end
        else
          # rubocop:disable Style/RepeatedExample
          it { is_expected.not_to contain_yumrepo('vmware-osps') }
          # rubocop:enable Style/RepeatedExample
        end
      when 'Debian'
        it { is_expected.not_to contain_class('apt') }
        it { is_expected.not_to contain_apt__key('vmware') }
        it { is_expected.not_to contain_apt__source('vmware-osps') }
      end

      case facts[:osfamily]
      when 'CentOS', 'RedHat'
        case facts[:os]['release']['major']
        when '7', '8'
          exec_before = ['Package[open-vm-tools]']
        else
          exec_before = ['Package[vmware-tools-esx-nox]']
        end
      when 'Suse'
        exec_before = if facts[:os]['release']['major'] == '11'
                        ['Package[vmware-tools-esx-nox]']
                      else
                        ['Package[open-vm-tools]']
                      end
      when 'Debian'
        exec_before = ['Package[open-vm-tools]']
      end

      it do
        is_expected.to contain_exec('Remove vmware tools script installation').only_with(
          {
            'path'    => '/usr/bin/:/etc/vmware-tools/',
            'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
            'command' => 'installer.sh uninstall',
            'before'  => exec_before,
          },
        )
      end

      case facts[:os]['name']
      when 'CentOS', 'RedHat'
        package = if facts[:os]['release']['major'] >= '7'
                    'open-vm-tools'
                  else
                    'vmware-tools-esx-nox'
                  end
      when 'SLES', 'SLED'
        package = if facts[:os]['release']['major'] >= '12'
                    'open-vm-tools'
                  elsif facts[:os]['release']['major'] >= '11' && facts[:os]['release']['minor'] >= '4'
                    'open-vm-tools'
                  else
                    'vmware-tools-esx-nox'
                  end
      when 'OpenSuSE'
        package = if facts[:os]['release']['major'] >= '12'
                    'open-vm-tools'
                  else
                    'vmware-tools-esx-nox'
                  end
      when 'Ubuntu'
        package = if facts[:os]['release']['major'] >= '12'
                    'open-vm-tools'
                  else
                    'vmware-tools-esx-nox'
                  end
      end

      it do
        is_expected.to contain_package(package).only_with(
          {
            'ensure' => 'present',
          },
        )
      end

      case facts[:osfamily]
      when 'CentOS', 'RedHat'
        case facts[:os]['release']['major']
        when '5', '6'
          service_name = 'vmware-tools-services'
        else
          service_name = 'vmtoolsd'
        end
      when 'Suse'
        service_name = if facts[:os]['release']['major'] == '11'
                         'vmware-tools-services'
                       else
                         'vmtoolsd'
                       end
      when 'Debian'
        service_name = 'open-vm-tools'
      end

      service_provider = if facts[:osfamily] == 'Debian'
                           'init'
                         else
                           'redhat'
                         end

      case facts[:osfamily]
      when 'CentOS', 'RedHat'
        case facts[:os]['release']['major']
        when '5', '6'
          service_require = 'Package[vmware-tools-esx-nox]'
        else
          service_require = 'Package[open-vm-tools]'
        end
      when 'Suse'
        service_require = if facts[:os]['release']['major'] == '11'
                            'Package[vmware-tools-esx-nox]'
                          else
                            'Package[open-vm-tools]'
                          end

      when 'Debian'
        service_require = 'Package[open-vm-tools]'
      end

      service_path = if facts[:os]['family'] == 'Suse'
                       '/etc/init.d'
                     elsif facts[:os]['family'] == 'RedHat'
                       if facts[:os]['release']['major'] == '5'
                         '/etc/init.d'
                       else
                         '/etc/vmware-tools/init'
                       end
                     else
                       '/etc/vmware-tools/init'
                     end

      case facts[:os]['name']
      when 'RedHat', 'CentOS'
        case facts[:os]['release']['major']
        when '5', '6'
          use_open_vm_tools = false
        else
          use_open_vm_tools = true
        end
      when 'SLES', 'SLED'
        case facts[:os]['release']['major']
        when '11'
          case facts[:os]['release']['minor']
          when '1', '2', '3'
            use_open_vm_tools = false
          else
            use_open_vm_tools = true
          end
        else
          use_open_vm_tools = true
        end
      when 'OpenSuSE'
        use_open_vm_tools = true
      when 'Ubuntu'
        use_open_vm_tools = true
      end

      case facts[:osfamily]
      when 'Debian'
        it do
          is_expected.to contain_service(service_name).with(
            {
              'ensure'    => 'running',
              'require'   => service_require,
              'hasstatus' => false,
              'status'    => '/bin/ps -ef | /bin/grep -i "vmtoolsd" | /bin/grep -v "grep"',
            },
          )
        end
      else
        if use_open_vm_tools == true
          it do
            is_expected.to contain_service(service_name).with(
              {
                # all
                'ensure'  => 'running',
                'require' => service_require,
              },
            )
          end
        else
          it do
            is_expected.to contain_service(service_name).with(
              {
                # all
                'ensure'   => 'running',
                'require'  => service_require,
                'provider' => service_provider,
                'path'     => service_path,
              },
            )
          end

        end
      end

      case facts[:osfamily]
      when 'CentOS', 'RedHat'
        case facts[:os]['release']['major']
        when '5', '6'
          file_require = 'Package[vmware-tools-esx-nox]'
        else
          file_require = 'Package[open-vm-tools]'
        end
      when 'Suse'
        file_require = if facts[:os]['release']['major'] == '11'
                         'Package[vmware-tools-esx-nox]'
                       else
                         'Package[open-vm-tools]'
                       end
      when 'Debian'
        file_require = 'Package[open-vm-tools]'
      end

      it do
        is_expected.to contain_file('vmtools_conf').only_with(
          {
            'ensure'  => 'file',
            'path'    => '/etc/vmware-tools/tools.conf',
            'require' => file_require,
          },
        )
      end

      case facts[:osfamily]
      when 'CentOS', 'RedHat'
        case facts[:os]['release']['major']
        when '5', '6'
          ini_vmbackup_notify = 'Service[vmware-tools-services]'
        else
          ini_vmbackup_notify = 'Service[vmtoolsd]'
        end
      when 'Suse'
        ini_vmbackup_notify = if facts[:os]['release']['major'] == '11'
                                'Service[vmware-tools-services]'
                              else
                                'Service[vmtoolsd]'
                              end
      when 'Debian'
        ini_vmbackup_notify = 'Service[open-vm-tools]'
      end

      it do
        is_expected.to contain_ini_setting('[vmtools] disable-tools-version').only_with(
          {
            'ensure'  => 'present',
            'path'    => '/etc/vmware-tools/tools.conf',
            'notify'  => ini_vmbackup_notify,
            'require' => 'File[vmtools_conf]',
            'section' => 'vmtools',
            'setting' => 'disable-tools-version',
            'value'   => 'true',
          },
        )
      end

      case facts[:osfamily]
      when 'CentOS', 'RedHat'
        ini_vmbackup_value = if facts[:kernelrelease] >= '2.6.32-358'
                               'true'
                             else
                               'false'
                             end
      else
        ini_vmbackup_value = if facts[:kernelrelease] >= '2.6.35-2'
                               'true'
                             else
                               'false'
                             end
      end

      it do
        is_expected.to contain_ini_setting('[vmbackup] enableSyncDriver').only_with(
          {
            'ensure'  => 'present',
            'path'    => '/etc/vmware-tools/tools.conf',
            'notify'  => ini_vmbackup_notify,
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
