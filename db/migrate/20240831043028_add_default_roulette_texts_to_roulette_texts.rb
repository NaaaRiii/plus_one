class AddDefaultRouletteTextsToRouletteTexts < ActiveRecord::Migration[7.0]
  def up
    default_texts = {
      1 => "5分お散歩をする",
      2 => "お菓子を1つ食べる",
      3 => "3分間ストレッチをする",
      4 => "ジュースをコップ1杯飲む",
      5 => "好きな動物の写真や動画を5分観る",
      6 => "好きな曲を2曲聴く",
      7 => "好きな本を4ページ読む",
      8 => "5分間お昼寝をする",
      9 => "深いことは考えずに3枚適当に写真を撮る",
      10 => "5分間日記を書く",
      11 => "コーヒーor紅茶or緑茶を飲む",
      12 => "5分間瞑想をする"
    }

    # 各ユーザーに対してデフォルトのルーレットテキストを作成
    User.find_each do |user|
      default_texts.each do |number, text|
        user.roulette_texts.create(number: number, text: text)
      end
    end
  end

  def down
    default_texts = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    RouletteText.where(number: default_texts).delete_all
  end
end
