include_recipe "rsyslog::default"

gem_package "remote_syslog"

files = node[:remote_syslog][:files]

search(:apps) do |app|
  (app["server_roles"] & node.run_list.roles).each do |app_role|
    if (app["type"][app_role])
      app["type"][app_role].each do |thing|
        if thing == "rails"
          files << "#{app['deploy_to']}/shared/log/#{node.chef_environment}.log"
        end
      end
    end
  end
end

if File::directory?( "/etc/sv" )
  Dir.foreach("/etc/sv") do |entry|
    if entry != "remote_syslog"
      Dir.chdir("/etc/sv/#{entry}") do
        if File::exists?("log/main/current")
          files << File::expand_path("log/main/current")
        end
      end
    end
  end
end

node.run_state.delete(:current_app)

template "/etc/rsyslog.d/remote_syslog.conf" do
  source "remote_syslog.conf.erb"
  mode 0640
  notifies :restart, "service[rsyslog]"
  variables(
    :server => node[:remote_syslog][:server],
    :port => node[:remote_syslog][:port]
  )
end

directory "/etc/remote_syslog/"

template "/etc/remote_syslog/log_files.yml" do 
  source "log_files.yml.erb"
  mode 0640
  variables(
    :server => node[:remote_syslog][:server],
    :port => node[:remote_syslog][:port],
    :files => files
  )
end

runit_service 'remote_syslog' do
  template_name 'remote_syslog'
end
