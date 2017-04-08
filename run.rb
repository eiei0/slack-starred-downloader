require 'json'
require 'open-uri'
require 'httparty'
require 'highline/import'
require 'gist'
require 'pry'

system "clear"
SLACK_API_TOKEN = ask "Find your Slack API token here: https://api.slack.com/custom-integrations/legacy-tokens\nEnter your Slack API token:\n"
system "clear"

Gist.login!
system "clear"

def generate_json_pages(response, path)
  last_page = response['paging']['pages']

  if last_page > 1
    (1..last_page).to_a.each do |page_number|
      break HTTParty.get("https://slack.com/#{path}/&page=#{page_number}")
    end
  else
    response
  end
end

def generate_json(api_method, token)
  path = "api/#{api_method}?token=#{token}&pretty=1"
  response = HTTParty.get("https://slack.com/#{path}")

  response['paging'] ? generate_json_pages(response, path) : response
end

user_json = generate_json("users.list", SLACK_API_TOKEN)
starred_json = generate_json("stars.list", SLACK_API_TOKEN)

def team_name(team_response=nil)
  if team_response.nil?
    team_response = generate_json("team.info", SLACK_API_TOKEN)
  end
  team_response.parsed_response["team"]["name"]
end

def user_name(user_json, user_id)
  users = user_json['members']
  users.each do |user|
    if user['id'] == user_id
      return user['real_name']
    end
  end
end


SELECTED = ask "Continue exporting #{team_name} starred messages [yes/no]\n"
system "clear"
SELECTED == 'yes' ? print("exporting...\n") : print("aborting task") && return

def format_messages(starred_json, user_json)
  message = ""
  starred_json['items'].each do |item|
    if item['message']
      user_id = item['message']['user']

      message.concat(
        "## From: #{user_name(user_json, user_id)}\n" +
        "#{item['message']['text']}\n\n"
      )
    elsif item['file']
      user_id = item['file']['user']

      message.concat(
        "## From: #{user_name(user_json, user_id)}\n" +
        "#{item['file']['name']}\n" +
        "#{item['file']['text']}\n" +
        "#{item['file']['url_private_download']}\n\n"
      )
    else
      print "\nStarred message type currently not supported" && next
    end
  end
  message
end

file = File.new("starred_messages_from_#{team_name}.md", "w")
file.puts("#{format_messages(starred_json, user_json)}")
file.close

Gist.gist("#{File.read(file)}", filename: "#{file.path}")
File.delete(file.path)
