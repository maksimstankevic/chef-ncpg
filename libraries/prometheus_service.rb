class Chef
  class Resource
    class PrometheusService < BaseService
      provides(:prometheus_service)

    end
  end

  class Provider
    class PrometheusService < BaseService
      provides(:prometheus_service)

      def action_install
        converge_by("chef-ncpg installing #{new_resource.name}") do
          notifying_block do
            deriver_install
          end
        end
      end

      protected

      def deriver_install
        raise  'No service implementation for Prometheus. Please use docker option.'
      end

    end
  end
end
