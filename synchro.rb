require 'httparty'

# TODO: retry if URL doesn't resolve, on GET and POST
# TODO: implement emailing

def game_date(date)
  Date.new(date.to_s[0..3].to_i, date.to_s[5..6].to_i, date.to_s[8..9].to_i)
end

def military_time_now
  Time.now.strftime('%H%M').to_i
end

todays_date      = Date.today
game_sched_today = false
now              = military_time_now()

puts
puts "Today: " + todays_date.to_s
puts "Start: " + now.to_s
puts

# game_slate = HTTParty.get('http://localhost:3000/admin/active_game_slate', :body => { :secret => ARGV[0] })
game_slate = HTTParty.get('https://shepic.herokuapp.com/admin/active_game_slate', :body => { :secret => ARGV[0] })

if game_slate.parsed_response != nil

  game_slate.each_with_index do |game, index|
    puts "INDEX: " + index.to_s

    game_date = game_date(game['date'])

    if game_date == todays_date
      puts "Game(s) scheduled for today... #{todays_date}!"
      puts

      game_sched_today = true
      break
    end
  end

  if game_sched_today
    game_slate.each do |game|
      game_date    = game_date(game['date'])
      game_started = game['game_started']
      game_time    = game['start_time'].to_i

      puts 'ID: ' + game['id'].to_s + ' => ' + game['away'] + ' vs. ' + game['home']
      puts game['date'].to_s[0..9] + ' ' + game['start_time'].to_s

      if game_date == todays_date && game_started == false
        while game_time > now
          sleep(60)
          now = military_time_now()
        end

        # updated_game_record = HTTParty.post('http://localhost:3000/admin/game_started', :body => { :id => game['id'], :secret => ARGV[0] })
        updated_game_record = HTTParty.post('https://shepic.herokuapp.com/admin/game_started', :body => { :id => game['id'], :secret => ARGV[0] })
        puts '*****'
        puts 'NOW: ' + now.to_s
        puts 'GAME ID: ' + updated_game_record.parsed_response['id'].to_s + ' => started... ' + updated_game_record.parsed_response['game_started'].to_s
        puts '*****'
      end

      puts
    end
  end

end
