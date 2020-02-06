class Chef
  class Resource
    # resource for installing/conffiguring node_exporter via systemd
    class NodeExporterService < BaseService
      provides(:node_exporter_service)

      attribute(
        :user,
        kind_of: String,
        default: lazy { node['chef-ncpg']['node_exporter']['user'] }
      )

      attribute(
        :group,
        kind_of: String,
        default: lazy { node['chef-ncpg']['node_exporter']['group'] }
      )

      attribute(
        :version,
        kind_of: String,
        default: lazy { node['chef-ncpg']['node_exporter']['version'] }
      )

      attribute(
        :release_url_template,
        kind_of: String,
        default: lazy { node['chef-ncpg']['node_exporter']['release_url'] }
      )

      attribute(
        :bin_name,
        kind_of: String,
        default: lazy { node['chef-ncpg']['node_exporter']['bin_name'] }
      )

      attribute(
        :service_args,
        kind_of: Array,
        default: lazy { node['chef-ncpg']['node_exporter']['args'] }
      )
    end
  end

  class Provider
    # resource for installing/conffiguring node_exporter via systemd
    class NodeExporterService < BaseService
      provides(:node_exporter_service)

      def action_delete
        service new_resource.service_name do
          action %i[stop disable]
        end
      end

      protected

      def release_url
        @templated_url = new_resource.release_url_template
        @ver = new_resource.version
        @archive_file_name = ::File.basename(@templated_url
                                   .gsub('XX.XX.XX', @ver))
        @templated_url.gsub('XX.XX.XX', @ver)
      end

      # rubocop:disable Metrics/MethodLength
      def release_checksum
        checksum_file_url = @templated_url.gsub(/vXX.XX.XX.*/,
                                                "v#{@ver}/sha256sums.txt")

        @cache_path = Chef::Config[:file_cache_path]
        checksums_file_path = ::File.join(@cache_path, 'sha256sums.txt')

        remote_file checksums_file_path do
          source checksum_file_url
        end.run_action(:create)

        # rubocop:disable Style/GuardClause
        if ::File.exist?(checksums_file_path)
          ::File.readlines(checksums_file_path)
                .grep(/#{@archive_file_name}/)[0]
                .chomp
                .gsub(/^(\w+).*$/, '\1')
        end
        # rubocop:enable Style/GuardClause
      end
      # rubocop:enable Metrics/MethodLength

      def deriver_install
        install_binary
        install_service
        start_service
      end
    end
  end
end
