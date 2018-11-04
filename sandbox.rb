require 'nokogiri'

live_ex = File.open("html_live_example.html") { |f| Nokogiri::XML(f) }
puts 'anyong!'  if live_ex.css('#scoreboard-group-2 div div').at('h3').text == 'Live'
puts 'anyong 2' if live_ex.css('#scoreboard-group-2 div:nth-child(3) div').at('h3').text == 'Finished'

(1..3).each do |t|
  if live_ex.css("#scoreboard-group-2 div:nth-child(#{t}) div").at('h3').text == 'Finished'
    puts t
    finished_scrape_div = Nokogiri::HTML(scrape).css("#scoreboard-group-2 div:nth-child(#{t}) ul li").css('div')
    break
  end
end

# finished_ex = File.open("html_finished_example.html") { |f| Nokogiri::XML(f) }
# puts 'fin' if finished_ex.css('#scoreboard-group-2 div div').at('h3').text == 'Finished'
# puts 'fin 2' if finished_ex.css('#scoreboard-group-2 div:nth-child(1) div').at('h3').text == 'Finished'

# (1..3).each do |t|
#   puts t
#   break if t == 2
# end
