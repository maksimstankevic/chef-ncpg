class Chef
  class Resource
    class PrometheusDocker < BaseDocker

      provides(:prometheus_docker)

      attribute(
        :user, kind_of: String, default: lazy { node['chef-ncpg']['prometheus']['user'] }
      )

      attribute(
        :group, kind_of: String, default: lazy { node['chef-ncpg']['prometheus']['group'] }
      )

      attribute(
        :version, kind_of: String, default: lazy { node['chef-ncpg']['prometheus']['version'] }
      )

      attribute(
        :version_lock, kind_of: [TrueClass, FalseClass], default: lazy { node['chef-ncpg']['prometheus']['version_lock'] }
      )

      attribute(
        :port, kind_of: String, default: lazy { node['chef-ncpg']['prometheus']['port'] }
      )

      attribute(
        :docker_port, kind_of: String, default: lazy { node['chef-ncpg']['docker']['prometheus']['docker_host_port'] }
      )

      attribute(
        :container_ip, kind_of: String, default: lazy { node['chef-ncpg']['docker']['prometheus']['container_ip'] }
      )

      attribute(
        :ini_options, kind_of: Array, default: lazy { node['chef-ncpg']['prometheus']['ini_options'] }
      )

    end
  end

  class Provider
    class PrometheusDocker < BaseDocker

      provides(:prometheus_docker)


      def deriver_install
        prometheus_container
      end

      protected

      def validate!
        super
        # if grafana_pass.nil? then
        #   raise 'Please set grafana admin password'
        # end
      end

      private

      def prometheus_container
        ver = new_resource.version
        port = new_resource.port
        docker_port = new_resource.docker_port
        container_ip = new_resource.container_ip

        docker_image "prometheusImage" do
          repo 'prom/prometheus'
          tag ver if new_resource.version_lock
          action :pull_if_missing
        end

        docker_container 'prometheus' do
          repo 'prom/prometheus'
          tag ver if new_resource.version_lock
          port docker_port + ':' + port
          restart_policy 'always'
          action :run
          network_mode "#{new_resource.docker_net_name}"
          ip_address container_ip
        end
      end
    end
  end
end
