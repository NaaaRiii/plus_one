require 'rails_helper'

RSpec.describe User, type: :model do
  # 共通で使うユーザーの基本属性
  let(:base_attrs) do
    {
      name: 'TestUser',
      email: 'testuser@example.com',
      password: 'password',
      tickets: 0
    }
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
end
