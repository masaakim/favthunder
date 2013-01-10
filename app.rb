# -*- coding: utf-8 -*-
$KCODE='u'
#require 'jcode'
require 'sinatra'
require 'twitter'
require 'oauth'
require 'pp'


helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end
 

configure do
  use Rack::Session::Cookie, :secret => Digest::SHA1.hexdigest(rand.to_s)
  KEY = "3sON24EvPRDBEcdv6VlWQ"
  SECRET = "tuMeO9Oqe6MaZK9r4W48VmS2QcdAD7e1MGuWGk4s"
end

 
before do
  if session[:access_token]
    Twitter.configure do |config|
      config.consumer_key = '3sON24EvPRDBEcdv6VlWQ'
      config.consumer_secret = 'tuMeO9Oqe6MaZK9r4W48VmS2QcdAD7e1MGuWGk4s'
      config.oauth_token = session[:access_token]
      config.oauth_token_secret = session[:access_token_secret]
    end
    @twitter = Twitter::Client.new
  else
    @twitter = nil
  end
end



def base_url
  default_port = (request.scheme == "http") ? 80 : 443
  port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
  "#{request.scheme}://#{request.host}#{port}"
end

 
def oauth_consumer
  OAuth::Consumer.new(KEY, SECRET, :site => "http://twitter.com")
end



get '/request_token' do
  callback_url = "#{base_url}/access_token"
  request_token = oauth_consumer.get_request_token(:oauth_callback => callback_url)
  session[:request_token] = request_token.token
  session[:request_token_secret] = request_token.secret
  redirect request_token.authorize_url
end

 
get '/access_token' do
  request_token = OAuth::RequestToken.new(
    oauth_consumer, session[:request_token], session[:request_token_secret])
  begin
    @access_token = request_token.get_access_token(
      {},
      :oauth_token => params[:oauth_token],
      :oauth_verifier => params[:oauth_verifier])
  rescue OAuth::Unauthorized => @exception
    return erb %{ oauth failed: <%=h @exception.message %> }
  end
  session[:access_token] = @access_token.token
  session[:access_token_secret] = @access_token.secret

  redirect '/fav'
end


get '/' do
  if @twitter then
    redirect '/fav'
  else
    redirect '/login'
  end
end


get '/login' do
  erb :index
end


get '/fav' do
  redirect '/' unless @twitter
  #my_id = Twitter.user.screen_name
  #my_follow = Twitter.friend_ids(my_id)
  erb :fav
end


$global_tweets_id = []

def getUserTimelineIdByScreenName screen_name, count
  if Twitter.user?(screen_name) then
    options = {:count => count}
    Twitter.user_timeline(screen_name, options).each do |tweet|
      $global_tweets_id.push(tweet.id)
    end
    return $global_tweets_id
  else
    #redirect 'error'
  end
end


post '/fav' do
  screen_name = params[:screen_name]
  count = params[:count]
  tweet_id = getUserTimelineIdByScreenName(screen_name, count)
  tweet_id.each do |t_id|
    Twitter.favorite(t_id)
  end

  redirect '/fav'
end

