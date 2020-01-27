#
# Cookbook:: chef-ncpg
# Recipe:: default
#
# Copyright:: 2020, The Authors, All Rights Reserved.

grafana_via_docker = node['chef-ncpg']['grafana']['implement_via_docker']
prometheus_via_docker = node['chef-ncpg']['prometheus']['implement_via_docker']

grafana_via_docker ? (grafana_docker 'ncpg' do password 'pass' end) : (grafana_service 'ncpg')
prometheus_via_docker ? (prometheus_docker 'ncpg') : (prometheus_service 'ncpg')
