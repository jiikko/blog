
listen '/tmp/.lokka.sock'
worker_processes 1 # this should be >= nr_cpus
LOKKA_ROOT = File.expand_path('../../../../', __FILE__)
pid "#{LOKKA_ROOT}/tmp/pids/unicorn.pid"


stderr_path "#{LOKKA_ROOT}/log/unicorn.stderr.log"
stdout_path "#{LOKKA_ROOT}/log/unicorn.stdout.log"

timeout 200

preload_app true


before_fork do |server, worker|
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
  # if defined?(ActiveRecord::Base)
  #   ActiveRecord::Base.connection.disconnect!
  # end
end

# datamapperだからいらない
# after_fork do |server, worker|
#   defined?(ActiveRecord::Base) and
#     ActiveRecord::Base.establish_connection
# end
