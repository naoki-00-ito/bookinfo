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

# 一覧表示からの処理
# "http://localhost:8099/list" で呼び出される
server.mount_proc("/list") { |req, res|
  p req.query
  # 'operation'の値の後の(.delete, .edit)で処理を分岐する
  if /(.*)\.(delete|edit)$/ =~ req.query['operation']
    target_id = $1
    operation = $2
    # 選択された処理を実行する画面に移行する
    # ERBを、ERBHandlerを経由せずに直接呼び出して利用している
    if operation == "delete"
      template = ERB.new(File.read('delete.erb'))
    elsif operation == "edit"
      template = ERB.new(File.read('edit.erb'))
    end
    res.body << template.result(binding)
  else # データが選択されていないなど
    template = ERB.new(File.read('noselected.erb'))
    res.body << template.result(binding)
  end
}

# 登録の処理
# "http://localhost:8099/entry" で呼び出される
server.mount_proc("/entry") { |req, res| 
  p req.query
  # dbhを作成し、データベース'bookinfo_sqlite.db'に接続する
  dbh = DBI.connect('DBI:SQLite3:../db/bookinfo_sqlite.db')

  # idが使われていたら登録できない
  rows = dbh.select_one("select * from bookinfos where id='#{req.query['id']}';")
  if rows then
    # データベースとの接続を終了する
    dbh.disconnect

    # 処理の結果を表示する
    # ERBを、ERBHandlerを経由せずに直接呼び出して利用している
    template = ERB.new(File.read('noentried.erb'))
    res.body << template.result(binding)
  else
    # テーブルにデータを追加する
    dbh.do("insert into bookinfos values('#{req.query['id']}','#{req.query['title']}','#{req.query['author']}','#{req.query['page']}','#{req.query['publish_date']}');")
    # データベースとの接続を終了する
    dbh.disconnect

    # 処理の結果を表示する
    # ERBを、ERBHandlerを経由せずに直接呼び出して利用している
    template = ERB.new(File.read('entried.erb'))
    res.body << template.result(binding)
  end
}

# 検索の処理
# "http://localhost:8099/retrieve" で呼び出される
server.mount_proc("/retrieve") { |req, res| 
  p req.query

  # 検索条件の整理
  a = ['id', 'title', 'author', 'page', 'publish_date']
  # 問合せ条件のある要素以外を削除
  a.delete_if{ |name|
    req.query[name] == ""
  }

  if a.empty?
    where_data = ""
  else
    # 残った要素を検索条件文字列に変換
    a.map! { |name|
      "#{name}='#{req.query[name]}'"
    }
    # 要素があるときは、where句に直す
    # (現状、項目ごとの完全一致のorだけ)
    where_data = "where " + a.join(' or ')
  end

  # 処理の結果を表示する
  # ERBを、ERBHandlerを経由せずに直接呼び出して利用している
  template = ERB.new(File.read('retrieved.erb'))
  res.body << template.result(binding)
}

# 修正の処理
# "http://localhost:8099/edit" で呼び出される
server.mount_proc("/edit") { |req, res| 
  p req.query
  # dbhを作成し、データベース'bookinfo_sqlite.db'に接続する
  dbh = DBI.connect('DBI:SQLite3:../db/bookinfo_sqlite.db')
  # テーブルのデータを更新する
  dbh.do("update bookinfos set id='#{req.query['id']}',title='#{req.query['title']}',author='#{req.query['author']}',page='#{req.query['page']}',publish_date='#{req.query['publish_date']}' where id='#{req.query['id']}';")
  # データベースとの接続を終了する
  dbh.disconnect
  # 処理の結果を表示する
  # ERBを、ERBHandlerを経由せずに直接呼び出して利用している
  template = ERB.new(File.read('edited.erb'))
  res.body << template.result(binding)
}

# 削除の処理
# "http://localhost:8099/delete" で呼び出される
server.mount_proc("/delete") { |req, res| 
  p req.query
  # dbhを作成し、データベース'bookinfo_sqlite.db'に接続する
  dbh = DBI.connect('DBI:SQLite3:../db/bookinfo_sqlite.db')

  # テーブルのデータを削除する
  dbh.do("delete from bookinfos where id='#{req.query['id']}';")

  # データベースとの接続を終了する
  dbh.disconnect

  # 処理の結果を表示する
  # ERBを、ERBHandlerを経由せずに直接呼び出して利用している
  template = ERB.new(File.read('deleted.erb'))
  res.body << template.result(binding)
}

# Ctrl-C割り込みがあった場合にサーバーを停止する処理を登録しておく
trap(:INT) do
  server.shutdown
end

# 上記記述の処理をこなすサーバーを開始する
server.start

