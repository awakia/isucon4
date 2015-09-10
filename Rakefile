## Global
ssh_profile = "isucon4"
language = "ruby"

## Itamae
ssh_host = "107.167.183.23"
ssh_key = "~/.ssh/id_rsa.github"
ssh_user = "dtan4"
itamae_recipe = "recipe.rb"

desc "Converge Itamae recipes"
task :itamae do
  Dir.chdir("itamae") do
    sh "bundle exec itamae ssh -h #{ssh_host} -u #{ssh_user} -i #{ssh_key} #{itamae_recipe}"
  end
end

namespace :web do
  desc "Upload web files"
  task "upload" do
    sh "rsync -avz webapp/#{language}/ #{ssh_profile}:/home/isucon/webapp/#{language}"
  end

  desc "Restart web"
  task "restart" do
    abort "[ERROR] Please run this by 'isucon' user!" unless ENV["USER"] == "isucon"
    sh "sudo /etc/init.d/supervisord restart"
  end
end

namespace :nginx do
  desc "Upload nginx.conf"
  task "upload" do
    sh "rsync -avz config/etc/nginx/nginx.conf #{ssh_profile}:/etc/nginx/nginx.conf"
  end

  desc "Restart nginx"
  task "restart" do
    abort "[ERROR] Please run this by 'isucon' user!" unless ENV["USER"] == "isucon"
    sh "sudo /etc/init.d/nginx restart"
  end
end

namespace :mysql do
  desc "Upload my.cnf"
  task "upload" do
    sh "rsync -avz config/etc/my.cnf #{ssh_profile}:/etc/my.cnf"
  end

  desc "Restart MySQL"
  task "restart" do
    abort "[ERROR] Please run this by 'isucon' user!" unless ENV["USER"] == "isucon"
    sh "sudo /etc/init.d/mysql55-mysqld restart"
  end
end

namespace :redis do
  desc "Upload redis.conf"
  task "upload" do
    sh "rsync -avz config/etc/redis.conf #{ssh_profile}:/etc/redis.conf"
  end

  desc "Restart Redis"
  task "restart" do
    abort "[ERROR] Please run this by 'isucon' user!" unless ENV["USER"] == "isucon"
    sh "sudo /etc/init.d/redis restart"
  end
end
