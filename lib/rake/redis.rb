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

end