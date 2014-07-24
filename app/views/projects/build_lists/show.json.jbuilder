json.build_list do
  if !@build_list.in_work? && @build_list.started_at
    json.human_duration @build_list.human_duration
  elsif @build_list.in_work?
    json.human_duration "#{@build_list.human_current_duration} / #{@build_list.human_average_build_time}"
  end
  
  json.cache! [@build_list, current_user], expires_in: 1.minute do
    json.(@build_list, :id, :container_status, :status)
    json.(@build_list, :update_type)
    json.updated_at @build_list.updated_at
    json.updated_at_utc @build_list.updated_at.strftime('%Y-%m-%d %H:%M:%S UTC')


    json.can_publish can?(:publish, @build_list)
    json.can_publish_into_testing can?(:publish_into_testing, @build_list) && @build_list.can_publish_into_testing?
    json.can_cancel @build_list.can_cancel?
    json.can_create_container @build_list.can_create_container?
    json.can_reject_publish @build_list.can_reject_publish?

    json.extra_build_lists_published @build_list.extra_build_lists_published?
    json.can_publish_in_future can_publish_in_future?(@build_list)
    json.can_publish_into_repository @build_list.can_publish_into_repository?


    json.container_path container_url if @build_list.container_published?

    json.publisher do
      json.fullname @build_list.publisher.try(:fullname)
      json.path user_path(@build_list.publisher)
    end if @build_list.publisher

    json.builder do
      json.fullname @build_list.builder.try(:fullname)
      json.path user_path(@build_list.builder)
    end if @build_list.builder && (!@build_list.builder.system? || current_user.try(:admin?))

    json.advisory do
      json.(@build_list.advisory, :description, :advisory_id)
      json.path advisory_path(@build_list.advisory)
    end if @build_list.advisory

    json.results @build_list.results do |result|
      json.file_name result['file_name']
      json.sha1 result['sha1']
      json.size result['size']

      timestamp = result['timestamp']
      json.created_at Time.zone.at(result['timestamp']).to_s if timestamp

      json.url file_store_results_url(result['sha1'], result['file_name'])
    end if @build_list.new_core? && @build_list.results.present?

    json.packages @build_list.packages do |package|
      json.(package, :id, :name, :fullname, :release, :version, :sha1, :epoch)
      json.url "#{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{package.sha1}" if package.sha1

      json.dependent_projects dependent_projects(package) do |project, packages|
        json.url project_path(project.name_with_owner)
        json.name project.name_with_owner
        json.dependent_packages packages
        json.new_url new_project_build_list_path(project)
      end if @build_list.save_to_platform.main?

    end if @build_list.packages.present?


    json.item_groups do |group|
      @item_groups.each_with_index do |group, level|
        json.group group do |item|
          json.(item, :name, :status)
          json.path build_list_item_version_link item
          json.level level
        end
      end
    end if @item_groups.present?
  end

end
