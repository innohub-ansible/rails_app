require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/chruby'

{% if rails_app_sidekiq and inventory_hostname in groups[rails_app_sidekiq_group] %}
  require 'mina_sidekiq/tasks'
  set :sidekiq_pid, "#{deploy_to}/shared/tmp/pids/sidekiq.pid"
{% endif %}

# Domain will not be used!
set :domain, 'foobar.com'
set :deploy_to, '{{ rails_app_deploy_to }}'
set :repository, '{{ rails_app_repo }}'
set :branch, '{{ rails_app_repo_branch }}'

set :shared_paths, [
  'config/database.yml',
  'config/secrets.yml',
  'log',
  'tmp'
]

task :environment do
  invoke :'chruby[{{ ruby_default_version }}]'
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    {% if rails_app_sidekiq and inventory_hostname in groups[rails_app_sidekiq_group] %}
    invoke :'sidekiq:quiet'
    {% endif %}

    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    to :launch do
      {% if rails_app_sidekiq and inventory_hostname in groups[rails_app_sidekiq_group] %}
      invoke :'sidekiq:restart'
      {% endif %}

      queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
    end
  end
end