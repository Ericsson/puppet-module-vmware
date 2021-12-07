# These functions provide the same values as used in hiera
def default_open_tools_x_package(facts)
  if facts[:os]['name'] == 'OpenSuSE'
    'open-vm-tools-gui'
  elsif facts[:os]['name'] == 'Ubuntu' && facts[:os]['release']['full'].to_i <= 14.04
    'open-vm-toolbox'
  else
    'open-vm-tools-desktop'
  end
end

def default_open_vm_tools_exist(facts)
  if facts[:os]['family'] == 'RedHat' && facts[:os]['release']['major'].to_i <= 6
    false
  elsif facts[:os]['family'] == 'Suse' && facts[:os]['release']['full'].to_i <= 11.3
    false
  else
    true
  end
end

def default_service_name_open(facts)
  if facts[:os]['family'] == 'Debian'
    'open-vm-tools'
  else
    'vmtoolsd'
  end
end

def service_name(facts)
  if default_open_vm_tools_exist(facts) == true
    default_service_name_open(facts)
  else
    'vmware-tools-services'
  end
end

def service_path(facts)
  if facts[:os]['family'] == 'Suse' || facts[:os]['family'] == 'RedHat' && facts[:os]['release']['major'].to_i == 5
    '/etc/init.d'
  else
    '/etc/vmware-tools/init'
  end
end

def service_provider(facts)
  if facts[:os]['family'] == 'Debian'
    'init'
  else
    'redhat'
  end
end

def tools_nox_package_name(facts)
  if default_open_vm_tools_exist(facts) == true
    'open-vm-tools'
  else
    'vmware-tools-esx-nox'
  end
end

def tools_x_package_name(facts)
  if default_open_vm_tools_exist(facts) == true
    default_open_tools_x_package(facts)
  else
    'vmware-tools-esx'
  end
end

def working_kernel_release(facts)
  if facts[:os]['family'] == 'RedHat'
    '2.6.32-358'
  else
    '2.6.35-22'
  end
end
