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

    time.size.times do |i|
      unless i+1 >= time.size
        t = time[i][:time] - time[i+1][:time]
        midTime.push({msg: time[i], time: t})
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
      score = {}
      text = m["text"]

      if !m["file"].nil?
        score[:file] = 1
      else
        score[:file] = 0
      end

      if /[A-Z]/ =~ text
        score[:capital] = 1
      else
        score[:capital] = 0
      end

      ["boyfriend","girlfriend","cheat","kissed","did you hear",
       "javascript", "good", "bad", "ruby", "go", "programming"].each do |k|
        if text.include? k
          score[:keywords] = 1
          break
        else
          score[:keywords] = 0
        end
      end

      if /\$|[0-9]/ =~ text
        score[:numbers] = 1
      else
        score[:numbers] = 0
      end

      if /\?/ =~ text
        score[:question] = 1
      else
        score[:question] = 0
      end

      if text.length > average_length(messages)
        score[:length] = 1
      else
        score[:length] = 0
      end

      split = text.split(' ')
      if split.size > average_num_words(messages)
        score[:word_count] = 1
      else
        score[:word_count] = 0
      end

      final_score = 0.15*score[:file] + 0.05*score[:capital] 
        + 0.05*score[:keywords] + 0.3*score[:numbers] + 0.1*score[:question] 
        + 0.15*score[:length] + 0.2*score[:word_count]

        m["score"] = final_score
    end

    messages = messages.select {|x| x["score"] > 0}
    messages.sort_by {|x| x["score"]}
  end
end

