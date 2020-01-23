require_relative 'base_service'

class Chef
  class Resource
    class GrafanaDocker < BaseDocker

      provides(:grafana_docker)

      attribute(
        :user, kind_of: String, default: lazy { node['chef-ncpg']['user'] }
      )

      attribute(
        :group, kind_of: String, default: lazy { node['chef-ncpg']['group'] }
      )

      attribute(
        :user_shell, kind_of: String, default: lazy { node['chef-ncpg']['user_shell'] }
      )

      attribute(
        :grafana_password, kind_of: String, default: lazy { node['chef-ncpg']['grafana']['grafana_pass'] }
      )

    end
  end

  class Provider
    class GrafanaDocker < BaseDocker

      provides(:grafana_docker)


      def deriver_install
        grafana_container
        #wait_for_grafana
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
        new_resource.grafana_password
      end

      def grafana_container
        docker_image "grafanaImage" do
          repo 'grafana/grafana'
          action :pull_if_missing
        end

        # docker_container 'grafana' do
        #   repo 'grafana/grafana'
        #   port node['coolClothes']['docker']['net']['grafanaPort'] + \
        #   ':' + \
        #   node['coolClothes']['docker']['net']['grafanaPort']
        #   env 'GF_SECURITY_ADMIN_PASSWORD=' + \
        #   node['coolClothes']['docker']['net']['grafanaPass']
        #   restart_policy 'always'
        #   action :run_if_missing
        #   network_mode 'pg'
        #   ip_address node['coolClothes']['docker']['net']['grafanaContainerIp']
        # end
      end

      #grafana takes time to start, below is grafanaUpWaiter
      def wait_for_grafana
        ruby_block 'makeSureGrafanaIsUp' do
          block do
            server = node['coolClothes']['docker']['net']['grafanaContainerIp']
            port = Integer(node['coolClothes']['docker']['net']['grafanaPort'])
            needToBreak = false
            while true do
              begin
                Timeout.timeout(5) do
                  Socket.tcp(server, port){}
                end
                Chef::Log.info 'Successfully connected to Grafana'
                needToBreak = true
              rescue
                Chef::Log.info 'Grafana not up yet'
              end
              break if needToBreak
            end
          end
        end
      end

    end
  end
end
