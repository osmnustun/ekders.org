# Ek Ders Hesaplama - Production Deployment Script
# Bu script projeyi production için hazırlar ve FTP ile deploy eder

# =============================================================================
# FTP DEPLOYMENT AYARLARI
# =============================================================================

# FTP sunucu ayarları
$FTP_SERVER = "ftp.osmanustun.tr"
$FTP_USERNAME = "osman"
$FTP_PASSWORD = "Server2025."
$FTP_REMOTE_PATH = "/ekders"

Write-Host "📋 FTP konfigürasyonu tanımlandı" -ForegroundColor Green
Write-Host "🎯 FTP Server: $FTP_SERVER" -ForegroundColor Cyan
Write-Host "📁 Remote Path: $FTP_REMOTE_PATH" -ForegroundColor Cyan
Write-Host "👤 Username: $FTP_USERNAME" -ForegroundColor Cyan

# =============================================================================
# FTP BAĞLANTI TEST FONKSIYONU
# =============================================================================

function Test-FtpConnection {
    param(
        [string]$Server,
        [string]$Username,
        [string]$Password,
        [string]$RemotePath
    )
    
    try {
        Write-Host ""
        Write-Host "🔍 FTP bağlantısı test ediliyor..." -ForegroundColor Yellow
        
        # FTP bağlantısı oluştur
        $ftpUri = "ftp://$Server$RemotePath"
        $request = [System.Net.FtpWebRequest]::Create($ftpUri)
        $request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        $request.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
        $request.UseBinary = $true
        $request.UsePassive = $true
        $request.KeepAlive = $false
        $request.Timeout = 30000
        
        # Bağlantıyı test et
        $response = $request.GetResponse()
        $stream = $response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $content = $reader.ReadToEnd()
        
        $reader.Close()
        $stream.Close()
        $response.Close()
        
        Write-Host "✅ FTP bağlantısı başarılı!" -ForegroundColor Green
        Write-Host "📁 Remote dizin içeriği:" -ForegroundColor Cyan
        
        if ($content -and $content.Trim()) {
            $lines = $content -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
            if ($lines.Count -gt 0) {
                Write-Host "   📊 Toplam $($lines.Count) öğe bulundu:" -ForegroundColor Yellow
                foreach ($line in $lines) {
                    $trimmedLine = $line.Trim()
                    if ($trimmedLine) {
                        # Dosya mı klasör mü kontrol et
                        if ($trimmedLine -match "^d") {
                            Write-Host "   📁 $trimmedLine" -ForegroundColor Blue
                        } else {
                            Write-Host "   📄 $trimmedLine" -ForegroundColor Gray
                        }
                    }
                }
            } else {
                Write-Host "   📂 Dizin boş görünüyor" -ForegroundColor Yellow
            }
        } else {
            Write-Host "   ⚠️ İçerik alınamadı - dizin boş olabilir veya liste formatı farklı olabilir" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Host "❌ FTP bağlantı hatası: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# FTP bağlantısını test et
$connectionTest = Test-FtpConnection -Server $FTP_SERVER -Username $FTP_USERNAME -Password $FTP_PASSWORD -RemotePath $FTP_REMOTE_PATH

if (-not $connectionTest) {
    Write-Host ""
    Write-Host "🛑 FTP bağlantısı başarısız! Deployment durduruluyor." -ForegroundColor Red
    exit 1
}

# =============================================================================
# DEPLOYMENT PIPELINE
# =============================================================================

Write-Host ""
Write-Host "🚀 Ek Ders Hesaplama Projesi - Production Build & Deploy" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green

# 1. CLEAN & BUILD
$projectFile = "ekders.org.csproj"

Write-Host ""
Write-Host "🧹 1. Proje temizleniyor..." -ForegroundColor Yellow
dotnet clean $projectFile --configuration Release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Clean işlemi başarısız!" -ForegroundColor Red
    exit 1
}

# obj ve bin klasörlerini tamamen temizle
Write-Host "�️  2. Obj ve bin klasörleri temizleniyor..." -ForegroundColor Yellow
if (Test-Path ".\obj") { Remove-Item ".\obj" -Recurse -Force }
if (Test-Path ".\bin") { Remove-Item ".\bin" -Recurse -Force }

Write-Host "�📦 3. Dependencies restore ediliyor..." -ForegroundColor Yellow
dotnet restore $projectFile
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Restore işlemi başarısız!" -ForegroundColor Red
    exit 1
}

Write-Host "🔨 4. Proje Release mode'da build ediliyor..." -ForegroundColor Yellow
dotnet build $projectFile --configuration Release --no-restore
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build işlemi başarısız!" -ForegroundColor Red
    exit 1
}

