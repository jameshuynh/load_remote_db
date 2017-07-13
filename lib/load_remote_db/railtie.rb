module LoadRemoteDb
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/load_remote_db.rake'
    end
  end
end
