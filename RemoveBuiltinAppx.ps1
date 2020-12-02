<#
.SYNOPSIS
    Remove built-in appx from Windows 10.

.DESCRIPTION
    This script will remove all built-in appx with a provisioning package that's not specified in the 'white-list' in this script.
	Documentation: https://docs.microsoft.com/en-us/windows/application-management/apps-in-windows-10

.EXAMPLE
    .\RemoveBuiltinAppx.ps1

.NOTES
    FileName:    RemoveBuiltinAppx.ps1
    Author:      Mark Messink
    Contact:     
    Created:     2020-07-05
    Updated:     2020-11-24
	
	Information:
	White list of appx packages to keep installed
	XBOX and Zune are not listed, and will be removed by default
	Create new list --> 'Get-AppxProvisionedPackage -online | FT Displayname'

    Version history:
	1.0.0 - (2020-03-31) Windows 10 version 1803, 1809, 1903, and 1909
    1.0.0 - (2020-07-05) Windows 10 version 2004
	1.0.1 - (2020-10-01) Windows 10 version 20H2
	
	Microsoft Store:
	The Store app can't be removed. If you want to remove and reinstall the Store app, you can only bring Store back by either restoring your system from a backup or resetting your system. 
	Instead of removing the Store app, you should use group policies to hide or disable it.

#>

Begin {
    $WhiteListedAppx = New-Object -TypeName System.Collections.ArrayList
	
<##### Microsoft Edge #####>
	$WhiteListedAppx.AddRange(@(
	"Microsoft.MicrosoftEdge.Stable",
	"Microsoft.MicrosoftEdge.Beta",
	"Microsoft.MicrosoftEdge.Dev"
	))

<##### APPx that shouldn't be removed #####>
	$WhiteListedAppx.AddRange(@(
	"Microsoft.WindowsStore" # unsupported
	))
    	
<##### Version: 1803 #####>
	$WhiteListedAppx.AddRange(@(
	###	"Microsoft.BingWeather",
	"Microsoft.DesktopAppInstaller",
	###	"Microsoft.GetHelp",
	###	"Microsoft.GetStarted",
	### "Microsoft.Messaging", # removed in 20H1
	### "Microsoft.Microsoft3DViewer",
	"Microsoft.MicrosoftOfficeHub",
	###	"Microsoft.MicrosoftSolitaireCollection",
	###	"Microsoft.MicrosoftStickyNotes",
	"Microsoft.MSPaint",
	###	"Microsoft.Office.OneNote",
	### "Microsoft.OneConnect", # removed in 20H1
	###	"Microsoft.People",
	### "Microsoft.Print3D", # removed in 20H1
	###	"Microsoft.SkypeApp",
	"Microsoft.StorePurchaseApp",
	###	"Microsoft.Wallet",
	"Microsoft.WebMediaExtensions",
	"Microsoft.Windows.Photos",
	"Microsoft.WindowsAlarms",
	"Microsoft.WindowsCalculator", 
	"Microsoft.WindowsCamera", 
	###	"Microsoft.WindowsCommunicationsApps", # Mail, Calendar etc
	###	"Microsoft.WindowsFeedbackHub", 
	"Microsoft.WindowsMaps",
	"Microsoft.WindowsSoundRecorder"
	))

<##### Version: 1809 #####>
	$WhiteListedAppx.AddRange(@(
	"Microsoft.HEIFImageExtension",
	###	"Microsoft.MixedReality.Portal",
	###	"Microsoft.ScreenSketch",
	"Microsoft.VP9VideoExtensions",
	"Microsoft.WebpImageExtension",
	"Microsoft.YourPhone"
	))
	
<##### Version: 1903 #####>
	$WhiteListedAppx.AddRange(@(
	### "No new provisioned Windows APPx
	))
	
<##### Version: 1909 #####>
	$WhiteListedAppx.AddRange(@(
	### "No new provisioned Windows APPx
	))
	
<##### Version: 2004 #####>
	$WhiteListedAppx.AddRange(@(
	###	"Microsoft.549981C3F5F10", # Cortana
	"Microsoft.VCLibs.140.00"
	))
	
<##### Version: 20H2 #####>
	$WhiteListedAppx.AddRange(@(
	### "No new provisioned Windows APPx
    ))

<##### Version: 21H1 - Insider Preview #####>
	$WhiteListedAppx.AddRange(@(
	"Microsoft.BingNews",
	"Microsoft.Todos",
	"Microsoft.UI.Xaml.2.2",
	"Microsoft.UI.Xaml.2.4"
	
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
            [string]$FileName = "pslog_RemoveAppx.txt"
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

	# Create logpath (if not exist)
	$path = "C:\IntuneLogs"
	If(!(test-path $path))
	{
      New-Item -ItemType Directory -Force -Path $path
	}

    # Initial logging
	$date = get-date
	Write-LogEntry -Value "-------------------------------------------------------------------------------"
    Write-LogEntry -Value "Script Version: 20H2 (2020-11-23)"
	Write-LogEntry -Value "$date"
	Write-LogEntry -Value "-------------------------------------------------------------------------------"
    Write-LogEntry -Value "Starting built-in AppxPackage, AppxProvisioningPackage removal process"

    # Determine provisioned apps
    $AppArrayList = Get-AppxProvisionedPackage -Online | Select-Object -ExpandProperty DisplayName

    # Loop through the list of appx packages
    foreach ($App in $AppArrayList) {
		Write-LogEntry -Value "-------------------------------------------------------------------------------"
        Write-LogEntry -Value "Processing appx package: $($App)"

        # If application name not in appx package white list, remove AppxPackage and AppxProvisioningPackage
        if (($App -in $WhiteListedAppx)) {
            Write-LogEntry -Value ">>> Skipping excluded application package: $($App)"
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
	Write-LogEntry -Value "-------------------------------------------------------------------------------"
}