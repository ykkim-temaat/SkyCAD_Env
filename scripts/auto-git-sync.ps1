# ==============================================================================
# SkyCAD Daily Auto Git Sync Script (Commit, Pull/Update from Remote, Push, Email)
# Runs daily at 09:00 AM via Windows Task Scheduler
# ==============================================================================

$ErrorActionPreference = "Continue"
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$RepoPath = "C:\Workspaces\SkyCAD"
$NasPath = "Y:\3. 전장설계\SkyCAD_Library"
$LogFile = Join-Path $RepoPath "scripts\auto-git-sync.log"
$EmailConfigFile = Join-Path $RepoPath "scripts\email-config.xml"

$RunLogs = New-Object System.Collections.Generic.List[string]
$ChangedFilesList = New-Object System.Collections.Generic.List[string]
$CommitMsg = "변경 사항 없음"
$CommitHash = (git -C $RepoPath rev-parse --short HEAD 2>$null)
if (-not $CommitHash) { $CommitHash = "-" }
$RemoteAheadCount = 0
$LocalAheadCount = 0
$NasAheadCount = 0
$PushStatus = "푸시 대상 없음"
$NasPushStatus = "푸시 대상 없음"
$NasSynced = $false
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

# 5. 로컬이 원격(origin/main)보다 앞선 커밋이 있으면 푸시
$LocalAheadCount = [int](git rev-list origin/main..HEAD --count 2>$null)
if ($LocalAheadCount -gt 0) {
    Write-SyncLog "로컬 커밋 ${LocalAheadCount}건을 origin/main으로 푸시합니다..."
    $PushOutput = git push origin main 2>&1
    $PushExitCode = $LASTEXITCODE
    $PushOutput | ForEach-Object { Write-SyncLog "  $_" }
    if ($PushExitCode -eq 0) {
        $PushStatus = "성공 (${LocalAheadCount}건 푸시 완료, HEAD: $CommitHash)"
        Write-SyncLog "origin 푸시 완료."
    } else {
        $PushStatus = "실패 (종료 코드: $PushExitCode)"
        $HasError = $true
        Write-SyncLog "origin 푸시 실패!"
    }
} else {
    Write-SyncLog "origin/main으로 푸시할 새로운 커밋이 없습니다."
}

# 5-2. NAS 원격 저장소(nas/main) 강제 미러링 동기화 (미연결 시 안전하게 건너뜀, NAS 자체 변경사항은 무시)
if (Test-Path -Path $NasPath) {
    Write-SyncLog "NAS 서버 연결 확인됨 ($NasPath). 상태 점검 및 동기화 진행..."

    # NAS 내 임의 변경 사항(uncommitted/untracked) 확인 및 강제 초기화
    $NasDirtyLines = @(git -C $NasPath status --porcelain 2>$null)
    if ($LASTEXITCODE -eq 0) {
        if ($NasDirtyLines.Count -gt 0) {
            Write-SyncLog "NAS 저장소 내 임의 변경 사항 $($NasDirtyLines.Count)건 감지됨. 백업/공유 전용 정책에 따라 변경 사항을 무시하고 초기화합니다..."
            git -C $NasPath reset --hard HEAD 2>&1 | ForEach-Object { Write-SyncLog "  $_" }
            git -C $NasPath clean -fd 2>&1 | ForEach-Object { Write-SyncLog "  $_" }
        }

        $LocalHeadFull = (git rev-parse HEAD 2>$null)
        $NasHeadFull = (git -C $NasPath rev-parse HEAD 2>$null)

        if (($LocalHeadFull -ne $NasHeadFull) -or ($NasDirtyLines.Count -gt 0)) {
            $NasAheadCount = [int](git rev-list "$NasHeadFull..$LocalHeadFull" --count 2>$null)
            Write-SyncLog "NAS 저장소를 origin/로컬 최신 상태(HEAD: $CommitHash)와 동일하게 강제 푸시(동기화)합니다..."
            # SMB 네트워크 드라이브에서 updateInstead 체크아웃 시 파일 잠금/충돌 방지를 위해 refs만 먼저 푸시 후 reset 수행
            git -C $NasPath config receive.denyCurrentBranch ignore 2>$null
            $NasPushOutput = git push --force nas main 2>&1
            $NasPushExitCode = $LASTEXITCODE
            $NasPushOutput | ForEach-Object { Write-SyncLog "  $_" }

            # 푸시 후 NAS 작업 트리(working tree)도 main 브랜치와 100% 일치하도록 강제 리셋 및 정리 보장
            git -C $NasPath reset --hard main 2>&1 | ForEach-Object { Write-SyncLog "  $_" }
            git -C $NasPath clean -fd 2>&1 | ForEach-Object { Write-SyncLog "  $_" }

            if ($NasPushExitCode -eq 0) {
                $SyncDetail = if ($NasAheadCount -gt 0) { "${NasAheadCount}건 반영" } else { "작업 트리 초기화 및 동기화" }
                $NasPushStatus = "성공 ($SyncDetail, HEAD: $CommitHash)"
                $NasSynced = $true
                Write-SyncLog "NAS 동기화 완료."
            } else {
                $NasPushStatus = "실패 (종료 코드: $NasPushExitCode)"
                $HasError = $true
                Write-SyncLog "NAS 푸시 실패!"
            }
        } else {
            $NasPushStatus = "최신 상태 유지 (origin과 동일)"
            Write-SyncLog "NAS 저장소(nas/main)가 이미 origin/로컬과 동일합니다."
        }
    } else {
        $NasPushStatus = "건너뜀 (NAS Git 저장소 응답 없음)"
        Write-SyncLog "경고: NAS 경로($NasPath)는 존재하나 Git 상태 조회에 실패하여 NAS 동기화를 건너뜁니다."
    }
} else {
    $NasPushStatus = "건너뜀 (NAS 서버 미연결)"
    Write-SyncLog "NAS 서버($NasPath)가 연결되어 있지 않아 NAS 동기화를 건너뜁니다. (다음 연결 시 자동 동기화)"
}

Write-SyncLog "=== SkyCAD 정기 Git 자동 동기화 종료 ==="

# 6. 이메일 요약 발송 (scripts/email-config.xml 설정 파일이 존재하는 경우)
if (Test-Path $EmailConfigFile) {
    try {
        $EmailCfg = Import-Clixml -Path $EmailConfigFile
        $HasActivity = ($ChangedFilesList.Count -gt 0) -or ($RemoteAheadCount -gt 0) -or ($LocalAheadCount -gt 0) -or $NasSynced -or $HasError

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
    <tr><th style="background:#f5f5f5; text-align:left;">GitHub(origin) 푸시 결과</th><td><b>$PushStatus</b></td></tr>
    <tr><th style="background:#f5f5f5; text-align:left;">NAS(nas) 푸시 결과</th><td><b>$NasPushStatus</b></td></tr>
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
