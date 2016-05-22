json.total_items @total_items

json.projects @projects do |project|
  json.id               project.id
  json.visibility_class fa_visibility_icon(project)
  json.path             project_build_lists_path(project.name_with_owner)
  json.name             project.name_with_owner
  if policy(@repository).remove_project?
    json.remove_path       remove_project_platform_repository_path(@platform, @repository, project_id: project.id)
  end
end
