require_relative 'base_service'

class Chef
  class Resource
    class GrafanaService < BaseService
      provides(:grafana_service)

      attribute(
        :version,
        kind_of: String,
        default: lazy { node['chef-ncpg']['grafana']['version'] }
      )

      attribute(:bin_name, kind_of: String, default: 'grafana-server')
      attribute(:args, kind_of: Hash, default: lazy { node['chef-ncpg']['grafana']['args'] })
    end
  end

  class Provider
    class GrafanaService < BaseService
      provides(:grafana_service)

      def action_delete
        service new_resource.service_name do
          action %i[stop disable]
        end
      end

      def additional_args
        args = {}
        args
      end

      protected

      def deriver_install
        install_ncpg_binary
        install_service
        start_service
      end

      def ncpg_release_url
        node['chef-ncpg']['grafana']['url']
      end

      def ncpg_release_checksum
        node['chef-ncpg']['grafana']['checksum']
      end

      def ncpg_release_cache_path
        cache_path = Chef::Config[:file_cache_path]
        release_url = ncpg_release_url
        archive_file_name = ::File.basename(release_url)
        archive_cache_path = ::File.join(cache_path, archive_file_name)
        archive_cache_path.gsub(/\.tar\.gz$/, '')
      end

      def cache_ncpg_binary
        cache_path = Chef::Config[:file_cache_path]
        release_url = ncpg_release_url
        release_checksum = ncpg_release_checksum
        archive_file_name = ::File.basename(release_url)
        archive_cache_path = ::File.join(cache_path, archive_file_name)

        bash "extract ncpg bin file #{archive_cache_path}" do
          cwd cache_path
          user 'root'
          code "tar -zxf #{archive_cache_path}"
          action :nothing
        end

        remote_file archive_cache_path do
          source release_url
          owner 'root'
          group 'root'
          mode '0640'
          checksum release_checksum
          notifies :run, "bash[extract ncpg bin file #{archive_cache_path}]", :immediate
        end
      end

      def install_ncpg_binary
        bin_name_with_release = "#{new_resource.bin_name}-#{new_resource.version}"
        bin_path_with_release = ::File.join(new_resource.bin_path, bin_name_with_release)
        bin_source_path = ::File.join(ncpg_release_cache_path, 'bin', new_resource.bin_name)

        cache_ncpg_binary

        remote_file "copy #{bin_source_path} to #{bin_path_with_release}" do
          path "#{bin_path_with_release}"
          source "file://#{bin_source_path}"
          owner 'root'
          group 'root'
          mode 0755
        end

        link ::File.join(new_resource.bin_path, new_resource.bin_name) do
          to bin_path_with_release
        end
      end
    end
  end
end
