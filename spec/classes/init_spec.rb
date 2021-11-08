require 'spec_helper'
describe 'vmware' do
  let(:default_facts) do
    {
      virtual: 'vmware',
      vmware_has_x: false,
      kernelrelease: '2.6.32-431.11.2.el6.x86_64',
      os: {
        architecture: 'x86_64',
        family: 'RedHat',
        name: 'RedHat',
        release: {
          full: '6.0',
          major: '6',
          minor: '0',
        }
      }
    }
  end
  let(:facts) { default_facts }

  describe 'with defaults for all parameters on machine running on vmware' do
    context 'on machine without X installed' do
      it { is_expected.to contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }
      it { is_expected.not_to contain_package('vmware-tools-esx') }
      it do
        is_expected.to contain_exec('Remove vmware tools script installation').with({
                                                                                      'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                                                                                    })
      end
      it do
        is_expected.to contain_class('vmware::repo::redhat').only_with(
          {
            'repo_base_url' => 'http://packages.vmware.com/tools/esx',
            'gpgkey_url'    => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
            'esx_version'   => 'latest',
            'proxy_host'    => nil,
            'proxy_port'    => '8080',
          },
        )
      end
      it do
        is_expected.to contain_yumrepo('vmware-osps').with({
                                                             'baseurl' => 'http://packages.vmware.com/tools/esx/latest/rhel6/x86_64',
          'enabled'  => '1',
          'gpgcheck' => '1',
          'gpgkey'   => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
          'proxy'    => nil,
                                                           })
      end
      it do
        is_expected.to contain_service('vmware-tools-services').with({
                                                                       'ensure'   => 'running',
          'require'  => 'Package[vmware-tools-esx-nox]',
          'provider' => 'redhat',
          'path'     => '/etc/vmware-tools/init',
          'start'    => '/etc/vmware-tools/init/vmware-tools-services start',
          'stop'     => '/etc/vmware-tools/init/vmware-tools-services stop',
          'status'   => '/etc/vmware-tools/init/vmware-tools-services status',
                                                                     })
      end
    end

    context 'on machine with X installed' do
      let(:facts) { [default_facts, { vmware_has_x: true }].reduce(:merge) }

      it { is_expected.to contain_package('vmware-tools-esx').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters on RHEL 5 running on vmware' do
    context 'on machine without X installed' do
      specific_facts = {
        kernelrelease: '2.6.18-400.1.1.el5',
        os: {
          architecture: 'x86_64',
          family: 'RedHat',
          release: {
            full: '5.0',
            major: '5',
            minor: '0',
          }
        }

      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.not_to contain_package('open-vm-tools') }
      it { is_expected.not_to contain_package('open-vm-tools-desktop') }
      it { is_expected.to contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }
      it { is_expected.not_to contain_package('vmware-tools-esx') }
      it do
        is_expected.to contain_exec('Remove vmware tools script installation').with({
                                                                                      'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                                                                                    })
      end
      it do
        is_expected.to contain_class('vmware::repo::redhat').only_with(
          {
            'repo_base_url' => 'http://packages.vmware.com/tools/esx',
            'gpgkey_url'    => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
            'esx_version'   => 'latest',
            'proxy_host'    => nil,
            'proxy_port'    => '8080',
          },
        )
      end
      it do
        is_expected.to contain_yumrepo('vmware-osps').with({
                                                             'enabled' => '1',
          'baseurl'     => 'http://packages.vmware.com/tools/esx/latest/rhel5/x86_64',
          'gpgcheck'    => '1',
          'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
                                                           })
      end
      it do
        is_expected.to contain_service('vmware-tools-services').with({
                                                                       'ensure'   => 'running',
          'require'  => 'Package[vmware-tools-esx-nox]',
          'provider' => 'redhat',
          'path'     => '/etc/init.d',
          'start'    => '/etc/init.d/vmware-tools-services start',
          'stop'     => '/etc/init.d/vmware-tools-services stop',
          'status'   => '/etc/init.d/vmware-tools-services status',
                                                                     })
      end
    end

    context 'on machine with X installed' do
      specific_facts = {
        vmware_has_x: true,
        kernelrelease: '2.6.18.2-34-default',
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters except force_open_vm_tools => true on RHEL 6 running on vmware' do
    context 'on machine without X installed' do
      let(:params) { { force_open_vm_tools: true } }

      it { is_expected.not_to contain_package('vmware-tools-esx-nox') }
      it { is_expected.not_to contain_package('vmware-tools-esx') }

      it { is_expected.to contain_package('open-vm-tools') }
      it { is_expected.not_to contain_package('open-vm-tools-desktop').with('ensure' => 'present') }

      it do
        is_expected.to contain_exec('Remove vmware tools script installation').with({
                                                                                      'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                                                                                    })
      end
      it do
        is_expected.to contain_service('vmtoolsd').with({
                                                          'ensure' => 'running',
          'require' => 'Package[open-vm-tools]',
                                                        })
      end
    end

    context 'on machine with X installed' do
      let(:facts) { [default_facts, { vmware_has_x: true }].reduce(:merge) }
      let(:params) { { force_open_vm_tools: true } }

      it { is_expected.to contain_package('open-vm-tools').with('ensure' => 'present') }
      it { is_expected.to contain_package('open-vm-tools-desktop').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters on RHEL 7 running on vmware' do
    context 'on machine without X installed' do
      specific_facts = {
        kernelrelease: '3.10.0-123.9.2.el7.x86_64',
        os: {
          family: 'RedHat',
          release: {
            full: '7.0',
            major: '7',
            minor: '0',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('open-vm-tools').with('ensure' => 'present') }
      it { is_expected.not_to contain_package('open-vm-tools-desktop') }

      it { is_expected.not_to contain_package('vmware-tools-esx-nox') }
      it { is_expected.not_to contain_package('vmware-tools-esx') }
      it do
        is_expected.to contain_exec('Remove vmware tools script installation').with({
                                                                                      'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                                                                                    })
      end
      it { is_expected.not_to contain_yumrepo('vmware-osps') }
      it do
        is_expected.to contain_service('vmtoolsd').with({
                                                          'ensure'  => 'running',
          'require' => 'Package[open-vm-tools]',
                                                        })
      end
      it { is_expected.not_to contain_service('vmtoolsd').with('provider' => 'init') }
    end

    context 'on machine with X installed' do
      specific_facts = {
        kernelrelease: '3.10.0-123.9.2.el7.x86_64',
        vmware_has_x: true,
        os: {
          family: 'RedHat',
          release: {
            full: '7.0',
            major: '7',
            minor: '0',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('open-vm-tools-desktop').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters on SLES 10 running on vmware' do
    context 'on machine without X installed' do
      specific_facts = {
        kernelrelease: '2.6.18.2-34-default',
        os: {
          architecture: 'x86_64',
          family: 'Suse',
          name: 'SLES',
          release: {
            full: '10.2',
            major: '10',
            minor: '2',
          }
        }
      }

      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.not_to contain_package('open-vm-tools') }
      it { is_expected.not_to contain_package('open-vm-tools-desktop') }

      it { is_expected.to contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }
      it { is_expected.not_to contain_package('vmware-tools-esx') }
      it do
        is_expected.to contain_exec('Remove vmware tools script installation').with({
                                                                                      'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                                                                                    })
      end
      it do
        is_expected.to contain_class('vmware::repo::suse').only_with(
          {
            'repo_base_url' => 'http://packages.vmware.com/tools/esx',
            'gpgkey_url'    => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
            'esx_version'   => 'latest',
            'proxy_host'    => nil,
            'proxy_port'    => '8080',
          },
        )
      end
      it do
        is_expected.to contain_zypprepo('vmware-osps').with({
                                                              'enabled'     => '1',
          'autorefresh' => '0',
          'baseurl'     => 'http://packages.vmware.com/tools/esx/latest/sles10/x86_64',
          'path'        => '/',
          'type'        => 'yum',
          'gpgcheck'    => '1',
          'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
                                                            })
      end
      it do
        is_expected.to contain_service('vmware-tools-services').with({
                                                                       'ensure'   => 'running',
          'require'  => 'Package[vmware-tools-esx-nox]',
          'provider' => 'redhat',
          'path'     => '/etc/init.d',
          'start'    => '/etc/init.d/vmware-tools-services start',
          'stop'     => '/etc/init.d/vmware-tools-services stop',
          'status'   => '/etc/init.d/vmware-tools-services status',

                                                                     })
      end
    end

    context 'on machine with X installed' do
      specific_facts = {
        kernelrelease: '2.6.18.2-34-default',
        vmware_has_x: true,
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters on SLED 11.4 running on vmware' do
    context 'on machine without X installed' do
      specific_facts = {
        kernelrelease: '3.0.101-63-default',
        os: {
          family: 'Suse',
          name: 'SLED',
          release: {
            full: '11.4',
            major: '11',
            minor: '4',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('open-vm-tools').with('ensure' => 'present') }
      it { is_expected.not_to contain_package('open-vm-tools-desktop') }
      it { is_expected.not_to contain_package('vmware-tools-esx-nox') }
      it { is_expected.not_to contain_package('vmware-tools-esx') }
      it do
        is_expected.to contain_exec('Remove vmware tools script installation').with({
                                                                                      'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                                                                                    })
      end
      it { is_expected.not_to contain_yumrepo('vmware-osps') }
      it do
        is_expected.to contain_service('vmtoolsd').with({
                                                          'ensure'  => 'running',
          'require' => 'Package[open-vm-tools]',
                                                        })
      end
      it { is_expected.not_to contain_service('vmtoolsd').with('provider' => 'init') }
    end

    context 'on machine with X installed' do
      specific_facts = {
        kernelrelease: '3.0.101-63-default',
        vmware_has_x: true,
        os: {
          family: 'Suse',
          name: 'SLED',
          release: {
            full: '11.4',
            major: '11',
            minor: '4',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('open-vm-tools-desktop').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters on SLED 12 running on vmware' do
    context 'on machine without X installed' do
      specific_facts = {
        kernelrelease: '3.10.0-123.9.2.el7.x86_64',
        os: {
          family: 'Suse',
          name: 'SLED',
          release: {
            full: '12.0',
            major: '12',
            minor: '0',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('open-vm-tools').with('ensure' => 'present') }
      it { is_expected.not_to contain_package('open-vm-tools-desktop') }

      it { is_expected.not_to contain_package('vmware-tools-esx-nox') }
      it { is_expected.not_to contain_package('vmware-tools-esx') }
      it do
        is_expected.to contain_exec('Remove vmware tools script installation').with({
                                                                                      'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                                                                                    })
      end
      it { is_expected.not_to contain_yumrepo('vmware-osps') }
      it do
        is_expected.to contain_service('vmtoolsd').with({
                                                          'ensure'  => 'running',
          'require' => 'Package[open-vm-tools]',
                                                        })
      end
      it { is_expected.not_to contain_service('vmtoolsd').with('provider' => 'init') }
    end

    context 'on machine with X installed' do
      specific_facts = {
        kernelrelease: '3.10.0-123.9.2.el7.x86_64',
        vmware_has_x: true,
        os: {
          family: 'Suse',
          name: 'SLED',
          release: {
            full: '12.0',
            major: '12',
            minor: '0',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('open-vm-tools-desktop').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters on SLES 11 running on vmware' do
    context 'on machine without X installed' do
      specific_facts = {
        kernelrelease: '3.0.13-0.27.1',
        os: {
          architecture: 'x86_64',
          family: 'Suse',
          name: 'SLES',
          release: {
            full: '11.2',
            major: '11',
            minor: '2',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.not_to contain_package('open-vm-tools') }
      it { is_expected.not_to contain_package('open-vm-tools-desktop') }

      it { is_expected.to contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }
      it { is_expected.not_to contain_package('vmware-tools-esx') }
      it do
        is_expected.to contain_exec('Remove vmware tools script installation').with({
                                                                                      'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                                                                                    })
      end
      it do
        is_expected.to contain_class('vmware::repo::suse').only_with(
          {
            'repo_base_url' => 'http://packages.vmware.com/tools/esx',
            'gpgkey_url'    => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
            'esx_version'   => 'latest',
            'proxy_host'    => nil,
            'proxy_port'    => '8080',
          },
        )
      end
      it do
        is_expected.to contain_zypprepo('vmware-osps').with({
                                                              'enabled'     => '1',
          'autorefresh' => '0',
          'baseurl'     => 'http://packages.vmware.com/tools/esx/latest/sles11.2/x86_64',
          'path'        => '/',
          'type'        => 'yum',
          'gpgcheck'    => '1',
          'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
                                                            })
      end
      it do
        is_expected.to contain_service('vmware-tools-services').with({
                                                                       'ensure'   => 'running',
          'require'  => 'Package[vmware-tools-esx-nox]',
          'provider' => 'redhat',
          'path'     => '/etc/init.d',
          'start'    => '/etc/init.d/vmware-tools-services start',
          'stop'     => '/etc/init.d/vmware-tools-services stop',
          'status'   => '/etc/init.d/vmware-tools-services status',
                                                                     })
      end
    end

    context 'on machine with X installed' do
      specific_facts = {
        kernelrelease: '3.0.13-0.27.1',
        vmware_has_x: true,
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }
    end

    context 'with esx_version = 6.0, x86_64' do
      specific_facts = {
        os: {
          architecture: 'x86_64',
          family: 'Suse',
          name: 'SLES',
          release: {
            full: '11.2',
            major: '11',
            minor: '2',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }
      let(:params) { { esx_version: '6.0' } }

      it do
        is_expected.to contain_class('vmware::repo::suse').only_with(
          {
            'repo_base_url' => 'http://packages.vmware.com/tools/esx',
            'gpgkey_url'    => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
            'esx_version'   => '6.0',
            'proxy_host'    => nil,
            'proxy_port'    => '8080',
          },
        )
      end
      it do
        is_expected.to contain_zypprepo('vmware-osps').with({
                                                              'enabled'     => '1',
          'autorefresh' => '0',
          'baseurl'     => 'http://packages.vmware.com/tools/esx/6.0/sles11sp2/x86_64',
          'path'        => '/',
          'type'        => 'yum',
          'gpgcheck'    => '1',
          'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
                                                            })
      end
    end

    context 'with esx_version < 6.0, x86_64' do
      specific_facts = {
        os: {
          architecture: 'x86_64',
          family: 'Suse',
          name: 'SLES',
          release: {
            full: '11.2',
            major: '11',
            minor: '2',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }
      let(:params) { { esx_version: '5.5latest' } }

      it do
        is_expected.to contain_class('vmware::repo::suse').only_with(
          {
            'repo_base_url' => 'http://packages.vmware.com/tools/esx',
            'gpgkey_url'    => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
            'esx_version'   => '5.5latest',
            'proxy_host'    => nil,
            'proxy_port'    => '8080',
          },
        )
      end
      it do
        is_expected.to contain_zypprepo('vmware-osps').with({
                                                              'enabled'     => '1',
          'autorefresh' => '0',
          'baseurl'     => 'http://packages.vmware.com/tools/esx/5.5latest/sles11.2/x86_64',
          'path'        => '/',
          'type'        => 'yum',
          'gpgcheck'    => '1',
          'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
                                                            })
      end
    end

    context 'with esx_version < 6.0, i386' do
      specific_facts = {
        os: {
          architecture: 'i386',
          family: 'Suse',
          name: 'SLES',
          release: {
            full: '11.2',
            major: '11',
            minor: '2',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }
      let(:params) { { esx_version: '5.5latest' } }

      it do
        is_expected.to contain_class('vmware::repo::suse').only_with(
          {
            'repo_base_url' => 'http://packages.vmware.com/tools/esx',
            'gpgkey_url'    => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
            'esx_version'   => '5.5latest',
            'proxy_host'    => nil,
            'proxy_port'    => '8080',
          },
        )
      end
      it do
        is_expected.to contain_zypprepo('vmware-osps').with({
                                                              'enabled'     => '1',
          'autorefresh' => '0',
          'baseurl'     => 'http://packages.vmware.com/tools/esx/5.5latest/sles11.2/i586',
          'path'        => '/',
          'type'        => 'yum',
          'gpgcheck'    => '1',
          'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
                                                            })
      end
    end
  end

  describe 'with defaults for all parameters on OpenSuSE 12 running on vmware' do
    context 'on machine without X installed' do
      specific_facts = {
        kernelrelease: '3.12.28-4.6',
        os: {
          family: 'Suse',
          name: 'OpenSuSE',
          release: {
            full: '12.0',
            major: '12',
            minor: '0',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('open-vm-tools').with('ensure' => 'present') }
      it { is_expected.not_to contain_package('open-vm-tools-desktop') }

      it { is_expected.not_to contain_package('vmware-tools-esx-nox') }
      it { is_expected.not_to contain_package('vmware-tools-esx') }
      it do
        is_expected.to contain_exec('Remove vmware tools script installation').with({
                                                                                      'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                                                                                    })
      end
      it { is_expected.not_to contain_zypprepo('vmware-osps') }
      it { is_expected.to contain_service('vmtoolsd').with('ensure' => 'running') }
      it { is_expected.not_to contain_service('vmtoolsd').with('provider' => 'init') }
    end

    context 'on machine with X installed' do
      specific_facts = {
        kernelrelease: '3.12.28-4.6',
        vmware_has_x: true,
        os: {
          family: 'Suse',
          name: 'OpenSuSE',
          release: {
            full: '12.0',
            major: '12',
            minor: '0',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('open-vm-tools-gui').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters on Ubuntu 12.04 running on vmware' do
    context 'on machine without X installed' do
      specific_facts = {
        kernelrelease: '3.2.0-23-generic',
        os: {
          family: 'Debian',
          name: 'Ubuntu',
          release: {
            full: '12.04',
            major: '12.04',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('open-vm-tools').with('ensure' => 'present') }
      it { is_expected.not_to contain_package('open-vm-toolbox') }

      it { is_expected.not_to contain_package('vmware-tools-esx-nox') }
      it { is_expected.not_to contain_package('vmware-tools-esx') }
      it do
        is_expected.to contain_exec('Remove vmware tools script installation').with({
                                                                                      'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                                                                                    })
      end
      it { is_expected.not_to contain_class('apt') }
      it do
        is_expected.to contain_service('open-vm-tools').with({
                                                               'ensure' => 'running',
          'hasstatus' => 'false',
          'status'    => '/bin/ps -ef | /bin/grep -i "vmtoolsd" | /bin/grep -v "grep"',
                                                             })
      end
      it { is_expected.not_to contain_service('vmtoolsd').with('provider' => 'init') }
    end

    context 'on machine with X installed' do
      specific_facts = {
        kernelrelease: '3.2.0-23-generic',
        vmware_has_x: true,
        os: {
          family: 'Debian',
          name: 'Ubuntu',
          release: {
            full: '12.04',
            major: '12.04',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('open-vm-toolbox').with('ensure' => 'present') }
    end

    context 'with prefer_open_vm_tools = false' do
      specific_facts = {
        kernelrelease: '3.2.0-23-generic',
        lsbdistid: 'ubuntu',  # needed for apt
        lsbdistcodename: 'precise', # needed for apt
        os: {
          family: 'Debian',
          name: 'Ubuntu',
          release: {
            full: '12.04',
            major: '12.04',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }
      let(:params) { { prefer_open_vm_tools: false } }

      it { is_expected.not_to contain_package('open-vm-tools') }
      it { is_expected.not_to contain_package('open-vm-toolbox') }

      it { is_expected.to contain_package('vmware-tools-esx-nox') }
      it { is_expected.not_to contain_package('vmware-tools-esx') }
      it do
        is_expected.to contain_exec('Remove vmware tools script installation').with({
                                                                                      'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                                                                                    })
      end

      it do
        is_expected.to contain_class('vmware::repo::debian').only_with(
          {
            'repo_base_url' => 'http://packages.vmware.com/tools/esx',
            'gpgkey_url'    => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
            'esx_version'   => 'latest',
            'proxy_host'    => nil,
            'proxy_port'    => '8080',
          },
        )
      end
      it do
        is_expected.to contain_apt__key('vmware').with(
          {
            'key'        => 'C0B5E0AB66FD4949',
            'key_source' => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
          },
        )
      end
      it do
        is_expected.to contain_apt__source('vmware-osps').with({
                                                                 'location' => 'http://packages.vmware.com/tools/esx/latest/ubuntu',
          'release'     => 'precise',
          'repos'       => 'main',
          'include_src' => false,
                                                               })
      end
      it do
        is_expected.to contain_service('vmware-tools-services').with({
                                                                       'ensure'   => 'running',
          'require'  => 'Package[vmware-tools-esx-nox]',
          'provider' => 'init',
          'path'     => '/etc/vmware-tools/init',
          'status'   => '/bin/ps -ef | /bin/grep -i "vmtoolsd" | /bin/grep -v "grep"',
                                                                     })
      end
    end
  end

  context 'with custom values for parameters on machine running on vmware' do
    let(:facts) { [default_facts, { vmware_has_x: true }].reduce(:merge) }
    let(:params) do
      {
        tools_nox_package_name: 'vmware-tools-esx-nox-custom',
        tools_nox_package_ensure: '0.2-1',
        tools_x_package_name: 'vmware-tools-esx-custom',
        tools_x_package_ensure: '0.3-1',
      }
    end

    it { is_expected.to contain_package('vmware-tools-esx-nox-custom').with('ensure' => '0.2-1') }
    it { is_expected.to contain_package('vmware-tools-esx-custom').with('ensure' => '0.3-1') }
  end

  context 'with managing the x package on a machine without x' do
    let(:params) do
      {
        manage_tools_x_package: true,
        tools_x_package_name: 'vmware-tools-esx-custom',
        tools_x_package_ensure: '0.5-1',
      }
    end

    it { is_expected.to contain_package('vmware-tools-esx-custom').with('ensure' => '0.5-1') }
  end

  context 'without managing packages' do
    let(:params) do
      {
        manage_tools_nox_package: false,
        manage_tools_x_package: false,
      }
    end

    it { is_expected.not_to contain_package('vmware-tools-esx') }
    it { is_expected.not_to contain_package('vmware-tools-esx-nox') }
    it { is_expected.not_to contain_exec('Remove vmware tools script installation') }
    it do
      is_expected.to contain_service('vmware-tools-services').with({
                                                                     'ensure' => 'running',
        'require'  => nil,
        'provider' => 'redhat',
        'path'     => '/etc/vmware-tools/init',
                                                                   })
    end
  end

  context 'on a machine that does not run on vmware' do
    let(:facts) { [default_facts, { virtual: 'physical' }].reduce(:merge) }

    it { is_expected.not_to contain_package('vmware-tools-esx') }
    it { is_expected.not_to contain_package('vmware-tools-esx-nox') }
    it { is_expected.not_to contain_exec('Remove vmware tools script installation') }
    it { is_expected.not_to contain_service('vmware-tools-services') }
  end

  describe 'with defaults for all parameters on Ubuntu 16.04 running on vmware' do
    context 'on machine without X installed' do
      specific_facts = {
        kernelrelease: '4.4.0-166-generic',
        os: {
          family: 'Debian',
          name: 'Ubuntu',
          release: {
            full: '16.04',
            major: '16.04',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('open-vm-tools').with('ensure' => 'present') }
      it { is_expected.not_to contain_package('open-vm-toolbox') }

      it { is_expected.not_to contain_package('vmware-tools-esx-nox') }
      it { is_expected.not_to contain_package('vmware-tools-esx') }
      it do
        is_expected.to contain_exec('Remove vmware tools script installation').with({
                                                                                      'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
                                                                                    })
      end
      it { is_expected.not_to contain_class('apt') }
      it do
        is_expected.to contain_service('open-vm-tools').with({
                                                               'ensure' => 'running',
          'hasstatus' => 'false',
          'status'    => '/bin/ps -ef | /bin/grep -i "vmtoolsd" | /bin/grep -v "grep"',
                                                             })
      end
      it { is_expected.not_to contain_service('vmtoolsd').with('provider' => 'init') }
    end

    context 'on machine with X installed' do
      specific_facts = {
        kernelrelease: '4.4.0-166-generic',
        vmware_has_x: true,
        os: {
          family: 'Debian',
          name: 'Ubuntu',
          release: {
            full: '16.04',
            major: '16.04',
          }
        }
      }
      let(:facts) { [default_facts, specific_facts].reduce(:merge) }

      it { is_expected.to contain_package('open-vm-tools-desktop').with('ensure' => 'present') }
    end
  end

  context 'managing tools.conf on RHEL6' do
    context 'with defaults' do
      it do
        is_expected.to contain_file('vmtools_conf').with({
                                                           'ensure'  => 'file',
          'path'    => '/etc/vmware-tools/tools.conf',
          'require' => 'Package[vmware-tools-esx-nox]',
                                                         })
      end
      it do
        is_expected.to contain_ini_setting('[vmtools] disable-tools-version').with({
                                                                                     'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmtools',
          'value'   => 'true',
          'notify'  => %r{Service\[vmware-tools-services\]},
          'require' => 'File[vmtools_conf]',
                                                                                   })
      end
      it do
        is_expected.to contain_ini_setting('[vmbackup] enableSyncDriver').with({
                                                                                 'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmbackup',
          'value'   => 'true',
          'notify'  => %r{Service\[vmware-tools-services\]},
          'require' => 'File[vmtools_conf]',
                                                                               })
      end
    end

    context 'with true' do
      let(:params) do
        {
          tools_conf_path: '/path/to/file',
          disable_tools_version: true,
          enable_sync_driver: true,
        }
      end

      it do
        is_expected.to contain_file('vmtools_conf').with({
                                                           'ensure'  => 'file',
          'path'    => '/path/to/file',
          'require' => 'Package[vmware-tools-esx-nox]',
                                                         })
      end
      it do
        is_expected.to contain_ini_setting('[vmtools] disable-tools-version').with({
                                                                                     'ensure'  => 'present',
          'path'    => '/path/to/file',
          'section' => 'vmtools',
          'value'   => 'true',
          'notify'  => %r{Service\[vmware-tools-services\]},
          'require' => 'File[vmtools_conf]',
                                                                                   })
      end
      it do
        is_expected.to contain_ini_setting('[vmbackup] enableSyncDriver').with({
                                                                                 'ensure'  => 'present',
          'path'    => '/path/to/file',
          'section' => 'vmbackup',
          'value'   => 'true',
          'notify'  => %r{Service\[vmware-tools-services\]},
          'require' => 'File[vmtools_conf]',
                                                                               })
      end
    end
    context 'with false' do
      let(:params) do
        {
          disable_tools_version: false,
          enable_sync_driver: false,
        }
      end

      it do
        is_expected.to contain_file('vmtools_conf').with({
                                                           'ensure'  => 'file',
          'path'    => '/etc/vmware-tools/tools.conf',
          'require' => 'Package[vmware-tools-esx-nox]',
                                                         })
      end
      it do
        is_expected.to contain_ini_setting('[vmtools] disable-tools-version').with({
                                                                                     'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmtools',
          'value'   => 'false',
          'notify'  => %r{Service\[vmware-tools-services\]},
          'require' => 'File[vmtools_conf]',
                                                                                   })
      end
      it do
        is_expected.to contain_ini_setting('[vmbackup] enableSyncDriver').with({
                                                                                 'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmbackup',
          'value'   => 'false',
          'notify'  => %r{Service\[vmware-tools-services\]},
          'require' => 'File[vmtools_conf]',
                                                                               })
      end
    end
    context 'with undef default' do
      it do
        is_expected.to contain_ini_setting('[vmbackup] enableSyncDriver').with({
                                                                                 'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmbackup',
          'value'   => 'true',
          'notify'  => %r{Service\[vmware-tools-services\]},
          'require' => 'File[vmtools_conf]',
                                                                               })
      end
    end
    context 'with undef, set kernel <' do
      let(:params) do
        {
          working_kernel_release: '2.6.32-238',
        }
      end

      it do
        is_expected.to contain_ini_setting('[vmbackup] enableSyncDriver').with({
                                                                                 'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmbackup',
          'value'   => 'true',
          'notify'  => %r{Service\[vmware-tools-services\]},
          'require' => 'File[vmtools_conf]',
                                                                               })
      end
    end
    context 'with undef, set kernel >' do
      let(:params) do
        {
          working_kernel_release: '2.6.32-440',
        }
      end

      it do
        is_expected.to contain_ini_setting('[vmbackup] enableSyncDriver').with({
                                                                                 'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmbackup',
          'value'   => 'false',
          'notify'  => %r{Service\[vmware-tools-services\]},
          'require' => 'File[vmtools_conf]',
                                                                               })
      end
    end
    context 'with undef, set kernel =' do
      let(:params) do
        {
          working_kernel_release: '2.6.32-431.11.2.el6.x86_64',
        }
      end

      it do
        is_expected.to contain_ini_setting('[vmbackup] enableSyncDriver').with({
                                                                                 'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmbackup',
          'value'   => 'true',
          'notify'  => %r{Service\[vmware-tools-services\]},
          'require' => 'File[vmtools_conf]',
                                                                               })
      end
    end

    context 'invalid disable_tools_version' do
      let(:params) do
        {
          disable_tools_version: 'invalid',
          working_kernel_release: '2.6.32-238',
        }
      end

      it 'fails' do
        expect { is_expected.to contain_ini_setting('[vmtools] disable-tools-version') }.to raise_error(Puppet::Error, %r{expects a Boolean value})
      end
    end

    context 'invalid enable_sync_driver' do
      let(:params) do
        {
          enable_sync_driver: 'invalid',
          working_kernel_release: '2.6.32-238',
        }
      end

      it 'fails' do
        expect { is_expected.to contain_ini_setting('[vmbackup] enableSyncDriver') }.to raise_error(Puppet::Error, %r{expects a value of type Undef or Boolean})
      end
    end
  end

  context 'managing tools.conf on RHEL7' do
    specific_facts = {
      kernelrelease: '3.10.0-229.7.2.el7.x86_64',
      os: {
        family: 'RedHat',
        name: 'RedHat',
        release: {
          full: '7.0',
          major: '7',
          minor: '0',
        }
      }
    }
    let(:facts) { [default_facts, specific_facts].reduce(:merge) }

    context 'with defaults' do
      it do
        is_expected.to contain_file('vmtools_conf').with({
                                                           'ensure'  => 'file',
          'path'    => '/etc/vmware-tools/tools.conf',
          'require' => 'Package[open-vm-tools]',
                                                         })
      end
    end
  end
end
