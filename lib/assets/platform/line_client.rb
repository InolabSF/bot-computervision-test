require 'json'
require 'line/bot'
require './lib/assets/third_party/cloudinary_client'


class LineClient

  MAX_NUMBER_OF_QUICK_REPLY = 5


  # get channel configs
  #
  # @param [String] user_id messenger user ID
  # @return [Hash] hash contaings verify_token and access_token
  # {
  #   :verify_token => '.....',
  #   :access_token => '.....',
  # }
  def self.get_config_by_user_id(user_id)
    verify_token = ENV["LINE_CHANNEL_SECRET"]
    access_token = ENV["LINE_CHANNEL_ACCESS_TOKEN"]
    sender = Sender.find_by_user_id_using_code(user_id)
    if sender
      bot = Bot.find_by_id(sender.bot_id)
      if bot
        verify_token = bot.verify_token if bot.verify_token
        access_token = bot.access_token if bot.access_token
      end
    end

    { :verify_token => verify_token, :access_token => access_token }
  end

  # initialize
  #
  # @param [String] user_id messenger user ID
  def initialize(user_id)
    configs = LineClient.get_config_by_user_id(user_id)
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = configs[:verify_token]
      config.channel_token = configs[:access_token]
    }
    @user_id = user_id
  end


  # get message content user sent
  #
  # @param [String] content_id content id string
  # @return [Response] http response
  def get_message_content(content_id)
    @client.get_message_content(content_id)
  end

  # get profile
  #
  # @return [UserProfile] line's user profile object
  # @return [Hash] json response
  def get_profile
    response = @client.get_profile(@user_id)

    begin
      JSON.parse(response.body)
    rescue Exception => e
      {}
    end
  end


  # post hash on line messenger platform
  #
  # @param [Hash] message Hash to send
  # @return [Hash] json response
  def post_message(message)
    response = @client.push_message(@user_id, message)

    begin
      json_to_return = JSON.parse(response.body)
      json_to_return["code"] = response.code

      # error handling
      #store_error_by_json({"platform" => 'line', "user_id" => @user_id, "json" => message}, json_to_return)
      json_to_return
    rescue Exception => e
      {"code" => 400}
    end
  end

  # post message to line
  #
  # @param [String] text text to send
  # @return [Hash] json response
#  def post_text(text)
#    post_message({ "type" => 'text', "text" => "#{text}" })
#  end
  def get_text(text)
    [{ "type" => 'text', "text" => "#{text}" }]
  end

  # post image to line
  #
  # @param [String] image_uri uri of image
  # @return [Hash] json response
#  def post_image(url)
#    url.gsub!('http:', 'https:')
#    post_message({ "type" => 'image', "originalContentUrl" => url, "previewImageUrl" => url })
#  end
  def get_image(url)
    url.gsub!('http:', 'https:')
    [{ "type" => 'image', "originalContentUrl" => url, "previewImageUrl" => url }]
  end


  # post buttons to line
  #
  # @param [Hash] button hash
  #   {
  #     "text" : "title",
  #     "buttons" : [
  #       { "type" : "web_url", "title" : "title", "url" : "https://google.com" },
  #       { "type" : "postback", "title" : "title", "payload" : "postback_abc" }
  #     ]
  #   }
  # @return [Hash] json response
