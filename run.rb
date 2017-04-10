require 'highline/import'
require 'gist'
require_relative 'lib/slack_json_parser.rb'

system "clear"
SLACK_API_TOKEN = ask 'Find your Slack API token here: '\
  "https://api.slack.com/custom-integrations/legacy-tokens \nEnter your Slack API token:\n"
system "clear"

Gist.login!
system "clear"

parser = SlackJsonParser.new
user_json = parser.generate_json("users.list", SLACK_API_TOKEN)
starred_json = parser.generate_json("stars.list", SLACK_API_TOKEN)

selected = ask "Continue exporting #{parser.team_name} starred messages [yes/no]\n"
system "clear"
selected == 'yes' ? print("exporting...\n") : print("aborting task") && return

file = File.new("starred_messages_from_#{parser.team_name}.md", "w")
file.puts("#{parser.format_messages(starred_json, user_json)}")
file.close

Gist.gist("#{File.read(file)}", filename: "#{file.path}")
File.delete(file.path)
