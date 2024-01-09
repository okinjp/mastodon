# frozen_string_literal: true

class FixIndexForPublicTimelineSpeeds < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  # rubocop:disable Naming/VariableNumber
  def up
    add_index :statuses, [:id], name: :index_statuses_public_20240108, algorithm: :concurrently, order: { id: :desc }, where: 'deleted_at IS NULL AND visibility IN (0, 10, 11) AND reblog_of_id IS NULL AND ((NOT reply) OR (in_reply_to_account_id = account_id))'
    remove_index :statuses, name: :index_statuses_public_20231213
  end

  def down
    add_index :statuses, [:id, :account_id], name: :index_statuses_public_20231213, algorithm: :concurrently, order: { id: :desc }, where: 'deleted_at IS NULL AND visibility IN (0, 10, 11) AND reblog_of_id IS NULL AND ((NOT reply) OR (in_reply_to_account_id = account_id))'
    remove_index :statuses, name: :index_statuses_public_20240108
  end
  # rubocop:enable Naming/VariableNumber
end
