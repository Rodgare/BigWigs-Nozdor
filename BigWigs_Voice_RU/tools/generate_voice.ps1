param(
    [switch]$Force,
    [int]$Limit = 0,
    [switch]$IncludeEnglish,
    [switch]$EnglishOnly,
    [switch]$HighQuality,
    [switch]$LowQuality,
    [string]$Csv = ""
)

$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$voiceRoot = Split-Path -Parent $here
if ($Csv) {
    $csv = (Resolve-Path -LiteralPath $Csv).Path
} else {
    $csv = Join-Path $here "voice_manifest.csv"
}
$sounds = Join-Path $voiceRoot "Sounds"

if (-not (Test-Path -LiteralPath $csv)) {
    throw "Manifest not found: $csv. Run: python voice_manifest.py"
}

New-Item -ItemType Directory -Force -Path $sounds | Out-Null

Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

$ruVoice = $synth.GetInstalledVoices() |
    Where-Object { $_.VoiceInfo.Culture.Name -eq "ru-RU" } |
    Select-Object -First 1

if ($ruVoice) {
    $synth.SelectVoice($ruVoice.VoiceInfo.Name)
    Write-Host "Voice: $($ruVoice.VoiceInfo.Name)"
} else {
    Write-Warning "Russian SAPI voice not found, using the default voice."
}

$synth.Rate = 0
$synth.Volume = 100

# 11 kHz / 16-bit / mono is roughly half the size of the default 22 kHz WAV.
$sampleRate = 11025
$bits = [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen
if ($HighQuality) {
    $sampleRate = 22050
    $bits = [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen
} elseif ($LowQuality) {
    $sampleRate = 11025
    $bits = [System.Speech.AudioFormat.AudioBitsPerSample]::Eight
}
$format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(
    $sampleRate,
    $bits,
    [System.Speech.AudioFormat.AudioChannel]::Mono
)

$rows = Import-Csv -LiteralPath $csv -Encoding UTF8
$made = 0
$skipped = 0
$skippedEnglish = 0

foreach ($row in $rows) {
    $key = ([string]$row.key).Trim()
    $text = ([string]$row.text).Trim()
    if (-not $key -or -not $text) { continue }

    $isRussian = [regex]::IsMatch($text, "[\u0400-\u04FF]")
    if ($EnglishOnly -and $isRussian) { continue }
    if (-not $EnglishOnly -and -not $IncludeEnglish -and -not $isRussian) {
        $skippedEnglish++
        continue
    }

    $out = Join-Path $sounds ($key + ".wav")
    $old = Get-ChildItem -LiteralPath $sounds -Filter ($key + ".*") -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in ".ogg", ".mp3", ".wav" }

    if ($old -and -not $Force) {
        $skipped++
        continue
    }
    if ($old) {
        $old | Remove-Item -Force
    }

    try {
        $synth.SetOutputToWaveFile($out, $format)
        $synth.Speak($text)
        $made++
    } finally {
        $synth.SetOutputToNull()
    }

    if ($Limit -gt 0 -and $made -ge $Limit) {
        break
    }
}

$synth.Dispose()
Write-Host "Generated: $made, skipped existing: $skipped, skipped non-Russian: $skippedEnglish"
