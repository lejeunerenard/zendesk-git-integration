# Zendesk-Git Integration
Integrate Zendesk with Git by posting an internal note with the git commit info when mentioning a Zendesk Ticket in a commit on the repo's master branch.

## Install

```sh
# Copy
cp update.pl /path/to/repo/.git/hooks/update
```

## Test

```sh
prove t/
```
