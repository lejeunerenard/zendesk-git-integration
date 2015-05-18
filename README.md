# Zendesk-Git Integration
Integrate Zendesk with Git by posting an internal note with the git commit info when mentioning a Zendesk Ticket in a commit on the repo's master branch.

## Install
Make sure you have all the packages listed in `cpanfile` installed and accessible to the server-side user.

```sh
# Setup zendesk credentials per user
git config --global zendesk.subdomain mysubdomain
git config --global zendesk.token xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Copy
cp update.pl /path/to/repo/.git/hooks/update
```

## How It Works
Whenever you push to the repo that you install the `update` script into, it will check to see that all the following apply:

1. The Ref being pushed is the master branch
2. That any of the commit between the previous commit and the new commit contain the ticket number.

    The Ticket number must be referred to as:

    ```text
    Ticket #1337
    ```

3. That the Zendesk Credentials were defined in git's config.

When everything is satisfied, a comment containing the `full` git commit message is sent as an internal note on given ticket. All Zendesk API response are returned to the user pushing to the repo.
