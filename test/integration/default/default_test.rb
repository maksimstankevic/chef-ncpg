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

describe service('cadvisor') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe service('node_exporter') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe port(8080) do
  it { should be_listening }
end

describe port(9090) do
  it { should be_listening }
end

describe port(9100) do
  it { should be_listening }
end

describe port(3000) do
  it { should be_listening }
end

describe docker_container('prometheus') do
  it { should exist }
  it { should be_running }
  its('ports') { should eq '0.0.0.0:9090->9090/tcp' }
end

describe docker_container('grafana') do
  it { should exist }
  it { should be_running }
  its('ports') { should eq '0.0.0.0:3000->3000/tcp' }
end

# verify that datasources contain a prometheus one
describe http('http://192.168.13.3:3000/api/datasources',
              auth: { user: 'admin', pass: 'pass' },
              method: 'GET') do
  its('status') { should cmp 200 }
  its('headers.Content-Type') { should cmp 'application/json' }
end

# verify that dashboard that we installed exist
describe http('http://192.168.13.3:3000/api/search',
              auth: { user: 'admin', pass: 'pass' },
              method: 'GET') do
  its('status') { should cmp 200 }
  its('body') { should match %r{db\/docker-and-system-monitoring} }
  its('body') { should match %r{db\/1-node-exporter-for-prometheus-dashboard} }
  its('headers.Content-Type') { should cmp 'application/json' }
end
