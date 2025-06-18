require 'rails_helper'

RSpec.describe Api::TasksController, type: :controller do
  describe 'before_action :set_task' do
    it 'update_completed アクションで set_task が呼ばれること' do
      task = create(:task)

      expect(controller).to receive(:set_task).and_call_original

      post :update_completed, params: { id: task.id, completed: true }

      # 確認: レスポンス成功
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'update_completed アクション' do
    let!(:task) { create(:task, completed: false) }

    it 'completed=true を渡すと Task が完了状態になり 200 とメッセージ JSON が返る' do
      patch :update_completed, params: { id: task.id, completed: true }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to eq('message' => 'Task updated successfully')

      expect(task.reload.completed).to be true
    end

    it 'completed=false を渡すと Task が未完了状態になり 200 とメッセージ JSON が返る' do
      # 先に true にしておく
      task.update(completed: true)

      patch :update_completed, params: { id: task.id, completed: false }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to eq('message' => 'Task updated successfully')

      expect(task.reload.completed).to be false
    end

    it 'completed 以外の属性は変更されないこと' do
      original_content    = task.content
      original_created_at = task.created_at

      patch :update_completed, params: { id: task.id, completed: true }

      task.reload
      expect(task.completed).to be true
      expect(task.content).to eq original_content
      expect(task.created_at.to_i).to eq original_created_at.to_i
    end

    it "'true' 文字列を渡しても completed が true になること" do
      patch :update_completed, params: { id: task.id, completed: 'true' }

      task.reload
      expect(task.completed).to be true
    end

    it "'false' 文字列を渡しても completed が false になること" do
      task.update(completed: true)
      patch :update_completed, params: { id: task.id, completed: 'false' }

      task.reload
      expect(task.completed).to be false
    end

    it '許可されていないキーは無視される (hacker キー)' do
      patch :update_completed, params: { id: task.id, completed: true, hacker: 1 }

      expect(response).to have_http_status(:ok)
      task.reload
      expect(task.completed).to be true
      expect(task.attributes).not_to have_key('hacker')
    end

    context 'update 失敗の場合' do
      let!(:task) { create(:task) }

      before do
        allow_any_instance_of(Task).to receive(:update).and_return(false)
      end

      it '422 とエラーメッセージ JSON が返る' do
        patch :update_completed, params: { id: task.id, completed: true }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json).to eq('error' => 'Failed to update task')
      end
    end
  end

  describe '存在しない ID を指定した場合' do
    it 'ActiveRecord::RecordNotFound を発生させる' do
      expect do
        patch :update_completed, params: { id: 999_999, completed: true }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end 