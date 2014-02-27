namespace :redis do

  desc "Stops the redis server"
  task :stop  do
    deploy.print_task('redis:stop')
    deploy.run_command("service redis-server stop || true")
  end

  desc "Starts the redis server"
  task :start do
    deploy.print_task('redis:start')
    deploy.run_command("service redis-server start")
  end

  desc "Restarts the redis server"
  task :restart do
    deploy.print_task('redis:restart')
    Rake::Task['redis:stop'].invoke
    Rake::Task['redis:start'].invoke
  end

  desc "Reloads the redis server"
  task :reload  do
    deploy.print_task('redis:reload')
    :restart
  end

  desc "Add redis and sesion configuration"
  task :config do
    deploy.print_task('redis:config')
    deploy.run_command("rm #{deploy.release_path}/config/initializers/redis.rb")
    deploy.run_command("rm #{deploy.release_path}/config/initializers/session_store.rb")
    deploy.run_command("cp #{deploy.rake_deploy_path}/config_files/session/session_store.rb #{deploy.release_path}/config/initializers/")
    deploy.run_command("cp #{deploy.rake_deploy_path}/config_files/redis/redis.rb #{deploy.release_path}/config/initializers/")
  end

end