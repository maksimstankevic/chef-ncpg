default['chef-ncpg']['cadvisor']['user'] = 'cadvisor'
default['chef-ncpg']['cadvisor']['group'] = 'cadvisor'
default['chef-ncpg']['cadvisor']['implement_via_docker'] = false
default['chef-ncpg']['cadvisor']['version'] = '0.18.1'
default['chef-ncpg']['cadvisor']['bin_name'] = 'node_exporter'
default['chef-ncpg']['cadvisor']['ini_options'] = {}
default['chef-ncpg']['cadvisor']['url'] = 'https://github.com/prometheus/node_exporter/releases/download/vXX.XX.XX/node_exporter-0.18.1.linux-amd64.tar.gz'
default['chef-ncpg']['cadvisor']['checksum_file_url'] = 'https://github.com/prometheus/node_exporter/releases/download/vXX.XX.XX/sha256sums.txt'
