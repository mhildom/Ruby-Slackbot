Ruby Slackbot

A simple bot designed to monitor a twitter handle for incoming tweets that contain specified key words.
To use, you will need to register a ruby bot and a developer twitter account.
Once those are set, update the config.yml with the keys/tokens you were given.

To run the file, use "bundle exec ruby Rubybot.rb"
It will output into the command line your initial settings that come from the search_config.yml

In slack, invite the bot to the channel you want it to post notifications in.

You can test if the bot is up and running in slack via the "rubybot hi" command

The following commands are available, with more hopefully coming as more features are added.

    rubybot 
            - hi
                Simple ping pong type response, bot will respond with hello.
            - set_target "TARGET"
                This will set the twitter handle the bot will monitor. you do not need to include an @.
                e.g. rubybot set_target matthildom | This will set the bot to monitor the twitter account @matthildom for incoming tweets.
            - show_target
                Will respond with the current target.
            - add_searchterm "TERM"
                This will add the specified term to search for. at the moment this must be a single word with no spaces.
                e.g. rubybot add_searchterm update | This will search the current target for any tweet containing the word update.
            - remove_searchterm "TERM"
                this will remove the specified term. at the moment this must be a single word with no spaces.
                e.g. rubybot remove_searchterm update | This will stop searching the target for tweets containing update.
            - list_searchterms
                This will force the bot to respond with all current search terms.
            - show_all_tweets true/false
                This is a slight workaround for looking at all tweets. It technically adds a search term (or removes) for ' ', so it will show any tweet including a space. This feature will be improved to a true show all in the future.
            - search_depth "INT"
                This will set the bot to look back this many tweets whenever it searches. It is advised not to use an overly large search depth, especially when using a short frequency (which at the moment can only be configured via search_config.yml file)

The bot will catalog all tweets that meet the requirements while running, so that it never display a tweet more than once. This resets on bot restart, but in future updates will be saved for persistance.

Additional features planned for future updates:
- Able to monitor any number of handles, each with its own set of terms
- GUI application to control bot settings outside of file editing/slack commands
