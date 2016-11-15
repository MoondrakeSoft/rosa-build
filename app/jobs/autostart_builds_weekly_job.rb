class AutostartBuildsWeeklyJob < BaseActiveRecordJob
  include Sidekiq::Worker

  def perform_with_ar_connection
    Product.autostart_iso_builds_once_a_week
    Project.autostart_build_lists_once_a_week
  end
end