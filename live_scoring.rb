require 'httparty'
require 'nokogiri'
require 'rufus-scheduler'

system "echo 'live scoring running!' | mail -s 'Kronos Live Scoring' lukekedziora@gmail.com"

def strip_RZ_from_team_name(team_name)
  # example 'OSURZ'
  team_name[-2..-1] == 'RZ' ? team_name[0..-3] : team_name
end

def strip_rank_from_team_name(team_name)
  # example '(3) OSU'
  if team_name[0] == '('
    index = team_name.index(' ')
    team_name = team_name[(index + 1)..-1]
  end

  team_name
end

def parse_points_from_attribute(attribute)
  attribute.css('span').first.text
end

active_week = HTTParty.get('https://shepic.herokuapp.com/admin/week_number_for_scripts', :body => { :secret => ARGV[0] })
weekly_game_slate = HTTParty.get('https://shepic.herokuapp.com/admin/active_game_slate', :body => { :secret => ARGV[0] })
games = []
weekly_game_slate.each do |game|
  details = {
    :id             => game['id'],
    :game_finished  => game['game_finished'],
    :away_team      => game['away'],
    :home_team      => game['home'],
  }
  games.push details
end

scheduler = Rufus::Scheduler.new
scheduler.every '5m', :first_in => 0 do
  puts
  puts '*'*100

  scrape = HTTParty.get("https://sports.yahoo.com/college-football/scoreboard/?confId=1%2C4%2C6%2C7%2C8%2C11%2C71%2C72%2C87%2C90%2C122&schedState=2&dateRange=#{active_week['week']}")
  live_html_elements = Nokogiri::HTML(scrape).css('#scoreboard-group-2 div ul li').css('div')

  time_remaining, away_team, home_team, away_pts, home_pts = nil
  live_html_elements.each do |el|
    # TIME REMAINING
    if el.attributes['class'] && el.attributes['class'].value == 'Ta(end) Cl(b) Fw(b) '
      if el.css('ul li').last && el.css('ul li').last.text
        time_remaining = el.css('ul li').last.text
      end
    end

    if time_remaining != nil
      # TEAMS
      if el.attributes['class'] && el.attributes['class'].value == 'Fw(b) Fz(14px)'
        team_name = el.children.children.text
        team_name = strip_RZ_from_team_name(team_name)
        team_name = strip_rank_from_team_name(team_name)

        away_team == nil ? away_team = team_name : home_team = team_name
      end

      # POINTS
      if el.attributes['class'] && el.attributes['class'].value == 'Whs(nw) D(tbc) Va(m) Fw(b) Fz(27px)'
        points = parse_points_from_attribute(l)
        away_pts == nil ? away_pts = points : home_pts = points
      end
    end

    if time_remaining != nil &&
       away_team      != nil &&
       home_team      != nil &&
       away_pts       != nil &&
       home_pts       != nil

      games.each do |g|
        next if g[:game_finished] == true

        if away_team == g[:away_team] && home_team == g[:home_team]
          puts
          puts 'TIME: ' + time_remaining.inspect
          puts 'AWAY: ' + away_team..ljust(20, ' ') + ' => ' + away_pts.inspect
          puts 'HOME: ' + home_team..ljust(20, ' ') + ' => ' + home_pts.inspect

          HTTParty.post('https://shepic.herokuapp.com/admin/update_score', :body => {
            :secret         => ARGV[0],
            :id             => g[:id],
            :game_finished  => false,
            :time_remaining => time_remaining,
            :away_pts       => away_pts,
            :home_pts       => home_pts,
          })
        else
          puts 'NO MATCH! ... AWAY: ' + away_team + '  HOME: ' + home_team
        end
      end

      time_remaining, away_team, home_team, away_pts, home_pts = nil
    end
  end

  time_remaining, away_team, home_team, away_pts, home_pts = nil
  finished_html_elements = Nokogiri::HTML(scrape).css('#scoreboard-group-2 div:nth-child(3) ul li').css('div')
  finished_html_elements.each_with_index do |el|
    # TIME REMAINING
    if el.attributes['class'] && el.attributes['class'].value == 'Ta(end) Cl(b) Fw(b) '
      time_remaining = el.text
    end

    if time_remaining != nil
      # TEAMS
      if el.attributes['class'] && el.attributes['class'].value == 'Fw(b) Fz(14px)'
        team_name = el.text
        team_name = strip_RZ_from_team_name(team_name)
        team_name = strip_rank_from_team_name(team_name)

        away_team == nil ? away_team = team_name : home_team = team_name
      end

      # POINTS
      if el.attributes['class'] && el.attributes['class'].value == 'Whs(nw) D(tbc) Va(m) Fw(b) Fz(27px)'
        points = parse_points_from_attribute(l)
        away_pts == nil ? away_pts = points : home_pts = points
      end
    end

    if time_remaining != nil &&
       away_team      != nil &&
       home_team      != nil &&
       away_pts       != nil &&
       home_pts       != nil

      games.each do |g|
        next if g[:game_finished] == true

        if away_team == g[:away_team] && home_team == g[:home_team]
          g[:game_finished] = (time_remaining == 'Final' || time_remaining == 'Final OT'  ? true : false)

          HTTParty.post('https://shepic.herokuapp.com/admin/update_score', :body => {
            :secret => ARGV[0],
            :id => g[:id],
            :game_finished => g[:game_finished],
            :time_remaining => time_remaining,
            :away_pts => away_pts,
            :home_pts => home_pts,
          })
        end
      end

      time_remaining, away_team, home_team, away_pts, home_pts = nil
    end
  end

  # TODO: if all games aren't on same day, will not turn off!
  if games.map { |g| g[:game_finished] }.all? then exit end
end
scheduler.join
