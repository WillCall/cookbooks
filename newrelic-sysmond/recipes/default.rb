#
# Thanks to Eron Nicholson at 37 Signals for providing this,
#  send thanks to him and blame to me.  -Nic Benders
#

apt_repository "newrelic" do
  uri "http://apt.newrelic.com/debian/"
  distribution "newrelic"
  components ["non-free"]
  action :add
end

template "/etc/newrelic/nrsysmond.cfg" do
  source "nrsysmond.cfg.erb"
  owner "newrelic"
  group "newrelic"
  mode 0640
  notifies :restart, "service[newrelic-sysmond]"
  variables(
    :license_key => node[:newrelic][:license_key]
  )
  action :nothing
end

directory "/etc/newrelic" do 
  owner "newrelic"
  group "newrelic"
  action :nothing
  notifies :create, resources(:template => "/etc/newrelic/nrsysmond.cfg"), :immediately
end

package "newrelic-sysmond" do
    options "--allow-unauthenticated"
    action :upgrade
    ignore_failure true
    notifies :create, resources(:directory => "/etc/newrelic"), :immediately
end

service "newrelic-sysmond" do
  action [ :enable, :start ]
end
