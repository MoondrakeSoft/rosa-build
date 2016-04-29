if @activity_feeds.next_page
  json.next_page_link @next_page_link
end

json.feed do
  json.array!(@activity_feeds) do |item|
    json.cache! item, expires_in: 10.minutes do
      json.date item.created_at
      json.kind item.kind
      user = get_user_from_activity_item(item)
      json.user do
        json.link user_path(user) if user.persisted?
        json.image avatar_url(user, :small) if user.persisted?
        json.uname (user.fullname || user.email)
      end if user

      project_name_with_owner = "#{item.project_owner}/#{item.project_name}"
      @project = Project.find_by_owner_and_name(project_name_with_owner)

      json.project_name_with_owner project_name_with_owner
      json.partial! item.partial, item: item, project_name_with_owner: project_name_with_owner
      json.id item.id
    end
  end
end
