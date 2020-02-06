class Chef
  class Resource
    # resource for cadvisor service installation/configuration
    class CadvisorService < BaseService
      provides(:cadvisor_service)

      attribute(
        :user,
        kind_of: String,
        default: lazy { node['chef-ncpg']['cadvisor']['user'] }
      )

      attribute(
        :group,
        kind_of: String,
        default: lazy { node['chef-ncpg']['cadvisor']['group'] }
      )

      attribute(
        :version,
        kind_of: String,
        default: lazy { node['chef-ncpg']['cadvisor']['version'] }
      )

      attribute(
        :release_url_template,
        kind_of: String,
        default: lazy { node['chef-ncpg']['cadvisor']['release_url'] }
      )

      attribute(
        :checksum_url_template,
        kind_of: String,
        default: lazy { node['chef-ncpg']['cadvisor']['checksum_url'] }
      )

      attribute(
        :bin_name,
        kind_of: String,
        default: lazy { node['chef-ncpg']['cadvisor']['bin_name'] }
      )

      attribute(
        :service_args,
        kind_of: Array,
        default: lazy { node['chef-ncpg']['cadvisor']['args'] }
      )
    end
  end

  class Provider
    # resource for cadv isor service installation/configuration
    class CadvisorService < BaseService
      provides(:cadvisor_service)

      def action_delete
        service new_resource.service_name do
          action %i[stop disable]
        end
      end

      protected

      def release_url
        templated_url = new_resource.release_url_template
        ver = new_resource.version
        @binary_file_name = ::File.basename(templated_url)
        templated_url.gsub('XX.XX.XX', ver)
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def release_checksum
        templated_url = new_resource.checksum_url_template
        ver = new_resource.version
        checksum_url = templated_url.gsub(/XX.XX.XX/, ver)
        @cache_path = Chef::Config[:file_cache_path]
        cache_path = @cache_path
        checksums_file_path = ::File.join(cache_path,
                                          "cadvisor_#{ver}_sha256_html.txt")

        bash 'get cadvisor sha checksum page html' do
          cwd cache_path
          user 'root'
          code "curl -s #{checksum_url} > #{checksums_file_path}"
          not_if { ::File.exist?(checksums_file_path) }
        end.run_action(:run)

        # rubocop:disable Style/GuardClause
        unless ::File.exist?(checksums_file_path)
          ::File.readlines(checksums_file_path).grep(/SHA256/)[0]
                .chomp
                .gsub(/\s+/, ' ')
                .split(' ')[1]
                .split('<')[0]
        end
        # rubocop:enable Style/GuardClause
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def release_cache_path
        @url = release_url
        @checksum = release_checksum
        @binary_cache_path = ::File.join(@cache_path, @binary_file_name)
        @binary_cache_path
      end

      def cache_binary
        url = @url
        checksum = @checksum
        binary_cache_path = @binary_cache_path

        directory binary_cache_path

        remote_file "#{binary_cache_path}/#{@binary_file_name}" do
          source url
          checksum checksum
        end
      end

      def deriver_install
        install_binary
        install_service
        start_service
      end
    end
  end
end
