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
        }
      end

      it { should contain_package('vmware-tools-esx').with('ensure' => 'present') }
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
        }
      end

      it { should contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }

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
        }
      end

      it { should contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }

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
end
