[CmdletBinding(SupportsShouldProcess=$true)]
    param (
        # Enter KB Number for removal
        [Parameter(Mandatory=$true, HelpMessage="Enter KB Number for removal.")]
        [ValidateNotNullOrEmpty]
        [ValidateScript({$_ -match '(?i)kb[0-9]{6,}'})]
        [string]$KBNumber
    )

    begin {
        # Use DISM online to get installed packages
        $SearchUpdates = dism /online /get-packages | findstr "Package_for"
    }
        
    process {
        # Use DISM online to search for installed packages
        foreach ($SearchUpdate in $SearchUpdates) {
            # For each package get the package info and search for the KB_Number
            $update = $SearchUpdate.split(":")[1].replace(" ","")
            $KBSearch = dism /online /get-packageinfo /PackageName:$update

            if ($KBSearch -match $KBNumber) {
                # if KB matches use DISM online to remove the installed update
                Write-Verbose -Message "FOUND $KBNumber: Uninstalling from $env:COMPUTERNAME"
                dism /Online /Remove-Package /PackageName:$update /quiet /norestart
            }
        }
    }
    
    end {
        # Validate that KB_Number has been removed
        $ValidationSearch = dism /online /get-packages | findstr "Package_for"
        foreach ($Validation in $ValidationSearch) {
            $update = $Validation.split(":")[1].replace(" ","")
            $KBValidation = dism /online /get-packageinfo /PackageName:$update
            if ($KBValidation -match $KBNumber) {
                Write-Error -Message "$KBNumber Still installed on system! Uninstall Failed"
            }
            elseif ($null -eq $KBValidation) {
                Write-Output "SUCCESS: $KBNumber Removed from system"
            }
        }
    }
