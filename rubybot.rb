require "slack-ruby-bot"
require "slack-ruby-client"
require "twitter"
require "yaml"
require "pp"

#run with "bundle exec ruby rubybot.rb"

config = YAML.load(File.open('config.yml').read)
search_config = YAML.load(File.open('search_config.yml').read)

#possibly create a way to load from config file
$search_depth = search_config['search_depth'].to_i
puts "Search Depth: #{$search_depth}"
$search_terms = []
search_config['search_terms'].each do |term|
  $search_terms.append(term)
end
puts "Search Terms: #{$search_terms}"
$search_target = search_config['search_target']
puts "Search Target: #{$search_target}"
$search_frequency = search_config['search_frequency'].to_i
puts "Search Frequency: #{$search_frequency}"

#Find way to save all keys to a single file so I dont accidently push a build that includes keys for slack and twitter
$SLACK_API_TOKEN  = config.dig("SLACK","SLACK_API_TOKEN")
$TWITTER_CONSUMER_KEY  = config.dig("TWITTER","CONSUMER_KEY")
$TWITTER_CONSUMER_SECRET = config.dig("TWITTER","CONSUMER_SECRET")
$TWITTER_ACCESS_TOKEN = config.dig("TWITTER","ACCESS_TOKEN")
$TWITTER_ACCESS_TOKEN_SECRET = config.dig("TWITTER","ACCESS_TOKEN_SECRET")

#configure the slack instance to use our key
Slack.configure do |config|
  config.token = $SLACK_API_TOKEN
end

#start a realtime client
client = Slack::RealTime::Client.new
client.web_client.auth_test

#set up a hook so we can respond to messages
client.on :message do |data|
  t = data.text.downcase
  text = t.split ' '
  if text[0] == 'rubybot'
    case text[1]
    #example of a simple ping/pong response
    when 'hi' then
      client.web_client.chat_postMessage(text: 'Hello!', channel: data.channel)
    when 'set_target' then
      client.web_client.chat_postMessage(text: "Setting target to: @#{text[2]}", channel: data.channel)
      $search_target = text[2]
    when 'add_searchterm' then
      client.web_client.chat_postMessage(text: "Added search term: #{text[2]}", channel: data.channel)
      $search_terms.append(text[2])
    when 'show_target' then
      client.web_client.chat_postMessage(text: "Current target is: @#{$search_target}", channel: data.channel)
    when 'remove_searchterm' then
      client.web_client.chat_postMessage(text: "Removed search term: #{text[2]}", channel: data.channel)
      $search_terms.delete(text[2])
    when 'list_searchterms' then
      $search_terms.each do |term|
        client.web_client.chat_postMessage(text: "#{term}", channel: data.channel)
      end
    when 'show_all_tweets' then
      if text[2] == 'true'
        $search_terms.append(' ')
        client.web_client.chat_postMessage(text: "Now showing all tweets to @#{search_target}", channel: data.channel)
      else
        $search_terms.delete(' ')
        client.web_client.chat_postMessage(text: "No longer showing all tweets to @#{search_target}", channel: data.channel)
      end
    when 'search_depth' then
      client.web_client.chat_postMessage(text: "Setting tweet search depth to: #{text[2]}", channel: data.channel)
      $search_depth = text[2].to_i
    end

    settings = {
      "search_depth" => $search_depth,
      "search_terms" => $search_terms,
      "search_target" => $search_target,
      "search_frequency" => $search_frequency
    }
    File.open("search_config.yml",'w') {|file| file.write(settings.to_yaml)}
  end
end

#start the client as an async client, so we can make our own later. If we dont run as async, we will not be able to also check twitter easily
client.start_async

#again, find a way to pull these keys and secrets from a seperate file
twitterclient = Twitter::REST::Client.new do |config|
  config.consumer_key = $TWITTER_CONSUMER_KEY
  config.consumer_secret = $TWITTER_CONSUMER_SECRET
  config.access_token = $TWITTER_ACCESS_TOKEN
  config.access_token_secret = $TWITTER_ACCESS_TOKEN_SECRET
end

#create a couple hashs to store data in. One is permanent, the other is reset per loop so we can compare if we added to the actual array.
tweets = {}
last_tweets = {}

#heres our loop, do things here. In the future we could possibly make this async as well, but its not needed as of now
loop do
  last_tweets = *tweets

  #Grab all tweets in our search depth towards the specified @, sort by recent and collect them together, then loop over them
  #in the future, we can have an array of @s and loop over that if we want to monitor several handles
  twitterclient.search("to:#{$search_target}", result_type: "recent").take($search_depth).collect do |tweet|
    tweet_text = tweet.text.downcase
    #check if the tweet contains one of our search terms
    $search_terms.each do |term|
      if tweet_text.include? term
        #if it does, lets see if its already in storage. We can do this by checking the tweet ID which should always be unique. This is set up with the key being the ID for easy reference,
        #with the value storing the user that tweeted and the message.
        unless tweets.key?(tweet.id)
          tweets[tweet.id] = "#{tweet.user.screen_name}: #{tweet.text}"
        end
      end
    end
  end
  #compare our two hashes, and create a temporary hash that contains only items that were added this loop
  #loop over it and send those new tweets to the slack channel!
  difference = tweets.to_a - last_tweets.to_a
  Hash[*difference.flatten].each do |key, value|
     client.web_client.chat_postMessage(channel: "#twitter-bot", text: "#{value}", as_user: true)
   end


   sleep $search_frequency
end
