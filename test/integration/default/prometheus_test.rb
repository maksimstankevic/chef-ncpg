
describe port(9090) do
  it { should be_listening }
end


describe docker_container('prometheus') do
  it { should exist }
  it { should be_running }
  its('ports') { should eq '0.0.0.0:9090->9090/tcp' }
end
