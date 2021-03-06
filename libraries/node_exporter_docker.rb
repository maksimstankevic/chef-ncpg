class Chef
  class Resource
    # node_exporter resource for installation/configuration via docker
    class NodeExporterDocker < BaseDocker
      provides(:node_exporter_docker)
    end
  end

  class Provider
    # node_exporter resource for installation/configuration via docker
    class NodeExporterDocker < BaseDocker
      provides(:node_exporter_docker)

      def action_install
        converge_by("chef-ncpg installing #{new_resource.bin_name}") do
          notifying_block do
            deriver_install
          end
        end
      end

      protected

      def deriver_install
        raise 'No docker implementation for NodeExporter.'\
        ' Please use service option.'
      end
    end
  end
end
