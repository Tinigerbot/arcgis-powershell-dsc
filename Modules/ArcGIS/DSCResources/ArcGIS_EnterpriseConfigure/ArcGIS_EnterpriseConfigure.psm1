﻿<#
    .SYNOPSIS
        Configures the Components (Server, Portal, DataStore - Relational, 2 Web Adaptors) of the Base Deployment using the Enterprise Builder.
    .PARAMETER Ensure
        Indicates if ArcGIS Enterprise Builder Components are to be Configured using Enterprise Builder API. Take the values Present or Absent. 
        - "Present" ensures that components of ArcGIS Enterpise Base Deployment is configured using the Enterprise Builder.
        - "Absent" ensures that components of ArcGIS Enterpise Base Deployment is unconfigured if already configured (Not Implemented).
    .PARAMETER ContentDirPath
        Path to a location for the content directory to store logs and configuration files - Can be a Physical Location or Network Share Address
    .PARAMETER AdministratorUser
        A MSFT_Credential Object - Credentials for the initial administrator's account. This account will be used to sign in to your ArcGIS Enterprise deployment for the first time and for initial administrative tasks such as creating additional accounts. 
    .PARAMETER FirstName
         First Name of the Admin User - Additional Account Information
    .PARAMETER LastName
         Last Name of the Admin User - Additional Account Information
    .PARAMETER AdminEMail
         Primary Email for the Admin User - Additional Account Information
    .PARAMETER AdminSecurityQuestionIndex
         Security Question Index for Admin User - Additional Account Information 
         - Can Speify all the option here.
    .PARAMETER AdminSecurityAnswer
         Answer to the Security Question Selected by the Admin User - Additional Account Information
    .PARAMETER ServerWAURL
        Optional Webadpator Endpoint for Server along with the Context - Default: server
    .PARAMETER PortalWAURL
        Optional Webadpator Endpoint for Portal along with the Context - Default: portal
