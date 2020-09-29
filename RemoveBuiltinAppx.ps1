<#
.SYNOPSIS
    Remove built-in appx from Windows 10.

.DESCRIPTION
    This script will remove all built-in appx with a provisioning package that's not specified in the 'white-list' in this script.
	Documentatie: https://docs.microsoft.com/en-us/windows/application-management/apps-in-windows-10

.EXAMPLE
    .\RemoveBuiltinAppx.ps1

.NOTES
    FileName:    RemoveBuiltinAppx.ps1
    Author:      Mark Messink
    Contact:     
    Created:     2020-09-29
    Updated:     

    Version history:
    1.0.0 - (2020-07-05) First script, Windows 10 version 2004
	1.0.1 - (2020-09-29) Windows 10 version 20H2
#>
Begin {
    # White list of appx packages to keep installed
	# XBOX and Zune are not listed, and will be removed by default
    $WhiteListedAppx = New-Object -TypeName System.Collections.ArrayList
    $WhiteListedAppx.AddRange(@(
		###	"Microsoft.549981C3F5F10", # Cortana
		###	"Microsoft.BingWeather",
			"Microsoft.DesktopAppInstaller",
		###	"Microsoft.GetHelp",
		###	"Microsoft.GetStarted",
			"Microsoft.HEIFImageExtension",
			"Microsoft.Microsoft3DViewer",
			"Microsoft.MicrosoftOfficeHub",
		###	"Microsoft.MicrosoftSolitaireCollection",
		###	"Microsoft.MicrosoftStickyNotes",
		###	"Microsoft.MixedReality.Portal",
			"Microsoft.MSPaint",
		###	"Microsoft.Office.OneNote",
		###	"Microsoft.People",
		###	"Microsoft.ScreenSketch",
		###	"Microsoft.SkypeApp",
			"Microsoft.StorePurchaseApp",
			"Microsoft.VCLibs.140.00",
			"Microsoft.VP9VideoExtensions",
		###	"Microsoft.Wallet",
			"Microsoft.WebMediaExtensions",
			"Microsoft.WebpImageExtension",
		###	"Microsoft.Windows.Photos",
		###	"Microsoft.WindowsAlarms",
			"Microsoft.WindowsCalculator", 
		###	"Microsoft.WindowsCamera", 
		###	"Microsoft.WindowsCommunicationsApps", # Mail, Calendar etc
		###	"Microsoft.WindowsFeedbackHub", 
			"Microsoft.WindowsMaps" #, 
		###	"Microsoft.WindowsSoundRecorder", 
		###	"Microsoft.YourPhone"
		
	# APPx that shouldn't be removed
	
		"Microsoft.WindowsStore", # Cannot be reinstalled
	
    ))

}
Process {
    # Functions
    function Write-LogEntry {
        param(
            [parameter(Mandatory=$true, HelpMessage="Value added to the logfile.")]
            [ValidateNotNullOrEmpty()]
            [string]$Value,

            [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
            [ValidateNotNullOrEmpty()]
            [string]$FileName = "ilog_RemoveAppx.txt"
        )
        # Determine log file location
        $LogFilePath = Join-Path -Path C:\IntuneLogs -ChildPath "$($FileName)"

        # Add value to log file
        try {
            Out-File -InputObject $Value -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to $($FileName) file"
        }
    }

	# Aanmaken standaard logpath (als deze nog niet bestaat)
	$path = "C:\IntuneLogs"
	If(!(test-path $path))
	{
      New-Item -ItemType Directory -Force -Path $path
	}

    # Initial logging
	$date = get-date
    Write-LogEntry -Value "$date"
    Write-LogEntry -Value "Starting built-in AppxPackage, AppxProvisioningPackage removal process"

    # Determine provisioned apps
    $AppArrayList = Get-AppxProvisionedPackage -Online | Select-Object -ExpandProperty DisplayName

    # Loop through the list of appx packages
    foreach ($App in $AppArrayList) {
		Write-LogEntry -Value "-------------------------------------------------------------------------------"
        Write-LogEntry -Value "Processing appx package: $($App)"

        # If application name not in appx package white list, remove AppxPackage and AppxProvisioningPackage
        if (($App -in $WhiteListedAppx)) {
            Write-LogEntry -Value "Skipping excluded application package: $($App)"
        }
        else {
            # Gather package names
            $AppPackageFullName = Get-AppxPackage -Name $App | Select-Object -ExpandProperty PackageFullName -First 1
            $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App } | Select-Object -ExpandProperty PackageName -First 1

            # Attempt to remove AppxPackage
            if ($AppPackageFullName -ne $null) {
                try {
                    Write-LogEntry -Value "Removing AppxPackage: $($AppPackageFullName)"
                    Remove-AppxPackage -Package $AppPackageFullName -ErrorAction Stop | Out-Null
                }
                catch [System.Exception] {
                    Write-LogEntry -Value "Removing AppxPackage '$($AppPackageFullName)' failed: $($_.Exception.Message)"
                }
            }
            else {
                Write-LogEntry -Value "Unable to locate AppxPackage for current app: $($App)"
            }

            # Attempt to remove AppxProvisioningPackage
            if ($AppProvisioningPackageName -ne $null) {
                try {
                    Write-LogEntry -Value "Removing AppxProvisioningPackage: $($AppProvisioningPackageName)"
                    Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -ErrorAction Stop | Out-Null
                }
                catch [System.Exception] {
                    Write-LogEntry -Value "Removing AppxProvisioningPackage '$($AppProvisioningPackageName)' failed: $($_.Exception.Message)"
                }
            }
            else {
                Write-LogEntry -Value "Unable to locate AppxProvisioningPackage for current app: $($App)"
            }
        }
    }

    # Complete
	Write-LogEntry -Value "-------------------------------------------------------------------------------"
    Write-LogEntry -Value "Completed built-in AppxPackage, AppxProvisioningPackage removal process"
}