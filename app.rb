# coding: utf-8

require "eventmachine"
require "twitter"
require "tweetstream"
require "logger"
require "randexp"

twitter_consumer_key = ENV["CLIENT_CONSUMER_KEY"]
twitter_consumer_secret = ENV["CLIENT_CONSUMER_SECRET"]
twitter_access_token = ENV["CLIENT_ACCESS_TOKEN"]
twitter_access_token_secret = ENV["CLIENT_ACCESS_TOKEN_SECRET"]

log = Logger.new STDOUT
STDOUT.sync = true

rest = Twitter::Client.new(
  consumer_key: twitter_consumer_key,
  consumer_secret: twitter_consumer_secret,
  oauth_token: twitter_access_token,
  oauth_token_secret: twitter_access_token_secret,
)

TweetStream.configure do |config|
  config.consumer_key = twitter_consumer_key
  config.consumer_secret = twitter_consumer_secret
  config.oauth_token = twitter_access_token
  config.oauth_token_secret = twitter_access_token_secret
  config.auth_method = :oauth
end

stream = TweetStream::Client.new

EventMachine.error_handler do |ex|
  log.error ex.message
end

EventMachine.run do
  EventMachine.add_periodic_timer(300) do
    friends = rest.friend_ids.all
    followers = rest.follower_ids.all
    to_follow = followers - friends
    to_unfollow = friends - followers

    # follow
    to_follow.each do |id|
      log.info "following #{id}"
      log.info "done." if rest.follow id
    end

    # unfollow
    to_unfollow.each do |id|
      log.info "unfollowing #{id}"
      log.info "done." if rest.unfollow id
    end
  end

  stream.on_inited do
    log.info "init"
  end

  stream.userstream do |status|
    log.info "status from @#{status.from_user}: #{status.text}"
    next if status.from_user == "kaeritainess"
    next if status.retweet?

    kaeritai = case status.text
    when /帰りたい|@kaeritainess/
      rand(10) > 7 ? /帰りたいにゃー?ん?！?？?/.generate : ""
    when /kaeritainess/i
      Regexp.last_match(0)
    end

    EM.add_timer(rand(10) ** 2) do
      tweet = rest.update("@#{status.user.screen_name} #{kaeritai}", in_reply_to_status_id: status.id) unless kaeritai.empty?
      log.info "tweeted: #{tweet.text}" if tweet
    end
  end
end
