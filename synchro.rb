require 'httparty'

route = HTTParty.get('http://localhost.com/3000/admin/active_game_slate')

puts route.inspect