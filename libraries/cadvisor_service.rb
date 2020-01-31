class Chef
  class Resource
    class CadvisorService < BaseService
      provides(:cadvisor_service)

      attribute(
        :user, kind_of: String, default: lazy { node['chef-ncpg']['cadvisor']['user'] }
      )

      attribute(
        :group, kind_of: String, default: lazy { node['chef-ncpg']['cadvisor']['group'] }
      )

      attribute(
        :version, kind_of: String, default: lazy { node['chef-ncpg']['cadvisor']['version'] }
      )

      attribute(
        :bin_name, kind_of: String, default: lazy { node['chef-ncpg']['cadvisor']['bin_name'] }
      )

      attribute(
        :ini_options, kind_of: Array, default: lazy { node['chef-ncpg']['cadvisor']['ini_options'] }
      )


    end
  end

  class Provider
    # Mysqlctld service installation and configuration
    class CadvisorService < BaseService
      provides(:cadvisor_service)

      def action_delete
        service new_resource.service_name do
          action %i[stop disable]
        end
      end

      protected

      def deriver_install
        #install_binary
        #install_service
        #start_service
      end
    end
  end
end
