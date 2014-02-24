#require 'rake/hooks'
require_relative 'deploy/deploy'
require_relative 'deploy/object'

desc 'Deploy the application'
task :deploy => ["deploy:run"]

namespace :deploy do 
  
  desc 'Generate timestamp for revision name'
  task :setup do
    print_task('setup')
    print_var('User', deploy.user);
    print_var("Rails enviroment", deploy.rails_env)
    print_var("Git repository", deploy.git_repo)
    print_var("Git barnch", deploy.branch)

    deploy.release_name ||= Time.now.utc.strftime("%Y%m%d%H%M%S")
    deploy.release_path ||= "#{deploy.deploy_to}/releases/#{deploy.release_name}"
    deploy.current_path ||= "#{deploy.deploy_to}/current"
    deploy.share_path ||= "#{deploy.deploy_to}/share"

    run_command("mkdir -p #{deploy.deploy_to}/releases/")
    run_command("mkdir -p #{deploy.share_path}/")

    print_var('Release name', deploy.release_name);
    print_var('Release path', deploy.release_path);
    print_var('Current path', deploy.current_path);
  end
  
  desc 'Clone git repo'
  task :clone_project do
    print_task('clone_project')
    run_command("git clone #{deploy.git_repo} #{deploy.release_path} && cd #{deploy.release_path} && git checkout #{deploy.branch}")
  end

  namespace :bundle do
    desc 'Create bundle config file'
    task :config do
      print_task('bundle_config')
      run_command("mkdir -p #{deploy.release_path}/.bundle")
      run_command("touch #{deploy.release_path}/.bundle/config")
      run_command("echo '---' >> #{deploy.release_path}/.bundle/config")
      run_command("echo 'BUNDLE_FROZEN: '1'' >> #{deploy.release_path}/.bundle/config")
      run_command("echo 'BUNDLE_PATH: #{deploy.share_path}/bundle' >> #{deploy.release_path}/.bundle/config")
      run_command("echo 'BUNDLE_WITHOUT: development:test:staging' >> #{deploy.release_path}/.bundle/config")
      run_command("echo 'BUNDLE_DISABLE_SHARED_GEMS: '1'' >> #{deploy.release_path}/.bundle/config")
    end

    desc 'Install all the gems and dependences'
    task :run => [:config] do
      print_task('bundle')
      run_command("cd #{deploy.release_path} && RAILS_ENV=#{deploy.rails_env} bundle install")
    end
  end

  desc 'Change database.yml for local version'
  task :configure_db do
    print_task('configure_db')
    #unless File.exist?('#{deploy.deploy_to}/share/database.yml') 
    #  run_command("cd #{deploy.release_path} && cp config/database.yml #{deploy.deploy_to}/share/database.yml") 
    #end
    run_command("cd #{deploy.release_path} && mv config/database.yml config/database.yml.bck") 
    run_command("ln -s #{deploy.deploy_to}/share/database.yml #{deploy.release_path}/config/database.yml") 
  end

  desc 'Checkout newer version'
  task :checkout => [:setup,:clone_project] do
    print_task('checkout')

    # TODO

    #deploy.shared.each do |shared_path|
    #  deploy.run("rm -rf #{deploy.release_path}#{shared_path}")
    #  deploy.run("ln -s #{deploy.deploy_to}/shared/scaffold#{shared_path} #{deploy.release_path}#{shared_path}")
    #end
  end

  desc 'Cleanin old assets'
  task :clean_assets do
    print_task('clean_assets')
    run_command("cd #{deploy.release_path} && RAILS_ENV=#{deploy.rails_env} bundle exec rake assets:clean")
  end

  desc 'Precompiling assets'
  task :precompile_assets do
    print_task('precompile_assets')
    run_command("cd #{deploy.release_path} && RAILS_ENV=#{deploy.rails_env} bundle exec rake assets:precompile")
  end

  desc 'Moving assets to share folder'
  task :symlink_assets do
    print_task('symlink_assets')
    run_command("cd #{deploy.release_path} && mv public/assets #{deploy.share_path}")
    run_command("ln -s #{deploy.share_path}/assets #{deploy.release_path}/public/assets")
  end

  desc 'Substitute log folder with local log folder'
  task :symlink_log do
    print_task('symlink_logs')
    #run_command("cd #{deploy.release_path} && rm log")
    #run_command("ln -s #{deploy.share_path}/logs #{deploy.release_path}/log")
  end
  

  desc 'Generating assets'
  task :assets  => [:clean_assets, :precompile_assets,:symlink_assets] do
  end

  desc 'Linking logs'
  task :logs  => [:symlink_log] do
  end
  
  desc 'Migrating the db'
  task :migration do
    print_task('migration')
    run_command("cd #{deploy.release_path} && RAILS_ENV=#{deploy.rails_env} bundle exec rake db:migrate")
  end

  desc 'Symlink to new version'
  task :symlink => [:checkout,'bundle:run',:configure_db,:assets,:logs,:migration] do
    print_task('symlink')
    run_command("unlink #{deploy.deploy_to}/current")
    run_command("ln -s #{deploy.release_path} #{deploy.deploy_to}/current")
  end  

  desc 'Run the application'
  task :run => [:symlink] do
    print_task('symlink')
    run_command("cd #{deploy.release_path} && RAILS_ENV=#{deploy.rails_env} rails server -d")
  end

  desc 'Destroy the application'
  task :nuke do
    print_task('nuke')
    run_command("rm -Rf #{deploy.deploy_to}/releases")
    run_command("rm -Rf #{deploy.deploy_to}/current")
  end
end

private

def print_var(name, var)
  print("\u001B[34m" + name + ': ' + var + "\u001b[39m") 
end

def print_command(command)
  print("\u001B[33m" + command  + "\u001b[39m") 
end

def print_task(task)
  print("\u001B[32m" + '=> ' + task + "\u001b[39m")
end

def print_output(out)
  print(out)
end

def print_error(mssg)
  print("\u001B[31m" + '=> ' + mssg + "\u001b[39m")
end

def print(str)
  time = Time.now.strftime("%d/%m/%Y %H:%M")
  puts '[' + time + '] ' + str
end

def run_command(command)
  print_command(command)
  #(command = 'sudo '+ command) if deploy.sudo
  begin
    system(command)
    print_command('[--- DONE COMMAND ---]')
  rescue => err
    print_error('[--- ERROR ---]')
  end 
end