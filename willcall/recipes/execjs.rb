# Install nodejs so that we have a javascript runtime

apt_repository "nodejs" do
  uri "http://ppa.launchpad.net/chris-lea/node.js/ubuntu/"
  distribution node['lsb']['codename']
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "C7917B12"
  action :add
end

package "nodejs" do
  action :install
end
