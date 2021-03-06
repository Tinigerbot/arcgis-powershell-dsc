<#
    .SYNOPSIS
        Creates a SelfSigned Certificate or Installs a SSL Certificated Provided and Configures it with Portal.
    .PARAMETER Ensure
        Ensure makes sure that a Portal site is configured and joined to site if specified. Take the values Present or Absent. 
        - "Present" ensures the certificate is installed and configured with the portal.
        - "Absent" ensures the certificate configured with the portal is uninstalled and deleted(Not Implemented).
    .PARAMETER SiteName
        Site Name or Default Context of Portal
    .PARAMETER SiteAdministrator
        A MSFT_Credential Object - Primary Site Adminstrator.
    .PARAMETER CertificateFileLocation
        Certificate Path from where to fetch the certificate to be installed.
    .PARAMETER CertificatePassword
        Sercret Certificate Password or Key.
    .PARAMETER CName
        CName with which the Certificate will be associated.
    .PARAMETER PortalEndPoint
        Portal Endpoint with which the Certificate will be associated.
	.PARAMETER ServerEndPoint
        Not sure - Adds a Host Mapping of Server Machine and associates it with the certificate being Installed.
#>

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SiteName
	)

    Import-Module $PSScriptRoot\..\..\ArcGISUtility.psm1 -Verbose:$false

	$null 
}

