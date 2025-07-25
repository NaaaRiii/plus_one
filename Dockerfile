# 1. Rubyイメージをベースにする
FROM ruby:3.2.8

# 2. パッケージのインストール
#    - nodejs / yarn はアセットコンパイルやWebpackerを使うなら必要
#    - mysql-client は DB マイグレーションで使う
RUN apt-get update -y && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. 作業ディレクトリ
WORKDIR /app

# 4. Gemfile / Gemfile.lock のコピーと bundle install
ARG BUNDLER_VERSION=2.6.9
RUN gem install bundler -v ${BUNDLER_VERSION}
COPY Gemfile Gemfile.lock ./
RUN bundle install

# 5. アプリケーション全体をコピー
COPY . .

# 6. (フロントエンドのアセットがある場合はプリコンパイル)
#    API-only の Rails なら不要
# RUN bundle exec rake assets:precompile

# 7. ポートを公開 (Rails が立ち上がる 3000 番)
EXPOSE 3000

# 8. Rails サーバを起動するコマンド
#    DB マイグレーションなどを起動前に実行したい場合は script にまとめるのもアリ
CMD ["bash", "-c", "bundle exec rails db:migrate && bundle exec rails s -b 0.0.0.0 -p 3000"]
