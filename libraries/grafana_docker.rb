class Chef
  class Resource
    class GrafanaDocker < BaseDocker

      provides(:grafana_docker)

      attribute(
        :user, kind_of: String, default: lazy { node['chef-ncpg']['grafana']['user'] }
      )

      attribute(
        :group, kind_of: String, default: lazy { node['chef-ncpg']['grafana']['group'] }
      )

      attribute(
        :password, kind_of: String, default: lazy { node['chef-ncpg']['grafana']['grafana_pass'] }
      )

      attribute(
        :version, kind_of: String, default: lazy { node['chef-ncpg']['grafana']['version'] }
      )

      attribute(
        :version_lock, kind_of: [TrueClass, FalseClass], default: lazy { node['chef-ncpg']['grafana']['version_lock'] }
      )

      attribute(
        :port, kind_of: String, default: lazy { node['chef-ncpg']['grafana']['port'] }
      )

      attribute(
        :docker_port, kind_of: String, default: lazy { node['chef-ncpg']['docker']['grafana']['docker_host_port'] }
      )

      attribute(
        :container_ip, kind_of: String, default: lazy { node['chef-ncpg']['docker']['grafana']['container_ip'] }
      )

      attribute(
        :grafana_env, kind_of: Array, default: lazy { node['chef-ncpg']['grafana']['env'] }
      )

    end
  end

  class Provider
    class GrafanaDocker < BaseDocker

      provides(:grafana_docker)


      def deriver_install
        grafana_container
      end

      protected

      def validate!
        super
        if grafana_pass.nil? then
          raise 'Please set grafana admin password'
        end
      end

      private

      def grafana_pass
        new_resource.password
      end

      def grafana_container
        ver = new_resource.version
        port = new_resource.port
        docker_port = new_resource.docker_port
        password = new_resource.password
        container_ip = new_resource.container_ip

        env = new_resource.grafana_env.dup

        env = env.map do |o|
          if o.include? "GF_SECURITY_ADMIN_PASSWORD"
            'GF_SECURITY_ADMIN_PASSWORD=' + password
          elsif o.include? "GF_SERVER_HTTP_PORT"
            'GF_SERVER_HTTP_PORT=' + port
          else
            o
          end
        end

        docker_image "grafanaImage" do
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
          network_mode "#{new_resource.docker_net_name}"
          ip_address container_ip
          #below extra config is to workaround change detection issues
          #in docker cookbook, it still incorrectly detectss changed
          #ip_address though and always redeploys
          ipc_mode 'shareable'
          working_dir '/usr/share/grafana'
          user 'grafana'
        end
      end
    end
  end
end
