# ==============================================================================
# SkyCAD Daily Auto Git Sync Script (Commit, Pull/Update from Remote, Push, Email)
# Runs daily at 09:00 AM via Windows Task Scheduler
# ==============================================================================

$ErrorActionPreference = "Continue"
$RepoPath = "C:\Workspaces\SkyCAD"
$LogFile = Join-Path $RepoPath "scripts\auto-git-sync.log"
$EmailConfigFile = Join-Path $RepoPath "scripts\email-config.xml"

$RunLogs = New-Object System.Collections.Generic.List[string]
$ChangedFilesList = New-Object System.Collections.Generic.List[string]
$CommitMsg = "변경 사항 없음"
$CommitHash = "-"
$RemoteAheadCount = 0
$LocalAheadCount = 0
$PushStatus = "푸시 대상 없음"
$HasError = $false

function Write-SyncLog {
    param([string]$Message)
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Line = "[$TimeStamp] $Message"
    Write-Output $Line
    $RunLogs.Add($Line)
    Add-Content -Path $LogFile -Value $Line -Encoding UTF8
}

Set-Location -Path $RepoPath
Write-SyncLog "=== SkyCAD 정기 Git 자동 동기화 시작 ==="

# 1. .git/index.lock 대기 (다른 Git 프로세스와 충돌 방지)
$LockFile = Join-Path $RepoPath ".git\index.lock"
$RetryCount = 0
while ((Test-Path $LockFile) -and ($RetryCount -lt 15)) {
    Write-SyncLog "Git 잠금 파일(.git/index.lock) 감지됨. 2초 대기 중... ($RetryCount/15)"
    Start-Sleep -Seconds 2
    $RetryCount++
}

# 2. 원격 저장소(origin/main) 최신 상태 가져오기
Write-SyncLog "git fetch origin main 실행..."
git fetch origin main 2>&1 | ForEach-Object { Write-SyncLog "  $_" }

# 3. 로컬 변경 사항 확인 및 커밋
$StatusLines = @(git status --porcelain)
if ($StatusLines.Count -gt 0) {
    $FileCount = $StatusLines.Count
    foreach ($s in $StatusLines) {
        $ChangedFilesList.Add($s.Trim())
    }
    $SampleFiles = ($StatusLines | ForEach-Object {
        $line = $_.Trim()
        $path = ($line -replace '^[MADRCU\?!]{1,2}\s+', '').Trim('"')
        [System.IO.Path]::GetFileNameWithoutExtension($path)
    } | Select-Object -Unique -First 3) -join ", "

    $DateStr = Get-Date -Format "yyMMdd"
    $CommitMsg = "chore(skycad): 정기 자동 커밋 ($DateStr) - $SampleFiles 등 ${FileCount}개 항목 업데이트"

    Write-SyncLog "로컬 변경 사항 ${FileCount}건 감지. 스테이징 및 커밋 진행: $CommitMsg"
    git add -A 2>&1 | ForEach-Object { Write-SyncLog "  $_" }
    git commit -m $CommitMsg 2>&1 | ForEach-Object { Write-SyncLog "  $_" }
    $CommitHash = (git rev-parse --short HEAD 2>$null)
} else {
    Write-SyncLog "로컬 작업 트리에 변경 사항이 없습니다."
}

# 4. 원격 저장소(origin/main)에 더 앞선 커밋이 있는지 확인 및 업데이트
$RemoteAheadCount = [int](git rev-list HEAD..origin/main --count 2>$null)
if ($RemoteAheadCount -gt 0) {
    Write-SyncLog "원격 저장소(origin/main)가 ${RemoteAheadCount}개 커밋 앞서 있습니다. 원격 내용으로 업데이트(rebase) 진행..."
    # rebase 시 upstream(origin/main)이 ours이므로 충돌 시 원격 내용을 우선 반영(-X ours)
    git pull --rebase -X ours origin main 2>&1 | ForEach-Object { Write-SyncLog "  $_" }

    # 만약 바이너리 파일 등으로 rebase가 멈춘 경우 원격 버전(--ours) 선택 후 계속 진행
    if (Test-Path (Join-Path $RepoPath ".git\rebase-merge")) {
        Write-SyncLog "Rebase 충돌 감지: 원격 저장소(origin/main) 파일 버전을 우선 적용합니다."
        git checkout --ours . 2>&1 | ForEach-Object { Write-SyncLog "  $_" }
        git add -A 2>&1 | ForEach-Object { Write-SyncLog "  $_" }
        $env:GIT_EDITOR = "true"
        git rebase --continue 2>&1 | ForEach-Object { Write-SyncLog "  $_" }
    }
    $CommitHash = (git rev-parse --short HEAD 2>$null)
} else {
    Write-SyncLog "원격 저장소(origin/main)에 추가로 앞선 커밋이 없습니다."
}

