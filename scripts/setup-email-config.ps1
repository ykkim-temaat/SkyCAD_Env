# ==============================================================================
# SkyCAD Daily Auto Git Sync - Email Notification Setup Script
# Windows DPAPI 암호화를 사용하여 현재 Windows 계정에서만 복호화 가능하도록
# SMTP 인증 정보(Gmail 앱 비밀번호 등)를 scripts/email-config.xml에 안전하게 저장합니다.
# ==============================================================================

param(
    [string]$SmtpServer = "smtp.gmail.com",
    [int]$SmtpPort = 587,
    [string]$FromEmail = "ykkim.temaat@gmail.com",
    [string]$ToEmail = "ykkim.temaat@gmail.com",
    [string]$AppPassword = "",
    [bool]$SendOnlyOnChanges = $false
)

$ConfigPath = Join-Path $PSScriptRoot "email-config.xml"

Write-Host "=== SkyCAD 자동 동기화 이메일 알림 설정 ===" -ForegroundColor Cyan
Write-Host "보내는/받는 기본 이메일: $ToEmail" -ForegroundColor Gray

if ([string]::IsNullOrWhiteSpace($AppPassword)) {
    Write-Host "`n[안내] Gmail을 사용하시는 경우 Google 계정 -> 보안 -> 2단계 인증 -> '앱 비밀번호(16자리)'를 입력해 주세요." -ForegroundColor Yellow
    $SecurePwd = Read-Host -Prompt "앱 비밀번호(App Password)를 입력하세요" -AsSecureString
} else {
    $SecurePwd = ConvertTo-SecureString ($AppPassword -replace '\s+', '') -AsPlainText -Force
}

$Credential = New-Object System.Management.Automation.PSCredential ($FromEmail, $SecurePwd)

$Config = [PSCustomObject]@{
    SmtpServer        = $SmtpServer
    SmtpPort          = $SmtpPort
    FromEmail         = $FromEmail
    ToEmail           = $ToEmail
    Credential        = $Credential
    SendOnlyOnChanges = $SendOnlyOnChanges
}

$Config | Export-Clixml -Path $ConfigPath
Write-Host "`n[완료] 암호화된 이메일 설정이 저장되었습니다: $ConfigPath" -ForegroundColor Green
Write-Host "  (이 파일은 .gitignore에 등록되어 Git에 절대 커밋되지 않으며, 현재 Windows 사용자만 복호화할 수 있습니다.)" -ForegroundColor Gray

# 테스트 메일 발송
Write-Host "`n테스트 메일을 발송합니다 ($ToEmail)..." -ForegroundColor Cyan
try {
    $Subject = "[SkyCAD] 정기 Git 자동 동기화 이메일 알림 연동 완료"
    $Body = @"
<h3>SkyCAD 정기 Git 자동 동기화 알림 설정 완료</h3>
<p>매일 오전 9시 <b>SkyCAD_Daily_Git_Sync</b> 작업 수행 결과가 이 메일 주소로 요약 발송됩니다.</p>
<ul>
  <li><b>대상 워크스페이스</b>: C:\Workspaces\SkyCAD</li>
  <li><b>원격 저장소</b>: git@github.com:ykkim-temaat/SkyCAD_Env.git</li>
  <li><b>발송 조건</b>: $(if ($SendOnlyOnChanges) { "변경 사항 또는 동기화 내역이 있을 때만 발송" } else { "매일 실행 시 결과 요약 발송" })</li>
</ul>
"@
    Send-MailMessage -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl `
        -Credential $Credential -From $FromEmail -To $ToEmail `
        -Subject $Subject -Body $Body -BodyAsHtml -Encoding UTF8 -ErrorAction Stop
    Write-Host "[성공] 테스트 메일이 정상적으로 발송되었습니다! 메일함을 확인해 보세요." -ForegroundColor Green
} catch {
    Write-Host "[오류] 테스트 메일 발송 실패: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "앱 비밀번호(16자리) 또는 네트워크/SMTP 설정을 다시 확인해 주세요." -ForegroundColor Yellow
}
