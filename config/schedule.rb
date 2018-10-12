# http://github.com/javan/whenever
# https://github.com/mojombo/chronic

set :chronic_options, :hours24 => true

every 1.day, :at => '6:00' do
  rake 'connect:sync'
end

every 1.day, :at => '11:30' do
  rake 'connect:score'
end
