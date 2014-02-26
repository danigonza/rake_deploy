namespace :nginx do

  desc "Stops the nginx web server"
  task :stop do
    deploy.print_task('nginx:stop')
    deploy.run_command('service nginx stop; exit 0')
  end

  desc "Starts the nginx web server"
  task :start do
    deploy.print_task('nginx:start')
    deploy.run_command('service nginx status || service nginx start')
  end

  desc "Restarts the nginx web server"
  task :restart do
    deploy.print_task('nginx:restart')
    deploy.run_command('service nginx restart')
  #  serial_restart
  end

  desc "Reloads the nginx web server"
  task :reload do
    deploy.print_task('nginx:reload')
    deploy.run_command('if ! ps ax | grep -v grep | grep -c nginx &> /dev/null; then service nginx start; else service nginx reload; fi')
  end

  desc "Display status of the nginx web server"
  task :status do
    deploy.print_task('nginx:status')
    deploy.run_command('service nginx status || true')
    deploy.run_command('ps -eopid,user,fname | grep [n]ginx || true')
    deploy.run_command('netstat -tulpn | grep nginx || true')
  end

  desc "Add nginx configuration"
  task :config do
    deploy.print_task('nginx:config')
    deploy.run_command('mkdir -p /mnt/nginx/logs')
    deploy.run_command('mkdir -p /etc/nginx/unicorn')
    #deploy.run_command("cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bck")
    #deploy.run_command("cp /etc/nginx/unicorn/unicorn_nginx.conf /etc/nginx/unicorn/unicorn_nginx.conf.bck")
    #deploy.run_command("cp #{deploy.rake_deploy_path}/config_files/nginx/nginx.conf /etc/nginx/nginx.conf")
    #deploy.run_command("cp #{deploy.rake_deploy_path}/config_files/nginx/unicorn_nginx.conf /etc/nginx/unicorn/unicorn_nginx.conf")
  end
end
