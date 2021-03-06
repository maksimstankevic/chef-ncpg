require 'poise'
require 'chef/resource'
require 'chef/provider'

class Chef
  class Resource
    # base ncpg cookbook resource for docker implementattions
    class BaseDocker < Chef::Resource
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
        :user_shell,
        kind_of: String,
        default: lazy { node['chef-ncpg']['user_shell'] }
      )

      attribute(
        :docker_version,
        kind_of: String,
        default: lazy { node['chef-ncpg']['docker']['version'] }
      )

      attribute(
        :docker_version_lock,
        kind_of: [TrueClass, FalseClass],
        default: lazy { node['chef-ncpg']['docker']['version_lock'] }
      )

      attribute(
        :docker_net_name,
        kind_of: String,
        default: lazy { node['chef-ncpg']['docker']['net']['name'] }
      )

      attribute(
        :docker_net_subnet,
        kind_of: String,
        default: lazy { node['chef-ncpg']['docker']['net']['subnet'] }
      )

      attribute(
        :docker_net_gateway,
        kind_of: String,
        default: lazy { node['chef-ncpg']['docker']['net']['gateway'] }
      )

      attribute(
        :docker_bridge_ip,
        kind_of: String,
        default: lazy { node['chef-ncpg']['docker']['bridge_ip'] }
      )
    end
  end

  class Provider
    # base ncpg cookbook resource for docker implementattions
    class BaseDocker < Chef::Provider
      include Poise

      def action_install
        converge_by("chef-ncpg installing #{new_resource.name}") do
          notifying_block do
            validate!
            create_user
            install_docker
            configure_docker_network
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

      def install_docker
        ver = new_resource.docker_version

        docker_service 'default' do
          install_method 'package'
          version ver if new_resource.docker_version_lock
          bip new_resource.docker_bridge_ip
          action %i[create start]
        end
      end

      def configure_docker_network
        docker_network new_resource.docker_net_name do
          subnet new_resource.docker_net_subnet
          gateway new_resource.docker_net_gateway
        end
      end
    end
  end
end
