package "redis" do
  action :install
  options "--enablerepo=epel"
end

%w(/etc/nginx/nginx.conf /etc/redis.conf /etc/my.cnf).each do |f|
  file f do
    action :edit
    owner "dtan4"
  end
end
