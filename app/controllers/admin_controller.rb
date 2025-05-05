# frozen_string_literal: true
require 'zip'

class AdminController < ApplicationController
  include Blacklight::Catalog
  before_action :authenticate_user!
  before_action :store_location_for_user

  configure_blacklight do |config|
    config.full_width_layout = true
    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')
  end

  def index
  end

  def importer_running
    running = Delayed::Job.where("handler LIKE ?", "%ImportFullRecordsJob%")
                           .where("progress_current < progress_max")
                           .exists?
    render json: { running: running }
  end

  def latest_full_import_progress
    latest_job = Delayed::Job.where("handler LIKE ?", "%ImportFullRecordsJob%")
                             .order(created_at: :desc)
                             .first

    unless latest_job
      return render json: { progress: 0, stage: 'No recent job found' }
    end

    render json: { job_id: latest_job.id }
  end

  def full_import_progress
    job_id = params[:job_id] || Delayed::Job.where("handler LIKE ?", "%ImportFullRecordsJob%")
                                            .order(created_at: :desc)
                                            .pluck(:id)
                                            .first

    job = Delayed::Job.find_by(id: job_id)

    if job
      if job.progress_max.to_i > 0
        progress = (job.progress_current.to_f / job.progress_max.to_f * 100).round
        stage = if job.progress_stage.present?
                  job.progress_stage
                elsif job.progress_max == 100
                  "Initializing import..."
                else
                  "Starting import"
                end

        render json: {
          job_id: job.id,
          progress: progress,
          stage: stage
        }
      else
        render json: {
          job_id: job.id,
          progress: 0,
          stage: job.progress_stage.presence || 'Waiting for record count'
        }
      end
    else
      render json: { progress: 0, stage: 'Pending' }
    end
  end


  def single_import_progress
    # Optional: check if job still exists
    percent = Delayed::Job.exists?(["handler LIKE ?", "%#{params[:id]}%"]) ? 50 : 100
    stage = (percent < 100) ? "Running..." : "Complete"
    render json: { progress: percent, stage: stage }
  end

  def run_full_import
    job_instance = ImportFullRecordsJob.new(delete: false, override: true)
    job = Delayed::Job.enqueue(job_instance)

    if job
      job_instance.args[:job_id] = job.id

      # Re-serialize handler BEFORE updating progress fields
      job.handler = job_instance.to_yaml

      # NOW update progress info (AFTER handler overwrite)
      job.update!(
        progress_stage: "Connecting to OAI",
        progress_current: 0,
        progress_max: 100
      )

      OralHistoryItem.index_logger.info("🟢 Enqueued full import job ID: #{job.id}")
      render json: { job_id: job.id }, status: :ok
    else
      render json: { error: "Failed to enqueue job" }, status: :internal_server_error
    end
  rescue => e
    OralHistoryItem.index_logger.error("🛑 Failed to enqueue full import: #{e.class} - #{e.message}")
    render json: { error: "Failed to start full import: #{e.message}" }, status: :internal_server_error
  end


  def run_single_import
    job_instance = ImportSingleRecordJob.new(params[:id])

    job = Delayed::Job.enqueue(job_instance)

    render json: { status: 'started', job_id: params[:id] }
  rescue => e
    OralHistoryItem.index_logger.error("🛑 Job enqueue failed: #{e.message}")
    render json: { status: 'error', message: e.message }, status: 500
  end

  def destroy_all_delayed_jobs
    Delayed::Job.destroy_all
    redirect_to admin_path, alert: 'All Delayed::Jobs have been deleted.'
  end

  def importer_log
    send_log_file('importer.log')
  end

  def worker_log
    send_log_file('worker.log')
  end

  def development_log
    if Rails.env.development?
      send_log_file('development.log')
    else
      head :forbidden
    end
  end

  def download_all_logs
    temp_file = Tempfile.new('logs.zip')

    begin
      Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
        add_log_to_zip(zipfile, 'importer_log.txt', 'log/importer.log')
        add_log_to_zip(zipfile, 'worker_log.txt', 'log/worker.log')
        add_log_to_zip(zipfile, 'development_log.txt', 'log/development.log') if Rails.env.development?
      end

      send_data File.read(temp_file.path), type: 'application/zip', filename: 'all_logs.zip'
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def clear_all_logs
    log_files = ['importer.log', 'worker.log']
    log_files << 'development.log' if Rails.env.development?

    log_files.each do |log_file|
      log_path = Rails.root.join('log', log_file)
      File.truncate(log_path, 0) if File.exist?(log_path)
    end

    redirect_to admin_path, notice: 'All logs have been cleared.'
  end

  private

  def store_location_for_user
    store_location_for(:user, request.fullpath)
  end

  def send_log_file(filename)
    send_file Rails.root.join('log', filename), type: 'text/plain', disposition: 'inline'
  end

  def add_log_to_zip(zipfile, zip_name, path)
    filepath = Rails.root.join(path)
    zipfile.add(zip_name, filepath) if File.exist?(filepath)
  end
end
