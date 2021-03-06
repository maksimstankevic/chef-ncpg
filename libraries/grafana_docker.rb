class Chef
  class Resource
    # resource for installing/configuring gafana via docker
    class GrafanaDocker < BaseDocker
      provides(:grafana_docker)

      attribute(
        :user,
        kind_of: String,
        default: lazy { node['chef-ncpg']['grafana']['user'] }
      )

      attribute(
        :group,
        kind_of: String,
        default: lazy { node['chef-ncpg']['grafana']['group'] }
      )

      attribute(
        :password,
        kind_of: String,
        default: lazy { node['chef-ncpg']['grafana']['grafana_pass'] }
      )

      attribute(
        :version,
        kind_of: String,
        default: lazy { node['chef-ncpg']['grafana']['version'] }
      )

      attribute(
        :version_lock,
        kind_of: [TrueClass, FalseClass],
        default: lazy { node['chef-ncpg']['grafana']['version_lock'] }
      )

      attribute(
        :port,
        kind_of: String,
        default: lazy { node['chef-ncpg']['grafana']['port'] }
      )

      attribute(
        :docker_port,
        kind_of: String,
        default:
        lazy { node['chef-ncpg']['docker']['grafana']['docker_host_port'] }
      )

      attribute(
        :container_ip,
        kind_of: String,
        default: lazy { node['chef-ncpg']['docker']['grafana']['container_ip'] }
      )

      attribute(
        :grafana_env,
        kind_of: Array,
        default: lazy { node['chef-ncpg']['grafana']['env'] }
      )

      attribute(
        :add_prometheus_datasource,
        kind_of: [TrueClass, FalseClass],
        default:
        lazy { node['chef-ncpg']['grafana']['auto_add_prometheus_datasource'] }
      )

      attribute(
        :add_dashboards,
        kind_of: [TrueClass, FalseClass],
        default: lazy { node['chef-ncpg']['grafana']['auto_add_dashboards'] }
      )

      attribute(
        :dashboards_dir_name,
        kind_of: String,
        default: lazy do
          node['chef-ncpg']['grafana']\
          ['dashboards_folder_name_in_cookbook_files']
        end
      )
    end
  end

  class Provider
    # resource for installing/configuring gafana via docker
    class GrafanaDocker < BaseDocker
      provides(:grafana_docker)

      def deriver_install
        grafana_container
        add_prometheus_datasource\
        if new_resource.add_prometheus_datasource
        add_dashboards\
        if new_resource.add_prometheus_datasource && new_resource.add_dashboards
      end

      protected

      def validate!
        super
        raise 'Please set grafana admin password' if grafana_pass.nil?
      end

      private

      def grafana_pass
        new_resource.password
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def grafana_container
        ver = new_resource.version
        port = new_resource.port
        docker_port = new_resource.docker_port
        password = new_resource.password
        container_ip = new_resource.container_ip

        env = new_resource.grafana_env.dup

        env = env.map do |o|
          if o.include? 'GF_SECURITY_ADMIN_PASSWORD'
            'GF_SECURITY_ADMIN_PASSWORD=' + password
          elsif o.include? 'GF_SERVER_HTTP_PORT'
            'GF_SERVER_HTTP_PORT=' + port
          else
            o
          end
        end

        docker_image 'grafanaImage' do
          repo 'grafana/grafana'
          tag ver if new_resource.version_lock
          action :pull_if_missing
        end

        docker_container 'grafana' do
          repo 'grafana/grafana'
          tag ver if new_resource.version_lock
          port docker_port + ':' + port
          env env
          restart_policy 'always'
          action :run
          network_mode new_resource.docker_net_name
          ip_address container_ip
          # below extra config is to workaround change detection issues
          # in docker cookbook, it still incorrectly detectss changed
          # ip_address though and always redeploys
          ipc_mode 'shareable'
          working_dir '/usr/share/grafana'
          user 'grafana'
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def add_prometheus_datasource
        grafana_ip = new_resource.container_ip
        grafana_port = new_resource.docker_port
        grafana_env_arr = new_resource.grafana_env.dup
        grafana_admin_user = \
          grafana_env_arr.grep(/^GF_SECURITY_ADMIN_USER=/)[0].match(/[^=]+$/)[0]
        grafana_admin_pass = new_resource.password
        grafana_auth = "#{grafana_admin_user}:#{grafana_admin_pass}"
        prometheus_ip = \
          node['chef-ncpg']['docker']['prometheus']['container_ip']
        prometheus_port = \
          node['chef-ncpg']['docker']['prometheus']['docker_host_port']

        http_request 'add prometheus datasource' do
          action :post
          url "http://#{grafana_ip}:#{grafana_port}/api/datasources"
          message({ name: 'prometheus',
                    type: 'prometheus',
                    url: "http://#{prometheus_ip}:#{prometheus_port}",
                    access: 'proxy' }.to_json)
          headers('AUTHORIZATION' => "Basic #{Base64.encode64(grafana_auth)}",\
                  'Content-Type' => 'application/json')
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def add_dashboards
        remote_directory '/tmp/dashboards' do
          source new_resource.dashboards_dir_name
        end.run_action(:create)

        dashboards = Dir.entries('/tmp/dashboards')
                        .reject { |f| ::File.directory? f }

        grafana_ip = new_resource.container_ip
        grafana_port = new_resource.docker_port
        grafana_env_arr = new_resource.grafana_env.dup
        grafana_admin_user = \
          grafana_env_arr.grep(/^GF_SECURITY_ADMIN_USER=/)[0].match(/[^=]+$/)[0]
        grafana_admin_pass = new_resource.password
        grafana_auth = "#{grafana_admin_user}:#{grafana_admin_pass}"

        dashboards.each do |f|
          http_request 'add grafana dashboards' do
            action :post
            url "http://#{grafana_ip}:#{grafana_port}/api/dashboards/db"
            message(lazy { IO.read("/tmp/dashboards/#{f}") })
            headers('AUTHORIZATION' => 'Basic'\
                    " #{Base64.encode64(grafana_auth)}",\
                    'Content-Type' => 'application/json')
          end
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
    end
  end
end
