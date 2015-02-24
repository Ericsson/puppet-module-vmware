require 'spec_helper'
describe 'vmware' do

  describe 'with defaults for all parameters on machine running on vmware' do
    context 'on machine without X installed' do
      let(:facts) do
        { :virtual      => 'vmware',
          :vmware_has_x => 'false',
        }
      end

      it { should contain_package('vmwaretools-repo').with('ensure' => 'present') }
      it { should contain_package('vmware-tools-esx-nox').with('ensure' => 'present') }
      it { should contain_package('vmware-tools-esx-kmods').with('ensure' => 'present') }
      it { should_not contain_package('vmware-tools-esx') }
      it {
        should contain_exec('Remove vmware tools script installation').with({
          'command' => 'installer.sh uninstall',
          'path' => '/usr/bin/:/etc/vmware-tools/',
          'onlyif' => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        })
      }
    end

    context 'on machine with X installed' do
      let(:facts) do
        { :virtual => 'vmware',
          :vmware_has_x => 'true',
        }
      end

      it { should contain_package('vmware-tools-esx').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters on RHEL 7 running on vmware' do
    context 'on machine without X installed' do
      let(:facts) do
        { :virtual                   => 'vmware',
          :vmware_has_x              => 'false',
          :osfamily                  => 'RedHat',
          :operatingsystemmajrelease => '7',
        }
      end

      it { should contain_package('open-vm-tools').with('ensure' => 'present') }
      it { should_not contain_package('open-vm-tools-desktop') }

      it { should_not contain_package('vmwaretools-repo') }
      it { should_not contain_package('vmware-tools-esx-nox') }
      it { should_not contain_package('vmware-tools-esx-kmods') }
      it { should_not contain_package('vmware-tools-esx') }
      it {
        should contain_exec('Remove vmware tools script installation').with({
          'command' => 'installer.sh uninstall',
          'path' => '/usr/bin/:/etc/vmware-tools/',
          'onlyif' => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        })
      }
    end

    context 'on machine with X installed' do
      let(:facts) do
        { :virtual                   => 'vmware',
          :vmware_has_x              => 'true',
          :osfamily                  => 'RedHat',
          :operatingsystemmajrelease => '7',
        }
      end

      it { should contain_package('open-vm-tools-desktop').with('ensure' => 'present') }
    end
  end

  describe 'with defaults for all parameters on SUSE 12 running on vmware' do
    context 'on machine without X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'false',
          :osfamily          => 'Suse',
          :lsbmajdistrelease => '12',
        }
      end

      it { should contain_package('open-vm-tools').with('ensure' => 'present') }
      it { should_not contain_package('open-vm-tools-desktop') }

      it { should_not contain_package('vmwaretools-repo') }
      it { should_not contain_package('vmware-tools-esx-nox') }
      it { should_not contain_package('vmware-tools-esx-kmods') }
      it { should_not contain_package('vmware-tools-esx') }
      it {
        should contain_exec('Remove vmware tools script installation').with({
          'command' => 'installer.sh uninstall',
          'path' => '/usr/bin/:/etc/vmware-tools/',
          'onlyif' => 'test -e "/etc/vmware-tools/locations" -a ! -e "/usr/lib/vmware-tools/dsp"',
        })
      }
    end

    context 'on machine with X installed' do
      let(:facts) do
        { :virtual           => 'vmware',
          :vmware_has_x      => 'true',
          :osfamily          => 'Suse',
          :lsbmajdistrelease => '12',
        }
      end

      it { should contain_package('open-vm-tools-desktop').with('ensure' => 'present') }
    end
  end

  context 'with custom values for parameters on machine running on vmware' do
    let(:facts) do
      { :virtual => 'vmware',
        :vmware_has_x => 'true',
      }
    end
    let(:params) do
      { :repo_package_name => 'vmwaretools-key-custom',
        :repo_package_ensure => 'latest',
        :tools_nox_package_name => 'vmware-tools-esx-nox-custom',
        :tools_nox_package_ensure => '0.2-1',
        :tools_x_package_name => 'vmware-tools-esx-custom',
        :tools_x_package_ensure => '0.3-1',
        :tools_kmod_package_name => 'vmware-tools-esx-kmods-custom',
        :tools_kmod_package_ensure => '0.4-1',
      }
    end

    it { should contain_package('vmwaretools-key-custom').with( 'ensure' => 'latest') }
    it { should contain_package('vmware-tools-esx-nox-custom').with('ensure' => '0.2-1') }
    it { should contain_package('vmware-tools-esx-custom').with('ensure' => '0.3-1') }
    it { should contain_package('vmware-tools-esx-kmods-custom').with('ensure' => '0.4-1') }
  end

  context 'with managing the x package on a machine without x' do
    let(:facts) do
      { :virtual => 'vmware',
        :vmware_has_x => 'false',
      }
    end
    let(:params) do
      { :manage_tools_x_package => 'true',
        :tools_x_package_name => 'vmware-tools-esx-custom',
        :tools_x_package_ensure => '0.5-1',
      }
    end

    it { should contain_package('vmware-tools-esx-custom').with('ensure' => '0.5-1') }
  end

  context 'without managing packages' do
    let(:facts) do
      { :virtual => 'vmware',
      }
    end
    let(:params) do
      { :manage_repo_package => 'false',
        :manage_tools_nox_package => 'false',
        :manage_tools_x_package => 'false',
        :manage_tools_kmod_package => 'false',
      }
    end

    it { should_not contain_package('vmwaretools-key') }
    it { should_not contain_package('vmware-tools-esx') }
    it { should_not contain_package('vmware-tools-esx-nox') }
    it { should_not contain_package('vmware-tools-esx-kmods') }
    it { should_not contain_exec('Remove vmware tools script installation') }
  end

  context 'on a machine that does not run on vmware' do
    let(:facts) do
      { :virtual => 'physical',
      }
    end

    it { should_not contain_package('vmwaretools-key') }
    it { should_not contain_package('vmware-tools-esx') }
    it { should_not contain_package('vmware-tools-esx-nox') }
    it { should_not contain_package('vmware-tools-esx-kmods') }
    it { should_not contain_exec('Remove vmware tools script installation') }
  end

  describe 'with incorrect types' do
    let(:facts) do
      { :virtual => 'vmware',
        :vmware_has_x => 'true',
      }
    end

    context 'with manage_repo_package as an array' do
      let(:params) do
        { :manage_repo_package => ['yes'],
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/\["yes"\] is not a boolean.  It looks to be a Array/)
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

    context 'with manage_tools_kmod_package as an array' do
      let(:params) do
        { :manage_tools_kmod_package => ['no'],
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/\["no"\] is not a boolean.  It looks to be a Array/)
      end
    end

    context 'with repo_package_name as a bool' do
      let(:params) do
        { :repo_package_name => true,
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/true is not a string.  It looks to be a TrueClass/)
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

    context 'with tools_kmod_package_name as a bool' do
      let(:params) do
        { :tools_kmod_package_name => false,
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/false is not a string.  It looks to be a FalseClass/)
      end
    end

    context 'with repo_package_ensure as a bool' do
      let(:params) do
        { :repo_package_ensure => true,
        }
      end

      it 'should fail' do
        expect {
          should contain_class('vmware')
        }.to raise_error(Puppet::Error,/true is not a string.  It looks to be a TrueClass/)
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

    context 'with tools_kmod_package_ensure as a bool' do
      let(:params) do
        { :tools_kmod_package_ensure => false,
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
