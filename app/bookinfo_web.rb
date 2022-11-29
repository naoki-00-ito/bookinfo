# -*- coding: utf-8 -*- 
require 'webrick'
require 'erb'
require 'rubygems'
require 'dbi'

# Stringクラスのconcatメソッドを置き換えるバッチ
class String
  alias_method(:orig_concat, :concat)
  def concat(value)
    if RUBY_VERSION > "1.9"
    else
      orig_concat value
    end
  end
end

config = {
  :Port => 8099,
  :DocumentRoot => '.',
}

# 拡張子erbのファイルをERBを、呼び出して処理するERBHandlerと関連付ける
WEBrick::HTTPServlet::FileHandler.add_handler("erb", WEBrick::HTTPServlet::ERBHandler)

# WEBrickのHTTP Serverクラスのサーバーインスタンスを作成する
server = WEBrick::HTTPServer.new(config)

# erbのMINEタイプを設定
server.config[:MimeTypes]["erb"] = "text/html"

# Ctrl-C割り込みがあった場合にサーバーを停止する処理を登録しておく
trap(:INT) do
  server.shutdown
end

# 上記記述の処理をこなすサーバーを開始する
server.start

