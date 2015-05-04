Facter.add(:vmware_has_x) do
  confine :virtual => 'vmware'
  setcode do
    if Facter::Util::Resolution.exec("which X >/dev/null 2>&1 || which Xorg >/dev/null 2>&1 && echo 'true'") == 'true'
      true
    else
      false
    end
  end
end

