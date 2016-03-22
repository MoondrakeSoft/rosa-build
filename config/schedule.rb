#every 1.day, at: '0:05 am' do
#  runner 'Download.rotate_nginx_log'
#end
#
#every 1.day, at: '0:10 am' do
#  runner 'Download.parse_and_remove_nginx_log'
#end

every :day, at: '3:00 am' do
  rake 'activity_feeds:clear', output: 'log/activity_feeds.log'
end

every :day, at: '2:30 am' do
  rake 'sitemap:refresh', output: 'log/sitemap.log'
end

every 1.hour do
  rake 'buildlist:clear:outdated_canceling', output: 'log/canceling_build_list_clear.log'
end

every :day, at: '4am' do
  runner 'Product.autostart_iso_builds_once_a_12_hours',    output: 'log/autostart_iso_builds.log'
  runner 'Product.autostart_iso_builds_once_a_day',         output: 'log/autostart_iso_builds.log'
  runner 'Project.autostart_build_lists_once_a_12_hours',   output: 'log/autostart_build_lists.log'
  runner 'Project.autostart_build_lists_once_a_day',        output: 'log/autostart_build_lists.log'
end

every :day, at: '4pm' do
  runner 'Product.autostart_iso_builds_once_a_12_hours',  output: 'log/autostart_iso_builds.log'
  runner 'Project.autostart_build_lists_once_a_12_hours', output: 'log/autostart_build_lists.log'
end

every :sunday, at: '4am' do
  runner 'Product.autostart_iso_builds_once_a_week',  output: 'log/autostart_iso_builds.log'
  runner 'Project.autostart_build_lists_once_a_week', output: 'log/autostart_build_lists.log'
end

every :day, at: '1am' do
  runner 'Platform.autostart_metadata_regeneration("day")', output: 'log/autostart_platform_metadata_regeneration.log'
end

every :saturday, at: '2am' do
  runner 'Platform.autostart_metadata_regeneration("week")', output: 'log/autostart_platform_metadata_regeneration.log'
end
