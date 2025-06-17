require 'rails_helper'
require 'rspec-parameterized'

RSpec.describe User, type: :model do
  let(:base_attrs) do
    {
      name: 'TestUser',
      email: 'testuser@example.com',
      password: 'password',
      tickets: 0
    }
  end

  let(:user) { User.create!(base_attrs.merge(total_exp: 0)) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(build(:user)).to be_valid
    end

    it 'is invalid without a name' do
      user = build(:user, name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it 'is invalid with a name that is too long' do
      user = build(:user, name: 'a' * 51)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include('is too long (maximum is 50 characters)')
    end

    it 'is invalid without an email' do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'is invalid with an email that is too long' do
      user = build(:user, email: 'a' * 256 + '@example.com')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is too long (maximum is 255 characters)')
    end

    it 'is invalid with an invalid email format' do
      user = build(:user, email: 'invalid_email')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end

    it 'is invalid with a duplicate email' do
      create(:user, email: 'test@example.com')
      user = build(:user, email: 'test@example.com')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('has already been taken')
    end

    it 'is invalid with a password that is too short' do
      user = build(:user, password: 'a' * 5)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
    end

    it 'is valid when updating without changing password' do
      user = create(:user)
      user.name = "New Name"
      expect(user).to be_valid
    end

    it 'is invalid with negative tickets' do
      user = build(:user, tickets: -1)
      expect(user).not_to be_valid
      expect(user.errors[:tickets]).to include('must be greater than or equal to 0')
    end
  end

  describe 'callbacks' do
    it 'downcases email before saving' do
      user = create(:user, email: 'TEST@EXAMPLE.COM')
      expect(user.email).to eq('test@example.com')
    end

    it 'creates activation digest before creating' do
      user = build(:user)
      expect(user.activation_digest).to be_nil
      user.save
      expect(user.activation_digest).not_to be_nil
    end

    it 'creates default roulette texts after creating' do
      user = create(:user)
      expect(user.roulette_texts.count).to eq(12)
      expect(user.roulette_texts.first.text).to eq('5分お散歩をする')
    end
  end

  describe 'authentication methods' do
    describe '#authenticated?' do
      it 'returns false for nil digest' do
        user = create(:user)
        expect(user.authenticated?(:remember, '')).to be false
      end

      it 'returns true for valid token' do
        user = create(:user)
        user.remember
        expect(user.authenticated?(:remember, user.remember_token)).to be true
      end
    end

    describe '#remember' do
      it 'sets remember token and digest' do
        user = create(:user)
        user.remember
        expect(user.remember_token).not_to be_nil
        expect(user.remember_digest).not_to be_nil
      end
    end

    describe '#forget' do
      it 'clears remember digest' do
        user = create(:user)
        user.remember
        expect(user.remember_digest).not_to be_nil
        user.forget
        expect(user.remember_digest).to be_nil
      end
    end

    describe '#session_token' do
      it 'returns remember digest if exists' do
        user = create(:user)
        user.remember
        expect(user.session_token).to eq(user.remember_digest)
      end

      it 'creates new remember digest if not exists' do
        user = create(:user)
        expect(user.session_token).not_to be_nil
      end
    end

    describe '#activate' do
      it 'activates user and sets activated_at' do
        user = create(:user, activated: false)
        user.activate
        expect(user.activated).to be true
        expect(user.activated_at).not_to be_nil
      end
    end

    describe '#send_activation_email' do
      it 'sends activation email' do
        user = create(:user)
        expect do
          user.send_activation_email
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end

  describe '#generate_auth_token' do
    it 'generates a valid JWT token' do
      user = create(:user)
      token = user.generate_auth_token
      decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base, true, algorithm: 'HS256')[0]
      expect(decoded_token['user_id']).to eq(user.id)
    end
  end

  describe '#update_tickets' do
    context '9 → 10 を跨いだ場合' do
      let!(:user) { User.create!(base_attrs.merge(last_roulette_rank: 9)) }

      before do
        allow(user).to receive(:calculate_rank).and_return(10)
      end

      it 'tickets を +1 する' do
        expect do
          user.update_tickets
        end.to change { user.reload.tickets }.by(1)
      end
    end

    context '9 → 21 を跨いだ場合（二段階跨ぎ）' do
      let!(:user) { User.create!(base_attrs.merge(last_roulette_rank: 9)) }

      before do
        allow(user).to receive(:calculate_rank).and_return(21)
      end

      it '十の位の差分である 2 枚分 tickets を +2 する' do
        expect do
          user.update_tickets
        end.to change { user.reload.tickets }.by(2)
      end

      it 'last_roulette_rank が 9 → 21 に更新される' do
        expect do
          user.update_tickets
        end.to change { user.reload.last_roulette_rank }.from(9).to(21)
      end
    end

    context '10 未満 → 10 未満 では tickets は増えない' do
      let!(:user) { User.create!(base_attrs.merge(last_roulette_rank: 0)) }

      before do
        allow(user).to receive(:calculate_rank).and_return(9)
      end

      it 'tickets が増えない' do
        expect do
          user.update_tickets
        end.not_to(change { user.reload.tickets })
      end
    end

    context '同じ十の位内(11 → 19)では tickets は増えない' do
      let!(:user) { User.create!(base_attrs.merge(last_roulette_rank: 10)) }

      before do
        allow(user).to receive(:calculate_rank).and_return(19)
      end

      it 'tickets が増えない' do
        expect do
          user.update_tickets
        end.not_to(change { user.reload.tickets })
      end
    end
  end

  describe '#update_rank' do
    context '9 → 10 を跨いだ場合' do
      let!(:user) { User.create!(base_attrs.merge(last_roulette_rank: 9)) }

      before do
        allow(user).to receive(:calculate_rank).and_return(10)
      end

      it 'last_roulette_rank を 9 → 10 に更新する' do
        expect do
          user.update_rank
        end.to change { user.reload.last_roulette_rank }.from(9).to(10)
      end
    end

    context '9 → 21 を跨いだ場合（二段階跨ぎ）' do
      let!(:user) { User.create!(base_attrs.merge(last_roulette_rank: 9)) }

      before do
        allow(user).to receive(:calculate_rank).and_return(21)
      end

      it 'last_roulette_rank を 9 → 21 に更新する' do
        expect do
          user.update_rank
        end.to change { user.reload.last_roulette_rank }.from(9).to(21)
      end
    end

    context '同じ十の位(11 → 19)では last_roulette_rank は更新されない' do
      let!(:user) { User.create!(base_attrs.merge(last_roulette_rank: 10)) }

      before do
        allow(user).to receive(:calculate_rank).and_return(19)
      end

      it 'last_roulette_rank が変わらない' do
        expect do
          user.update_rank
        end.not_to(change { user.reload.last_roulette_rank })
      end
    end
  end

  describe '#update_tickets / #update_rank の冪等性' do
    context '同ランクで 2 回呼んでも 2 回目以降 tickets は増えない' do
      let!(:user) { User.create!(base_attrs.merge(last_roulette_rank: 9)) }

      before do
        allow(user).to receive(:calculate_rank).and_return(10)
      end

      it '1 回目は +1, 2 回目は変化なし' do
        expect do
          user.update_tickets
        end.to change { user.reload.tickets }.by(1)

        # 2 回目の呼び出しでは tickets は増えない
        expect do
          user.update_tickets
        end.not_to(change { user.reload.tickets })
      end

      it 'update_rank も同じく 2 回目は last_roulette_rank を更新しない' do
        expect do
          user.update_rank
        end.to change { user.reload.last_roulette_rank }.from(9).to(10)

        # 2 回目の呼び出しでは変化なし
        expect do
          user.update_rank
        end.not_to(change { user.reload.last_roulette_rank })
      end
    end
  end

  describe '#update_tickets の同時実行' do
    it '2 スレッド同時でも tickets は +1 で止まる' do
      user = User.create!(base_attrs.merge(last_roulette_rank: 9))

      # ★ どのインスタンスでも rank=10 を返すようにスタブ
      allow_any_instance_of(User).to receive(:calculate_rank).and_return(10)

      threads = 2.times.map do
        Thread.new { User.find(user.id).update_tickets }
      end
      threads.each(&:join)

      user.reload
      expect(user.tickets).to eq 1               # 1 枚だけ付与
      expect(user.last_roulette_rank).to eq 10   # rank は更新
    end
  end

  describe '#use_ticket の負数防止' do
    it 'tickets が 0 のとき use_ticket は false を返し tickets はそのまま' do
      user = User.create!(base_attrs.merge(tickets: 0))
      expect(user.use_ticket).to be_falsey
      expect(user.reload.tickets).to eq(0)
    end

    it 'tickets が正の場合 use_ticket は true を返し tickets を -1' do
      user = User.create!(base_attrs.merge(tickets: 2))
      expect(user.use_ticket).to be_truthy
      expect(user.reload.tickets).to eq(1)
    end
  end

  describe '#update_rank は tickets を増やさない' do
    it 'update_rank は tickets を一切変更しない' do
      user = User.create!(base_attrs.merge(tickets: 5, last_roulette_rank: 9))
      allow(user).to receive(:calculate_rank).and_return(10)

      expect do
        user.update_rank
      end.not_to(change { user.reload.tickets })
      expect(user.last_roulette_rank).to eq 10   # rank は更新
    end
  end

  describe '#calculate_rank の境界値' do
    let(:user) { User.create!(base_attrs.merge(total_exp: exp)) }

    context 'total_exp = 4 (<5)' do
      let(:exp) { 4 }
      it 'rank は 1' do
        expect(user.calculate_rank).to eq(1)
      end
    end

    context 'total_exp = 5 (ちょうど 5 の閾値)' do
      let(:exp) { 5 }
      it 'rank は 2' do
        expect(user.calculate_rank).to eq(2)
      end
    end

    context 'total_exp = 14 (5 ≤ 14 < 15)' do
      let(:exp) { 14 }
      it 'rank は 2' do
        expect(user.calculate_rank).to eq(2)
      end
    end

    context 'total_exp = 15 (ちょうど 15 の閾値)' do
      let(:exp) { 15 }
      it 'rank は 3' do
        expect(user.calculate_rank).to eq(3)
      end
    end
  end

  # ─────────── add_exp ───────────
  describe '#add_exp' do
    it '指定量だけ total_exp を加算し DB に保存する' do
      expect do
        user.add_exp(42)
      end.to change { user.reload.total_exp }.by(42)
    end
  end

  # ─────────── calculate_rank_up_experience ───────────
  describe '#calculate_rank_up_experience' do    
    subject(:table) { user.calculate_rank_up_experience(25) }
    # （max_rank=25 程度まで作っておけば、21→22 までチェックできます）

    it '先頭 2 要素は [0, 5] になる' do
      expect(table[0..1]).to eq [0, 5]
    end

    it 'rank2→3 の閾値差は +10 になる' do
      # table[1] == 5, table[2] == 15
      expect(table[2] - table[1]).to eq 10
    end

    it 'rank1→2 の閾値差は +5 になる' do
      expect(table[1] - table[0]).to eq 5
    end

    it 'rank6→7 の閾値差は +15 になる' do
      # table[5] は rank6 の閾値 (45), table[6] は rank7 の閾値 (60)
      expect(table[6] - table[5]).to eq 15
    end

    it 'rank11→12 の閾値差は +20 になる' do
      # table[11] は rank11 の閾値 (120), table[12] は rank12 の閾値 (140)
      expect(table[12] - table[11]).to eq 20
    end

    it 'rank16→17 の閾値差は +25 になる' do
      # table[16] == 220, table[17] == 245
      expect(table[17] - table[16]).to eq 25
    end

    it 'rank21→22 の閾値差は +30 になる' do
      # table[21] == 345, table[22] == 375
      expect(table[22] - table[21]).to eq 30
    end
  end

  # ─────────── calculate_rank (境界値 & 加算後挙動) ───────────
  describe '#calculate_rank' do
    context '境界値チェック' do
      where(:exp, :expected_rank) do
        [
          [0, 1],      # < 5
          [4.9, 1],
          [5, 2],      # ちょうど 5
          [14.9, 2],
          [15, 3],     # ちょうど 15
          [24.9, 3],
          [25, 4],
          [34.9, 4],
          [35, 5],
          [44.9, 5],
          [45, 6],
          [59.9, 6],
          [60, 7],
          [74.9, 7],
          [75, 8],
          [89.9, 8],
          [90, 9],
          [104.9, 9],
          [105, 10]
        ]
      end

      with_them do
        it { expect(User.new(total_exp: exp).calculate_rank).to eq expected_rank }
      end
    end

    context 'EXP を加算したあと rank が上がること' do
      it 'add_exp でランク 1 → 2 になる' do
        expect(user.calculate_rank).to eq 1   # 初期値 0 EXP

        user.add_exp(5)                       # +5 EXP
        expect(user.calculate_rank).to eq 2   # ランクアップ
      end
    end
  end
end
