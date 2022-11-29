# bookinfo

## 利用書籍
https://www.sbcr.jp/product/4797371277/

## SASSコンパイル

### Sassをインストール

`gem install sass`

### Sass格納ディレクトリに移動
`cd ./app/assets/stylesheets`

### 更新されたら自動でコンパイルするように監視
`sass --watch style.scss:style.css`

## アプリケーションの起動

### appディレクトリに移動
`cd ./app/`

### bookinfo_web.rbを起動する
`ruby bookinfo_web.rb`

### 下記URLで確認できる
http://localhost:8099/index.html