#  def post_button(button)
#    # normalize facebook json into line json
#    button_hashes = []
#    buttons = button['buttons']
#    buttons.each do |button_hash|
#      button_hash['label'] = button_hash['title']
#      if button_hash['type'] == 'web_url'
#        button_hash['type'] = 'uri'
#        button_hash['uri'] = button_hash['url']
#      elsif button_hash['type'] == 'postback'
#        button_hash['data'] = button_hash['payload']
#      end
#      button_hashes.push(button_hash)
#    end
#    text = button['text']
#    # json
#    message = {
#      "type" => 'template',
#      "altText" => "#{text}",
#      "template" => {
#          "type" => 'buttons',
#          "text" => "#{text}",
#          "actions" => button_hashes
#      }
#    }
#    # post
#    post_message(message)
#  end
  def get_button(button)
    # normalize facebook json into line json
    button_hashes = []
    buttons = button['buttons']
    buttons.each do |button_hash|
      button_hash['label'] = button_hash['title']
      if button_hash['type'] == 'web_url'
        button_hash['type'] = 'uri'
        button_hash['uri'] = button_hash['url']
      elsif button_hash['type'] == 'postback'
        button_hash['data'] = button_hash['payload']
      end
      button_hashes.push(button_hash)
    end
    text = button['text']
    # json
    message = {
      "type" => 'template',
      "altText" => "#{text}",
      "template" => {
          "type" => 'buttons',
          "text" => "#{text}",
          "actions" => button_hashes
      }
    }
    # post
    [message]
  end


  # post quick replies
  #
  # @param [Hash] json json to send
  #   {
  #     "text" : "title",
  #     "quick_replies" : [
  #       { "content_type" : 'text', "title" : 'button_title', "payload" : 'payload' },
  #       { "content_type" : 'text', "title" : 'button_title', "payload" : 'payload' }
  #     ]
  #   }
  # @return [Hash] response
#  def post_quick_replies(json)
#    image_url = json['image_url']
#    public_id = CloudinaryClient.new.get_public_id_by_url(image_url)
#    return unless public_id
#    quick_replies = json['quick_replies']
#    return unless quick_replies
#    count = quick_replies.count
#    return if count == 0
#
#    # title
#    post_text(json['text']) if json['text']
#    # imagemap
#    width = 1040
#    height = 130
#    cloudinary_hash = {}
#    actions = []
#    quick_replies.each_with_index do |quick_reply, i|
#      next if i >= MAX_NUMBER_OF_QUICK_REPLY
#
#      actions.push({
#        "type" => "message",
#        "text" => quick_reply["title"],
#        "area" => { "x" => width/count*i, "y" => 0, "width" => width/count, "height" => height }
#      })
#      cloudinary_hash[:"quick_reply_#{i+1}"] = quick_reply["title"]
#    end
#
#    cloudinary_string = ''
#    cloudinary_hash.each do |key, value|
#      cloudinary_string = "#{cloudinary_string}#{key}:#{value}:"
#    end
#
#    url = "#{ENV['ROOT_URL']}/quick_reply_image/#{public_id}/#{cloudinary_string}/"
#    #url = "https://jcbbot.herokuapp.com/quick_reply_image/#{public_id}/#{cloudinary_string}/"
#    post_message({
#      "type" => "imagemap",
#      "baseUrl" => URI.escape(url),
#      "altText" => json['text'],
#      "baseSize" => { "width" => width, "height" =>height },
#      "actions" => actions
#    })
#  end
  def get_quick_replies(json)
    image_url = json['image_url']
    public_id = CloudinaryClient.new.get_public_id_by_url(image_url)
    return [] unless public_id
    quick_replies = json['quick_replies']
    return [] unless quick_replies
    count = quick_replies.count
    return [] if count == 0

    messages = []
    # title
    messages.push(get_text(json['text'])) if json['text']
    # imagemap
    alt_text = ' '
    width = 1040
    height = 130
    cloudinary_hash = {}
    actions = []
    quick_replies.each_with_index do |quick_reply, i|
      next if i >= MAX_NUMBER_OF_QUICK_REPLY

      actions.push({
        "type" => "message",
        "text" => quick_reply["title"],
        "area" => { "x" => width/count*i, "y" => 0, "width" => width/count, "height" => height }
      })
      alt_text = "#{alt_text}#{quick_reply["title"]} "
      cloudinary_hash[:"quick_reply_#{i+1}"] = quick_reply["title"].gsub(',', '')
    end

    cloudinary_string = ''
    cloudinary_hash.each do |key, value|
      cloudinary_string = "#{cloudinary_string}#{key}:#{value}:"
    end

    #url = "#{ENV['ROOT_URL']}/quick_reply_image/#{public_id}/#{cloudinary_string}/"
    url = "https://jcbbot.herokuapp.com/quick_reply_image/#{public_id}/#{cloudinary_string}/"
    message = {
      "type" => "imagemap",
      "baseUrl" => URI.escape(url),
      "baseSize" => { "width" => width, "height" => height },
      "actions" => actions
    }
    message["altText"] = alt_text
    messages.push(message)
    messages
  end


  # post elements
  #
  # @param [Array] elements to send
  #   [
  #     {
  #       "title" : "hoge",
  #       "subtitle" : "fuga",
  #       "image_url" : "https://res.cloudinary.com/hdeg2ynq4/image/upload/v1492466874/jwi1mtghdsgofh4mqdr8.jpg",
  #       "buttons" : [
  #         { "type" : "web_url", "title" : "web_url", "url" : "https://google.com" },
  #         { "type" : "postback", "title" : "postback", "payload" : "postback_abc" }
  #       ]
  #     },
  #     ...
  #   ]
  # @return [Hash] json response