#>

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ContentDirPath,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$AdministratorUser
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
        $ContentDirPath = "C:\\arcgis",

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdministratorUser,

        [System.String]
        $FirstName,

        [System.String]
        $LastName,

        [System.String]
        $AdminEMail,

        [System.String]
        $AdminSecurityQuestionIndex,

        [System.String]
        $AdminSecurityAnswer,

        [System.String]
        $ServerWAURL,

        [System.String]
        $PortalWAURL,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )
    
    Import-Module $PSScriptRoot\..\..\ArcGISUtility.psm1 -Verbose:$false

    $Name = "EnterpriseBuilder"
    if($Ensure -eq 'Present') {
        $EnterpriseAdminUrl = "https://localhost:6443/arcgis/enterpriseadmin/"
        $Referer = "https://localhost:6443/arcgis/enterprise"

        $ConfigureCheck = Invoke-ArcGISWebRequest -Url ($EnterpriseAdminUrl) -HttpMethod 'GET' -HttpFormParameters @{ f = 'json'; } -Referer $Referer -LogResponse
        if($ConfigureCheck.status -eq "error" -and $ConfigureCheck.messages -match "SITE_NOT_INITIALIZED"){
            $ContentDirValidation = Invoke-ArcGISWebRequest -Url ($EnterpriseAdminUrl + "validateParameters") -HttpMethod 'GET' -HttpFormParameters @{ f = 'json'; contentDir = $ContentDirPath } -Referer $Referer -LogResponse
            if($ContentDirValidation.status -eq "success"){
                
                $HttpFormParams = @{
                    f= 'json';
                    username = $AdministratorUser.GetNetworkCredential().UserName;
                    password = $AdministratorUser.GetNetworkCredential().Password;
                    contentDir = $ContentDirPath;
                    firstname= $FirstName;
                    lastname= $LastName;
                    email= $AdminEMail;
                    securityQuestionIdx = $AdminSecurityQuestionIndex;
                    securityQuestionAns = $AdminSecurityAnswer;
                    serverWAURL=$ServerWAURL;
                    portalWAURL=$PortalWAURL;
                    runAsync = 'true';
                }
                $ValidationAll = Invoke-ArcGISWebRequest -Url ($EnterpriseAdminUrl + "validateAllParameters") -HttpMethod 'POST' -HttpFormParameters $HttpFormParams -Referer $Referer -LogResponse
                Write-Verbose $ValidationAll
                if($ValidationAll.status -eq "success"){
                    $JobRequest = Invoke-ArcGISWebRequest -Url ($EnterpriseAdminUrl + "createWebGIS") -HttpMethod 'POST' -HttpFormParameters $HttpFormParams -Referer $Referer -LogResponse
                    $step = 0
                    Write-Verbose "Starting Enterprise Configuration"
                    while($step -lt 12){
                        $ConfigurationStatus = Invoke-ArcGISWebRequest -Url ($EnterpriseAdminUrl + "getStatus") -HttpMethod 'GET' -HttpFormParameters @{ f = 'json'; jobid = $JobRequest.jobId } -Referer $Referer -LogResponse
                        if($ConfigurationStatus.status -ieq 'success'){
                            if(($step -ieq 0) -and $ConfigurationStatus.messages.300014){
                                Write-Verbose $ConfigurationStatus.messages.300014
                                $step = 1
                            }
                            if(($step -ieq 1) -and $ConfigurationStatus.messages.300018){
                                Write-Verbose $ConfigurationStatus.messages.300018
                                $step = 2
                            }
                            if(($step -ieq 2) -and $ConfigurationStatus.messages.300019){
                                Write-Verbose $ConfigurationStatus.messages.300019
                                $step = 3
                            }
                            if(($step -ieq 3) -and $ConfigurationStatus.messages.300020){
                                Write-Verbose $ConfigurationStatus.messages.300020
                                $step = 4
                            }
                            if(($step -ieq 4) -and $ConfigurationStatus.messages.300021){
                                Write-Verbose $ConfigurationStatus.messages.300021
                                $step = 5
                            } 
                            if(($step -ieq 5) -and $ConfigurationStatus.messages.300022){
                                Write-Verbose $ConfigurationStatus.messages.300022
                                $step = 6
                            } 
                            if(($step -ieq 6) -and $ConfigurationStatus.messages.300023){
                                Write-Verbose $ConfigurationStatus.messages.300023
                                $step = 7
                            } 
                            if(($step -ieq 7) -and $ConfigurationStatus.messages.300024){
                                Write-Verbose $ConfigurationStatus.messages.300024
                                $step = 8
                            } 
                            if(($step -ieq 8) -and $ConfigurationStatus.messages.300025){
                                Write-Verbose $ConfigurationStatus.messages.300025
                                $step = 9
                            }    
                            if(($step -ieq 9) -and $ConfigurationStatus.messages.300026){
                                Write-Verbose $ConfigurationStatus.messages.300026
                                $step = 10
                            } 
                            if(($step -ieq 10) -and $ConfigurationStatus.messages.300027){
                                Write-Verbose $ConfigurationStatus.messages.300027
                                $step = 11
                            } 
                            if(($step -ieq 11) -and $ConfigurationStatus.messages.300067){
                                Write-Verbose $ConfigurationStatus.messages.300067
                                $step = 12
                            } 
                        }
                    }
                    
                    if($step -ieq 12){
                        $ConfigurationCompletionStatus = Invoke-ArcGISWebRequest -Url ($EnterpriseAdminUrl) -HttpMethod 'GET' -HttpFormParameters @{ f = 'json'; } -Referer $Referer -LogResponse
                        if($ConfigurationCompletionStatus.status -eq 'success'){
                            $ConfigurationCompletionStatus
                        }
                    }else{
                        Write-Verbose "An error occured"
                    }
                }else{
                    Write-Verbose "All Validation Error: $($ValidationAll)"
                }
            }else{
                Write-Verbose "Content Dir Validation Error: $($ContentDirValidation)"
            }
        }
    }
    elseif($Ensure -eq 'Absent') {
       Write-Verbose "Not Yet Implemented"
    }
    Write-Verbose "In Set-Resource for $Name"
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
        [parameter(Mandatory = $true)]
        [System.String]
        $ContentDirPath = "C:\\arcgis",

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $AdministratorUser,

        [System.String]
        $FirstName,

        [System.String]
        $LastName,

        [System.String]
        $AdminEMail,

        [System.String]
        $AdminSecurityQuestionIndex,

        [System.String]
        $AdminSecurityAnswer,

        [System.String]
        $ServerWAURL,

        [System.String]
        $PortalWAURL,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )
    
    Import-Module $PSScriptRoot\..\..\ArcGISUtility.psm1 -Verbose:$false

    $Name = "EnterpriseBuilder"
    
    $EnterpriseAdminUrl = "https://localhost:6443/arcgis/enterpriseadmin/"
    $Referer = "https://localhost:6443/arcgis/enterprise"

    $result = $False

    $ConfigurationCompletionStatus = Invoke-ArcGISWebRequest -Url ($EnterpriseAdminUrl) -HttpMethod 'GET' -HttpFormParameters @{ f = 'json'; } -Referer $Referer -LogResponse
    if($ConfigurationCompletionStatus.status -eq 'success'){
        $result = $True
    }elseif($ConfigureCheck.status -eq "error" -and $ConfigureCheck.messages -match "SITE_NOT_INITIALIZED"){
        $result = $False
    }

    if($Ensure -ieq 'Present') {
	       $result   
    }
    elseif($Ensure -ieq 'Absent') {        
        (-not($result))
    }
}

Export-ModuleMember -Function *-TargetResource

