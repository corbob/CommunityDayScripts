function Get-GitHubCommunityDayContributions {
    param(
        [Parameter(Mandatory)]
        [string[]]
        $Organization,
        [Parameter(Mandatory)]
        [System.DateOnly]
        $Date
    )

    $RepositoriesSearchQueries = foreach($org in $Organization) {
        "search repos --owner $org --limit 1000 --json fullName"
    }

    $Repositories = foreach($RepoSearchQuery in $RepositoriesSearchQueries) {
        $RepoSearchQuery = $RepoSearchQuery -split ' '
        & Invoke-GH @RepoSearchQuery
    }

    $Query = "search {0} --repo $($Repositories.fullName -join ' --repo ') --updated $($Date.ToString('yyyy-MM-dd'))..$(Get-Date -Format 'yyyy-MM-dd') --json repository,title,number --limit 1000"
    $IssuesSearchQuery = $Query -f 'issues' -split ' '
    $PrsSearchQuery = $Query -f 'prs' -split ' '
    $Issues = Invoke-GH @IssuesSearchQuery
    $Prs = Invoke-GH @PrsSearchQuery

    @(
        $issues | Select-Object @{n = 'repo' ; e = { $_.repository.nameWithOwner } }, number, title, @{n = 'type'; e = { 'Issue' } }
        $prs | Select-Object @{n = 'repo' ; e = { $_.repository.nameWithOwner } }, number, title, @{n = 'type'; e = { 'Pull Request' } }
    ) | ForEach-Object {
        $issue = $_
        $eventsSearchQuery = "api /repos/$($issue.repo)/issues/$($issue.number)/events" -split ' '
        $commentsSearchQuery = "api /repos/$($issue.repo)/issues/$($issue.number)/comments" -split ' '
        Invoke-GH @eventsSearchQuery | Where-Object event -NotIn 'mentioned', 'subscribed' | Where-Object { [DateOnly]::FromDateTime($_.created_at) -eq $Date } | Select-Object @{n = 'type'; e = { $issue.type } }, @{n = 'number'; e = { $issue.number } } , @{n = 'IssueTitle'; e = { $issue.title } }, event, created_at, @{n = 'Author'; e = { $_.actor.login } }, @{n = 'Repo'; e = { $issue.repo } }
        Invoke-GH @commentsSearchQuery | Where-Object { [DateOnly]::FromDateTime($_.created_at) -eq $Date } | Select-Object @{n = 'type'; e = { $issue.type } }, @{n = 'number'; e = { $issue.number } } , @{n = 'IssueTitle'; e = { $issue.title } }, @{n = 'event'; e = { 'comment' } }, created_at, @{n = 'Author'; e = { $_.user.login } }, @{n = 'Repo'; e = { $issue.repo } }
    }
}
