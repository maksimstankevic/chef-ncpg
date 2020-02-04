default['chef-ncpg']['prometheus']['user'] = 'prometheus'
default['chef-ncpg']['prometheus']['group'] = 'prometheus'
default['chef-ncpg']['prometheus']['port'] = '9090'
default['chef-ncpg']['prometheus']['implement_via_docker'] = true
default['chef-ncpg']['prometheus']['version'] = 'v2.9.2'
default['chef-ncpg']['prometheus']['version_lock'] = true
default['chef-ncpg']['prometheus']['args'] = [
  '--web.listen-address="0.0.0.0:9090"',
  '--config.file="/etc/prometheus/prometheus.yml"',
  '--storage.tsdb.retention.time="5d"'
]
