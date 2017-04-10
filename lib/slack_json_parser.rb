require 'json'
require 'open-uri'
require 'httparty'

class SlackJsonParser

  def initialize
  end

  def generate_json(api_method, token)
    path = "api/#{api_method}?token=#{token}&pretty=1"
    response = HTTParty.get("https://slack.com/#{path}")

    response['paging'] ? generate_json_pages(response, path) : response
  end

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

  def show_export_message(message)
    print "#{message}..."
    show_wait_cursor{
      sleep rand(4)+2
    }
    system "clear"
  end

  private

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

  def show_wait_cursor(fps=10)
    chars = %w[| / - \\]
    delay = 1.0/fps
    iter = 0
    spinner = Thread.new do
      while iter do
        print chars[(iter+=1) % chars.length]
        sleep delay
        print "\b"
      end
    end
    yield.tap{
      iter = false
      spinner.join
    }
  end
end
