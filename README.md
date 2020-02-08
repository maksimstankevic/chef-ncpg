chef-ncpg cookbook

This cookbook provides custom Chef resources for installing and configuring
node_exporter, cadvisor, prometheus and grafana. Currently node_exporter and
cadvisor support systemd implementation and prometheus/grafana support docker
implementation.

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

default['chef-ncpg']['cadvisor']['args'] = [
  '-port 8080',
  '-log_file /tmp/cadvisor.log'
]

default['chef-ncpg']['prometheus']['args'] = [
  '--web.listen-address="0.0.0.0:9090"',
  '--config.file="/etc/prometheus/prometheus.yml"',
  '--storage.tsdb.retention.time="5d"'
]

You can add any underlying software supported configuration to those attributes
to have fine-grain control for all the components.

Example for setting up the whole system:

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

Check full version in default.rb recipe that is controlled by attributes to
decide which components to implement via docker and which via systemd, this
recipe as well supports restarting systemd services if configuration changes.
