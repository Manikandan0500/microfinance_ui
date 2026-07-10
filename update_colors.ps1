$dir = 'c:\BBot - LMS\MICRO-FINANCE\microfinance_ui\lib\programs'
Get-ChildItem $dir -Filter '*.dart' | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_.FullName)
    $newContent = $content.Replace('0xFF1E2640', '0xFF0A1628')
    $newContent = $newContent.Replace('0xFF2A5C91', '0xFF152238')
    if ($content -ne $newContent) {
        [System.IO.File]::WriteAllText($_.FullName, $newContent)
        Write-Host "Updated: $($_.Name)"
    }
}
