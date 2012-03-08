include_recipe "mongodb::10gen_repo"

gem_package 'mongo'

directory "/srv/willcall/shared/log" do
 owner "willcall"
 group "sysadmin"
 mode "0770"
 action :create
  recursive true
end

file "/srv/willcall/shared/log/mongodb.log" do
 owner "mongodb"
 group "sysadmin"
 mode "0660"
 action :create
 backup false
 content nil
end

directory "/srv/willcall/data" do
 owner "mongodb"
 group "sysadmin"
 mode "0770"
 action :create
  recursive true
end

include_recipe "mongodb::replicaset"
include_recipe "mongodb::default"