function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SiteName,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.Management.Automation.PSCredential]
		$SiteAdministrator,
		
		[System.String]
		$CertificateFileLocation,

		[System.String]
		$CertificatePassword,

        [System.String]
		$CName,

		[System.String]
		$PortalEndPoint,

		[System.String]
		$ServerEndPoint
	)

    Import-Module $PSScriptRoot\..\..\ArcGISUtility.psm1 -Verbose:$false

	if($ServerEndPoint -and ($ServerEndPoint -as [ipaddress])) {
		Write-Verbose "Adding Host mapping for $ServerEndPoint"
		Add-HostMapping -hostname $ServerEndPoint -ipaddress $ServerEndPoint        
	}
	elseif($CName -as [ipaddress]) {
		Write-Verbose "Adding Host mapping for $CName"
		Add-HostMapping -hostname $CName -ipaddress $CName        
	}

    if($CertificateFileLocation -and (Test-Path $CertificateFileLocation)) 
	{
		[System.Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
		$result = $false
		$MachineEndPoint = if($PortalEndPoint) { $PortalEndPoint} else { $env:COMPUTERNAME }
	    $FQDN = $MachineEndPoint
        if($FQDN.IndexOf('.') -lt 0) {
            $FQDN = Get-FQDN $MachineEndPoint
        }
		$PortalUrl = "https://$($FQDN):7443"  
		$Referer = $PortalUrl
		$token = Get-PortalToken -PortalHostName $FQDN -SiteName $SiteName  -Credential $SiteAdministrator -Referer $Referer 
		if(-not($token.token)) {
			throw "Unable to retrieve Portal Token for '$($PortalAdministrator.UserName)'"
		}
		$certsConfig = Get-SSLCertificatesForPortal -PortalHostName $FQDN -SiteName $Sitename -Token $token.token -Referer $Referer 
		Write-Verbose "Current Alias for SSL Certificate:- '$($certsConfig.webServerCertificateAlias)' Certificates:- '$($certsConfig.sslCertificates -join ',')'"

		if(-not($certsConfig.sslCertificates -icontains $CName)) {
			Write-Verbose "Importing SSL Certificate with alias $CName"
			Import-ExistingCertificate -PortalHostName $FQDN -SiteName $Sitename -Token $token.token `
					-Referer $Referer -CertAlias $CName -CertificateFilePath $CertificateFileLocation -CertificatePassword $CertificatePassword
		}else {
			Write-Verbose "SSL Certificate with alias $CName already exists"
		}
		
		if($certsConfig.webServerCertificateAlias -ine $CName) {
			Write-Verbose "Updating Alias to use $CName"
			Update-PortalSSLCertificate -PortalHostName $FQDN -SiteName $Sitename -Token $token.token -Referer $Referer -CertAlias $CName 
		}else {
			Write-Verbose "SSL Certificate alias $CName is the current one"
		}        

        Write-Verbose "Waiting for $($PortalUrl)/$SiteName/portaladmin/"
		Wait-ForUrl -Url "$($PortalUrl)/$SiteName/portaladmin/" -HttpMethod 'GET' -LogFailures

		Write-Verbose 'Verifying that SSL Certificates config for site can be retrieved'
		$certsConfig = Get-SSLCertificatesForPortal -PortalHostName $FQDN -SiteName $Sitename -Token $token.token -Referer $Referer 
		Write-Verbose "Current Alias for SSL Certificate:- '$($certsConfig.webServerCertificateAlias)'"
    }else {
        Write-Verbose "CertificateFileLocation not specified or '$CertificateFileLocation' not accessible"
        Write-Warning "CertificateFileLocation not specified or '$CertificateFileLocation' not accessible"
    }
}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SiteName,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.Management.Automation.PSCredential]
		$SiteAdministrator,

		[System.String]
		$CertificateFileLocation,

		[System.String]
		$CertificatePassword,

        [System.String]
		$CName,

		[System.String]
		$PortalEndPoint,

		[System.String]
		$ServerEndPoint
	)   
  
    Import-Module $PSScriptRoot\..\..\ArcGISUtility.psm1 -Verbose:$false
 
    [System.Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
    $result = $false
    $MachineEndPoint = if($PortalEndPoint) { $PortalEndPoint} else { $env:COMPUTERNAME }	
	$FQDN = $MachineEndPoint
    if(-not($FQDN -as [ipaddress])) {
        $FQDN = Get-FQDN $MachineEndPoint
    }
    $PortalUrl = "https://$($FQDN):7443" 
	#Write-Verbose "Waiting for portal at 'https://$($FQDN):7443/$($SiteName)/sharing/rest/' to initialize" 
	#Wait-ForUrl -Url "https://$($FQDN):7443/$($SiteName)/sharing/rest/" -MaxWaitTimeInSeconds 180 -HttpMethod 'GET' -LogFailures -MaximumRedirection -1
	$Referer = $PortalUrl
    $token = $null
    try{ 
        $token = Get-PortalToken -PortalHostName $FQDN -SiteName $SiteName  -Credential $SiteAdministrator -Referer $Referer 
        if(-not($token)) {
            # Unable to retrieve token. Restart the service and try again
            $ServiceName = 'Portal for ArcGIS'
            try {
			    Write-Verbose "Restarting Service $ServiceName"
			    Stop-Service -Name $ServiceName -Force -ErrorAction Ignore
			    Write-Verbose 'Stopping the service' 
			    Wait-ForServiceToReachDesiredState -ServiceName $ServiceName -DesiredState 'Stopped'
			    Write-Verbose 'Stopped the service'
		    }catch {
                Write-Verbose "[WARNING] Stopping Service $_"
            }
		    try {
			    Write-Verbose 'Starting the service'
			    Start-Service -Name $ServiceName -ErrorAction Ignore        
			    Wait-ForServiceToReachDesiredState -ServiceName $ServiceName -DesiredState 'Running'
			    Write-Verbose "Restarted Service $ServiceName"
		    }catch {
                Write-Verbose "[WARNING] Starting Service $_"
            }
        }
        $token = Get-PortalToken -PortalHostName $FQDN -SiteName $SiteName  -Credential $SiteAdministrator -Referer $Referer 
    }
    catch {
        Write-Verbose "[WARNING] Unable to get token:- $_"
    }
	if(-not($token.token)) {
		throw "Unable to retrieve Portal Token for '$($SiteAdministrator.UserName)'"
	}else {
        Write-Verbose "Retrieved Portal Token"
    }
    Write-Verbose "Retrieve SSL Certificate for Portal from $FQDN and checking for Alias $CNAME"
	$certsConfig = Get-SSLCertificatesForPortal -PortalHostName $FQDN -SiteName $Sitename -Token $token.token -Referer $Referer 
    Write-Verbose "Number of certificates:- $($certsConfig.sslCertificates.Length) Certificates:- '$($certsConfig.sslCertificates -join ',')' Current Alias :- '$($certsConfig.webServerCertificateAlias)'"
	$result = ($certsConfig.sslCertificates -icontains $CName) -and ($certsConfig.webServerCertificateAlias -ieq $CName) 
    if($result) {
        Write-Verbose "Certificate $($certsConfig.webServerCertificateAlias) matches expected alias of '$CNAME'"
    }
    else {
        Write-Verbose "Certificate $($certsConfig.webServerCertificateAlias) does not match expected alias of '$CNAME'"
    }

    if($Ensure -ieq 'Present') {           
           $result
    }
    elseif($Ensure -ieq 'Absent') {        
        (-not($result))
    }
}

function Get-SSLCertificatesForPortal
{
    param(
        [System.String]
        $PortalHostName = 'localhost',

        [System.String]
        $SiteName = 'arcgis',

        [System.String]
        $Token,

        [System.String]
        $Referer
    )

    Invoke-ArcGISWebRequest -Url "https://$($PortalHostName):7443/$($SiteName)/portaladmin/security/sslCertificates" -HttpFormParameters @{ f = 'json'; token = $Token } -Referer $Referer -HttpMethod 'GET'
}

function Import-ExistingCertificate
{
    [CmdletBinding()]
    param(
        [System.String]
        $PortalHostName = 'localhost', 

        [System.String]
        $SiteName = 'arcgis', 

        [System.String]
        $Token, 

        [System.String]
        $Referer, 

        [System.String]
        $CertAlias, 

        [System.String]
        $CertificatePassword, 

        [System.String]
        $CertificateFilePath
    )

    $ImportCertUrl  = "https://$($PortalHostName):7443/$SiteName/portaladmin/security/sslCertificates/importExistingServerCertificate"
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true} # Allow self-signed certificates
        
    $props = @{ f= 'json'; token = $Token; alias = $CertAlias; password = $CertificatePassword  }    
    $res = Upload-File -url $ImportCertUrl -filePath $CertificateFilePath -fileContentType 'application/x-pkcs12' -formParams $props -Referer $Referer -fileParameterName 'file'    
    if($res -and $res.Content) {
        $response = $res | ConvertFrom-Json
        Check-ResponseStatus $response -Url $ImportCACertUrl
    } else {
        Write-Verbose "[WARNING] Response from $ImportCertUrl was null"
    }
}

function Update-PortalSSLCertificate
{
    [CmdletBinding()]
    param(
        [System.String]
        $PortalHostName = 'localhost', 

        [System.String]
        $SiteName = 'arcgis', 

        [System.String]
        $Token, 

        [System.String]
        $Referer, 

        [System.String]
        $CertAlias
    )

    Invoke-ArcGISWebRequest -Url "https://$($PortalHostName):7443/$($SiteName)/portaladmin/security/sslCertificates/update" -HttpFormParameters @{ f = 'json'; token = $Token; webServerCertificateAlias = $CertAlias; sslProtocols = 'TLSv1.2,TLSv1.1,TLSv1' } -Referer $Referer
}

Export-ModuleMember -Function *-TargetResource