#  def post_elements(elements)
#    # normalize facebook json into line json
#    columns = []
#    elements.each do |element|
#      # actions
#      actions = []
#      buttons = element["buttons"]
#      buttons.each do |button|
#        case button["type"]
#        when "web_url"
#          actions.push({ "type" => 'uri', "label" => button["title"], "uri" => button["url"] })
#        when "postback"
#          actions.push({ "type" => 'postback', "label" => button["title"], "data" => button["payload"] })
#        else
#        end
#      end
#      # column
#      title = element["title"]
#      title = (title[0, 38] + '…') if title.length > 40
#      subtitle = (element["subtitle"].to_s.empty?) ? ' ' : element["subtitle"]
#      subtitle = (subtitle[0, 58] + '…') if subtitle.length > 60
#      columns.push({
#        "title" => title,
#        "text" => subtitle,
#        "thumbnailImageUrl" => (element["image_url"]) ? element["image_url"].gsub('http://', 'https://') : nil,
#        "actions" => actions
#      })
#    end
#    # json
#    message = {
#      "type" => 'template',
#      "altText" => columns.first["title"],
#      "template" => {
#          "type" => 'carousel',
#          "columns" => columns
#      }
#    }
#    # post
#    post_message(message)
#  end
  def get_elements(elements)
    # normalize facebook json into line json
    columns = []
    elements.each do |element|
      # actions
      actions = []
      buttons = element["buttons"]
      buttons.each do |button|
        case button["type"]
        when "web_url"
          actions.push({ "type" => 'uri', "label" => button["title"], "uri" => button["url"] })
        when "postback"
          actions.push({ "type" => 'postback', "label" => button["title"], "data" => button["payload"] })
        else
        end
      end
      # column
      title = element["title"]
      title = (title[0, 38] + '…') if title.length > 40
      subtitle = (element["subtitle"].to_s.empty?) ? ' ' : element["subtitle"]
      subtitle = (subtitle[0, 58] + '…') if subtitle.length > 60
      columns.push({
        "title" => title,
        "text" => subtitle,
        "thumbnailImageUrl" => (element["image_url"]) ? element["image_url"].gsub('http://', 'https://') : nil,
        "actions" => actions
      })
    end
    # json
    message = {
      "type" => 'template',
      "altText" => columns.first["title"],
      "template" => {
          "type" => 'carousel',
          "columns" => columns
      }
    }
    # post
    [message]
  end


  def post_messages(messages)
    messages.each do |message|
      post_message(message)
    end
  end

end

#user_id = 'U3d0862ca55cdfd807f6738cbb085b7a3'
###user_id = 'U3d328b27c267a2644f1b7fbf045760ef'
#line_client = LineClient.new(user_id)
#json = {
#  "image_url" => "https://res.cloudinary.com/hlxlaihl9/image/upload/v1502924269/ehouv9f0plek3cwgap2a",
#  "text" => "JCBプラザがあなたへのおすすめ情報をピックアップしました。",
#  "quick_replies" => [
#    { "content_type" => 'text', "title" => '食事', "payload" => 'payload' },
#    { "content_type" => 'text', "title" => '買い物', "payload" => 'payload' },
#    { "content_type" => 'text', "title" => 'ツアー', "payload" => 'payload' },
#    { "content_type" => 'text', "title" => 'チケット', "payload" => 'payload' }
#  ]
#}
#puts line_client.post_quick_replies(json)
