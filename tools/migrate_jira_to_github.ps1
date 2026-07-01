<#
.SYNOPSIS
    Mirrors the tickets of any Jira Cloud project into GitHub issues.

.DESCRIPTION
    Generic Jira -> GitHub issue migration:

      1. Fetches every issue in the given Jira project via the REST API
         (POST /rest/api/3/search/jql), paginating with nextPageToken.
      2. Flattens each Jira description from ADF (Atlassian Document
         Format, a JSON tree) into plain text.
      3. Creates a GitHub label per Jira issue type (epic, task, bug, ...).
      4. Creates one GitHub issue per ticket, in ascending key order.
         On a brand-new repo with no issues or PRs, this makes GitHub
         issue #N line up with Jira key KEY-N (PRs share the same
         number counter, so any existing PR breaks the alignment).
      5. With -CloseDone, issues whose Jira status category is "Done"
         are closed immediately with reason "completed".

    Requirements:
      * GitHub CLI (`gh`) installed and authenticated: gh auth login
      * A Jira API token: https://id.atlassian.com/manage-profile/security/api-tokens
        Jira Cloud REST auth is HTTP Basic with "email:api-token".

.PARAMETER ProjectKey
    The Jira project key to migrate, e.g. "PG".

.PARAMETER JiraBaseUrl
    Your Jira site, e.g. "https://yoursite.atlassian.net".

.PARAMETER JiraEmail
    Atlassian account email. Defaults to $env:JIRA_EMAIL.

.PARAMETER JiraApiToken
    Jira API token. Defaults to $env:JIRA_API_TOKEN. Prefer the env var
    over typing the token on the command line (shell history!).

.PARAMETER Repo
    Target GitHub repo as "owner/name". Defaults to the repo of the
    current directory's git remote (gh figures it out).

.PARAMETER CloseDone
    Close mirrored issues whose Jira status category is "Done".

.PARAMETER DryRun
    Print what would happen without creating anything on GitHub.

.EXAMPLE
    $env:JIRA_EMAIL = "me@example.com"
    $env:JIRA_API_TOKEN = "..."
    .\migrate_jira_to_github.ps1 -ProjectKey PG `
        -JiraBaseUrl https://gtea524.atlassian.net -CloseDone

.EXAMPLE
    .\migrate_jira_to_github.ps1 -ProjectKey OPS `
        -JiraBaseUrl https://yoursite.atlassian.net `
        -Repo greentea524/ops-tools -DryRun
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$ProjectKey,
    [Parameter(Mandatory = $true)] [string]$JiraBaseUrl,
    [string]$JiraEmail = $env:JIRA_EMAIL,
    [string]$JiraApiToken = $env:JIRA_API_TOKEN,
    [string]$Repo,
    [switch]$CloseDone,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if (-not $JiraEmail -or -not $JiraApiToken) {
    throw 'Jira credentials missing. Set $env:JIRA_EMAIL and $env:JIRA_API_TOKEN, or pass -JiraEmail / -JiraApiToken.'
}

# When -Repo is given, add "--repo owner/name" to every gh call via
# splatting; otherwise gh infers the repo from the cwd's git remote.
$repoArgs = @()
if ($Repo) { $repoArgs = @('--repo', $Repo) }

# ---------------------------------------------------------------------
# 1. Fetch all issues from Jira
# ---------------------------------------------------------------------
# Jira Cloud REST auth: HTTP Basic, base64("email:api-token").
$pair = '{0}:{1}' -f $JiraEmail, $JiraApiToken
$auth = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))
$headers = @{ Authorization = "Basic $auth" }

