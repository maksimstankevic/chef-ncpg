require 'poise'
require 'chef/resource'
require 'chef/provider'

class Chef
  class Resource
    class BaseService < Chef::Resource
      include Poise

      actions(:install)

      attribute(
        :user,
        kind_of: String,
        default: lazy { node['chef-ncpg']['user'] }
      )
      attribute(
        :group,
        kind_of: String,
        default: lazy { node['chef-ncpg']['group'] }
      )
      attribute(
        :bin_path,
        kind_of: String,
        default: '/usr/local/bin'
      )
      attribute(
        :bin_name,
        kind_of: String,
        default: lazy { raise 'Not implemented' }
      )
      attribute(
        :ncpg_user_shell,
        kind_of: String,
        default: '/bin/false'
      )

      attribute(
        :service_name,
        kind_of: String,
        default: lazy { bin_name }
      )

      attribute(
        :service_unit_after,
        kind_of: Array,
        default: %w[syslog.target network.target]
      )
      attribute(
        :service_restart,
        kind_of: String,
        default: 'on-failure'
      )

      attribute(
        :ncpgroot,
        kind_of: String,
        default: '/var/lib/ncpg'
      )

      attribute(
        :ncpgdataroot,
        kind_of: String,
        default: '/var/lib/ncpgdataroot'
      )

    end
  end

  class Provider
    class BaseService < Chef::Provider
      include Poise

      def additional_args
        args = {}
        args['log_dir'] = service_log_dir if new_resource.args['log_dir'].nil?
        args
      end

      def action_install
        converge_by("chef-ncpg installing #{new_resource.name}") do
          notifying_block do
            validate!
            create_user
            create_directories [
              new_resource.ncpgroot,
              new_resource.ncpgdataroot,
              ncpg_bin_path,
              ncpg_config_path,
              base_log_dir,
              service_log_dir
            ]
            deriver_install
          end
        end
      end

      protected

      def service_log_dir
        @service_log_dir ||= ::File.join(base_log_dir, new_resource.service_name)
      end

      def base_log_dir
        @base_log_dir ||= '/var/log/ncpg'
      end

      def ncpg_bin_path
        @ncpg_bin_path ||= ::File.join(new_resource.ncpgroot, 'bin')
      end

      def ncpg_config_path
        @ncpg_config_path ||= ::File.join(new_resource.ncpgroot, 'config')
      end

      def create_directories(dirs)
        Array(dirs).each do |dir|
          directory dir do
            owner new_resource.user
            group new_resource.group
            mode '0750'
          end
        end
      end

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


      def start_service
        service new_resource.service_name do
          supports(
            status: true,
            restart: true
          )
          action %i[enable start]
        end
      end

      def service_args(args = new_resource.args)
        args
          .merge(additional_args)
          .reject { |_k, v| v.nil? }
          .map { |k, v| "-#{k}=#{v}" }
          .join(" \\\n ")
      end

      def ncpg_environment
        {
          'NCPGROOT' => new_resource.ncpgroot,
          'NCPGDATAROOT' => new_resource.ncpgdataroot,
        }
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
