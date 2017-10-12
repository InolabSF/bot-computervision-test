class HomeController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def line_test
    print params


      # messaging = params['events'][0]['type']
      # raise "messaging is needed" unless messaging

      # user_id = params['events'][0]['source']['userId']
      # print user_id

      # raise "line user id is needed" unless user_id

    # rescue => e
    #   json = { :application_code => 400, :message => e.message}
    #   render :json => json, :status => 400
    #   return
    # end
    #
    # apiUrl = "westcentralus.api.cognitive.microsoft.com"
    # uri = "https://" + apiUrl
    #
    # conn = Faraday::Connection.new(:url => uri) do |builder|
    #  ## URLをエンコードする
    #   builder.use Faraday::Request::UrlEncoded
    #  ## ログを標準出力に出したい時(本番はコメントアウトでいいかも)
    #   builder.use Faraday::Response::Logger
    #  ## アダプター選択（選択肢は他にもあり）
    #   builder.use Faraday::Adapter::NetHttp
    #
    #   #microsoft vision apiKey
    #   category = "Categories,Description,Tags,Faces&details=Landmarks"
    #   requrl = "/vision/v1.0/analyze" + "?visualFeatures=" + category
    #
    #   res = conn.post do |req|
    #      req.url requrl
    #      req.headers['Content-Type'] = 'application/json'
    #      req.headers['Ocp-Apim-Subscription-Key'] = '4892073d721d4314844a1e0e618d399e'
    #      req.body = '{"url":"https://blog-001.west.edge.storage-yahoo.jp/res/blog-89-aa/chi316shun/folder/749549/46/20120746/img_0"}'
    #   end
    #
    # end
    # render json: {"user_id": user_id}, status: 200
    render status: 200
  end

  def handle_webhook

    # faradayコネクションの作成

    # ms Vision api url
    apiUrl = "westcentralus.api.cognitive.microsoft.com"
    uri = "https://" + apiUrl

    conn = Faraday::Connection.new(:url => uri) do |builder|
     ## URLをエンコードする
      builder.use Faraday::Request::UrlEncoded
     ## ログを標準出力に出したい時(本番はコメントアウトでいいかも)
      builder.use Faraday::Response::Logger
     ## アダプター選択（選択肢は他にもあり）
      builder.use Faraday::Adapter::NetHttp

    end

    # faradayからpostリクエスト

    #microsoft vision apiKey
    category = "Categories,Description,Tags,Faces&details=Landmarks"
    requrl = "/vision/v1.0/analyze" + "?visualFeatures=" + category

    res = conn.post do |req|
       req.url requrl
       req.headers['Content-Type'] = 'application/json'
       req.headers['Ocp-Apim-Subscription-Key'] = '4892073d721d4314844a1e0e618d399e'
       req.body = '{"url":"https://blog-001.west.edge.storage-yahoo.jp/res/blog-89-aa/chi316shun/folder/749549/46/20120746/img_0"}'
    end

    body = JSON.parse(res.body)
    text = body["description"]["captions"][0]["text"]

      render json: { :description => text }, status: 200
  end

end
