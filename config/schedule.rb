# http://github.com/javan/whenever
# https://github.com/mojombo/chronic

set :chronic_options, :hours24 => true

every 1.day, :at => '16:45' do
  rake 'connect:sync'
end

# this works
# CLI => SECRET=7marco9Bene17 rake connect:sync
