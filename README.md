# chef-ncpg cookbook

This cookbook provides custom Chef resources for installing and configuring
node_exporter, cadvisor, prometheus and grafana. Currently node_exporter and
cadvisor support systemd implementation and prometheus/grafana support docker
implementation.

## Requirements

 - Systemd

## Supported OS

 - CentOS 6

 ## Details

Using this cookbook's resources it is possible to build complete monitoring
system with prometheus scraping metrics from node_exporter and cadvisor, then
visualizing these data in grafana by adding promethus datasource. You can provide
any of your existing grafana dashboards as json files and have chef import them
to grafana.

There is a lot of configuration options available, check attributes folder for
the whole list. All binaries including docker are version-controlled, for docker
implementatios you can disable version locks if latest versions are preferred.
Every resource has "args" or "env" attribute that is used for configuring native
parameters for underlying software, for example:

```ruby
default['chef-ncpg']['cadvisor']['args'] = [
  '-port 8080',
  '-log_file /tmp/cadvisor.log'
]

default['chef-ncpg']['prometheus']['args'] = [
  '--web.listen-address="0.0.0.0:9090"',
  '--config.file="/etc/prometheus/prometheus.yml"',
  '--storage.tsdb.retention.time="5d"'
]
```

You can add any underlying software supported configuration to those attributes
to have fine-grain control for all the components.

## Attributes

default.rb
```ruby
default['chef-ncpg']['user_shell'] = '/bin/false'
default['chef-ncpg']['bin_path'] = '/usr/local/bin'
```
docker.rb
```ruby
default['chef-ncpg']['docker']['version'] = '19.03.5'
default['chef-ncpg']['docker']['version_lock'] = true
default['chef-ncpg']['docker']['net']['name'] = 'ncpg'
default['chef-ncpg']['docker']['net']['subnet'] = '192.168.13.0/29'
default['chef-ncpg']['docker']['net']['gateway'] = '192.168.13.1'
default['chef-ncpg']['docker']['bridge_ip'] = '172.17.0.1/24'
default['chef-ncpg']['docker']['grafana']['docker_host_port'] = '3000'
default['chef-ncpg']['docker']['grafana']['container_ip'] = '192.168.13.3'
default['chef-ncpg']['docker']['prometheus']['docker_host_port'] = '9090'
default['chef-ncpg']['docker']['prometheus']['container_ip'] = '192.168.13.2'
```
cadvisor.rb
```ruby
default['chef-ncpg']['cadvisor']['user'] = 'cadvisor'
default['chef-ncpg']['cadvisor']['group'] = 'cadvisor'
default['chef-ncpg']['cadvisor']['implement_via_docker'] = false
default['chef-ncpg']['cadvisor']['version'] = '0.34.0'
default['chef-ncpg']['cadvisor']['bin_name'] = 'cadvisor'
default['chef-ncpg']['cadvisor']['release_url'] = 'https://github.com/'\
'google/cadvisor/releases/download/vXX.XX.XX/cadvisor'
default['chef-ncpg']['cadvisor']['checksum_url'] = 'https://github.com'\
'/google/cadvisor/releases/tag/vXX.XX.XX'
default['chef-ncpg']['cadvisor']['args'] = [
  '-port 8080',
  '-log_file /tmp/cadvisor.log'
]
```
grafana.rb
```ruby
default['chef-ncpg']['grafana']['user'] = 'grafana'
default['chef-ncpg']['grafana']['group'] = 'grafana'

# this will override GF_SERVER_HTTP_PORT in env
default['chef-ncpg']['grafana']['port'] = '3000'

# this will override GF_SECURITY_ADMIN_PASSWORD in env
default['chef-ncpg']['grafana']['pass'] = ''

default['chef-ncpg']['grafana']['implement_via_docker'] = true
default['chef-ncpg']['grafana']['version'] = '6.5.3'
default['chef-ncpg']['grafana']['version_lock'] = true
default['chef-ncpg']['grafana']['env'] = [
  'GF_SECURITY_ADMIN_PASSWORD=will_get_overridden',
  'GF_SERVER_HTTP_PORT=2000',
  'GF_SECURITY_ADMIN_USER=root'
]
default['chef-ncpg']['grafana']['auto_add_prometheus_datasource'] = true

# below option will only trigger action
# when "auto_add_prometheus_datasource" is "true" as well
default['chef-ncpg']['grafana']['auto_add_dashboards'] = true

default['chef-ncpg']['grafana']\
['dashboards_folder_name_in_cookbook_files'] = 'dashboards'
```
node_exporter.rb
```ruby
default['chef-ncpg']['node_exporter']['user'] = 'node_exporter'
default['chef-ncpg']['node_exporter']['group'] = 'node_exporter'
default['chef-ncpg']['node_exporter']['implement_via_docker'] = false
default['chef-ncpg']['node_exporter']['version'] = '0.18.1'
default['chef-ncpg']['node_exporter']['bin_name'] = 'node_exporter'
default['chef-ncpg']['node_exporter']['release_url'] = 'https://github.com/'\
'prometheus/node_exporter/releases/'\
'download/vXX.XX.XX/node_exporter-XX.XX.XX.linux-amd64.tar.gz'
default['chef-ncpg']['node_exporter']['checksum_url'] = 'https://github.com/'\
'prometheus/node_exporter/releases/download/vXX.XX.XX/sha256sums.txt'
default['chef-ncpg']['node_exporter']['args'] = [
  '--web.listen-address=":9100"',
  '--collector.filesystem.ignored-mount-points='\
  '"^/(dev|proc|sys|var/lib/docker/.+)($|/)"'
]
```
prometheus.rb
```ruby
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
```

## Example for setting up the whole thing:

```ruby
node_exporter_service 'ncpg'

cadvisor_service 'ncpg'

grafana_docker 'ncpg' do
  password 'pass'
end)

prometheus_docker 'ncpg'

# restart node_exporter service if
# different version installed or service args change
service node['chef-ncpg']['node_exporter']['bin_name'] do
  action :nothing
end

# restart cadvisor service if different version installed or service args change
service node['chef-ncpg']['cadvisor']['bin_name'] do
  action :nothing
end
```

Check full version in default.rb recipe that is controlled by attributes to
decide which components to implement via docker and which via systemd, this
recipe as well supports restarting systemd services if configuration changes.

## Resources

Please, check libraries folder for details on implemented resources and their attributes.
