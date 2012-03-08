#
# Cookbook Name:: clockwork
# Recipe:: default
#
# Copyright 2012, WillCall
#
# All rights reserved - Do Not Redistribute
#

clockwork_apps = []

search(:apps) do |app|
  if (app["scheduler_role"] & node.run_list.roles)
    (app["scheduler_role"] & node.run_list.roles).each do |app_role|
      clockwork_apps << app
    end
  end
end

clockwork_apps.each do |app|
  env_vars = []
  if  !app['env_vars'].nil?
    env_vars = app['env_vars'][node.chef_environment].nil? ? [] : app['env_vars'][node.chef_environment]
  end
  
  runit_service "clockwork_#{app['id']}" do
    template_name 'clockwork'
    options(
      :app => app,
      :rails_env => node.run_state[:rails_env] || node.chef_environment
    )
    env env_vars
  end
  
  if node.recipes.include?("monit::default") or node.recipes.include?("monit")
    template "/etc/monit/conf.d/clockwork_#{app['id']}.conf" do
      owner "root"
      group "root"
      mode 0644
      source "clockwork.conf.erb"
      notifies :restart, resources(:service => "monit"), :delayed
      action :create
      variables(
        :pidfile => "/etc/sv/clockwork_#{app['id']}/supervise/pid",
        :service => "clockwork_#{app['id']}"
      )
    end
  end
  
end