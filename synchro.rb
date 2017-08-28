require 'logger'
require 'httparty'

require_relative 'prettify_log_output'
stamp     = Time.new.strftime('%Y%m%d%H%M')
log       = Logger.new("./logger/log_#{stamp}.txt", 10, 1024000)
log.level = Logger::INFO
output    = PrettifyLogOutput.new

# TODO: retry if URL doesn't resolve, on GET and POST
# TODO: implement emailing
# TODO: automatic environment detection (no manual switch from localhost to herokuapp.com)

def game_date(date)
  Date.new(date.to_s[0..3].to_i, date.to_s[5..6].to_i, date.to_s[8..9].to_i)
end

def military_time_now
  Time.now.strftime('%H%M').to_i
end

todays_date      = Date.today
game_sched_today = false
now              = military_time_now()

log.info output.start
log.info output.new_line
log.info "Today: " + todays_date.to_s
log.info "Start: " + now.to_s
log.info output.new_line

# game_slate = HTTParty.get('http://localhost:3000/admin/active_game_slate', :body => { :secret => ARGV[0] })
game_slate = HTTParty.get('https://shepic.herokuapp.com/admin/active_game_slate', :body => { :secret => ARGV[0] })
log.info 'SHEPIC RESPONSE:'
log.info game_slate.inspect
log.info output.new_line

if game_slate && game_slate.parsed_response != nil

  game_slate.each_with_index do |game, index|
    log.info "INDEX: " + index.to_s
    log.info game_date(game['date']).to_s + " " + game['away'].to_s + " vs. " + game['home'].to_s

    game_date = game_date(game['date'])

    if game_date == todays_date
      log.info "Game(s) scheduled for today... #{todays_date}!"
      log.info output.new_line

      game_sched_today = true
      break
    end
  end

  if game_sched_today
    game_slate.each do |game|
      game_date    = game_date(game['date'])
      game_started = game['game_started']
      game_time    = game['start_time'].to_i

      log.info 'ID: ' + game['id'].to_s + ' => ' + game['away'] + ' vs. ' + game['home']
      log.info game['date'].to_s[0..9] + ' ' + game['start_time'].to_s

      if game_date == todays_date && game_started == false
        while game_time > now
          sleep(60)
          now = military_time_now()
        end

        # updated_game_record = HTTParty.post('http://localhost:3000/admin/game_started', :body => { :id => game['id'], :secret => ARGV[0] })
        updated_game_record = HTTParty.post('https://shepic.herokuapp.com/admin/game_started', :body => { :id => game['id'], :secret => ARGV[0] })
        log.info '*****'
        log.info 'NOW: ' + now.to_s
        log.info 'GAME ID: ' + updated_game_record.parsed_response['id'].to_s + ' => started... ' + updated_game_record.parsed_response['game_started'].to_s
        log.info '*****'

        system "echo 'game locked.' | mail -s 'Notice from Shepic!' lukekedziora@gmail.com -A logger/log_#{stamp}.txt"
      end
      log.info output.new_line
    end
  else
    system "echo 'no games scheduled today!' | mail -s 'Notice from Shepic!' lukekedziora@gmail.com -A logger/log_#{stamp}.txt"
  end
else
  system "echo 'game_slate is nil!' | mail -s 'Notice from Shepic!' lukekedziora@gmail.com -A logger/log_#{stamp}.txt"
end
