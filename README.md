# github_commits

This plugin adds a comment in redmine issue whenever user commits to github with the redmine issue number in the commit message. We have created this plugin because it is very painful to keep track of all commits for an issue, and we just wanted to connect the github with our own Redmine. 

## Steps to use this plugin:

1. When user commits on github, the commit message should include `#rm123` where `123` should be the issue_id in redmine for which the commit is pushed. for eg : `git commit -m 'user signup - #rm123'`

2. User who pushes commit on github, should have the same email address which is used as redmine user also. It will add comment on behalf of the original user or admin user.

3. Configure the environment variable `GITHUB_SECRET_TOKEN` when you run Redmine and also use the same token while creating a webhook on github.

4. Github -> Repo setting –> webhook –> In event, select "send me everything" or you can select "Let me select individual events" and inside check the checkbox for commit event and then create web hook.

5. For repository, webhook should be created with payload-url as `localhost:3000/github_commits/create_comment.json` where in url replace `localhost:3000` with your host address.

6. In Redmine, Go to Administration -> Settings -> General Tab and change text formatting to `Markdown`. This will show the comment message properly.

## Steps to use second feature (github change notification) which moves issues when there is a PR

1. Create webhook like previous feature but with `/github_commits/github_change_notification.json` as URL. Send Pull Request only.

2. Set ENV Variables like when you did for `GITHUB_SECRET_TOKEN` but for `CURRENT_REDMINE_STATE` (single integer) and `NEXT_REDMINE_STATE` (single integer).

3. When doing a PR add `#rmXXX` like previous in the title to point which redmine ticket number must be automatically updated.
