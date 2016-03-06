require "byebug"
require 'date'
require 'httparty'

class MessageRater
  def top_fourth messages
    time = []
    midTime = []
    messages.each do |m|
      time.push({msg: m, time: Time.strptime(m["ts"],"%s")})
    end

    time = time.reverse

    tempTime = time[0][:time]
    time.size.times do |i|
      unless i+1 >= time.size
        t = tempTime - time[i+1][:time]
        midTime.push({msg: time[i], time: t})
        tempTime = time[i+1][:time]
      end
    end

   midTime =  midTime.sort_by {|x| x[:time]}
   size = midTime.size

   midTime[0..(size/4)]
  end

  def average_length messages
    sum = 0
    messages.each do |m|
      sum += m["text"].length
    end

    sum / messages.size
  end

  def average_num_words messages
    total = 0
    messages.each do |m|
      split = m["text"].split(" ")
      total += split.size
    end

    total / messages.size
  end

  def set_score messages
    messages.each do |m|
      score = {a: 0, b: 0, c: 0, d: 0, e: 0, f: 0, h: 0}
      text = m["text"]

      if !m["file"].nil?
        score[:a] = 1
      else
        score[:a] = 0
      end

      if /[A-Z]/ =~ text
        score[:b] = 1
      else
        score[:b] = 0
      end

      ["boyfriend","girlfriend","cheat","kissed","did you hear"].each do |k|
        if text.include? k
          score[:c] = 1
          break
        else
          score[:c] = 0
        end
      end

      if /[0-9]/ =~ text
        score[:d] = 1
      else
        score[:d] = 0
      end

      if /\$/ =~ text
        score[:e] = 1
      else
        score[:e] = 0
      end

      if /\?/ =~ text
        score[:f] = 1
      else
        score[:f] = 0
      end

      if text.length > average_length(messages)
        score[:g] = 1
      else
        score[:g] = 0
      end

      split = text.split(' ')
      if split.size > average_num_words(messages)
        score[:h] = 1
      else
        score[:h] = 0
      end

      final_score = 0.15*score[:a] + 0.05*score[:b] + 0.05*score[:c] + 0.2*score[:d] + 0.2*score[:e] + 0.15*score[:f] + 0.1*score[:g] + 0.1*score[:h]

        m["score"] = final_score
    end

    messages = messages.select {|x| x["score"] > 0}
    messages.sort_by {|x| x["score"]}
  end
end

# messages = [{time: "5"}, {time: "3"}, {time: "3"}, {time: "3"}]
resp = HTTParty.get("https://slack.com/api/channels.list?token=xoxp-3163547988-6152538678-24669835091-ea7d0b9870")
body = JSON.parse resp.body
channel = body["channels"]
general = channel.select {|c| c["name"] == "general"}
id = general.first["id"]

resp = HTTParty.get("https://slack.com/api/channels.history?token=xoxp-3163547988-6152538678-24669835091-ea7d0b9870&channel=#{id}")
resp = JSON.parse resp.body

messages = resp["messages"]
messages = messages.sort {|s| s["ts"].to_f}
# messages.reverse

a = MessageRater.new
top = a.top_fourth(messages)
top = a.set_score(messages)
puts top[1]["text"]
