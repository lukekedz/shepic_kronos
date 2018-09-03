require 'logger'
require 'httparty'
require 'nokogiri'

require_relative 'prettify_log_output'
stamp     = Time.new.strftime('%Y%m%d%H%M')
log       = Logger.new("./logger/scoring_log_#{stamp}.txt", 10, 1024000)
log.level = Logger::INFO
output    = PrettifyLogOutput.new

# puts game_slate.first.inspect

game_slate = HTTParty.get('https://shepic.herokuapp.com/admin/active_game_slate', :body => { :secret => ARGV[0] })
games = []
game_slate.each do |game|
    details = {
        :id => game['id'],
        :time_remaining => nil,
        :away_team => game['away'],
        :away_pts => game['away_pts'],
        :home_team => game['home'],
        :home_pts => game['home_pts'],
    }

    games.push details
end

games.each do |g|
    # puts g.inspect
end

scores = HTTParty.get('https://sports.yahoo.com/college-football/scoreboard/?confId=1%2C4%2C6%2C7%2C8%2C11%2C71%2C72%2C87%2C90%2C122&schedState=2&dateRange=1')

live = Nokogiri::HTML(scores).css('#scoreboard-group-2 ul').first.css('li div')
# puts live.inspect

time_remaining, away_team, home_team, away_pts, home_pts = nil

live.each_with_index do |l, index|

    # puts l.attributes.inspect
    # puts l.attributes["class"]

    if l.attributes["class"] &&
       l.attributes["class"].value == 'Ta(end) Cl(b) Fw(b) '

       # puts
       # puts 'time remaining: ' + l.css('ul li').last.text
       time_remaining = l.css('ul li').last.text
    end

    if time_remaining != nil

        if l.attributes["class"] &&
           l.attributes["class"].value == 'Fw(b) Fz(14px)'

            if l.children.children.text[0] == '('

                index = l.children.children.text.index(' ')
                # puts l.children.children.text + ' => ' + l.children.children.text[(index + 1)..-1]

                if away_team == nil
                    # puts 'away team: ' + l.children.children.text[(index + 1)..-1]
                    away_team = l.children.children.text[(index + 1)..-1]
                    if away_team[-2..-1] == 'RZ'
                        away_team = away_team[0..-3]
                    end
                else
                    # puts 'home team: ' + l.children.children.text[(index + 1)..-1]
                    home_team = l.children.children.text[(index + 1)..-1]
                    if home_team[-2..-1] == 'RZ'
                        home_team = home_team[0..-3]
                    end
                end

            else

                if away_team == nil
                    # puts 'away team: ' + l.children.children.text
                    away_team = l.children.children.text
                    if away_team[-2..-1] == 'RZ'
                        away_team = away_team[0..-3]
                    end
                else
                    # puts 'home team: ' + l.children.children.text
                    home_team = l.children.children.text
                    if home_team[-2..-1] == 'RZ'
                        home_team = home_team[0..-3]
                    end
                end

            end
        end

        if l.attributes["class"] &&
           l.attributes["class"].value == 'Whs(nw) D(tbc) Va(m) Fw(b) Fz(27px)'

            if away_pts == nil
                # puts 'away pts: ' + l.css('span').first.text
                away_pts = l.css('span').first.text
            else
                # puts 'home pts: ' + l.css('span').first.text
                home_pts = l.css('span').first.text
            end
        end

    end

    # puts
    # puts time_remaining.inspect
    # puts away_team.inspect
    # puts away_pts.inspect
    # puts home_team.inspect
    # puts home_pts.inspect

    if time_remaining != nil && away_team != nil && home_team != nil && away_pts != nil && home_pts != nil
        # puts 'here'

        games.each do |g|
            # puts
            # puts g[:away_team]
            # puts g[:home_team]

            if g[:away_team] == away_team && g[:home_team] == home_team
                # puts 'here2'
                g[:time_remaining] = time_remaining
                g[:away_pts] = away_pts
                g[:home_pts] = home_pts
            end
        end

        time_remaining, away_team, home_team, away_pts, home_pts = nil
    end

    # TODO: throw this code away except for class value
    # div with all the needed info (live, upcoming, final games)
    # if l.attributes["class"] &&
    #    l.attributes["class"].value == 'Bdc(#d8dade) Bdc(card-border):h Bds(s) Bdrs(4px) Bdw(1px)'
    #     # puts
    #     # puts l.inspect
    # end
end

puts
games.each do |g|
    if g[:id] == 22
        HTTParty.post('https://shepic.herokuapp.com/admin/update_score', :body => {
            :id => g[:id],
            :away_pts => g[:away_pts],
            :home_pts => g[:home_pts],
            :secret => ARGV[0] }
        )

        puts g.inspect
    end
end
puts


