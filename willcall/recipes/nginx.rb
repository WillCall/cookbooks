apt_repository "nginx-php" do
  uri "http://ppa.launchpad.net/nginx/stable/ubuntu"
  distribution node['lsb']['codename']
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "C300EE8C"
  action :add
end

include_recipe "nginx::default"
include_recipe "application::rails"

pool_members = []

this_app = nil

include_localhost = false

search(:apps) do |app|
  if app[:id] == "willcall"
    this_app = app
    server_roles = ["#{app[:id]}_app_server"]
    if !app[:varnish_role].nil?
      server_roles = app[:varnish_role]
    elsif !app[:haproxy_role]
      server_roles = app[:haproxy_role]
    elsif !app[:server_role]
      server_roles = app[:server_roles]
    end
    server_roles.each do |role|
      pool_members.concat search("node", "role:#{role} AND chef_environment:#{node.chef_environment}")
      if node.run_list.roles.include?(role) && !pool_members.include?(node)
        include_localhost = true
        pool_members << node
      end
    end
  end
end

# we prefer connecting via local_ipv4 if 
# pool members are in the same cloud
# TODO refactor this logic into library...see COOK-494
pool_members.map! do |member|
  backup = false
  server_ip = begin
    if member.attribute?('cloud')
      if node.attribute?('cloud') && (member['cloud']['provider'] == node['cloud']['provider'])
         member['cloud']['local_ipv4']
      elsif member.attribute?('ec2') && node.attribute?('ec2') && (member['ec2']['placement_availability_zone'] == node['ec2']['placement_availability_zone'])
        member['cloud']['local_ipv4']
      else
        backup = true
        member['cloud']['public_ipv4']
      end
    else
      member['ipaddress']
    end
  end
  
  if include_localhost && member['ipaddress'] != node['ipaddress']
    backup = true
  end

  if this_app[:varnish_role] && member.run_list.roles.include?(this_app[:varnish_role][0])
    port = "6081"
  elsif this_app[:haproxy_role] && member.run_list.roles.include?(this_app[:haproxy_role])
    port = member["haproxy"]["port"]
  else
    port = "8080"
  end
  {:ipaddress => server_ip, :hostname => member['hostname'], :backup => backup, :port => port}
end

wordpress_servers = search("node", "role:wordpress_server AND chef_environment:#{node.chef_environment}") || []

cookbook_file "/srv/willcall/shared/getwillcall_com.crt" do 
  source "getwillcall_com.crt"
  owner "root"
  group "sysadmin"
  mode 0644
  only_if "test -d /srv/willcall/shared"
end

cookbook_file "/srv/willcall/shared/getwillcall_com.key" do 
  source "getwillcall_com.key"
  owner "root"
  group "sysadmin"
  mode 0644
  only_if "test -d /srv/willcall/shared"
end

template "#{node[:nginx][:dir]}/sites-available/willcall" do
  source "nginx-template.erb"
  owner "root"
  group "sysadmin"
  mode 0644
  variables({
    :haproxy_server => "localhost:8088",
    :wordpress_servers => wordpress_servers,
    :haproxy_servers => pool_members.uniq
  })
  notifies :reload, "service[nginx]"
end

nginx_site "willcall"

nginx_site "default" do
  enable false
end

if node.recipes.include?("munin::client") or node.recipes.include?("munin")
  munin_plugin "nginx_connection_request"
  munin_plugin "nginx_memory"
  munin_plugin "nginx_request"
  munin_plugin "nginx_status"
end
