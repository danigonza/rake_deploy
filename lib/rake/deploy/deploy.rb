require 'net/ssh'
require 'ostruct'

class Deploy < OpenStruct
  def initialize
    super
    @ssh_sessions = {}
    self.branch = BRANCH
    self.rails_env = DEPLOY_RAILS_ENV
    self.shared = %w(/tmp /log /public/system)
    self.user   = `who am i`.split(' ').first
    self.rake_deploy_path = `pwd`.strip

    self.deploy_to = DEPLOY_TO
    self.git_repo = GIT_REPO
    self.git_assets_repo  GIT_ASSETS_REPO
    self.sudo = DEPLOY_SUDO
    self.release_name ||= Time.now.utc.strftime("%Y%m%d%H%M%S")
    self.release_path ||= "#{self.deploy_to}/releases/#{self.release_name}"
    self.current_path ||= "#{self.deploy_to}/current"
    self.share_path   ||= "#{self.deploy_to}/share"
  end
  
  # Run a command in a remote server:
  # run("ls") Run ls in current deploy.host
  # run("my_host.com", "ls") run ls in "my_host.com"
  # run("my_host.com", "guillermo", "ls") run ls in "my_shot.com" as user "guillermo"
  def run(*args)
    case args.size
    when 3
      ssh_host, ssh_user, ssh_command = args 
    when 2
      ssh_host, ssh_command = args
      ssh_user = self.user
    when 1
      ssh_host, ssh_user = self.host, self.user
      ssh_command = args.first
    else
      raise ArgumentError
    end
    return ssh_host.map{|host| run(host, ssh_user, ssh_command)} if ssh_host.is_a? Array
    
    key = "#{ssh_user}@#{ssh_host}"
    puts "    #{key}$ #{ssh_command}"
    @ssh_sessions[key] ||= Net::SSH.start(ssh_host, ssh_user)
    output = @ssh_sessions[key].exec!(ssh_command)
    puts output.split("\n").map{|l| "    #{key}> #{l}"}.join("\n") if output
    output
  end

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
  
end