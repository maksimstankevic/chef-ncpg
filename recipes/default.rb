#
# Cookbook:: chef-ncpg
# Recipe:: default
#
# Copyright:: 2020, The Authors, All Rights Reserved.

grafana_via_docker = node['chef-ncpg']['grafana']['implement_via_docker']

grafana_via_docker ? (grafana_docker 'ncpg' do grafana_password 'pass' end) : nil
