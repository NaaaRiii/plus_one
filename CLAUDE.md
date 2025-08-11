# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

**PlusONE**は、目標達成をゲーム化した日本語のタスク管理アプリケーションです。EXP（経験値）とランキングシステムを通じて、ユーザーがGoal（目標）を設定し、それをSmall GoalとTaskに分割して、完了時にEXPを獲得します。高ランクで解放されるごほうびルーレットシステムも含まれています。

## アーキテクチャ

**Rails API + Next.jsフロントエンド**のAWSデプロイ構成：

- **バックエンド**: Ruby 3.2.8 + Rails 7.0.7.2 API専用アプリケーション
- **フロントエンド**: Next.js（AWS Amplifyに別途デプロイ）
- **データベース**: MySQL 8.0.42
- **インフラ**: AWS ECS Fargate + Terraform IaC

RailsバックエンドはAPIエンドポイントのみ提供（ビュー/HTMLなし）し、フロントエンドは別のNext.jsアプリケーションとしてRails APIを消費します。

## 主要コマンド

### 開発
```bash
# Railsサーバー起動
bundle exec rails server

# Railsコンソール起動
bundle exec rails console

# データベース操作
bundle exec rake db:migrate
bundle exec rake db:seed

# ER図生成
bundle exec rake erd
```

### テスト
```bash
# 全RSpecテスト実行
bundle exec rspec

# 特定テストファイル実行
bundle exec rspec spec/models/user_spec.rb

# 特定コントローラーテスト実行
bundle exec rspec spec/controllers/api/
```

### コード品質
```bash
# RuboCopリンティング実行
bundle exec rubocop

# RuboCop自動修正
bundle exec rubocop -a
```

### Docker
```bash
# サービスビルド・起動
docker-compose up --build

# バックグラウンド実行
docker-compose up -d
```

## コアデータモデル

### 階層構造
```
User（ユーザー）
├── Goal（メイン目標・期限あり）
│   └── SmallGoal（ゴールに属するサブ目標）
│       └── Task（個別の実行可能項目）
├── Activity（EXP追跡記録）
└── RouletteText（カスタマイズ可能なごほうびメッセージ）
```

### 主要リレーション
- User has_many :goals, :activities, :roulette_texts
- Goal belongs_to :user, has_many :small_goals
- SmallGoal belongs_to :goal, has_many :tasks
- Task belongs_to :small_goal

### EXP・ランキングシステム
- ユーザーはSmallGoalとTask完了でEXPを獲得
- EXPはUserモデルの`calculate_rank`メソッドでランクを決定
- 10ランクごとにごほうびルーレット用チケットを獲得
- 難易度倍率がEXP獲得に影響（`DifficultyMultiplier` concernで処理）

## API構造

### 認証
- カスタムJWTベース認証（Deviseは未使用）
- `UserAuthenticatable` concernで認証ロジックを処理
- AWS Cognitoとの連携でユーザー管理

### 主要APIエンドポイント
```
GET  /api/current_user              # 現在のユーザー情報
POST /api/guest_login               # ゲストログイン
GET  /api/weekly_exp                # チャート用EXPデータ
GET  /api/daily_exp                 # カレンダー用日次EXPデータ

POST /api/goals                     # ゴール作成
POST /api/goals/:id/complete        # ゴール完了
POST /api/small_goals/:id/complete  # スモールゴール完了
POST /api/tasks/:id/complete        # タスク完了

GET  /api/roulette_texts/tickets    # ユーザーチケット取得
PATCH /api/roulette_texts/spin      # ルーレット回転
```

## テスト

- **RSpec** + **FactoryBot**でテストデータ作成
- Controller specsでAPIエンドポイントテスト
- Model specsでビジネスロジックテスト
- Request specsでAPI統合テスト
- Rails固有テストは`rails_helper.rb`を使用

## 重要な実装詳細

### EXP・チケット管理
- EXP計算はUserモデルのメソッドで処理: `add_exp`, `calculate_rank`, `update_tickets`
- スレッドセーフなチケット操作でデータベースロッキング使用（`with_lock`）
- 新規ユーザーにはデフォルトルーレットテキストを自動作成

### データバリデーション
- 全体的に日本語テキストサポート（UTF-8）
- ゴールタイトル最大50文字、内容最大200文字
- SmallGoalの難易度がEXP倍率に影響
- チケットは非負整数である必要

### データベースマイグレーション
- シンプルなタスクアプリからゲーム化システムへの進化を示す豊富なマイグレーション履歴
- 注目すべきマイグレーション: EXPシステム追加、ルーレット機能、AWS Cognito統合

## 開発ノート

- バックエンドは**API専用** - Railsビューやフロントエンドアセットなし
- フロントエンドはAWS Amplifyに別途デプロイ（このリポジトリには含まれない）
- フロントエンドからのクロスオリジンリクエスト用にCORS設定済み
- 本番環境ではMySQL、開発環境ではSQLiteを使用
- コンテナ化デプロイ用のDockerfile
- コードスタイル用の充実したRuboCop設定