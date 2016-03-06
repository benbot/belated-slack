require "sinatra"
require "json"
require "./message_rater"
# require "sinatra/reloader"

get "/" do
  "NOPE"
end

get "/belate" do
  # messages = [{time: "5"}, {time: "3"}, {time: "3"}, {time: "3"}]
  resp = HTTParty.get("https://slack.com/api/channels.list?token=xoxp-23405578101-24698746982-24712729345-75f715a977")
  body = JSON.parse resp.body
  channel = body["channels"]
  general = channel.select {|c| c["name"] == "general"}
  id = general.first["id"]

  resp = HTTParty.get("https://slack.com/api/channels.history?token=xoxp-23405578101-24698746982-24712729345-75f715a977&channel=#{id}")
  resp = JSON.parse resp.body

  messages = resp["messages"]
  messages = messages.sort {|s| s["ts"].to_f}
  # messages.reverse

  a = MessageRater.new
  top = a.top_fourth(messages)
  top = a.set_score(messages)

  s = ""

  s += "Important Messages!\n 1. #{top[0]["text"]}\n2. #{top[1]["text"]}\n3. #{top[2]["text"]}\n"

  # {"text": s}.to_json
  s
end
