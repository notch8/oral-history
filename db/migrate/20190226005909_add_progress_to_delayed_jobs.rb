class AddProgressToDelayedJobs < ActiveRecord::Migration[5.1]
  def change
    create_table :delayed_jobs, force: true do |t|
      t.integer  :priority, default: 0
      t.integer  :attempts, default: 0
      t.text     :handler
      t.text     :last_error
      t.datetime :run_at
      t.datetime :locked_at
      t.datetime :failed_at
      t.string   :locked_by
      t.string   :queue
      t.timestamps

      t.integer :progress_max, null: false, default: 0
      t.integer :progress_current, null: false, default: 0
      t.string  :progress_stage, null: false, default: 'Queued'
    end
  end
end
