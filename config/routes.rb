# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
post 'github_commits/create_comment.json', to: 'github_commits#create_comment'
post 'github_commits/github_change_notification.json', to: 'github_commits#github_change_notification'
