require 'poise'
require 'chef/resource'
require 'chef/provider'

class Chef
  class Resource
    class BaseService < Chef::Resource
      include Poise

      actions(:install)

      attribute(
        :user, kind_of: String, default: lazy { raise 'not implemented' }
      )
      attribute(
        :group, kind_of: String, default: lazy { raise 'not implemented' }
      )
      attribute(
        :bin_path, kind_of: String, default: lazy { node['chef-ncpg']['bin_path'] }'
      )
      attribute(
        :bin_name, kind_of: String, default: lazy { raise 'Not implemented' }
      )
      attribute(
        :user_shell, kind_of: String, default: lazy { node['chef-ncpg']['user_shell'] }
      )

      attribute(
        :service_name, kind_of: String, default: lazy { bin_name }
      )

      attribute(
        :service_unit_after, kind_of: Array, default: %w[network-online.target]
      )
      attribute(
        :service_restart, kind_of: String, default: 'on-failure'
      )

    end
  end

  class Provider
    class BaseService < Chef::Provider
      include Poise

      def action_install
        converge_by("chef-ncpg installing #{new_resource.name}") do
          notifying_block do
            validate!
            create_user
            install_binary
            deriver_install
          end
        end
      end

      protected

      def deriver_install
        raise 'Not implemented'
      end

      def validate!
        platform_supported?
      end

      def platform_supported?
        platform = node['platform']
        return if %w[centos].include?(platform)
        raise "Platform #{platform} is not supported"
      end

      def bin_location
        @bin_location ||= ::File.join(
          new_resource.bin_path,
          new_resource.bin_name
        )
      end

      def release_hash
        @vitess_release_hash ||= {}
        @vitess_release_hash[new_resource.bin_name] ||= new_resource.version.split('-')[1]
      end

      def release_url
        node['vitess']['releases'][vitess_release_hash]['url']
      end

      def release_checksum
        node['vitess']['releases'][vitess_release_hash]['checksum']
      end

      def release_cache_path
        cache_path = Chef::Config[:file_cache_path]
        release_url = vitess_release_url
        archive_file_name = ::File.basename(release_url)
        archive_cache_path = ::File.join(cache_path, archive_file_name)
        archive_cache_path.gsub(/\.tar\.gz$/, '')
      end

      def cache_binary
        cache_path = Chef::Config[:file_cache_path]
        release_url = release_url
        release_checksum = release_checksum
        archive_file_name = ::File.basename(release_url)
        archive_cache_path = ::File.join(cache_path, archive_file_name)

        bash "extract vitess bin file #{archive_cache_path}" do
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
          notifies :run, "bash[extract vitess bin file #{archive_cache_path}]", :immediate
        end
      end

      def install_binary
        bin_name_with_release = "#{new_resource.bin_name}-#{vitess_release_hash}"
        bin_path_with_release = ::File.join(new_resource.bin_path, bin_name_with_release)
        bin_source_path = ::File.join(vitess_release_cache_path, 'bin', new_resource.bin_name)

        cache_binary

        bash "copy #{bin_source_path} to #{bin_path_with_release}" do
          user 'root'
          code <<-CODE
            cp #{bin_source_path} #{bin_path_with_release} &&
            chown root:root #{bin_path_with_release} &&
            chmod 0755 #{bin_path_with_release}
          CODE
          creates bin_path_with_release
        end

        link ::File.join(new_resource.bin_path, new_resource.bin_name) do
          to bin_path_with_release
        end
      end

      def start_service
        service new_resource.service_name do
          supports(
            status: true,
            restart: true
          )
          action %i[enable start]
        end
      end

      def install_service
        cmd = "#{bin_location} \\\n #{service_args}"
        service_name = new_resource.service_name
        exec_start = ::File.join(ncpg_bin_path, "#{service_name}.sh")
        env = ncpg_environment

        template exec_start do
          source 'wrap.sh.erb'
          variables cmd: cmd
          owner new_resource.user
          group new_resource.group
          mode '0750'
          cookbook 'chef-ncpg'
        end

        systemd_service service_name do
          unit do
            description "Chef managed #{service_name} service"
            after Array(new_resource.service_unit_after).join(' ')
          end

          install do
            wanted_by 'multi-user.target'
          end

          service do
            type 'simple'
            exec_start exec_start
            restart new_resource.service_restart
            user new_resource.user
            group new_resource.group
            environment env
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      private

      def create_user
        group new_resource.group do
          action :nothing
        end

        user new_resource.user do
          group new_resource.group
          shell new_resource.ncpg_user_shell
          action :create
          notifies :create, "group[#{new_resource.group}]", :before
        end
      end
    end
  end
end
