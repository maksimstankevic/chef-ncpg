
describe service('node_exporter') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end


describe port(9100) do
  it { should be_listening }
end
