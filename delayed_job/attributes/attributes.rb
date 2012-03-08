default[:delayed_job][:queues] = "*"
default[:delayed_job][:workers] = [node[:cpu][:total].to_i * 2, 8].min