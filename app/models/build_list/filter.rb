class BuildList::Filter
  PER_PAGE = [25, 50, 100]

  attr_reader :options

  def initialize(project, user, options = {})
    @project, @user = project, user
    set_options(options)
  end

  def find
    build_lists =  @project ? @project.build_lists : BuildList.all

    if @options[:id]
      build_lists = build_lists.where(id: @options[:id])
    else
      build_lists =
        case @options[:ownership]
        when 'owned'
          BuildListPolicy::Scope.new(@user, build_lists).owned
        when 'related'
          BuildListPolicy::Scope.new(@user, build_lists).related
        else
          BuildListPolicy::Scope.new(@user, build_lists).everything
        end
      if @options[:mass_build_id]
        build_lists = build_lists.by_mass_build(@options[:mass_build_id] == '-1' ? nil : @options[:mass_build_id])
      end
      build_lists = build_lists.for_status(@options[:status])
                               .scoped_to_arch(@options[:arch_id])
                               .scoped_to_save_platform(@options[:save_to_platform_id])
                               .scoped_to_build_for_platform(@options[:build_for_platform_id])
                               .scoped_to_save_to_repository(@options[:save_to_repository_id])
                               .scoped_to_project_version(@options[:project_version])
                               .scoped_to_project_name(@options[:project_name])
                               .for_notified_date_period(@options[:updated_at_start], @options[:updated_at_end])
    end

    build_lists
  end

  def respond_to?(name)
    return true if @options.has_key?(name)
    super
  end

  def method_missing(name, *args, &block)
    @options.has_key?(name) ? @options[name] : super
  end

  private

  def set_options(options)
    @options = HashWithIndifferentAccess.new(options.reverse_merge({
        ownership:             nil,
        status:                nil,
        updated_at_start:      nil,
        updated_at_end:        nil,
        arch_id:               nil,
        save_to_platform_id:   nil,
        build_for_platform_id: nil,
        save_to_repository_id: nil,
        is_circle:             nil,
        project_version:       nil,
        id:                    nil,
        project_name:          nil,
        mass_build_id:         nil
    }))

    @options[:ownership] = @options[:ownership].presence || (@project || !@user ? 'everything' : 'owned')
    @options[:status]                = @options[:status].present? ? @options[:status].to_i : nil
    @options[:created_at_start]      = build_date_from_params(:created_at_start, @options)
    @options[:created_at_end]        = build_date_from_params(:created_at_end, @options)
    @options[:updated_at_start]      = build_date_from_params(:updated_at_start, @options)
    @options[:updated_at_end]        = build_date_from_params(:updated_at_end, @options)
    @options[:project_version]       = @options[:project_version].presence
    @options[:arch_id]               = @options[:arch_id].try(:to_i)
    @options[:save_to_platform_id]   = @options[:save_to_platform_id].try(:to_i)
    @options[:build_for_platform_id] = @options[:build_for_platform_id].try(:to_i)
    @options[:save_to_repository_id] = @options[:save_to_repository_id].try(:to_i)
    @options[:is_circle]             = @options[:is_circle].present? ? @options[:is_circle] == "1" : nil
    @options[:id]                    = @options[:id].presence
    @options[:project_name]          = @options[:project_name].presence
    @options[:mass_build_id]         = @options[:mass_build_id].presence
  end

  def build_date_from_params(field_name, params)
    return nil if params[field_name].blank?
    params[field_name].strip!
    return Date.parse(params[field_name]) if params[field_name] =~ /\A\d{2}\/\d{2}\/\d{4}\z/
    return Time.at(params[field_name].to_i) if params[field_name] =~ /\A\d+\z/
    nil
  end
end
