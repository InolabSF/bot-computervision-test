require './lib/assets/platform/line_client'


class JsonConverter

  # initialize
  #
  # @param [String] platform Bot::LINE, Bot::FACEBOOK, etc
  def initialize(platform)
    @platform = platform
  end

  # replaced_json
  #
  # @param [Hash] json
  # @param [Hash] replaced_keys keys to replace
  # @return [Hash] json
  def replaced_json(json, replaced_keys)
    replaced_keys.each { |key, fb_key| json[fb_key] = json[key] }
    json
  end

  # return normalized json into facebook profile format
  #
  # @param [Hash] json
  # @return [Hash] json
  def profile_json(json)
    case @platform
    when Bot::LINE
      json = replaced_json(json, {"displayName" => "first_name", "pictureUrl" => "profile_pic"})
    else

    end

    json
  end

  # incoming json into facebook json
  #
  # @param [Integer] bot_id Bot#id
  # @param [Hash] json incoming json
  # @return [Hash] incoming facebook json
  def incoming_json(bot_id, json)
    facebook_json = { 'entry' => [ { 'messaging' => [ {} ] } ] }

    begin
      case @platform
      when Bot::LINE
        # join
        if json['events'][0]['type'] == 'follow'
          facebook_json['entry'][0]['messaging'][0]['sender'] = { 'id' => json['events'][0]['source']['userId']}
          get_started = GetStarted.find_by_bot_id(bot_id)
          facebook_json['entry'][0]['messaging'][0]['postback'] = { 'payload' =>  get_started.payload } if get_started
          return facebook_json
        end
        # message
        return facebook_json unless json['events'][0]['source']['type'] == 'user'
        facebook_json['entry'][0]['messaging'][0]['sender'] = { 'id' => json['events'][0]['source']['userId']}
        facebook_json['entry'][0]['messaging'][0]['timestamp'] = json['events'][0]['timestamp']
        type = json['events'][0]['message']['type'] if json['events'][0]['message']
        type = json['events'][0]['type'] unless type
        case type
        when 'text'
          facebook_json['entry'][0]['messaging'][0]['message'] = { 'text' => json['events'][0]['message']['text'] }
        when 'image'
          line_client = LineClient.new(json['events'][0]['source']['userId'])
          response = line_client.get_message_content(json['events'][0]['message']['id'])
          base64_image = Base64.encode64(response.body)
          facebook_json['entry'][0]['messaging'][0]['message'] = { 'attachments' => [ { 'type' => 'image', 'line_image' => base64_image } ] }
        when 'postback'
          facebook_json['entry'][0]['messaging'][0]['postback'] = { 'payload' => json['events'][0]['postback']['data'] }
        else
          facebook_json = json
        end
      else
        facebook_json = json
      end
    rescue => e
      return facebook_json
    end

    facebook_json
  end

end
