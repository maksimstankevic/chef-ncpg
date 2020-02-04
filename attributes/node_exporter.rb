default['chef-ncpg']['node_exporter']['user'] = 'node_exporter'
default['chef-ncpg']['node_exporter']['group'] = 'node_exporter'
default['chef-ncpg']['node_exporter']['implement_via_docker'] = false
default['chef-ncpg']['node_exporter']['version'] = '0.18.1'
default['chef-ncpg']['node_exporter']['bin_name'] = 'node_exporter'
default['chef-ncpg']['node_exporter']['release_url'] = 'https://github.com/prometheus/node_exporter/releases/download/vXX.XX.XX/node_exporter-XX.XX.XX.linux-amd64.tar.gz'
default['chef-ncpg']['node_exporter']['checksum_url'] = 'https://github.com/prometheus/node_exporter/releases/download/vXX.XX.XX/sha256sums.txt'
default['chef-ncpg']['node_exporter']['args'] = [
  '--web.listen-address=":9100"',
  '--collector.filesystem.ignored-mount-points="^/(dev|proc|sys|var/lib/docker/.+)($|/)"'
]
