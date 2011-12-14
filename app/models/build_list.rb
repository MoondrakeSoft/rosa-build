class BuildList < ActiveRecord::Base
  belongs_to :project
  belongs_to :arch
  belongs_to :pl, :class_name => 'Platform'
  belongs_to :bpl, :class_name => 'Platform'
  has_many :items, :class_name => "BuildList::Item", :dependent => :destroy

  validates :project_id, :presence => true
  validates :project_version, :presence => true
  #validates_inclusion_of :update_type, :in => UPDATE_TYPES#, :message => "extension %s is not included in the list"
  UPDATE_TYPES = %w[security bugfix enhancement recommended newpackage]
  validates :update_type, :inclusion => UPDATE_TYPES
  validate lambda {  
    errors.add(:bpl, I18n.t('flash.build_list.wrong_platform')) if pl.platform_type == 'main' && pl_id != bpl_id
  }
  validate lambda {
    errors.add(:bpl, I18n.t('flash.build_list.can_not_published')) if status == BUILD_PUBLISHED && status_was != BuildServer::SUCCESS    
  }

  # The kernel does not send these statuses directly
  BUILD_CANCELED = 5000
  WAITING_FOR_RESPONSE = 4000
  BUILD_PENDING = 2000
  BUILD_PUBLISHED = 6000

  STATUSES = [  WAITING_FOR_RESPONSE,
                BUILD_CANCELED,
                BUILD_PENDING,
                BUILD_PUBLISHED,
                BuildServer::SUCCESS,
                BuildServer::BUILD_STARTED,
                BuildServer::BUILD_ERROR,
                BuildServer::PLATFORM_NOT_FOUND,
                BuildServer::PLATFORM_PENDING,
                BuildServer::PROJECT_NOT_FOUND,
                BuildServer::PROJECT_VERSION_NOT_FOUND,
                BuildServer::BINARY_TEST_FAILED,
                BuildServer::DEPENDENCY_TEST_FAILED  ]

  HUMAN_STATUSES = { WAITING_FOR_RESPONSE => :waiting_for_response,
                     BUILD_CANCELED => :build_canceled,
                     BUILD_PENDING => :build_pending,
                     BUILD_PUBLISHED => :build_published,
                     BuildServer::BUILD_ERROR => :build_error,
                     BuildServer::BUILD_STARTED => :build_started,
                     BuildServer::SUCCESS => :success,
                     BuildServer::PLATFORM_NOT_FOUND => :platform_not_found,
                     BuildServer::PLATFORM_PENDING => :platform_pending,
                     BuildServer::PROJECT_NOT_FOUND => :project_not_found,
                     BuildServer::PROJECT_VERSION_NOT_FOUND => :project_version_not_found,
                     BuildServer::DEPENDENCY_TEST_FAILED => :dependency_test_failed,
                     BuildServer::BINARY_TEST_FAILED => :binary_test_failed
                    }

  scope :recent, order("#{table_name}.updated_at DESC")
  scope :current, lambda {
    outdatable_statuses = [BuildServer::SUCCESS, BuildServer::ERROR, BuildServer::PLATFORM_NOT_FOUND, BuildServer::PLATFORM_PENDING, BuildServer::PROJECT_NOT_FOUND, BuildServer::PROJECT_VERSION_NOT_FOUND]
    where(["status in (?) OR (status in (?) AND notified_at >= ?)", [WAITING_FOR_RESPONSE, BUILD_PENDING, BuildServer::BUILD_STARTED], outdatable_statuses, Time.now - 2.days])
  }
  scope :for_status, lambda {|status| where(:status => status) }
  scope :scoped_to_arch, lambda {|arch| where(:arch_id => arch) }
  scope :scoped_to_project_version, lambda {|project_version| where(:project_version => project_version) }
  scope :scoped_to_is_circle, lambda {|is_circle| where(:is_circle => is_circle) }
  scope :for_creation_date_period, lambda{|start_date, end_date|
    if start_date && end_date
      where(["#{table_name}.created_at BETWEEN ? AND ?", start_date, end_date])
    elsif start_date && !end_date
      where(["#{table_name}.created_at >= ?", start_date])
    elsif !start_date && end_date
      where(["#{table_name}.created_at <= ?", end_date])
    end
  }
  scope :for_notified_date_period, lambda{|start_date, end_date|
    if start_date && end_date
      where(["notified_at BETWEEN ? AND ?", start_date, end_date])
    elsif start_date && !end_date
      where(["notified_at >= ?", start_date])
    elsif !start_date && end_date
      where(["notified_at <= ?", end_date])
    end
  }
  scope :scoped_to_project_name, lambda {|project_name| joins(:project).where('projects.name LIKE ?', "%#{project_name}%")}
#  scope :scoped_open_to_user_with_groups, lambda {|user|
#    joins(:project).where("projects.visibility = 'open' OR projects.id IN (
#      SELECT target_id
#      FROM relations
#      WHERE object_id = :uid AND object_type = 'User' AND target_type = 'Project'
#      UNION
#      SELECT rel1.target_id AS target_id
#      FROM relations AS rel
#      INNER JOIN(
#        SELECT *
#        FROM relations
#        WHERE object_type = 'Group' AND target_type = 'Project'
#      )AS rel1 ON rel1.object_id = rel.target_id
#      WHERE rel.object_id = :uid AND rel.object_type = 'User' AND rel.target_type = 'Group')", :uid => user.id)
#  }

  serialize :additional_repos
  
  before_create :set_default_status
  after_create :place_build

  def self.human_status(status)
    I18n.t("layout.build_lists.statuses.#{HUMAN_STATUSES[status]}")
  end

  def human_status
    self.class.human_status(status)
  end

  def set_items(items_hash)
    self.items = []

    items_hash.each do |level, items|
      items.each do |item|
        self.items << self.items.build(:name => item['name'], :version => item['version'], :level => level.to_i)
      end
    end
  end
  
  def publish
    return false unless can_published?
    
    BuildServer.publish_container bs_id
    self.update_attribute(:status, BUILD_PUBLISHED)
    #self.destroy # self.delete
  end
  
  def can_published?
    self.status == BuildServer::SUCCESS
  end

  def cancel_build_list
    has_canceled = BuildServer.delete_build_list bs_id
    update_attribute(:status, BUILD_CANCELED) if has_canceled == 0
    
    return has_canceled == 0
  end

  #TODO: Share this checking on product owner.
  def can_cancel?
    self.status == BUILD_PENDING && bs_id
  end

  def event_log_message
    {:project => project.name, :version => project_version, :arch => arch.name}.inspect
  end

  private
    def set_default_status
      self.status = WAITING_FOR_RESPONSE unless self.status.present?
      return true
    end

    def place_build
      #XML-RPC params: project_name, project_version, plname, arch, bplname, update_type, build_requires, id_web
      self.status = BuildServer.add_build_list project.name, project_version, pl.name, arch.name, (pl_id == bpl_id ? '' : bpl.name), update_type, build_requires, id
      self.status = BUILD_PENDING if self.status == 0
      save
    end
    #handle_asynchronously :place_build

end
