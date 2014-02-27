#require 'rake/hooks'
require_relative 'deploy/deploy'
require_relative 'deploy/object'
require_relative 'unicorn'
require_relative 'nginx'
require_relative 'redis'
require_relative 'sidekiq'

desc 'Deploy the application'
task :deploy => ['deploy:checkout','deploy:bundle:all','deploy:db:configure','deploy:assets:all','deploy:logs:all','deploy:db:migration','deploy:symlink', 'deploy:run']

namespace :deploy do 
  
  desc 'Generate timestamp for revision name'
  task :setup do
    deploy.print_task('setup')

    deploy.print_var("User", deploy.user)
    deploy.print_var("Rails enviroment", deploy.rails_env)
    deploy.print_var("Git repository", deploy.git_repo)
    deploy.print_var("Git barnch", deploy.branch)

    deploy.run_command("mkdir -p #{deploy.deploy_to}/releases/")
    deploy.run_command("mkdir -p #{deploy.share_path}/")
    deploy.run_command("mkdir -p #{deploy.share_path}/pids")
    deploy.run_command("mkdir -p #{deploy.share_path}/system")
    deploy.run_command("mkdir -p #{deploy.share_path}/log")

    deploy.print_var('Release name', deploy.release_name)
    deploy.print_var('Release path', deploy.release_path)
    deploy.print_var('Current path', deploy.current_path)
  end
  
  desc 'Clone git repo'
  task :clone_project do
    deploy.print_task('clone_project')
    deploy.run_command("git clone #{deploy.git_repo} #{deploy.release_path} && cd #{deploy.release_path} && git checkout #{deploy.branch}")
  end

  namespace :bundle do
    desc 'Create bundle config file'
    task :config do
      deploy.print_task('bundle:config')
      deploy.run_command("mkdir -p #{deploy.release_path}/.bundle")
      deploy.run_command("touch #{deploy.release_path}/.bundle/config")
      deploy.run_command("echo '---' >> #{deploy.release_path}/.bundle/config")
      deploy.run_command("echo 'BUNDLE_FROZEN: '1'' >> #{deploy.release_path}/.bundle/config")
      deploy.run_command("echo 'BUNDLE_PATH: #{deploy.share_path}/bundle' >> #{deploy.release_path}/.bundle/config")
      deploy.run_command("echo 'BUNDLE_WITHOUT: development:test:staging' >> #{deploy.release_path}/.bundle/config")
      deploy.run_command("echo 'BUNDLE_DISABLE_SHARED_GEMS: '1'' >> #{deploy.release_path}/.bundle/config")
    end

    desc 'Install all the gems and dependences'
    task :run do
      deploy.print_task('bundle:run')
      deploy.run_command("cd #{deploy.release_path} && RAILS_ENV=#{deploy.rails_env} bundle install")
    end

    task :all => [:config, :run]
  end

  desc 'Checkout newer version'
  task :checkout => [:setup,:clone_project] do
    deploy.print_task('checkout')
  end

  desc 'Generating assets'
  namespace :assets do

    desc 'Cleanin old assets'
    task :clean do
      deploy.print_task('assets:clean')
      deploy.run_command("cd #{deploy.release_path} && RAILS_ENV=#{deploy.rails_env} bundle exec rake assets:clean")
      deploy.run_command("rm -Rf #{deploy.share_path}/assets")
    end

    desc 'Precompiling assets'
    task :precompile do
      deploy.print_task('assets:precompile')
      deploy.run_command("cd #{deploy.release_path} && RAILS_ENV=#{deploy.rails_env} bundle exec rake assets:precompile")
    end

    desc 'Clone assets from repo assets'
    task :clone do
      deploy.print_task('assets:clone')
      deploy.run_command("cd /tmp && git clone #{deploy.git_assets_repo} assets")
    end

    desc 'Moving assets to share folder'
    task :symlink do
      deploy.print_task('assets:symlink')
      deploy.run_command("cd /tmp && mv assets #{deploy.share_path}")
      deploy.run_command("ln -s #{deploy.share_path}/assets #{deploy.release_path}/public/assets")
    end

    task :all => [:clean, :clone, :symlink]
  end

  desc 'Linking logs'
  namespace :logs do

    desc 'Substitute log folder with local log folder'
    task :symlink do
      deploy.print_task('logs:symlink')
      deploy.run_command("rm -Rf #{deploy.release_path}/log")
      deploy.run_command("ln -s #{deploy.share_path}/log #{deploy.release_path}/log")
    end

    task :all => [:symlink]
  end

  namespace :db do

    desc 'Change database.yml for local version'
    task :configure do
      deploy.print_task('db:configure')
      unless File.exist?("#{deploy.deploy_to}/share/database.yml")
        deploy.run_command("cd #{deploy.release_path} && cp config/database.yml #{deploy.deploy_to}/share/database.yml")
      end
      deploy.run_command("cd #{deploy.release_path} && mv config/database.yml config/database.yml.bck")
      deploy.run_command("ln -s #{deploy.deploy_to}/share/database.yml #{deploy.release_path}/config/database.yml")
    end

    desc 'Migrating the db'
    task :migration do
      deploy.print_task('db:migration')
      deploy.run_command("cd #{deploy.release_path} && RAILS_ENV=#{deploy.rails_env} bundle exec rake db:migrate")
    end

  end

  desc 'Symlink to new version'
  task :symlink do
    deploy.print_task('symlink')
    deploy.run_command("cd #{deploy.release_path}/tmp && rm -Rf pids")
    deploy.run_command("cd #{deploy.release_path} && ln -s #{deploy.share_path}/pids #{deploy.release_path}/tmp/pids")
    deploy.run_command("cd #{deploy.release_path}/public && rm -Rf system")
    deploy.run_command("cd #{deploy.release_path} && ln -s #{deploy.share_path}/system #{deploy.release_path}/public/system")
    deploy.run_command("unlink #{deploy.deploy_to}/current")
    deploy.run_command("ln -s #{deploy.release_path} #{deploy.deploy_to}/current")
  end

  desc 'Run the application'
  task :run => ['nginx:config','unicorn:config', 'sidekiq:config', 'redis:config'] do
    deploy.print_task('run')
    status = `ps ax | grep -v grep | grep -c nginx`
    if status == 0
      deploy.print_task('deploy:start')
      Rake::Task['deploy:start'].invoke
    else
      deploy.print_task('deploy:restart')
      Rake::Task['deploy:restart'].invoke
    end
  end

  desc 'Start all the system'
  task :start => ['redis:start', 'nginx:start','unicorn:start', 'sidekiq:start']

  desc 'Stop all the system'
  task :stop => ['redis:stop', 'nginx:stop', 'unicorn:stop', 'sidekiq:stop']

  desc 'Restart all the system'
  task :restart => ['redis:restart', 'nginx:restart', 'unicorn:restart', 'sidekiq:restart']


  desc 'Destroy the application'
  task :nuke do
    deploy.print_task('nuke')
    deploy.run_command("rm -Rf #{deploy.deploy_to}/releases")
    deploy.run_command("rm -Rf #{deploy.deploy_to}/current")
    deploy.run_command("rm -Rf #{deploy.deploy_to}/share/assets")
  end
end