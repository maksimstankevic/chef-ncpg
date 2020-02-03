default['chef-ncpg']['cadvisor']['user'] = 'cadvisor'
default['chef-ncpg']['cadvisor']['group'] = 'cadvisor'
default['chef-ncpg']['cadvisor']['implement_via_docker'] = false
default['chef-ncpg']['cadvisor']['version'] = '0.34.0'
default['chef-ncpg']['cadvisor']['bin_name'] = 'cadvisor'
default['chef-ncpg']['cadvisor']['release_url'] = 'https://github.com/google/cadvisor/releases/download/vXX.XX.XX/cadvisor'
default['chef-ncpg']['cadvisor']['checksum_url'] = 'https://github.com/google/cadvisor/releases/tag/vXX.XX.XX'
default['chef-ncpg']['cadvisor']['args'] = [
  '-port 8080',
  '-log_file /tmp/cadvisor.log'
]
