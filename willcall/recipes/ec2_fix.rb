directory "/etc/chef/ohai_plugins" do
 owner "root"
 group "root"
 mode "0644"
 action :create
  recursive true
end

cookbook_file "/etc/chef/ohai_plugins/ec2_fix.rb" do 
  source "ec2_fix.rb"
  owner "root"
  group "sysadmin"
  mode 0755
end