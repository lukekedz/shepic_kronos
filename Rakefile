require 'dotenv/load'

namespace :connect do
  desc 'Connecting to Shepic for today\'s game slate...'

  task :sync do |t, args|
    ruby 'synchro.rb' + ' ' + ENV['ANYONG']
  end

  task :score do |t, args|
    ruby 'live_scoring.rb' + ' ' + ENV['ANYONG']
  end
end
