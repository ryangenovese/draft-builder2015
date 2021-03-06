# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'csv'

nfl_teams = CSV.read('db/nfl_teams.csv')

puts "\nLoading NFL Teams"
nfl_teams.each do |team|
  t = NflTeam.find_or_create_by(
    city: team[0], 
    nickname: team[1], 
    shortname: team[2], 
    bye: team[3].to_i
  )
  # puts "Loading the #{t.nickname}"
end

puts "\nLoading NFL Players"
['QB', 'RB', 'WR', 'TE', 'DEF', 'K'].each do |position|
  players = CSV.read("db/players/#{position.downcase}.csv")
  players.each do |player|
    pl = NflPlayer.find_or_create_by(
      position_rank: player[0].to_i, projected_points: player[1].to_d,
      last_name: player[2], first_name: player[3], position: position,
      nfl_team: NflTeam.where(shortname: player[4]).first
    )
  end
end

# keepers
# puts
# def keep(name, owner)
#   first, last = name.split(' ')
#   player = NflPlayer.where(first_name: first, last_name: last).first
#   FantasyTeam.where(owner: owner).first.draft_picks[3].update(nfl_player: player, keeper: true)
#   puts "#{owner} is keeping #{player.name}"
# end

# keep('Jeremy Hill', 'Rodney')
# keep('Mark Ingram', 'Lucas')

# load adp data
puts "\nLoading ADP data from FFC\n\n"
players = CSV.read('db/adp/ffc.csv')
players.each do |player|
  names = player[2].split(' ')
  if names.last == 'Defense'
    pl = NflPlayer.where(position: 'DEF').joins(:nfl_team).where(
      "nfl_teams.shortname" => player[4]).first 
  else
    first, last = [names[0], names.last(names.count-1).join(' ')] 
    pl = NflPlayer.where(last_name: last, position: player[3]).joins(:nfl_team).where(
      "nfl_teams.shortname" => player[4]).first
  end

  if !pl
    p "#{player[2]} not found!!!"
  else
    pl.update(adp_ffc: player[1].to_f, adp_round: player[0].to_f)
  end
end

NflPlayer.where(adp_ffc: nil).each do |player|
  player.update(adp_ffc: 170, adp_round: 20.0)
end

puts "\nLoading ADP data from ESPN\n\n"
File.open('db/adp/espn.txt', "r") do |f|
  f.each_line do |line|
    names, data = line.split(',').map { |part| part.strip.split(' ') }
    if names.last == 'D/ST'
      pl = NflPlayer.where(position: 'DEF').joins(:nfl_team).where(
        "nfl_teams.shortname" => data[1].upcase).first  
    else
      first, last = [names[0], names.last(names.count-1).join(' ')] 
      pl = NflPlayer.where(last_name: last, position: data[1]).joins(:nfl_team).where(
        "nfl_teams.shortname" => data[0].upcase).first
    end

    if !pl
      p "#{names.join(' ')} not found!!!"
    else
      pl.update(adp_espn: data[2].to_f)
    end

  end
end

NflPlayer.where(adp_espn: nil).each do |player|
  player.update(adp_espn: 201)
end

puts "\nLoading ADP data from Yahoo\n\n"
players = CSV.read('db/adp/yahoo.csv')
players.each do |player|
  
  if player[3] == 'DEF'
    pl = NflPlayer.where(position: 'DEF').joins(:nfl_team).where(
      "nfl_teams.shortname" => player[4]).first 
  else
    pl = NflPlayer.where(last_name: player[2], position: player[3]).joins(:nfl_team).where(
      "nfl_teams.shortname" => player[4]).first
  end

  if !pl
    p player
    # p "#{player[1] + " " + player[2]} not found!!!"
  else
    pl.update(adp_yahoo: player[0].to_f)
  end
end

NflPlayer.where(adp_yahoo: nil).each do |player|
  player.update(adp_yahoo: 240)
end