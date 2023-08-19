# Lokka [<img src="https://secure.travis-ci.org/lokka/lokka.png"/>](http://travis-ci.org/lokka/lokka)

CMS written in Ruby for cloud computing.

## Features

* Performs in the cloud environment such as Google App Engine and Heroku as well as Windows, Mac, and Linux.
* Designed with reference to WordPress for WordPress users to easily understand.
* Easy installation
* Easy to create a theme for designers.
* A clear plug-in API for Rubyists

## Installation

```sh
$ git clone git://github.com/lokka/lokka.git
$ cd lokka
$ bundle install --without=production:test
$ bundle exec rake db:setup
$ bundle exec rackup
```

View at: http://localhost:9292/

## Deploy to Heroku

```sh
$ git clone git://github.com/lokka/lokka.git
$ cd lokka
$ heroku create
$ git push heroku master
$ heroku addons:add heroku-postgresql:hobby-dev
$ heroku rake db:setup
$ heroku open
```

or just copy and paste

```sh
curl -L http://bit.ly/ROX0lk | bash -s
```

to your terminal

## Docker

```sh
$ bin/docker_gemfile
$ docker-compose build
$ docker-compose run --rm app bundle exec rake db:setup
$ docker-compose up
```

open http://localhost:9292 on your browser.

## Test

```sh
rake spec
```

## How to make a theme

Make a directory for theme in public/theme and you need to create entries.erb and entry.erb at least. (erb, haml and slim is available.)

### Index page

public/theme/example/entries.haml:

```haml
!!! XML
!!!
%html
  %head
    %title Example
  %body
    %h1= @site.title
    - @entries.each do |entry|
      %h2= entry.title
      .body= entry.body
```

### Individual page

public/theme/example/entry.haml:

```haml
!!! XML
!!!
%html
  %head
    %title Example
  %body
    %h1= @site.title
    %h2= @entry.title
    .body= @entry.body
```

## How to make a plugin

Lokka Plugin is subset of [Sinatra Extension](http://www.sinatrarb.com/extensions.html). but Lokka had a specific rules of nomenclature.
If you need display "Hello, World" when access to "/hello", Write a following.

public/plugin/lokka-hello/lib/lokka/hello.rb:

```ruby
module Lokka::Hello
  def self.registerd(app)
    app.get '/hello' do
      'hello'
    end
  end
end
```

## Dockerで動作確認
* docker build -t gcr.io/jiikko/blog .
* ローカルのDBを使う
    * `docker run -p 8080:8080 -it --rm gcr.io/jiikko/blog` or
    * `docker compose up`
* CloudSQLに繋ぐ
  * `docker run -it -e RACK_ENV=production -e DATABASE_URL="mysql://koji:${DATABASE_PASSWORD}@${DATABASE_HOST}/lokka_production" -p 8080:8080 --rm gcr.io/jiikko/blog`
  * `docker run -it -e RACK_ENV=production -e DATABASE_URL="mysql://koji:${DATABASE_PASSWORD}@localhost/lokka_production?socket=/cloudsql/jiikko:asia-northeast1:hoby-db" -p 8080:8080 --rm gcr.io/jiikko/blog`

## Deploy to Cloud Run
* pushすれば環境変数を引き継いでCCP側でデプロイをする
* 初回デプロイするときは次のコマンドを実行する

```
docker buildx build --platform linux/amd64 -t gcr.io/jiikko/blog . --push
gcloud run deploy blog --image gcr.io/jiikko/blog \
    --max-instances=1 --region=asia-northeast1 \
    --allow-unauthenticated \
    --set-env-vars RACK_ENV=production \
    --set-env-vars DATABASE_URL="mysql://koji:${DATABASE_PASSWORD}@localhost/lokka_production?socket=/cloudsql/jiikko:asia-northeast1:hoby-db"
```

## TODO
* DATABASE_URLかDATABASE_PASSWORDをシークレットマネージャーで管理する
    * https://cloud.google.com/build/docs/securing-builds/use-secrets?hl=ja

## Copyright

Copyright (c) 2010 Masaki Komagata. See LICENSE for details.
