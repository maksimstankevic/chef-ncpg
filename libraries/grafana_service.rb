class Chef
  class Resource
    # resource for installing/configuring grafana via docker
    class GrafanaService < BaseService
      provides(:grafana_service)
    end
  end

  class Provider
    # resource for installing/configuring grafana via docker
    class GrafanaService < BaseService
      provides(:grafana_service)

      def action_install
        converge_by("chef-ncpg installing #{new_resource.name}") do
          notifying_block do
            deriver_install
          end
        end
      end

      protected

      def deriver_install
        raise 'No service implementation for Grafana.'\
        ' Please use docker option.'
      end
    end
  end
end