$jiraIssues = @()
$nextPageToken = $null
do {
    # POST /search/jql is the current (2024+) search endpoint; the old
    # GET /search with startAt pagination is deprecated. Pagination is
    # cursor-based: keep re-posting with the returned nextPageToken.
    $request = @{
        jql        = "project = $ProjectKey ORDER BY created ASC"
        fields     = @('summary', 'description', 'status', 'issuetype')
        maxResults = 100
    }
    if ($nextPageToken) { $request.nextPageToken = $nextPageToken }

    $response = Invoke-RestMethod -Method Post `
        -Uri "$JiraBaseUrl/rest/api/3/search/jql" `
        -Headers $headers -ContentType 'application/json' `
        -Body ($request | ConvertTo-Json)

    $jiraIssues += $response.issues
    $nextPageToken = $response.nextPageToken
} while ($nextPageToken)

if ($jiraIssues.Count -eq 0) {
    throw "No issues found for project '$ProjectKey' - check the key and your permissions."
}
Write-Output "Fetched $($jiraIssues.Count) issues from Jira project $ProjectKey."

# Sort by the numeric part of the key (PG-2 before PG-10; a plain
# string sort would get this wrong).
$jiraIssues = $jiraIssues | Sort-Object { [int]($_.key -replace '.*-', '') }

# ---------------------------------------------------------------------
# 2. ADF -> plain text
# ---------------------------------------------------------------------
# Jira v3 API returns descriptions as ADF: a JSON tree of typed nodes.
# For an issue body, recursively concatenating the "text" leaves and
# adding newlines after block nodes is a good-enough flattening.
function ConvertFrom-Adf($node) {
    if ($null -eq $node) { return '' }
    if ($node -is [string]) { return $node }
    $text = ''
    if ($node.type -eq 'text') { $text += $node.text }
    if ($node.type -eq 'hardBreak') { $text += "`n" }
    if ($node.PSObject.Properties['content'] -and $node.content) {
        foreach ($child in $node.content) { $text += ConvertFrom-Adf $child }
    }
    if ($node.type -in @('paragraph', 'heading', 'listItem', 'codeBlock', 'blockquote')) {
        $text += "`n"
    }
    return $text
}

# ---------------------------------------------------------------------
# 3. One GitHub label per Jira issue type
# ---------------------------------------------------------------------
$palette = @{ epic = '8250df'; story = '1d76db'; task = '0e8a16'; bug = 'd73a4a'; 'sub-task' = 'fbca04' }
$typeNames = $jiraIssues | ForEach-Object { $_.fields.issuetype.name.ToLower() } | Sort-Object -Unique
foreach ($type in $typeNames) {
    $color = $palette[$type]
    if (-not $color) { $color = 'ededed' }
    if ($DryRun) {
        Write-Output "[dry-run] would create label '$type' (#$color)"
    } else {
        # 2>$null: ignore "already exists" so the script is re-runnable.
        gh label create $type --color $color --description "Jira $type" @repoArgs 2>$null
    }
}

# ---------------------------------------------------------------------
# 4. Create (and optionally close) the GitHub issues
# ---------------------------------------------------------------------
foreach ($issue in $jiraIssues) {
    $key = $issue.key
    $fields = $issue.fields
    $type = $fields.issuetype.name.ToLower()
    $status = $fields.status.name
    # statusCategory.key is one of: new / indeterminate / done. It is
    # workflow-agnostic, unlike status names ("Done", "Closed", ...).
    $isDone = $fields.status.statusCategory.key -eq 'done'

    $description = (ConvertFrom-Adf $fields.description).Trim()
    if (-not $description) { $description = '_(no description)_' }

    $body = "Imported from Jira [$key]($JiraBaseUrl/browse/$key) - status: $status.`n`n" +
            "**Description**`n$description"

    $title = "[$key] $($fields.summary)"

    if ($DryRun) {
        $closeNote = ''
        if ($CloseDone -and $isDone) { $closeNote = ' + close as completed' }
        Write-Output "[dry-run] would create '$title' (label: $type)$closeNote"
        continue
    }

    # --body-file avoids every shell-quoting pitfall of multi-line
    # markdown (quotes, backticks, newlines).
    $bodyFile = Join-Path $env:TEMP 'jira_issue_body.md'
    Set-Content -Path $bodyFile -Value $body -Encoding utf8

    # gh prints the new issue's URL; capture it so we can close by URL
    # instead of guessing issue numbers.
    $url = gh issue create --title $title --body-file $bodyFile --label $type @repoArgs

    if ($CloseDone -and $isDone) {
        # "completed" (purple badge) vs "not planned" (gray badge).
        gh issue close $url --reason completed @repoArgs | Out-Null
        Write-Output "$key -> $url (closed)"
    } else {
        Write-Output "$key -> $url"
    }
}