# 2. PUBLISH
Write-Host "📤 5. Proje publish ediliyor..." -ForegroundColor Yellow

# Tüm çıktı klasörlerini temizle
$publishPath = "C:\temp\ekders-deploy"
if (Test-Path $publishPath) { 
    Remove-Item $publishPath -Recurse -Force 
    Write-Host "🗑️  Eski publish klasörü temizlendi" -ForegroundColor Gray
}
if (Test-Path ".\publish") { 
    Remove-Item ".\publish" -Recurse -Force 
    Write-Host "🗑️  Eski local publish klasörü temizlendi" -ForegroundColor Gray
}
if (Test-Path ".\release-output") { 
    Remove-Item ".\release-output" -Recurse -Force 
    Write-Host "🗑️  Eski release-output klasörü temizlendi" -ForegroundColor Gray
}

# Temp klasörde publish et
New-Item -ItemType Directory -Path $publishPath -Force | Out-Null
dotnet publish $projectFile --configuration Release --output $publishPath --verbosity quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Publish işlemi başarısız!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build ve Publish işlemleri tamamlandı!" -ForegroundColor Green

# 3. FTP UPLOAD FUNCTIONS
function Upload-FileToFtp {
    param(
        [string]$LocalPath,
        [string]$RemotePath,
        [string]$Server,
        [string]$Username,
        [string]$Password
    )
    
    try {
        $ftpUri = "ftp://$Server$RemotePath"
        $request = [System.Net.FtpWebRequest]::Create($ftpUri)
        Write-Host "Uploading to $ftpUri"
        $request.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
        $request.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
        $request.UseBinary = $true
        $request.UsePassive = $true
        $request.KeepAlive = $false
        
        $fileContent = [System.IO.File]::ReadAllBytes($LocalPath)
        $request.ContentLength = $fileContent.Length
        
        $requestStream = $request.GetRequestStream()
        $requestStream.Write($fileContent, 0, $fileContent.Length)
        $requestStream.Close()
        
        $response = $request.GetResponse()
        $response.Close()
        
        return $true
    }
    catch {
        Write-Host "❌ Upload hatası: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Delete-FtpFile {
    param(
        [string]$RemotePath,
        [string]$Server,
        [string]$Username,
        [string]$Password
    )
    
    try {
        $ftpUri = "ftp://$Server$RemotePath"
        $request = [System.Net.FtpWebRequest]::Create($ftpUri)
        $request.Method = [System.Net.WebRequestMethods+Ftp]::DeleteFile
        $request.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
        $request.UsePassive = $true
        $request.KeepAlive = $false
        
        $response = $request.GetResponse()
        $response.Close()
        
        return $true
    }
    catch {
        Write-Host "⚠️ Delete hatası: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

function Upload-DirectoryRecursive {
    param(
        [string]$LocalDir,
        [string]$RemoteDir,
        [string]$Server,
        [string]$Username,
        [string]$Password
    )
    
    $uploadCount = 0
    $errorCount = 0
    
    # Tüm dosyaları al
    $files = Get-ChildItem -Path $LocalDir -Recurse -File
    $totalFiles = $files.Count
    
    Write-Host "📊 Toplam $totalFiles dosya upload edilecek..." -ForegroundColor Cyan
    
    foreach ($file in $files) {
        $uploadCount++
        
        # Relative path'i doğru hesapla
        $localDirResolved = (Resolve-Path $LocalDir).Path
        $relativePath = $file.FullName.Substring($localDirResolved.Length).Replace('\', '/')
        
        # Remote path'i temizle - ekstra slash'ları kaldır
        $remotePath = "$RemoteDir$relativePath"
        $remotePath = $remotePath -replace '/+', '/'
        
        Write-Progress -Activity "FTP Upload" -Status "Uploading: $($file.Name)" -PercentComplete (($uploadCount / $totalFiles) * 100)
        
        $success = Upload-FileToFtp -LocalPath $file.FullName -RemotePath $remotePath -Server $Server -Username $Username -Password $Password
        
        if ($success) {
            Write-Host "✅ [$uploadCount/$totalFiles] $relativePath" -ForegroundColor Green
        } else {
            Write-Host "❌ [$uploadCount/$totalFiles] $relativePath" -ForegroundColor Red
            $errorCount++
        }
    }
    
    Write-Progress -Activity "FTP Upload" -Completed
    
    return @{
        TotalFiles = $totalFiles
        UploadedFiles = ($totalFiles - $errorCount)
        ErrorCount = $errorCount
    }
}

# 4. ZERO-DOWNTIME DEPLOYMENT
Write-Host ""
Write-Host "🛑 6. App Offline dosyası yükleniyor (Zero-downtime başlatılıyor)..." -ForegroundColor Yellow

# app_offline.htm yükle
$appOfflineSuccess = Upload-FileToFtp -LocalPath ".\app_offline.htm" -RemotePath "$FTP_REMOTE_PATH/app_offline.htm" -Server $FTP_SERVER -Username $FTP_USERNAME -Password $FTP_PASSWORD

if ($appOfflineSuccess) {
    Write-Host "✅ App Offline dosyası yüklendi - Site geçici olarak offline" -ForegroundColor Green
} else {
    Write-Host "❌ App Offline dosyası yüklenemedi!" -ForegroundColor Red
    exit 1
}

# 5. UPLOAD PROJECT FILES
Write-Host ""
Write-Host "📤 7. Proje dosyaları FTP ile yükleniyor..." -ForegroundColor Yellow

$uploadResult = Upload-DirectoryRecursive -LocalDir $publishPath -RemoteDir $FTP_REMOTE_PATH -Server $FTP_SERVER -Username $FTP_USERNAME -Password $FTP_PASSWORD

Write-Host ""
Write-Host "📊 Upload Özeti:" -ForegroundColor Cyan
Write-Host "   📁 Toplam dosya: $($uploadResult.TotalFiles)" -ForegroundColor White
Write-Host "   ✅ Başarılı: $($uploadResult.UploadedFiles)" -ForegroundColor Green
Write-Host "   ❌ Hatalı: $($uploadResult.ErrorCount)" -ForegroundColor Red

# 6. REMOVE APP OFFLINE
Write-Host ""
Write-Host "🟢 8. App Offline dosyası siliniyor (Site aktif hale getiriliyor)..." -ForegroundColor Yellow

$removeOfflineSuccess = Delete-FtpFile -RemotePath "$FTP_REMOTE_PATH/app_offline.htm" -Server $FTP_SERVER -Username $FTP_USERNAME -Password $FTP_PASSWORD

if ($removeOfflineSuccess) {
    Write-Host "✅ App Offline dosyası silindi - Site tekrar online!" -ForegroundColor Green
} else {
    Write-Host "⚠️ App Offline dosyası silinemedi - Manuel olarak silinmesi gerekebilir" -ForegroundColor Yellow
}

# 7. DEPLOYMENT SUMMARY
Write-Host ""
Write-Host "🎉 DEPLOYMENT TAMAMLANDI!" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host "🌐 Site URL: http://osmanustun.tr/ekders" -ForegroundColor Cyan
Write-Host "📁 Upload edilen dosya sayısı: $($uploadResult.UploadedFiles)/$($uploadResult.TotalFiles)" -ForegroundColor White

if ($uploadResult.ErrorCount -gt 0) {
    Write-Host "⚠️  $($uploadResult.ErrorCount) dosyada hata oluştu" -ForegroundColor Yellow
    Write-Host "🔍 Hata detayları yukarıdaki logları kontrol edin" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✨ Ek Ders Hesaplama sistemi başarıyla deploy edildi!" -ForegroundColor Green