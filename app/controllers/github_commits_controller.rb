class GithubCommitsController < ApplicationController
  unloadable
  skip_before_filter [ :check_if_login_required, :verify_authenticity_token]
  GITHUB_URL = "https://github.com/"

  def create_comment
    if params[:commits].present? && verify_signature?
      repository_name = params[:repository][:name]
      branch = params[:ref].split("/").last
      params[:commits].each do |last_commit|
        message = last_commit[:message]
        if message.present? && message.include?("#rm")
          issue_id = message.partition("#rm").last.split(" ").first.to_i
          issue = Issue.find_by(id: issue_id)
        end
        email = EmailAddress.find_by(address: last_commit[:author][:email])
        user = email.present? ? email.user : User.where(admin: true).first
          
        if last_commit.present? && issue.present?
          author = last_commit[:author][:name]
          notes = t('commit.message', author: author, 
                                      repository_name: repository_name, 
                                      github_url: GITHUB_URL, 
                                      branch: branch, 
                                      message: message, 
                                      commit_id: last_commit[:id],
                                      commit_url: last_commit[:url])
          issue.journals.create(journalized_id: issue_id, journalized_type: "Issue", user: user, notes: notes)
        end
      end
    end
    render nothing: true, status: :ok
  end

  def verify_signature?
    request.body.rewind
    payload_body = request.body.read
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), Rails.configuration.secret_token, payload_body)
    return Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
  end
end
