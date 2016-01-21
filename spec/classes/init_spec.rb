require 'spec_helper'
describe 'vmware' do

  describe 'with defaults for all parameters on machine running on vmware' do
    context 'on machine without X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'false',
          :operatingsystem   => 'RedHat',
          :osfamily          => 'RedHat',
          :lsbmajdistrelease => '6',
          :architecture      => 'x86_64',
          :kernelrelease     => '2.6.32-431.11.2.el6.x86_64',
        }
      end

      it { should contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }
      it { should_not contain_package('vmware-tools-esx') }
      it {
        should contain_exec('Remove vmware tools script installation').with({
          'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        })
      }
      it {
        should contain_yumrepo('vmware-osps').with
        ({
           'baseurl'  => 'http://packages.vmware.com/tools/esx/latest/rhel6/x86_64',
           'enabled'  => '1',
           'gpgcheck' => '1',
           'gpgkey'   => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
           'proxy'    => 'undef',
         })
      }
      it {
        should contain_service('vmware-tools-services').with({
           'ensure'   => 'running',
           'require'  => 'Package[vmware-tools-esx-nox]',
           'provider' => 'init',
           'path'     => '/etc/vmware-tools/init/',
        })
      }
    end

    context 'on machine with X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'true',
          :operatingsystem   => 'RedHat',
          :osfamily          => 'RedHat',
          :lsbmajdistrelease => '6',
          :kernelrelease     => '2.6.32-431.11.2.el6.x86_64',
        }
      end

      it { should contain_package('vmware-tools-esx').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters on RHEL 5 running on vmware' do
    context 'on machine without X installed' do
      let(:facts) do
        { :virtual                   => 'vmware',
          :vmware_has_x              => 'false',
          :operatingsystem           => 'RedHat',
          :osfamily                  => 'RedHat',
          :lsbmajdistrelease         => '5',
          :kernelrelease             => '2.6.18-400.1.1.el5',
          :architecture              => 'x86_64',
        }
      end

      it { should_not contain_package('open-vm-tools') }
      it { should_not contain_package('open-vm-tools-desktop') }

      it { should contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }
      it { should_not contain_package('vmware-tools-esx') }
      it {
        should contain_exec('Remove vmware tools script installation').with({
           'command' => 'installer.sh uninstall',
           'path'    => '/usr/bin/:/etc/vmware-tools/',
           'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        })
      }
      it {
        should contain_yumrepo('vmware-osps').with({
           'enabled'     => '1',
           'baseurl'     => 'http://packages.vmware.com/tools/esx/latest/rhel5/x86_64',
           'gpgcheck'    => '1',
           'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
         })
      }
      it {
        should contain_service('vmware-tools-services').with({
           'ensure'   => 'running',
           'require'  => 'Package[vmware-tools-esx-nox]',
           'provider' => 'init',
           'path'     => '/etc/init.d/',
        })
      }
    end

    context 'on machine with X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'true',
          :operatingsystem   => 'SLES',
          :osfamily          => 'Suse',
          :lsbmajdistrelease => '10',
          :kernelrelease     => '2.6.18.2-34-default',
        }
      end

      it { should contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }

    end
  end

  describe 'with defaults for all parameters except force_open_vm_tools => true on RHEL 5 running on vmware' do
    context 'on machine without X installed' do
      let(:facts) do
        { :virtual                   => 'vmware',
          :vmware_has_x              => 'false',
          :operatingsystem           => 'RedHat',
          :osfamily                  => 'RedHat',
          :lsbmajdistrelease         => '6',
          :kernelrelease             => '2.6.32-431.11.2.el6.x86_64',
          :architecture              => 'x86_64',
        }
      end
      let(:params) do
        { :force_open_vm_tools      => true, }
      end

      it { should_not contain_package('vmware-tools-esx-nox') }
      it { should_not contain_package('vmware-tools-esx') }

      it { should contain_package('open-vm-tools') }
      it { should_not contain_package('open-vm-tools-desktop').with('ensure' => 'present') }

      it {
        should contain_exec('Remove vmware tools script installation').with({
           'command' => 'installer.sh uninstall',
           'path'    => '/usr/bin/:/etc/vmware-tools/',
           'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        })
      }
      it {
        should contain_service('vmtoolsd').with({
           'ensure'   => 'running',
           'require'  => 'Package[open-vm-tools]',
        })
      }
    end

    context 'on machine with X installed' do
      let(:facts) do
        { :virtual                   => 'vmware',
          :vmware_has_x              => 'true',
          :operatingsystem           => 'RedHat',
          :osfamily                  => 'RedHat',
          :lsbmajdistrelease         => '6',
          :kernelrelease             => '2.6.32-431.11.2.el6.x86_64',
          :architecture              => 'x86_64',
        }
      end
      let(:params) do
        { :force_open_vm_tools      => true, }
      end

      it { should contain_package('open-vm-tools').with('ensure' => 'present') }
      it { should contain_package('open-vm-tools-desktop').with('ensure' => 'present') }

    end
  end

  describe 'with defaults for all parameters on RHEL 7 running on vmware' do
    context 'on machine without X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'false',
          :operatingsystem   => 'RedHat',
          :osfamily          => 'RedHat',
          :lsbmajdistrelease => '7',
          :kernelrelease     => '3.10.0-123.9.2.el7.x86_64',
        }
      end

      it { should contain_package('open-vm-tools').with('ensure' => 'present') }
      it { should_not contain_package('open-vm-tools-desktop') }

      it { should_not contain_package('vmware-tools-esx-nox') }
      it { should_not contain_package('vmware-tools-esx') }
      it {
        should contain_exec('Remove vmware tools script installation').with({
          'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        })
      }
      it {
        should_not contain_yumrepo('vmware-osps')
      }
      it {
        should contain_service('vmtoolsd').with({
           'ensure'  => 'running',
           'require' => 'Package[open-vm-tools]',
        })
      }
      it {
        should_not contain_service('vmtoolsd').with({
          'provider' => 'init',
        })
      }
    end

    context 'on machine with X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'true',
          :operatingsystem   => 'RedHat',
          :osfamily          => 'RedHat',
          :lsbmajdistrelease => '7',
          :kernelrelease     => '3.10.0-123.9.2.el7.x86_64',
        }
      end

      it { should contain_package('open-vm-tools-desktop').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters on SLES 10 running on vmware' do
    context 'on machine without X installed' do
      let(:facts) do
        { :virtual                => 'vmware',
          :vmware_has_x           => 'false',
          :operatingsystem        => 'SLES',
          :osfamily               => 'Suse',
          :lsbmajdistrelease      => '11',
          :operatingsystemrelease => '10.2',
          :architecture           => 'x86_64',
          :kernelrelease          => '2.6.18.2-34-default',
        }
      end

      it { should_not contain_package('open-vm-tools') }
      it { should_not contain_package('open-vm-tools-desktop') }

      it { should contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }
      it { should_not contain_package('vmware-tools-esx') }
      it {
        should contain_exec('Remove vmware tools script installation').with({
           'command' => 'installer.sh uninstall',
           'path'    => '/usr/bin/:/etc/vmware-tools/',
           'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        })
      }
      it {
        should contain_zypprepo('vmware-osps').with({
           'enabled'     => '1',
           'autorefresh' => '0',
           'baseurl'     => 'http://packages.vmware.com/tools/esx/latest/sles10/x86_64',
           'path'        => '/',
           'type'        => 'yum',
           'gpgcheck'    => '1',
           'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
         })
      }
      it {
        should contain_service('vmware-tools-services').with({
           'ensure'   => 'running',
           'require'  => 'Package[vmware-tools-esx-nox]',
           'provider' => 'init',
           'path'     => '/etc/init.d/',
        })
      }
    end

    context 'on machine with X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'true',
          :operatingsystem   => 'SLES',
          :osfamily          => 'Suse',
          :lsbmajdistrelease => '10',
          :kernelrelease     => '2.6.18.2-34-default',
        }
      end

      it { should contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }

    end
  end

  describe 'with defaults for all parameters on SLED 12 running on vmware' do
    context 'on machine without X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'false',
          :operatingsystem   => 'SLED',
          :osfamily          => 'Suse',
          :lsbmajdistrelease => '12',
          :kernelrelease     => '3.10.0-123.9.2.el7.x86_64',
        }
      end

      it { should contain_package('open-vm-tools').with('ensure' => 'present') }
      it { should_not contain_package('open-vm-tools-desktop') }

      it { should_not contain_package('vmware-tools-esx-nox') }
      it { should_not contain_package('vmware-tools-esx') }
      it {
        should contain_exec('Remove vmware tools script installation').with({
          'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        })
      }
      it {
        should_not contain_yumrepo('vmware-osps')
      }
      it {
        should contain_service('vmtoolsd').with({
           'ensure'  => 'running',
           'require' => 'Package[open-vm-tools]',
        })
      }
      it {
        should_not contain_service('vmtoolsd').with({
          'provider' => 'init',
        })
      }
    end

    context 'on machine with X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'true',
          :operatingsystem   => 'SLED',
          :osfamily          => 'Suse',
          :lsbmajdistrelease => '12',
          :kernelrelease     => '3.10.0-123.9.2.el7.x86_64',
        }
      end

      it { should contain_package('open-vm-tools-desktop').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters on SLES 11 running on vmware' do
    context 'on machine without X installed' do
      let(:facts) do
        { :virtual                => 'vmware',
          :vmware_has_x           => 'false',
          :operatingsystem        => 'SLES',
          :osfamily               => 'Suse',
          :lsbmajdistrelease      => '11',
          :operatingsystemrelease => '11.2',
          :architecture           => 'x86_64',
          :kernelrelease          => '3.0.13-0.27.1',
        }
      end

      it { should_not contain_package('open-vm-tools') }
      it { should_not contain_package('open-vm-tools-desktop') }

      it { should contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }
      it { should_not contain_package('vmware-tools-esx') }
      it {
        should contain_exec('Remove vmware tools script installation').with({
           'command' => 'installer.sh uninstall',
           'path'    => '/usr/bin/:/etc/vmware-tools/',
           'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        })
      }
      it {
        should contain_zypprepo('vmware-osps').with({
           'enabled'     => '1',
           'autorefresh' => '0',
           'baseurl'     => 'http://packages.vmware.com/tools/esx/latest/sles11.2/x86_64',
           'path'        => '/',
           'type'        => 'yum',
           'gpgcheck'    => '1',
           'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
         })
      }
      it {
        should contain_service('vmware-tools-services').with({
           'ensure'   => 'running',
           'require'  => 'Package[vmware-tools-esx-nox]',
           'provider' => 'init',
           'path'     => '/etc/init.d/',
        })
      }
    end

    context 'on machine with X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'true',
          :operatingsystem   => 'SLES',
          :osfamily          => 'Suse',
          :lsbmajdistrelease => '11',
          :kernelrelease     => '3.0.13-0.27.1',
        }
      end

      it { should contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }

    end

    context 'with esx_version = 6.0, x86_64' do
      let(:facts) do
        { :virtual                => 'vmware',
          :vmware_has_x           => 'false',
          :operatingsystem        => 'SLES',
          :osfamily               => 'Suse',
          :lsbmajdistrelease      => '11',
          :operatingsystemrelease => '11.2',
          :architecture           => 'x86_64',
        }
      end

      let(:params) do
        { :esx_version => '6.0',
        }
      end

      it {
        should contain_zypprepo('vmware-osps').with({
           'enabled'     => '1',
           'autorefresh' => '0',
           'baseurl'     => 'http://packages.vmware.com/tools/esx/6.0/sles11sp2/x86_64',
           'path'        => '/',
           'type'        => 'yum',
           'gpgcheck'    => '1',
           'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
         })
      }
    end

    context 'with esx_version < 6.0, x86_64' do
      let(:facts) do
        { :virtual                => 'vmware',
          :vmware_has_x           => 'false',
          :operatingsystem        => 'SLES',
          :osfamily               => 'Suse',
          :lsbmajdistrelease      => '11',
          :operatingsystemrelease => '11.2',
          :architecture           => 'x86_64',
        }
      end

      let(:params) do
        { :esx_version => '5.5latest',
        }
      end

      it {
        should contain_zypprepo('vmware-osps').with({
           'enabled'     => '1',
           'autorefresh' => '0',
           'baseurl'     => 'http://packages.vmware.com/tools/esx/5.5latest/sles11.2/x86_64',
           'path'        => '/',
           'type'        => 'yum',
           'gpgcheck'    => '1',
           'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
         })
      }
    end
    context 'with esx_version < 6.0, i386' do
      let(:facts) do
        { :virtual                => 'vmware',
          :vmware_has_x           => 'false',
          :operatingsystem        => 'SLES',
          :osfamily               => 'Suse',
          :lsbmajdistrelease      => '11',
          :operatingsystemrelease => '11.2',
          :architecture           => 'i386',
        }
      end

      let(:params) do
        { :esx_version => '5.5latest',
        }
      end

      it {
        should contain_zypprepo('vmware-osps').with({
           'enabled'     => '1',
           'autorefresh' => '0',
           'baseurl'     => 'http://packages.vmware.com/tools/esx/5.5latest/sles11.2/i586',
           'path'        => '/',
           'type'        => 'yum',
           'gpgcheck'    => '1',
           'gpgkey'      => 'http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub',
         })
      }
    end
  end

  describe 'with defaults for all parameters on OpenSuSE 12 running on vmware' do
    context 'on machine without X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'false',
          :operatingsystem   => 'OpenSuSE',
          :osfamily          => 'Suse',
          :lsbmajdistrelease => '12',
          :kernelrelease     => '3.12.28-4.6',
        }
      end

      it { should contain_package('open-vm-tools').with('ensure' => 'present') }
      it { should_not contain_package('open-vm-tools-desktop') }

      it { should_not contain_package('vmware-tools-esx-nox') }
      it { should_not contain_package('vmware-tools-esx') }
      it {
        should contain_exec('Remove vmware tools script installation').with({
          'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        })
      }
      it {
        should_not contain_zypprepo('vmware-osps')
      }
      it {
        should contain_service('vmtoolsd').with({
           'ensure' => 'running',
        })
      }
      it {
        should_not contain_service('vmtoolsd').with({
          'provider' => 'init',
        })
      }
    end

    context 'on machine with X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'true',
          :operatingsystem   => 'OpenSuSE',
          :osfamily          => 'Suse',
          :lsbmajdistrelease => '12',
          :kernelrelease     => '3.12.28-4.6',
        }
      end

      it { should contain_package('open-vm-tools-gui').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters on Ubuntu 12.04 running on vmware' do
    context 'on machine without X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'false',
          :operatingsystem   => 'Ubuntu',
          :osfamily          => 'Debian',
          :lsbmajdistrelease => '12',
          :kernelrelease     => '3.2.0-23-generic',
        }
      end

      it { should contain_package('open-vm-tools').with('ensure' => 'present') }
      it { should_not contain_package('open-vm-toolbox') }

      it { should_not contain_package('vmware-tools-esx-nox') }
      it { should_not contain_package('vmware-tools-esx') }
      it {
        should contain_exec('Remove vmware tools script installation').with({
          'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        })
      }
      it {
        should_not contain_class('apt')
      }
      it {
        should contain_service('open-vm-tools').with({
           'ensure'    => 'running',
           'hasstatus' => 'false',
           'status'    => '/bin/ps -ef | /bin/grep -i "vmtoolsd" | /bin/grep -v "grep"',
        })
      }
      it {
        should_not contain_service('vmtoolsd').with({
          'provider' => 'init',
        })
      }
    end

    context 'on machine with X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'true',
          :operatingsystem   => 'Ubuntu',
          :osfamily          => 'Debian',
          :lsbmajdistrelease => '12',
          :kernelrelease     => '3.2.0-23-generic',
        }
      end

      it { should contain_package('open-vm-toolbox').with('ensure' => 'present') }
    end

    context 'with prefer_open_vm_tools = false' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'false',
          :operatingsystem   => 'Ubuntu',
          :osfamily          => 'Debian',
          :lsbmajdistrelease => '12',
          :lsbdistid         => 'ubuntu', # for apt
          :lsbdistcodename   => 'precise',
          :lsbmajdistrelease => '12',
          :kernelrelease     => '3.2.0-23-generic',
        }
      end
      let(:params) do
        { :prefer_open_vm_tools => 'false',
        }
      end
      it { should_not contain_package('open-vm-tools') }
      it { should_not contain_package('open-vm-toolbox') }

      it { should contain_package('vmware-tools-esx-nox') }
      it { should_not contain_package('vmware-tools-esx') }
      it {
        should contain_exec('Remove vmware tools script installation').with({
          'command' => 'installer.sh uninstall',
          'path'    => '/usr/bin/:/etc/vmware-tools/',
          'onlyif'  => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        })
      }
      it {
        should contain_apt__source('vmware-osps').with({
            'location'    => 'http://packages.vmware.com/tools/esx/latest/ubuntu',
            'release'     => 'precise',
            'repos'       => 'main',
            'include_src' => false,
         })
      }
      it {
        should contain_service('vmware-tools-services').with({
           'ensure'   => 'running',
           'require'  => 'Package[vmware-tools-esx-nox]',
           'provider' => 'init',
           'path'     => '/etc/vmware-tools/init/',
        })
      }
    end

  end

  context 'with custom values for parameters on machine running on vmware' do
    let(:facts) do
      { :virtual           => 'vmware',
        :vmware_has_x      => 'true',
        :operatingsystem   => 'RedHat',
        :osfamily          => 'RedHat',
        :lsbmajdistrelease => '6',
        :kernelrelease     => '2.6.32-431.11.2.el6.x86_64',
      }
    end
    let(:params) do
      { :tools_nox_package_name   => 'vmware-tools-esx-nox-custom',
        :tools_nox_package_ensure => '0.2-1',
        :tools_x_package_name     => 'vmware-tools-esx-custom',
        :tools_x_package_ensure   => '0.3-1',
      }
    end

    it { should contain_package('vmware-tools-esx-nox-custom').with('ensure' => '0.2-1') }
    it { should contain_package('vmware-tools-esx-custom').with('ensure' => '0.3-1') }
  end

  context 'with managing the x package on a machine without x' do
    let(:facts) do
      { :virtual           => 'vmware',
        :vmware_has_x      => 'false',
        :operatingsystem   => 'RedHat',
        :osfamily          => 'RedHat',
        :lsbmajdistrelease => '6',
        :kernelrelease     => '2.6.32-431.11.2.el6.x86_64',
      }
    end
    let(:params) do
      { :manage_tools_x_package => 'true',
        :tools_x_package_name   => 'vmware-tools-esx-custom',
        :tools_x_package_ensure => '0.5-1',
      }
    end

    it { should contain_package('vmware-tools-esx-custom').with('ensure' => '0.5-1') }
  end

  context 'without managing packages' do
    let(:facts) do
      { :virtual           => 'vmware',
        :operatingsystem   => 'RedHat',
        :osfamily          => 'RedHat',
        :lsbmajdistrelease => '6',
        :kernelrelease     => '2.6.32-431.11.2.el6.x86_64',
      }
    end
    let(:params) do
      { :manage_tools_nox_package => 'false',
        :manage_tools_x_package   => 'false',
      }
    end

    it { should_not contain_package('vmware-tools-esx') }
    it { should_not contain_package('vmware-tools-esx-nox') }
    it { should_not contain_exec('Remove vmware tools script installation') }
    it {
      should contain_service('vmware-tools-services').with({
         'ensure'   => 'running',
         'require'  => 'Package[vmware-tools-esx-nox]',
         'provider' => 'init',
         'path'     => '/etc/vmware-tools/init/',
      })
    }
  end

  context 'on a machine that does not run on vmware' do
    let(:facts) do
      { :virtual           => 'physical',
        :operatingsystem   => 'Debian',
        :osfamily          => 'Debian',
        :lsbmajdistrelease => '7',
        :kernelrelease     => '3.2.0-23-generic',
      }
    end

    it { should_not contain_package('vmware-tools-esx') }
    it { should_not contain_package('vmware-tools-esx-nox') }
    it { should_not contain_exec('Remove vmware tools script installation') }
    it { should_not contain_service('vmware-tools-services') }
  end

  describe 'with incorrect types' do
    let(:facts) do
      { :virtual           => 'vmware',
        :vmware_has_x      => 'true',
        :operatingsystem   => 'RedHat',
        :osfamily          => 'RedHat',
        :lsbmajdistrelease => '6',
        :kernelrelease     => '2.6.32-431.11.2.el6.x86_64',
      }
    end

    context 'with manage_repo as an array' do
      let(:params) do
        { :manage_repo => ['no'],
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/\["no"\] is not a boolean.  It looks to be a Array/)
      end
    end

    context 'with manage_service as an array' do
      let(:params) do
        { :manage_service => ['no'],
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/str2bool\(\): Requires either string to work with /)
      end
    end

    context 'with prefer_open_vm_tools as an array' do
      let(:params) do
        { :prefer_open_vm_tools => ['no'],
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/\["no"\] is not a boolean.  It looks to be a Array/)
      end
    end

    context 'with manage_tools_nox_package as an array' do
      let(:params) do
        { :manage_tools_nox_package => ['no'],
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/\["no"\] is not a boolean.  It looks to be a Array/)
      end
    end

    context 'with manage_tools_x_package as an array' do
      let(:params) do
        { :manage_tools_x_package => ['no'],
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/\["no"\] is not a boolean.  It looks to be a Array/)
      end
    end

    context 'with tools_nox_package_name as a bool' do
      let(:params) do
        { :tools_nox_package_name => false,
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/false is not a string.  It looks to be a FalseClass/)
      end
    end

    context 'with tools_x_package_name as a bool' do
      let(:params) do
        { :tools_x_package_name => false,
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/false is not a string.  It looks to be a FalseClass/)
      end
    end

    context 'with tools_nox_package_ensure as a bool' do
      let(:params) do
        { :tools_nox_package_ensure => false,
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/false is not a string.  It looks to be a FalseClass/)
      end
    end

    context 'with tools_x_package_ensure as a bool' do
      let(:params) do
        { :tools_x_package_ensure => false,
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/false is not a string.  It looks to be a FalseClass/)
      end
    end
  end

  context 'managing tools.conf on RHEL6' do
    let(:facts) do
      { :virtual           => 'vmware',
        :vmware_has_x      => 'false',
        :operatingsystem   => 'RedHat',
        :osfamily          => 'RedHat',
        :lsbmajdistrelease => '6',
        :kernelrelease     => '2.6.32-431.11.2.el6.x86_64',
      }
    end

    context 'with defaults' do

      it {
        should contain_file('vmtools_conf').with({
          'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'require' => 'Package[vmware-tools-esx-nox]',
        })
      }
      it {
        should contain_ini_setting('[vmtools] disable-tools-version').with({
          'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmtools',
          'value'   => 'true',
          'notify'  => /Service\[vmware-tools-services\]/,
          'require' => 'File[vmtools_conf]',
        })
      }
      it {
        should contain_ini_setting('[vmbackup] enableSyncDriver').with({
          'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmbackup',
          'value'   => 'true',
          'notify'  => /Service\[vmware-tools-services\]/,
          'require' => 'File[vmtools_conf]',
        })
      }
    end

    context 'with true' do
      let(:params) do
        { :tools_conf_path => '/path/to/file',
          :disable_tools_version => true,
          :enable_sync_driver => true,
        }
      end

      it {
        should contain_file('vmtools_conf').with({
          'ensure'  => 'present',
          'path'    => '/path/to/file',
          'require' => 'Package[vmware-tools-esx-nox]',
        })
      }
      it {
        should contain_ini_setting('[vmtools] disable-tools-version').with({
          'ensure'  => 'present',
          'path'    => '/path/to/file',
          'section' => 'vmtools',
          'value'   => 'true',
          'notify'  => /Service\[vmware-tools-services\]/,
          'require' => 'File[vmtools_conf]',
        })
      }
      it {
        should contain_ini_setting('[vmbackup] enableSyncDriver').with({
          'ensure'  => 'present',
          'path'    => '/path/to/file',
          'section' => 'vmbackup',
          'value'   => 'true',
          'notify'  => /Service\[vmware-tools-services\]/,
          'require' => 'File[vmtools_conf]',
        })
      }
    end
    context 'with false' do
      let(:params) do
        { :disable_tools_version => false,
          :enable_sync_driver => false,
        }
      end

      it {
        should contain_file('vmtools_conf').with({
          'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'require' => 'Package[vmware-tools-esx-nox]',
        })
      }
      it {
        should contain_ini_setting('[vmtools] disable-tools-version').with({
          'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmtools',
          'value'   => 'false',
          'notify'  => /Service\[vmware-tools-services\]/,
          'require' => 'File[vmtools_conf]',
        })
      }
      it {
        should contain_ini_setting('[vmbackup] enableSyncDriver').with({
          'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmbackup',
          'value'   => 'false',
          'notify'  => /Service\[vmware-tools-services\]/,
          'require' => 'File[vmtools_conf]',
        })
      }
    end
    context 'with auto default' do
      let(:params) do
        {
          :enable_sync_driver => 'auto',
        }
      end

      it {
        should contain_ini_setting('[vmbackup] enableSyncDriver').with({
          'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmbackup',
          'value'   => 'true',
          'notify'  => /Service\[vmware-tools-services\]/,
          'require' => 'File[vmtools_conf]',
        })
      }
    end
    context 'with auto, set kernel <' do
      let(:params) do
        {
          :enable_sync_driver => 'auto',
          :working_kernel_release => '2.6.32-238',
        }
      end

      it {
        should contain_ini_setting('[vmbackup] enableSyncDriver').with({
          'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmbackup',
          'value'   => 'true',
          'notify'  => /Service\[vmware-tools-services\]/,
          'require' => 'File[vmtools_conf]',
        })
      }
    end
    context 'with auto, set kernel >' do
      let(:params) do
        {
          :enable_sync_driver => 'auto',
          :working_kernel_release => '2.6.32-440',
        }
      end

      it {
        should contain_ini_setting('[vmbackup] enableSyncDriver').with({
          'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmbackup',
          'value'   => 'false',
          'notify'  => /Service\[vmware-tools-services\]/,
          'require' => 'File[vmtools_conf]',
        })
      }
    end
    context 'with auto, set kernel =' do
      let(:params) do
        {
          :enable_sync_driver => 'auto',
          :working_kernel_release => '2.6.32-431.11.2.el6.x86_64',
        }
      end

      it {
        should contain_ini_setting('[vmbackup] enableSyncDriver').with({
          'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'section' => 'vmbackup',
          'value'   => 'true',
          'notify'  => /Service\[vmware-tools-services\]/,
          'require' => 'File[vmtools_conf]',
        })
      }
    end
    context 'invalid disable_tools_version' do
      let(:params) do
        {
          :disable_tools_version  => 'invalid',
          :working_kernel_release => '2.6.32-238',
        }
      end

      it {
        expect {
          should contain_ini_settings('[vmtools] disable-tools-version')
        }.to raise_error(Puppet::Error,/Unknown type of boolean/)
      }
    end
    context 'invalid enable_sync_driver' do
      let(:params) do
        {
          :enable_sync_driver     => 'invalid',
          :working_kernel_release => '2.6.32-238',
        }
      end

      it {
        expect {
          should contain_ini_setting('[vmbackup] enableSyncDriver')
        }.to raise_error(Puppet::Error,/Unknown type of boolean/)
      }

    end
  end

  context 'managing tools.conf on RHEL7' do
    let(:facts) do
      { :virtual           => 'vmware',
        :vmware_has_x      => 'false',
        :operatingsystem   => 'RedHat',
        :osfamily          => 'RedHat',
        :lsbmajdistrelease => '7',
        :kernelrelease     => '3.10.0-229.7.2.el7.x86_64',
      }
    end

    context 'with defaults' do

      it {
        should contain_file('vmtools_conf').with({
          'ensure'  => 'present',
          'path'    => '/etc/vmware-tools/tools.conf',
          'require' => 'Package[open-vm-tools]',
        })
      }
    end
  end

  describe 'variable type and content validations' do
    let(:facts) do
      { :virtual                   => 'vmware',
        :vmware_has_x              => 'true',
        :operatingsystem           => 'RedHat',
        :osfamily                  => 'RedHat',
        :lsbmajdistrelease         => '6',
        :kernelrelease             => '2.6.32-431.11.2.el6.x86_64',
        :architecture              => 'x86_64',
      }
    end

    validations = {
      'bool (true|false)' => {
        :name => %w{force_open_vm_tools},
        :valid => [true, 'true', false, 'false'],
        :invalid => ['string', %w{array}, { 'ha' => 'sh' }, 3, 2.42, nil],
      },
    }

    validations.sort.each do |type, var|
      var[:name].each do |var_name|
        var[:params] = {} if var[:params].nil?
        var[:valid].each do |valid|
          context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
            let(:params) { [ var[:params], { :"#{var_name}" => valid, }].reduce(:merge) }
            it { should compile }
          end
        end

        var[:invalid].each do |invalid|
          context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { [ var[:params], { :"#{var_name}" => invalid, }].reduce(:merge) }
            it 'should fail' do
              expect {
                should contain_class('vmware')
              }.to raise_error(Puppet::Error)
            end
          end
        end
      end
    end
  end
end
