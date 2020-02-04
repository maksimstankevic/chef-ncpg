default['chef-ncpg']['grafana']['user'] = 'grafana'
default['chef-ncpg']['grafana']['group'] = 'grafana'

#this will override GF_SERVER_HTTP_PORT in env
default['chef-ncpg']['grafana']['port'] = '3000'

#this will override GF_SECURITY_ADMIN_PASSWORD in env
default['chef-ncpg']['grafana']['pass'] = ''

default['chef-ncpg']['grafana']['implement_via_docker'] = true
default['chef-ncpg']['grafana']['version'] = '6.5.3'
default['chef-ncpg']['grafana']['version_lock'] = true
default['chef-ncpg']['grafana']['env'] = [
  'GF_SECURITY_ADMIN_PASSWORD=will_get_iverridden',
  'GF_SERVER_HTTP_PORT=2000',
  'GF_SECURITY_ADMIN_USER=root'
]
