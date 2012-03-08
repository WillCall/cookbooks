#
# Cookbook Name:: delayed_job
# Recipe:: default
#
# Copyright 2012, WillCall
#
# All rights reserved - Do Not Redistribute
#

delayed_apps = []

search(:apps) do |app|
  if (app["worker_role"] & node.run_list.roles)
    (app["worker_role"] & node.run_list.roles).each do |app_role|
      delayed_apps << app
    end
  end
end

delayed_apps.each do |app|
  
  env_vars = Hash.new
  if  !app['env_vars'].nil?
    env_vars = app['env_vars'][node.chef_environment].nil? ? Hash.new : app['env_vars'][node.chef_environment]
  end
  
  if node[:delayed_job][:queues] != "*"
    env_vars["QUEUES"] = node[:delayed_job][:queues]
  end
  
  (1..node[:delayed_job][:workers]).each do |i|
    env_vars["DJ_WORKER"] = i.to_s
    
    runit_service "dj_#{app['id']}_#{i}" do
      template_name 'delayed_job'
      options(
        :app => app,
        :worker => i,
        :rails_env => node.run_state[:rails_env] || node.chef_environment
      )
      env env_vars
    end
  
    if node.recipes.include?("monit::default") or node.recipes.include?("monit")
      template "/etc/monit/conf.d/dj_#{app['id']}_#{i}.conf" do
        owner "root"
        group "root"
        mode 0644
        source "monitrc.conf.erb"
        notifies :restart, resources(:service => "monit"), :delayed
        action :create
        variables(
          :process => "dj_#{app['id']}_#{i}"   
        )
      end
    end
  end
end