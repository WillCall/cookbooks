include_recipe "cron::default"

cron "rake sitemaps" do
  minute "5"
  command "cd /srv/willcall/current; chpst -u willcall -e /etc/sv/willcall/env bundle exec rake sitemap:refresh"
  only_if do File.exist?("/srv/willcall/current") end
end