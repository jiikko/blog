set :application, 'blog.jiikko.com'
set :repo_url, 'git@github.com:jiikko/blog.git'

set :user, 'deployer'
set :use_sudo, false

set :git_shallow_clone, 1 # １つ前のコミットまでとる

set :app_name, 'blog'
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }
set :bundle_without, %w{development test}.join(' ')

# set :rvm_ruby_version, '2.1'
set :rvm_ruby_version, '2.1.0@lokka'

# set :format, :pretty
# set :log_level, :debug
# set :pty, true

# set :linked_files, %w{config/database.yml}
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :keep_releases, 5



set :unicorn_pid, "#{shared_path}/tmp/pids/unicorn.pid"
set :unicorn_config, "#{current_path}/config/servers/production/unicorn.conf.rb"

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'unicorn:restart'
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # execute :rake, 'cache:clear'
    end
  end
  after :finishing, 'deploy:cleanup'

  namespace :unicorn do
    task :start do
      on roles(:app), in: :sequence, wait: 5 do
        within current_path do
          execute :bundle, :exec, :unicorn, "-c #{fetch(:unicorn_config)} -E #{fetch(:stage)} -D"
        end
      end
    end

    task :restart do
      on roles(:web), in: :groups, limit: 3, wait: 10 do
        execute :kill, "-USR2 `cat #{fetch(:unicorn_pid)}`"
      end
    end

    task :stop do
      on roles(:web), in: :groups, limit: 3, wait: 10 do
        execute :kill, "-QUIT `cat #{fetch(:unicorn_pid)}`"
      end
    end
  end
end
