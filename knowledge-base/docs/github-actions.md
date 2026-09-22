---
titulo: Github Actions
---

## main


```yml
name: "main"

on: [push, pull_request]

jobs:
 lint:
 runs-on: ubuntu-latest
 steps:
 - uses: ahmadnassri/action-commit-lint@v2

```

## change log

```yml
name: Generate Changelog

on:
 push:
 branches: [main, master]
 pull_request:
 branches: [main, master]

jobs:
 changelog:
 runs-on: ubuntu-latest
 if: github.event_name == 'push'

 permissions:
 contents: write

 steps:
 - uses: actions/checkout@v4
 with:
 fetch-depth: 0
 token: ${{ secrets.GITHUB_TOKEN }}

 - uses: actions/setup-node@v4
 with:
 node-version: "20"
 cache: "npm"

 - name: Install dependencies
 run: npm ci

 - name: Generate Changelog
 run: npm run version

 - name: Commit and push
 run: |
 git config --local user.email "action@github.com"
 git config --local user.name "GitHub Action"
 git add CHANGELOG.md
 if git diff --staged --quiet; then
 echo "No changes to commit"
 else
 git commit -m "docs: update changelog [skip ci]"
 git push
 fi
```