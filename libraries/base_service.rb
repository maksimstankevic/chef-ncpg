require 'poise'
require 'chef/resource'
require 'chef/provider'

class Chef
  class Resource
    # base ncpg resource for systemd implementations
    class BaseService < Chef::Resource
      include Poise

      actions(:install)

      attribute(
        :user,
        kind_of: String,
        default: lazy { raise 'not implemented' }
      )
      attribute(
        :group,
        kind_of: String,
        default: lazy { raise 'not implemented' }
      )
      attribute(
        :bin_path,
        kind_of: String,
        default: lazy { node['chef-ncpg']['bin_path'] }
      )
      attribute(
        :bin_name,
        kind_of: String,
        default: lazy { raise 'Not implemented' }
      )
      attribute(
        :user_shell,
        kind_of: String,
        default: lazy { node['chef-ncpg']['user_shell'] }
      )
      attribute(
        :service_name,
        kind_of: String,
        default: lazy { bin_name }
      )
      attribute(
        :service_unit_after,
        kind_of: Array,
        default: %w[network-online.target]
      )
      attribute(
        :service_restart,
        kind_of: String,
        default: 'on-failure'
      )
    end
  end

  class Provider
    # base ncpg resource for systemd implementations
    # rubocop:disable Metrics/ClassLength
    class BaseService < Chef::Provider
      include Poise

      def action_install
        converge_by('chef-ncpg'\
          " installing service for #{new_resource.bin_name}") do
          notifying_block do
            validate!
            create_user
            deriver_install
          end
        end
      end

      protected

      def deriver_install
        raise 'Not implemented'
      end

      def release_url
        raise 'Not implemented'
      end

      def release_checksum
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

      def release_cache_path
        @url = release_url
        @checksum = release_checksum
        @archive_cache_path = ::File.join(@cache_path, @archive_file_name)
        @archive_cache_path.gsub(/\.tar\.gz$/, '')
      end

      # rubocop:disable Metrics/MethodLength
      def cache_binary
        url = @url
        checksum = @checksum
        archive_cache_path = @archive_cache_path
        cache_path = @cache_path

        bash "extract bin file #{archive_cache_path}" do
          cwd cache_path
          user 'root'
          code "tar -zxf #{archive_cache_path}"
          action :nothing
        end

        remote_file archive_cache_path do
          source url
          owner 'root'
          group 'root'
          mode '0640'
          checksum checksum
          notifies :run,
                   "bash[extract bin file #{archive_cache_path}]",
                   :immediate
        end
      end
      # rubocop:enable Metrics/MethodLength

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def install_binary
        bin_name_with_version = "#{new_resource.bin_name}"\
        "-#{new_resource.version}"
        bin_path_with_version = ::File.join(new_resource.bin_path,
                                            bin_name_with_version)
        bin_source_path = ::File.join(release_cache_path, new_resource.bin_name)

        cache_binary

        file bin_path_with_version do
          content(lazy { IO.read(bin_source_path) })
          mode '0755'
          action :create
          notifies :restart, "service[#{new_resource.service_name}]", :delayed
        end

        link ::File.join(new_resource.bin_path, new_resource.bin_name) do
          to bin_path_with_version
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      def start_service
        service new_resource.service_name do
          supports(
            status: true,
            restart: true
          )
          action %i[enable start]
        end
      end

      def service_args
        args = new_resource.service_args.dup
        args.join(" \\\n ")
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def install_service
        cmd = "#{bin_location} \\\n #{service_args}"
        service_name = new_resource.service_name
        bin_path = new_resource.bin_path
        exec_start = ::File.join(bin_path, "#{service_name}.sh")

        template exec_start do
          source 'wrap.sh.erb'
          variables cmd: cmd
          owner new_resource.user
          group new_resource.group
          mode '0750'
          cookbook 'chef-ncpg'
          notifies :restart, "service[#{new_resource.service_name}]", :delayed
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
          end
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      private

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def create_user
        group new_resource.group do
          action :nothing
        end

        user new_resource.user do
          group new_resource.group
          shell new_resource.user_shell
          action :create
          notifies :create, "group[#{new_resource.group}]", :before
        end

        group 'docker' do
          append true
          members new_resource.user
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
    end
    # rubocop:enable Metrics/ClassLength
  end
end
