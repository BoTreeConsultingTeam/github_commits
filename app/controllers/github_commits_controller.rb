class GithubCommitsController < ApplicationController
  
  unloadable
   
  skip_before_action :check_if_login_required
  skip_before_action :verify_authenticity_token
  
  before_action :verify_signature?
  
  GITHUB_URL = "https://github.com/"
  REDMINE_JOURNALIZED_TYPE = "Issue"
  REDMINE_ISSUE_NUMBER_PREFIX = "#rm"

  #added JPBD Jan2022
  def github_change_notification
    resp_json = nil
    # if payload contains pr and action is opened (new pr)
    if params[:pull_request].present? && params[:action] == "opened"
      
      #get issue ID
      pr_title = params[:pull_request][:title]
      issue_id = pr_title.partition(REDMINE_ISSUE_NUMBER_PREFIX).last.split(" ").first.to_i
      issue = Issue.find_by(id: issue_id)
      
      #if issue id exists in redmine & status is in progress (2)
      if issue.present? && issue.status_id == 2
        issue.status = 14 #jenkins validation
        resp_json = {success: true}
      else
        resp_json = {success: false, error: t('lables.no_pr_found') }
      end

      resp_json = {success: true}
    else # if not a pr payload
      resp_json = {success: false, error: t('lables.no_update') }
    end

    respond_to do |format|
      format.json { render json: resp_json, status: :ok }
    end

  end
  # --


  def create_comment
    resp_json = nil
    if params[:commits].present?
      
      repository_name = params[:repository][:name]
      branch = params[:ref].split("/").last
      
      params[:commits].each do |last_commit|
        message = last_commit[:message]

        if message.present? && is_commit_to_be_tracked?(last_commit)         
          issue_id = message.partition(REDMINE_ISSUE_NUMBER_PREFIX).last.split(" ").first.to_i
          issue = Issue.find_by(id: issue_id)
        end

        if last_commit.present? && issue.present?

          email = EmailAddress.find_by(address: last_commit[:author][:email])
          user = email.present? ? email.user : User.where(admin: true).first
          
          author = last_commit[:author][:name]
          
          notes = t('commit.message', author: author, 
                                      branch: branch, 
                                      message: message, 
                                      commit_id: last_commit[:id],
                                      commit_url: last_commit[:url])
          
          issue.journals.create(journalized_id: issue_id, 
                                journalized_type: REDMINE_JOURNALIZED_TYPE, 
                                user: user, 
                                notes: notes
                               )
          resp_json = {success: true}
        else
          resp_json = {success: false, error: t('lables.no_issue_found') }
        end
      end
      
    else
      resp_json = {success: false, error: t('lables.no_commit_data_found') }
    end

    respond_to do |format|
      format.json { render json: resp_json, status: :ok }
    end

  end

  def verify_signature?
    if request.env['HTTP_X_HUB_SIGNATURE'].blank? || ENV["GITHUB_SECRET_TOKEN"].blank?
      render json: {success: false},status: 500
    else
      request.body.rewind
      payload_body = request.body.read
      signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV["GITHUB_SECRET_TOKEN"], payload_body)
      render json: {success: false},status: 500 unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
    end
  end

  private

  def is_commit_to_be_tracked?(commit_obj)
    commit_obj[:distinct] == true &&  #is it a fresh commit ?
    commit_obj[:message].include?(REDMINE_ISSUE_NUMBER_PREFIX) #Does it include the redmine issue prefix string pattern?
  end
end
