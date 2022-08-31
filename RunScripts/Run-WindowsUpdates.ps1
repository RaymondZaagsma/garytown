<# Control Windows Update via PowerShell
Gary Blok - GARYTOWN.COM
NOTE: I'm using this in a RUN SCRIPT, so I hav the Parameters set to STRING, and in the RUN SCRIPT, I Create a list of options (TRUE & FALSE).
In a normal script, you wouldn't do this... so modify for your deployment method.

This was also intended to be used with ConfigMgr, if you're not, feel free to remove the $CMReboot & Corrisponding Function

Installing Updates using this Method does NOT notify the user, and does NOT let the user know that updates need to be applied at the next reboot.  It's 100% hidden.

#>
[CmdletBinding()]
    Param (
		    [Parameter(Mandatory=$true)][string]$CMReboot = "FALSE",
            [Parameter(Mandatory=$true)][string]$RestartNow = "FALSE",
            [Parameter(Mandatory=$true)][string]$Install = "FALSE"
	    )

Function Restart-ComputerCM {
    if (Test-Path -Path "C:\windows\ccm\CcmRestart.exe"){

        $time = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        $Null = New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'RebootBy' -Value $time -PropertyType QWord -Force -ea SilentlyContinue;
        $Null = New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'RebootValueInUTC' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
        $Null = New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'NotifyUI' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
        $Null = New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'HardReboot' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;
        $Null = New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'OverrideRebootWindowTime' -Value 0 -PropertyType QWord -Force -ea SilentlyContinue;
        $Null = New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'OverrideRebootWindow' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;
        $Null = New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'PreferredRebootWindowTypes' -Value @("4") -PropertyType MultiString -Force -ea SilentlyContinue;
        $Null = New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData' -Name 'GraceSeconds' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;

        $CCMRestart = start-process -FilePath C:\windows\ccm\CcmRestart.exe -NoNewWindow -PassThru
    }
    else {
        Write-Output "No CM Client Found"
    }
}

$Results = @(
@{ ResultCode = '0'; Meaning = "Not Started"}
@{ ResultCode = '1'; Meaning = "In Progress"}
@{ ResultCode = '2'; Meaning = "Succeeded"}
@{ ResultCode = '3'; Meaning = "Succeeded With Errors"}
@{ ResultCode = '4'; Meaning = "Failed"}
@{ ResultCode = '5'; Meaning = "Aborted"}
)

$WUDownloader=(New-Object -ComObject Microsoft.Update.Session).CreateUpdateDownloader()
$WUInstaller=(New-Object -ComObject Microsoft.Update.Session).CreateUpdateInstaller()
$WUUpdates=New-Object -ComObject Microsoft.Update.UpdateColl
((New-Object -ComObject Microsoft.Update.Session).CreateupdateSearcher().Search("IsInstalled=0 and Type='Software'")).Updates|%{
    if(!$_.EulaAccepted){$_.EulaAccepted=$true}
    if ($_.Title -notmatch "Preview"){[void]$WUUpdates.Add($_)}
}

if ($WUUpdates.Count -ge 1){
    if ($Install -eq "TRUE"){
        $WUInstaller.ForceQuiet=$true
        $WUInstaller.Updates=$WUUpdates
        $WUDownloader.Updates=$WUUpdates
        write-host "Downloading " $WUDownloader.Updates.count "Updates"
        foreach ($update in $WUInstaller.Updates){Write-Host "$($update.Title)"}
        $WUDownloader.Download()
        write-host "Installing " $WUInstaller.Updates.count "Updates"
        $Install = $WUInstaller.Install()
        $ResultMeaning = ($Results | Where-Object {$_.ResultCode -eq $Install.ResultCode}).Meaning
        Write-Output $ResultMeaning
        if ($Install.RebootRequired -eq $true){
            if ($CMReboot -eq "TRUE"){Restart-ComputerCM}
            if ($RestartNow -eq "TRUE") {Restart-Computer -Force}
        }
    }
    else
        {
        Write-Output "Available Updates:"
        foreach ($update in $WUUpdates){Write-Host "$($update.Title)"}
     }
} 
else {
    write-host "No updates detected"
}
