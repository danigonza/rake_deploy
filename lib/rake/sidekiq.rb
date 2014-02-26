namespace :sidekiq do

  #before "deploy",        "rubber:sidekiq:quiet"
  #after "deploy:stop",    "rubber:sidekiq:stop"
  #after "deploy:start",   "rubber:sidekiq:start"
  #after "deploy:restart", "rubber:sidekiq:restart"

  desc "Quiet sidekiq (stop accepting new work)"
  task :quiet do
    deploy.print_task('sidekiq:quiet')
    deploy.run_command("if [ -d #{deploy.current_path} ]; then cd #{deploy.current_path} && if [ -f #{deploy.current_path}/tmp/pids/sidekiq.pid ]; then bundle exec sidekiqctl quiet #{deploy.current_path}/tmp/pids/sidekiq.pid ; fi; fi")
  end

  desc "Stop sidekiq"
  task :stop  do
    deploy.print_task('sidekiq:stop')
    deploy.run_command("cd #{deploy.current_path} && if [ -f #{deploy.current_path}/tmp/pids/sidekiq.pid ]; then bundle exec sidekiqctl stop #{deploy.current_path}/tmp/pids/sidekiq.pid 60 ; fi")
  end

  desc "Start sidekiq"
  task :start do
    deploy.print_task('sidekiq:start')
    deploy.run_command("cd #{deploy.current_path} ; nohup bundle exec sidekiq -e production -C #{deploy.current_path}/config/sidekiq.yml -P #{deploy.current_path}/tmp/pids/sidekiq.pid >> #{deploy.current_path}/log/sidekiq.log 2>&1 &")
    sleep 45 # Give the workers some time to start up before moving on so monit doesn't try to start as well.
  end

  desc "Restart sidekiq"
  task :restart do
    deploy.print_task('sidekiq:restart')
    Rake::Task['sidekiq:stop'].invoke
    Rake::Task['sidekiq:start'].invoke
  end

end
