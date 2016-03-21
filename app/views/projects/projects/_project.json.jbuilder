json.project do |proj|
  proj.visibility  project.visibility.to_s

  proj.name        project.name_with_owner
  proj.link        project_path(project)

  proj.role        t("layout.collaborators.role_names.#{current_user.best_role project}").force_encoding(Encoding::UTF_8)

  proj.leave_link  remove_user_project_path(project) unless project.owner == current_user or !alone_member? project
  proj.rights_class participant_class(alone_member?(project), project)
  proj.title t("layout.relations.#{participant_class(alone_member?(project), project)}")

  proj.owner do |owner|
    owner.name project.owner.uname
    owner.type project.owner.class.to_s.underscore
    owner.link project.owner.class == User ? user_path(project.owner) : group_path(project.owner)
  end
end
