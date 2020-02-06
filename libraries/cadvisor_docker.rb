class Chef
  class Resource
    # cadvisor resource for installation/configuration via docker
    class CadvisorDocker < BaseDocker
      provides(:cadvisor_docker)
    end
  end

  class Provider
    # cadvisor resource for installation/configuration via docker
    class CadvisorDocker < BaseDocker
      provides(:cadvisor_docker)

      def action_install
        converge_by("chef-ncpg installing #{new_resource.bin_name}") do
          notifying_block do
            deriver_install
          end
        end
      end

      protected

      def deriver_install
        raise 'No docker implementation for Cadvisor.'\
        ' Please use service option.'
      end
    end
  end
end
