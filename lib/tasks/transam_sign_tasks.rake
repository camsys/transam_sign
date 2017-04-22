# desc "Explaining what the task does"
# task :transam_sign do
#   # Task goes here
# end
namespace :transam_sign do
  desc "Prepare the dummy app for rspec and capybara"
  task :prepare_rspec => ["app:test:set_test_env", :environment] do
    %w(db:drop db:create db:schema:load db:migrate db:seed).each do |cmd|
      puts "Running #{cmd} in Sign"
      Rake::Task[cmd].invoke
    end
  end

  desc "Prepare the dummy app for rspec and capybara based on the canon schema"
  task :prepare_rspec_from_canon_schema => ["app:test:set_test_env", :environment] do
    # Checks out an old schema we can trust to have missed no migrations
    # Prepares rspec from there
    # This avoids missing migrations from depended-on engines that were not pushed when the schema last updated
    # (These would be left out going forward since they have an earlier timestamp than the schema)
    # If you decide a more recent schema is canon, just update the git checksum
    sh 'git', 'checkout', '7d4e909', Rails.root.join('db', 'schema.rb').to_s

    %w(db:drop db:create db:schema:load db:migrate db:seed).each do |cmd|
      puts "Running #{cmd} in Sign"
      Rake::Task[cmd].invoke
    end
  end
end

namespace :test do
  desc "Custom dependency to set test environment"
  task :set_test_env do # Note that we don't load the :environment task dependency
    Rails.env = "test"
  end
end
