class Realization < ActiveRecord::Base


  belongs_to :issue
  belongs_to :re_artifact_properties


    #an artifact is open iff one of the corresponding tickets is open
  def self.open_artifacts(project)
    #find all artifacts connected to at least one issue
    artifacts_with_issue = ReArtifactProperties.find(:all, :conditions => ['id in (select distinct re_artifact_properties_id from realizations) AND project_ID=?', project.id])

    openartifacts=[]

    artifacts_with_issue.each do |artifact|
      has_open_issue = false
      artifact.issues.each do |issue|
        if issue.status_id < 5
          has_open_issue = true
        end
      end
      if has_open_issue == true
        openartifacts << artifact
      end
    end
    openartifacts


  end

  def self.openartifacts_by_due_date(project)
    artifacts = open_artifacts(project)

      #sort by issue due next
    artifacts.each do |artifact|
      artifact.issues.sort! { |a, b| a.due_date <=> b.due_date }
    end
    artifacts.sort! { |a, b| a.issues.first.due_date<=>b.issues.first.due_date }
  end

  def self.openartifacts_todo(project)
    artifacts = open_artifacts(project)
    artifacts.delete_if { |artifact|
      del = true
      artifact.issues.each do |issue|
        if issue.assigned_to_id.blank? && issue.status_id < 5
          del = false
        end
      end
      del
    }

    artifacts.sort! do |a, b|
      self.artifact_done_ratio(b)<=>self.artifact_done_ratio(a)
    end
    artifacts

  end


  def self.artifacts_without_issues
     ReArtifactProperties.find(:all, :conditions => 'id not in (select distinct re_artifact_properties_id from realizations)')
  end

  def self.artifacts_without_issues_by_project(project)
     ReArtifactProperties.find(:all, :conditions => ['id not in (select distinct re_artifact_properties_id from realizations) AND project_id = ?', project.id])
  end

  def self.issues_without_artifacts
    Issue.find(:all, :conditions => 'id not in (select distinct issue_id from realizations)' )
  end


  def self.issues_without_artifacts_by_project(project)
    Issue.find(:all, :conditions => ['id not in (select distinct issue_id from realizations) AND project_id = ?', project.id])
  end

  private
  def self.artifact_done_ratio(artifact)
    progress = 0
    artifact.issues.each do |issue|
      progress+=(issue.status_id < 5 ? issue.done_ratio : 100)
    end
    progress/artifact.issues.count
  end


end
