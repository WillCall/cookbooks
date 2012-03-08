package "newrelic-php5" do
  options "--allow-unauthenticated"
  action :upgrade
  ignore_failure true
end

if node['recipes'].include? "wordpress::default"
  cookbook_file "/etc/php5/conf.d/newrelic.ini"
    action :create
  end
end