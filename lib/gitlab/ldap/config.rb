# Load a specific server configuration
module Gitlab
  module LDAP
    class Config
      attr_accessor :provider, :options

      def self.enabled?
        Gitlab.config.ldap.enabled
      end

      def self.servers
        Gitlab.config.ldap.servers.values
      end

      def self.providers
        servers.map {|server| server['provider_name'] }
      end

      def initialize(provider)
        @provider = provider
        invalid_provider unless valid_provider?
        @options = config_for(provider)
      end

      def enabled?
        base_config.enabled
      end

      def adapter_options
        {
          host: options['host'],
          port: options['port'],
          encryption: encryption
        }.tap do |options|
          options.merge!(auth_options) if has_auth?
        end
      end

      def base
        options['base']
      end

      def uid
        options['uid']
      end

      def sync_ssh_keys?
        sync_ssh_keys.present?
      end

      # The LDAP attribute in which the ssh keys are stored
      def sync_ssh_keys
        options['sync_ssh_keys']
      end

      def user_filter
        options['user_filter']
      end

      def group_base
        options['group_base']
      end

      def admin_group
        options['admin_group']
      end

      def active_directory
        options['active_directory']
      end

      protected
      def base_config
        Gitlab.config.ldap
      end

      def config_for(provider)
        base_config.servers.values.find { |server| server['provider_name'] == provider }
      end

      def encryption
        case options['method'].to_s
        when 'ssl'
          :simple_tls
        when 'tls'
          :start_tls
        else
          nil
        end
      end

      def valid_provider?
        self.class.providers.include?(provider)
      end

      def invalid_provider
        raise "Unknown provider (#{provider}). Available providers: #{self.class.providers}"
      end

      def auth_options
        {
          auth: {
            method: :simple,
            username: options['bind_dn'],
            password: options['password']
          }
        }
      end

      def has_auth?
        options['password'] || options['bind_dn']
      end
    end
  end
end
