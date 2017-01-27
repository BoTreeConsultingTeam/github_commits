# github_commits

This plugin adds a comment in redmine issue whenever user commits to github with the redmine issue number in the commit message. We have created this plugin because it is very painful to keep track of all commits for an issue, and we just wanted to connect the github with our own Redmine. 

## Steps to use this plugin:

1. When user commits on github, the commit message should include `#rm123` where `123` should be the issue_id in redmine for which the commit is pushed. for eg : `git commit -m 'user signup - #rm123'`

2. User who pushes commit on github, should have the same email address which is used as redmine user also. It will add comment on behalf of the original user or admin user.

3. Configure the environment variable `GITHUB_SECRET_TOKEN` when you run Redmine and also use the same token while creating a webhook on github.

4. Github -> Repo setting –> webhook –> In event, select "send me everything" or you can select "Let me select individual events" and inside check the checkbox for commit event and then create web hook.

5. For repository, webhook should be created with payload-url as `localhost:3000/github_commits/create_comment` where in url replace `localhost:3000` with your host address.

6. In Redmine, Go to Administration -> Settings -> General Tab and change text formatting to `Markdown`. This will show the comment message properly.
