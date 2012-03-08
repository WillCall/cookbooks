cookbook_file "/etc/cron.daily/automongobackup.sh" do 
  source "automongobackup.sh"
  owner "root"
  group "sysadmin"
  mode 0755
end