# 5. 로컬이 원격보다 앞선 커밋이 있으면 푸시
$LocalAheadCount = [int](git rev-list origin/main..HEAD --count 2>$null)
if ($LocalAheadCount -gt 0) {
    Write-SyncLog "로컬 커밋 ${LocalAheadCount}건을 origin/main으로 푸시합니다..."
    $PushOutput = git push origin main 2>&1
    $PushExitCode = $LASTEXITCODE
    $PushOutput | ForEach-Object { Write-SyncLog "  $_" }
    if ($PushExitCode -eq 0) {
        $PushStatus = "성공 (${LocalAheadCount}건 푸시 완료, HEAD: $CommitHash)"
        Write-SyncLog "푸시 완료."
    } else {
        $PushStatus = "실패 (종료 코드: $PushExitCode)"
        $HasError = $true
        Write-SyncLog "푸시 실패!"
    }
} else {
    Write-SyncLog "푸시할 새로운 커밋이 없습니다."
}

Write-SyncLog "=== SkyCAD 정기 Git 자동 동기화 종료 ==="

# 6. 이메일 요약 발송 (scripts/email-config.xml 설정 파일이 존재하는 경우)
if (Test-Path $EmailConfigFile) {
    try {
        $EmailCfg = Import-Clixml -Path $EmailConfigFile
        $HasActivity = ($ChangedFilesList.Count -gt 0) -or ($RemoteAheadCount -gt 0) -or ($LocalAheadCount -gt 0) -or $HasError

        if ((-not $EmailCfg.SendOnlyOnChanges) -or $HasActivity) {
            $DateTitle = Get-Date -Format "yyyy-MM-dd HH:mm"
            $StatusBadge = if ($HasError) { "[오류]" } elseif ($HasActivity) { "[동기화 완료]" } else { "[변경 없음]" }
            $Subject = "$StatusBadge SkyCAD 일일 Git 자동 동기화 보고 ($DateTitle)"

            $FilesHtml = if ($ChangedFilesList.Count -gt 0) {
                "<ul>" + (($ChangedFilesList | ForEach-Object { "<li><code>$_</code></li>" }) -join "") + "</ul>"
            } else {
                "<p>변경된 파일이 없습니다.</p>"
            }

            $LogsHtml = ($RunLogs -join "`r`n")
            $Body = @"
<div style="font-family: 'Malgun Gothic', sans-serif; line-height: 1.6;">
  <h2>SkyCAD 정기 Git 자동 동기화 결과 요약</h2>
  <table border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse; border-color: #ddd;">
    <tr><th style="background:#f5f5f5; text-align:left;">실행 시각</th><td>$DateTitle</td></tr>
    <tr><th style="background:#f5f5f5; text-align:left;">로컬 변경 파일 수</th><td>$($ChangedFilesList.Count)건</td></tr>
    <tr><th style="background:#f5f5f5; text-align:left;">커밋 메시지</th><td>$CommitMsg (<code>$CommitHash</code>)</td></tr>
    <tr><th style="background:#f5f5f5; text-align:left;">원격 선행 커밋 업데이트</th><td>${RemoteAheadCount}건</td></tr>
    <tr><th style="background:#f5f5f5; text-align:left;">원격 저장소 푸시 결과</th><td><b>$PushStatus</b></td></tr>
  </table>
  <h3>변경된 파일 목록</h3>
  $FilesHtml
  <h3>상세 실행 로그</h3>
  <pre style="background:#f8f9fa; padding:10px; border:1px solid #e9ecef; font-size:12px;">$LogsHtml</pre>
</div>
"@
            Send-MailMessage -SmtpServer $EmailCfg.SmtpServer -Port $EmailCfg.SmtpPort -UseSsl `
                -Credential $EmailCfg.Credential -From $EmailCfg.FromEmail -To $EmailCfg.ToEmail `
                -Subject $Subject -Body $Body -BodyAsHtml -Encoding UTF8 -ErrorAction Stop
            Write-SyncLog "이메일 요약 보고서 발송 완료 ($($EmailCfg.ToEmail))"
        } else {
            Write-SyncLog "변경 사항이 없어 이메일 발송을 건너뜁니다 (SendOnlyOnChanges=True)."
        }
    } catch {
        Write-SyncLog "이메일 발송 중 오류 발생: $($_.Exception.Message)"
    }
}
