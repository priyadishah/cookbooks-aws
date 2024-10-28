param (
    [Parameter(Mandatory=$true)]
    [string]
    $GitRepo,

    [Parameter(Mandatory=$true)]
    [string]
    $GitRepoPath,

    [Parameter(Mandatory=$true)]
    [string]
    $Branch,

    [Parameter(Mandatory=$true)]
    [string]
    $GitUserName,

    [boolean]
    $CalledUsingRemotePS = $false,

    [boolean]
    $InstallGit = $true
    )

Write-Debug "GitRepo = $GitRepo" | Write-Host
Write-Debug "GitRepoPath = $GitRepoPath" | Write-Host

$Update = $false

try {
    # Git outputs almost all normal messages to stderr. powershell interprets that as an error and
    # displays the error text. To stop that stderr is redirected to stdout on the git commands.

    Write-Debug "Path = $([Environment]::GetEnvironmentVariable('PATH', 'Machine'))" | Write-Host

    if ( $InstallGit -and (-not (Test-Path $GitRepoPath) ) )
    {
        Write-Host "Installing Git"
        Run-ExitCode 'choco' @('install', 'git', '-y', '--no-progress', '--force' ) | Out-Default | Write-Host
    
        refreshenv | Out-Default | Write-Host

        # Note, the Git install overwrites the current environment so need to modify path here
        Add-DirectoryToEnvPathOnce -Directory "C:\Program Files\Git\cmd" | Out-Default | Write-Host
        Write-Debug "Path = $([Environment]::GetEnvironmentVariable('PATH', 'Machine'))" | Write-Host

        Set-Location \ | Out-Default | Write-Host
        # cmd /C git clone https://github.com/robe070/cookbooks.git $GitRepo '2>&1'
        Run-ExitCode 'git' @('clone', "https://github.com/$GitUserName/cookbooks.git", $GitRepo) | Out-Default | Write-Host
    }
    else
    {
        # Make sure Git is in the path
        # Note, the Git install overwrites the current environment so need to modify path here
        Add-DirectoryToEnvPathOnce -Directory "C:\Program Files\Git\cmd" | Out-Default | Write-Host
        Write-Debug "Path = $([Environment]::GetEnvironmentVariable('PATH', 'Machine'))" | Write-Host
        $Update = $true
    }
    Write-Host "Git installed"

    Write-Debug "Path = $([Environment]::GetEnvironmentVariable('PATH', 'Machine'))" | Write-Host

    # Ensure we cope with an existing repo, not just a new clone...
    Set-Location $GitRepoPath | Out-Default | Write-Host
    # Throw away any local changes
    cmd /c git reset --hard HEAD '2>&1' | Out-Default | Write-Host
    # Ensure we have all changes
    cmd /c git fetch --all '2>&1' | Out-Default | Write-Host
    if ($Branch -Match "refs/pull/") {
      $BRANCHNAME = 'pr_branch'
      $PRID = $Branch.split("/")[2]
      Write-Host "fetching PR changes pull/$PRID/head:$BRANCHNAME"
      cmd /c git fetch origin pull/$PRID/head:$BRANCHNAME '2>&1' | Out-Default | Write-Host
      if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 128)
      {
          cmd /c exit $LastExitCode;
          throw 'Git checkout failed'
      }
      Write-Host "checkout to branch $BRANCHNAME"
      cmd /c git checkout -f $BRANCHNAME  '2>&1' | Out-Default | Write-Host
      if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 128)
      {
          cmd /c exit $LastExitCode;
          throw 'Git checkout failed'
      }
    } else {
      # Check out a potentially different branch
      Write-Host "Branch: $Branch"
      cmd /c git checkout -f $Branch  '2>&1' | Out-Default | Write-Host
      if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 128)
      {
          cmd /c exit $LastExitCode;
          throw 'Git checkout failed'
      }
      # Finally make sure the current branch matches the origin
      cmd /c git pull '2>&1' | Out-Default | Write-Host
    }
    Write-Debug "Path = $([Environment]::GetEnvironmentVariable('PATH', 'Machine'))" | Write-Host
} catch {
    $_
    Write-Host "installGit.ps1 is the <No file> in the stack dump below"
    $PSItem.ScriptStackTrace | Out-Default | Write-Host
    if ( $LASTEXITCODE -eq 0 ) {
        cmd /c exit 1
    }
    return
}
