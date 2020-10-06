Puppet::Type.type(:package).provide :puppet_gem, :parent => :gem do
  desc "Puppet Ruby Gem support. This provider is useful for managing
        gems needed by the ruby provided in the puppet-agent package."

  has_feature :versionable, :install_options, :uninstall_options

  if Puppet::Util::Platform.windows?
    commands :gemcmd => File.join(Puppet::Util.get_env('PUPPET_DIR').to_s, 'bin', 'gem.bat')
  else
    commands :gemcmd => "/opt/puppetlabs/puppet/bin/gem"
  end

  def uninstall
    super
    Puppet.debug("Invalidating rubygems cache after uninstalling gem '#{resource[:name]}'")
    Puppet::Util::Autoload.gem_source.clear_paths
  end

  def self.execute_gem_command(command, command_options, custom_environment = {})
    custom_environment['PKG_CONFIG_PATH'] = '/opt/puppetlabs/puppet/lib/pkgconfig' unless Puppet::Util::Platform.windows?
    super(command, command_options, custom_environment)
  end
end
