class GithubCommitsController < ApplicationController
  unloadable
  skip_before_filter :verify_authenticity_token

  def create_comment
    if params[:commits].present? && verify_signature?
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
          notes = "This User has Commited On #{branch} branch with message: *" + message + "*  \"#{last_commit[:id]}\":" + last_commit[:url]
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
