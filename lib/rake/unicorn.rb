namespace :unicorn do

  desc "Stops the unicorn server"
  task :stop do
    deploy.print_task('unicorn:stop')
    deploy.run_command("if [ -f /var/run/unicorn.pid ]; then pid=`cat /var/run/unicorn.pid` && kill -TERM $pid; fi")
  end

  desc "Starts the unicorn server"
  task :start  => :config do
    deploy.print_task('unicorn:start')
    deploy.run_command("cd #{deploy.current_path} && bundle exec unicorn_rails -c #{deploy.current_path}/config/unicorn.rb -E production -D")
  end

  desc "Restarts the unicorn server"
  task :restart do
    deploy.print_task('unicorn:restart')
    Rake::Task['unicorn:stop'].invoke
    Rake::Task['unicorn:start'].invoke
  end

  desc "Reloads the unicorn web server"
  task :reload do
    deploy.print_task('unicorn:reload')
    deploy.run_command("if [ -f /var/run/unicorn.pid ]; then pid=`cat /var/run/unicorn.pid` && kill -USR2 $pid; else cd #{deploy.current_path} && bundle exec unicorn_rails -c #{deploy.current_path}/config/unicorn.rb -E production -D; fi")
  end

  desc "Display status of the unicorn web server"
  task :status do
    deploy.print_task('unicorn:status')
    deploy.run_command("ps -eopid,user,cmd | grep [u]nicorn || true")
    deploy.run_command("netstat -tupan | grep unicorn || true")
  end

  desc "Add configuration file for unicorn"
  task :config do
    deploy.print_task('unicorn:config')
    deploy.run_command("cp #{deploy.rake_deploy_path}/config_files/unicorn/unicorn.rb #{deploy.current_path}/config/")
  end

end

