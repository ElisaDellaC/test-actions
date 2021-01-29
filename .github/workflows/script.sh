#!/bin/bash

echo 'my trigger is: ' $TRIGGER_EVENT_NAME

          if [ "$TRIGGER_EVENT_NAME" == pull_request ]; then
            sha=${{ github.event.pull_request.head.sha }}
            prNumber=${{ github.event.number }}
          else
            sha=${{ github.event.workflow_run.head_commit.id }}
            prNumber=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/search/issues\?q\="${sha}" | jq '. | .items' | jq '.[]' | jq '.number')
          fi

          echo my commit is: "${sha}"         
          echo my PR is: "${prNumber}"
          
          numberSuccessCheckSuites=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/ElisaDellaC/test-actions/commits/"${sha}"/check-suites | jq '.check_suites' | jq '.[] | select(.app.slug=="github-actions") |.conclusion' | jq  'select(. == "success")' | jq -s '.' | jq length)
          numberPercyLabels=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/ElisaDellaC/test-actions/issues/"${prNumber}" | jq '.labels' | jq '.[] | .name' | jq 'select(. == "check-percy-results-before-merge")' | jq -s '.' | jq length)

          echo 'successful checks:' $numberSuccessCheckSuites
          echo 'percy labels:' $numberPercyLabels
         
          # we set the workflow to pass if there is no percy labels set on the PR and the other 2 GH Actions Workflows status-checks have reported success
          if [ $numberSuccessCheckSuites -ge 2 ] && [ $numberPercyLabels -eq 0 ]; then
            echo "build-and-test & build-and-deploy are successful, no percy label is set"
            exit 0
          else
            echo "1 or more workflows are failed or Percy label is set"
            exit 1
          fi
             
          