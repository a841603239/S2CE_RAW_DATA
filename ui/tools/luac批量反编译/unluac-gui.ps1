# unluac 批量反编译 GUI
# 需要 Java 8+ 和 unluac_2025_12_23.jar 放在本脚本同一目录

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 找 jar
$jarPath = Join-Path $PSScriptRoot "unluac_2025_12_23.jar"
if (-not (Test-Path $jarPath)) {
    [System.Windows.Forms.MessageBox]::Show("找不到 unluac_2025_12_23.jar`n请把它和本脚本放在同一目录。", "错误")
    exit
}

# 检查 java
$null = & java -version 2>&1
if ($LASTEXITCODE -ne 0) {
    [System.Windows.Forms.MessageBox]::Show("未检测到 Java。`n请先安装 Java 8 或更高版本。", "错误")
    exit
}

# 选择输入文件夹
$fb = New-Object System.Windows.Forms.FolderBrowserDialog
$fb.Description = "选择包含 .luac 文件的文件夹"
if ($fb.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit }
$srcFolder = $fb.SelectedPath

# 选择输出文件夹
$fb2 = New-Object System.Windows.Forms.FolderBrowserDialog
$fb2.Description = "选择输出 .lua 文件的文件夹（取消则输出到源文件夹）"
if ($fb2.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $outFolder = $fb2.SelectedPath
} else {
    $outFolder = $srcFolder
}

# 找所有 luac 文件
$files = Get-ChildItem -Path $srcFolder -Filter *.luac -File -Recurse
if ($files.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("未找到 .luac 文件。", "提示")
    exit
}

# 进度窗口
$form = New-Object System.Windows.Forms.Form
$form.Text = "unluac 批量反编译"
$form.Size = New-Object System.Drawing.Size(520, 180)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(15, 15)
$label.Size = New-Object System.Drawing.Size(480, 40)
$label.Text = "准备中..."
$form.Controls.Add($label)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(15, 60)
$progress.Size = New-Object System.Drawing.Size(480, 25)
$progress.Minimum = 0
$progress.Maximum = $files.Count
$form.Controls.Add($progress)

$form.Show()
$form.Refresh()

$success = 0
$failed = 0
$failedList = @()
$i = 0

foreach ($file in $files) {
    $i++
    $label.Text = "正在处理 ($i/$($files.Count)): $($file.Name)"
    $progress.Value = $i
    $form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()

    # 保留目录结构
    $relPath = $file.FullName.Substring($srcFolder.Length).TrimStart('\')
    $relDir  = [System.IO.Path]::GetDirectoryName($relPath)
    $targetDir = if ($relDir) { Join-Path $outFolder $relDir } else { $outFolder }
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    $outFile = Join-Path $targetDir ($file.BaseName + ".lua")

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "java"
        $psi.Arguments = "-jar `"$jarPath`" `"$($file.FullName)`""
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow  = $true
        $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8

        $proc   = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()

        if ($proc.ExitCode -eq 0 -and $stdout) {
            $utf8 = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($outFile, $stdout, $utf8)
            $success++
        } else {
            $failed++
            $failedList += $file.Name
        }
    } catch {
        $failed++
        $failedList += $file.Name
    }
}

$form.Close()

$msg = "完成！`n`n成功：$success 个`n失败：$failed 个`n`n输出目录：`n$outFolder"
if ($failedList.Count -gt 0) {
    $msg += "`n`n失败文件（前 20 个）：`n" + (($failedList | Select-Object -First 20) -join "`n")
}
[System.Windows.Forms.MessageBox]::Show($msg, "结果")