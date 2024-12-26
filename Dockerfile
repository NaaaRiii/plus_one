# 1. Rubyイメージをベースにする
FROM ruby:3.2.2

# 2. パッケージのインストール
#    - nodejs / yarn はアセットコンパイルやWebpackerを使うなら必要
#    - mysql-client は DB マイグレーションで使う
RUN apt-get update -qq && \
		apt-get install -y nodejs yarn default-mysql-client

# 3. 作業ディレクトリ
WORKDIR /app

# 4. Gemfile / Gemfile.lock のコピーと bundle install
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
