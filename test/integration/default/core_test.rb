# InSpec test for recipe chef-ncpg::default

# The InSpec reference, with examples and extensive documentation, can be
# found at https://www.inspec.io/docs/reference/resources/

%w[grafana prometheus node_exporter cadvisor].each do |u|
  describe user(u) do
    it { should exist }
    its('groups') { should eq [u, 'docker'] }
  end
end

describe service('docker') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end
