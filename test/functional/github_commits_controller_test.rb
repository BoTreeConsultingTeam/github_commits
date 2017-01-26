require File.expand_path('../../test_helper', __FILE__)
require 'json'

class GithubCommitsControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  fixtures :users, :email_addresses

  def test_create_comment_without_hmac_signature_header
    hmac_header(invalid_body)
    assert_no_difference('Journal.count') do 
      post :create_comment, invalid_body
    end
    assert_response :error 
  end

  def test_create_comment_without_commit_data
    hmac_header(invalid_body)
    assert_no_difference('Journal.count') do 
      post :create_comment,invalid_body
    end
    assert_response :success
    assert_equal JSON.parse(@response.body)['error'], I18n.translate('lables.no_commit_data_found')
  end

  def test_create_comment_without_issue_number
    new_valid_body = valid_body
    new_valid_body[:commits][0][:message] = "Without issue number"
    hmac_header(new_valid_body)
    assert_no_difference('Journal.count') do 
      post :create_comment,new_valid_body
    end
    assert_equal JSON.parse(@response.body)['error'], I18n.translate('lables.no_issue_found')
    assert_response :success
  end

  def test_create_comment_with_invalid_issue_number
    new_valid_body = valid_body
    new_valid_body[:commits][0][:message] = "invalid issue number #rm89070"
    hmac_header(new_valid_body)
    assert_no_difference('Journal.count') do 
      post :create_comment,new_valid_body
    end
    assert_response :success
    assert_equal JSON.parse(@response.body)['error'], I18n.translate('lables.no_issue_found')
  end

  def test_create_comment_with_empty_issue_number
    new_valid_body = valid_body()
    new_valid_body[:commits][0][:message] = "empty issue number #rm fgfg"
    hmac_header(new_valid_body)
    assert_no_difference('Journal.count') do 
      post :create_comment,new_valid_body
    end
    assert_response :success
    assert_equal JSON.parse(@response.body)['error'], I18n.translate('lables.no_issue_found')
  end

  def test_create_comment_with_existing_user_email
    new_valid_body = valid_body
    new_valid_body[:commits][0][:author][:email] = email_addresses(:email_address_002).address
    hmac_header(new_valid_body)
    assert_difference('Journal.count') do 
      post :create_comment,new_valid_body
    end
    assert_response :success
    assert_equal JSON.parse(@response.body)['success'], true
    comment = Comment.last
    assert_equal comment.user.email, users(:users_002).email
    assert comment.notes.include?(valid_body[:commits][0][:message]), "Should have created comment with passed message"
  end

  def test_create_comment_without_existing_user_email
    hmac_header(valid_body)
    assert_difference('Journal.count') do 
      post :create_comment,valid_body
    end
    assert_response :success
    assert_equal JSON.parse(@response.body)['success'], true
    comment = Comment.last
    assert_equal comment.user.email, users(:users_001).email
    assert comment.notes.include?(valid_body[:commits][0][:message]), "Should have created comment with passed message"
  end

  private

  def invalid_body
    {}
  end

  def hmac_header(params)
    @request.headers['HTTP_X_HUB_SIGNATURE'] = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), 
                                                              Rails.configuration.secret_token, 
                                                              params.to_query
                                                             )
    @request.headers['CONTENT_TYPE'] = 'application/json'
    @request.headers['HTTP_ACCEPT'] = 'application/json'
  end

  def valid_body
    {
      "ref": "refs/heads/new_data",
      "before": "34058q23rkafdwf9as809fasd09f",
      "after": "3404rhj7rkafdwf9as809fasd09f",
      "created": false,
      "deleted": false,
      "forced": false,
      "base_ref": nil,
      "compare": "https://github.com/redmine/redmine/compare/0c453155ed7e...dfg9015b75b1",
      commits: [
        {
          "id": "zs809g8zsdv098sd0fizsd09f80adgkzdsnv8ew",
          "tree_id": "q983ruaweoifae09rufsd0cjkZXcDzsdgsdv2czdif",
          "distinct": true,
          message: "#rm123 - Doing something",
          "timestamp": "2017-01-26T16:15:38+05:30",
          "url": "https://github.com/redmine/redmine/commit/349587309rfusd09f7szd0fv8uzsd8duf",
          author: {
            "name": "Parth Barot",
            "email": "parth@example.com",
            "username": "parthb"
          },
          "committer": {
            "name": "Parth Barot",
            "email": "parth@example.com",
            "username": "parthb"
          }
        }
      ],
      "repository": {
        "id": 38929123,
        "name": "redmine",
        "full_name": "redmine/redmine",
        "owner": {
          "name": "redmine",
          "email": ""
        },
        "private": false,
        "html_url": "https://github.com/redmine/redmine"
      }
    }
  end

end
