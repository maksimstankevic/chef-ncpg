
describe port(3000) do
  it { should be_listening }
end

describe docker_container('grafana') do
  it { should exist }
  it { should be_running }
  its('ports') { should eq '0.0.0.0:3000->3000/tcp' }
end

# verify that datasources contain a prometheus one
describe http('http://127.0.0.1:3000/api/datasources',
              auth: { user: 'root', pass: 'pass' },
              method: 'GET') do
  its('status') { should cmp 200 }
  its('headers.Content-Type') { should cmp 'application/json' }
end

# verify that dashboard that we installed exist
describe http('http://127.0.0.1:3000/api/search',
              auth: { user: 'root', pass: 'pass' },
              method: 'GET') do
  its('status') { should cmp 200 }
  its('body') { should match %r{db\/docker-and-system-monitoring} }
  its('body') { should match %r{db\/1-node-exporter-for-prometheus-dashboard} }
  its('headers.Content-Type') { should cmp 'application/json' }
end
