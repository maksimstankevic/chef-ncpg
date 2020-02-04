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
        :args, kind_of: Array, default: lazy { node['chef-ncpg']['prometheus']['args'] }
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
      end

      private

      def prometheus_conf_file
        bridge_ip = new_resource.docker_bridge_ip.gsub(/\/.*/, '')
        # raise bridge_ip
        node_exporter_port_arr = node['chef-ncpg']['node_exporter']['args'].dup
        node_exporter_port = node_exporter_port_arr.grep(/^--web.listen-address=/)[0].match(/[0-9]+/)[0]
        cadvisor_port_arr = node['chef-ncpg']['cadvisor']['args'].dup
        cadvisor_port = cadvisor_port_arr.grep(/^-port /)[0].match(/[0-9]+/)[0]
        # raise cadvisor_port

        directory '/etc/prometheus'

        template "/etc/prometheus/prometheus.yml" do
          source 'prom.erb'
          variables(
            :docker_bridge_ip => bridge_ip,
            :node_exporter_port => node_exporter_port,
            :cadvisor_port => cadvisor_port
          )
        end
      end

      def prometheus_container
        ver = new_resource.version
        port = new_resource.port
        docker_port = new_resource.docker_port
        container_ip = new_resource.container_ip
        cmd = new_resource.args.join(' ')


        docker_image "prometheusImage" do
          repo 'prom/prometheus'
          tag ver if new_resource.version_lock
          action :pull_if_missing
        end

        prometheus_conf_file

        docker_container 'prometheus' do
          repo 'prom/prometheus'
          tag ver if new_resource.version_lock
          port docker_port + ':' + port
          restart_policy 'always'
          action :run
          network_mode "#{new_resource.docker_net_name}"
          ip_address container_ip
          volumes '/etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml'
          entrypoint '/bin/prometheus'
          cmd cmd
        end
      end
    end
  end
end
