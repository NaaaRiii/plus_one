# test/models/roulette_text_test.rb
require "test_helper"

class RouletteTextTest < ActiveSupport::TestCase
  def setup
    # テスト実行前に既存のデータをクリアし、テスト用のユーザーを作成
    RouletteText.delete_all
    User.delete_all

    # テスト用ユーザーの作成
    @user = User.create!(name: "Example User", email: "user@example.com", password: "password")

    # ユーザーにデフォルトの RouletteText を作成
    @user.send(:create_default_roulette_texts)

    # デフォルトの RouletteText を取得（number: 1 をデフォルトとして選択）
    @roulette_text = @user.roulette_texts.find_by(number: 1)
  end

  # ルーレットテキストが有効であることを確認する
  test "should be valid" do
    @roulette_text.text = "Valid text"
    assert @roulette_text.valid?
  end

  # number が存在しないと無効であることを確認
  test "number should be present" do
    @roulette_text.number = nil
    assert_not @roulette_text.valid?
    assert_match(/must be between 1 and 12/, @roulette_text.errors.full_messages.join)
  end

  # number が 1 〜 12 の範囲内であることを確認
  test "number should be between 1 and 12" do
    @roulette_text.number = 1
    assert @roulette_text.valid?, "1 should be valid"

    @roulette_text.number = 0
    assert_not @roulette_text.valid?, "0 should not be valid"

    @roulette_text.number = 13
    assert_not @roulette_text.valid?, "13 should not be valid"
  end

  # number が同じユーザー内で一意であることを確認
  test "number should be unique for the same user" do
    @roulette_text.save
    duplicate_text = @user.roulette_texts.build(number: @roulette_text.number, text: "Duplicate reward text")
    assert_not duplicate_text.valid?
    assert_match(/has already been taken/, duplicate_text.errors.full_messages.join)
  end

  # text が存在しないと無効であることを確認
  test "text should be present" do
    @roulette_text.text = " "  # 空白のみの text を設定
    assert_not @roulette_text.valid?
    assert_match(/Please set the content/, @roulette_text.errors[:text].join)  # text に対するエラーメッセージを確認
  end

  # テキストをブランクで保存できないことを確認
  test "should not save roulette text with blank content" do
    @roulette_text.text = " "  # 空白のみに設定
    assert_not @roulette_text.valid?, "RouletteText should not be valid with blank content"
    assert_match(/Please set the content/, @roulette_text.errors[:text].join)
  end

  # テキストを修正・保存し、再度修正・保存できることを確認
  test "should be able to save modified roulette text and modify it again" do
    # テキストを修正して保存
    @roulette_text.text = "Modified reward text"
    assert @roulette_text.save, "First modification and save should be successful"

    # 再度別のテキストに修正して保存
    @roulette_text.text = "Second modification"
    assert @roulette_text.save, "Second modification and save should be successful"
    
    # 修正したテキストが正しく保存されているかを確認
    assert_equal "Second modification", @roulette_text.reload.text
  end

  # テキストがブランクのまま再度保存できないことを確認
  test "should not allow saving modified roulette text with blank content again" do
    # 一度テキストを修正して保存
    @roulette_text.text = "Valid modification"
    @roulette_text.save!

    # 再度テキストを空白にして保存しようとする
    @roulette_text.text = " "
    assert_not @roulette_text.save, "Should not be able to save modified roulette text with blank content"
    assert_match(/Please set the content/, @roulette_text.errors[:text].join)
  end

  # text の長さが 50 文字以内であることを確認
  test "text should not be too long" do
    @roulette_text.text = "a" * 51
    assert_not @roulette_text.valid?
    assert_match(/is too long/, @roulette_text.errors.full_messages.join)
  end

  # user が削除されたときに RouletteText も削除されることを確認
  test "should be destroyed when user is destroyed" do
    @roulette_text.save
    assert_difference 'RouletteText.count', -@user.roulette_texts.count do
      @user.destroy
    end
  end

  # テキストが保存される前に正規化されることを確認
  test "text should be stripped and squeezed before save" do
    @roulette_text.text = "   Some     text   with    spaces  "
    @roulette_text.save
    assert_equal "Some text with spaces", @roulette_text.reload.text
  end

  # テキストに不正な空白文字が含まれていても、正規化されて保存されることを確認
  test "text should save with normalized format" do
    @roulette_text.text = "   Text with     irregular spacing    "
    @roulette_text.save
    assert_equal "Text with irregular spacing", @roulette_text.reload.text
  end

  # 不正な number を保存しようとしたときにエラーが発生することを確認
  test "invalid number should trigger validation error" do
    @roulette_text.number = 15
    assert_not @roulette_text.save
    assert_match(/must be between 1 and 12/, @roulette_text.errors.full_messages.join)
  end
end
