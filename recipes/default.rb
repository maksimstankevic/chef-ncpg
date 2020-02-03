#
# Cookbook:: chef-ncpg
# Recipe:: default
#
# Copyright:: 2020, The Authors, All Rights Reserved.

grafana_via_docker = node['chef-ncpg']['grafana']['implement_via_docker']
prometheus_via_docker = node['chef-ncpg']['prometheus']['implement_via_docker']
node_exporter_via_docker = node['chef-ncpg']['node_exporter']['implement_via_docker']
cadvisor_via_docker = node['chef-ncpg']['cadvisor']['implement_via_docker']

grafana_via_docker ? (grafana_docker 'ncpg' do password 'pass' end) : (grafana_service 'ncpg')
prometheus_via_docker ? (prometheus_docker 'ncpg') : (prometheus_service 'ncpg')
node_exporter_via_docker ? (node_exporter_docker 'ncpg') : (node_exporter_service 'ncpg')
cadvisor_via_docker ? (cadvisor_docker 'ncpg') : (cadvisor_service 'ncpg')

#restart node_exporter service if different version installed or service args change
service "#{node['chef-ncpg']['node_exporter']['bin_name']}" do
  action :nothing
end

#restart cadvisor service if different version installed or service args change
service "#{node['chef-ncpg']['cadvisor']['bin_name']}" do
  action :nothing
end
