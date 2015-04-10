require 'rubygems'
require 'sinatra'
BLACKJACK = 21
DEALER_HIT_MIN = 17

set :sessions, true

helpers do
  def calculate_total(cards)
    total = 0
    cards.each do |card|
      if card[0] == 'A'
        total += 11
      else
        total += card[0].to_i == 0 ? 10 : card[0].to_i
      end
    end

    cards.each do |card|
      if card[0] == 'A' && total > BLACKJACK
        total -= 10
      end
    end
    total
  end

  def card_image(card)
    value = case card[0]
    when "J" then "jack"
    when "Q" then "queen"
    when "K" then "king"
    when "A" then "ace"
    else
      card[0]
    end

    suit = case card[1]
    when "s" then "spades"
    when "c" then "clubs"
    when "d" then "diamonds"
    when "h" then "hearts"
    end
    
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner(msg)
    @show_hit_or_stay_buttons = false
    @play_again = true
    @success = "#{msg} #{session[:player_name]} wins!"
  end

  def loser(msg)
    @show_hit_or_stay_buttons = false
    @play_again = true
    @error = "#{msg} #{session[:player_name]} loses..."
  end

  def tie(msg)
    @show_hit_or_stay_buttons = false
    @play_again = true
    @success = "#{msg} It's a tie!"
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/set_name'
  end
end

get '/set_name' do
  erb :set_name
end

post '/set_name' do
  if params[:player_name].empty?
    @error = "Name is required."
    halt erb :set_name
  end
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  values = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
  suits = ["s", "c", "d", "h"]
  session[:deck] = values.product(suits).shuffle!
  session[:players_cards] = []
  session[:dealers_cards] = []
  2.times do
    session[:players_cards] << session[:deck].pop
    session[:dealers_cards] << session[:deck].pop
  end
  session[:turn] = "Player"
  player_total = calculate_total(session[:players_cards])
  if player_total == BLACKJACK && session[:players_cards].count == 2
    redirect '/game/player/blackjack'
  end
  erb :game
end

post '/game/player/hit' do
  session[:players_cards] << session[:deck].pop
  player_total = calculate_total(session[:players_cards])
  if player_total > BLACKJACK
    loser("Sorry, it looks like #{session[:player_name]} busted at #{calculate_total(session[:players_cards])}.")
  elsif player_total == BLACKJACK
    session[:turn] = "dealer"
    redirect '/game/dealer'
  end
  erb :game
end

post '/game/player/stay' do
  @show_hit_or_stay_buttons = false
  session[:turn] = "dealer"
  redirect '/game/dealer'
end

get '/game/dealer' do
  @show_hit_or_stay_buttons = false
  
  dealer_total = calculate_total(session[:dealers_cards])

  if dealer_total == BLACKJACK && session[:dealers_cards].count == 2
    loser("Dealer has Blackjack.")
  elsif dealer_total < DEALER_HIT_MIN
    @show_dealer_hit_button = true
  elsif dealer_total > BLACKJACK
    winner("Dealer busted at #{calculate_total(session[:dealers_cards])}.")
  else
    redirect '/game/compare'
  end
  erb :game
end

post '/game/dealer/hit' do
  session[:dealers_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  player_total = calculate_total(session[:players_cards])
  dealer_total = calculate_total(session[:dealers_cards])

  if player_total > dealer_total
    winner("#{session[:player_name]} has #{player_total} and the dealer has #{dealer_total}.")
  elsif player_total == dealer_total
    tie("#{session[:player_name]} and the dealer both have #{player_total}.")
  else
    loser("#{session[:player_name]} has #{player_total} and the dealer has #{dealer_total}.")
  end
  erb :game
end

get '/game/player/blackjack' do
  session[:turn] = "dealer"
  if calculate_total(session[:dealers_cards]) == BLACKJACK && session[:dealers_cards].count == 2
    tie("#{session[:player_name]} has Blackjack but the dealer also has Blackjack!")
  else
    winner("#{session[:player_name]} has Blackjack!")
  end
  erb :game
end






