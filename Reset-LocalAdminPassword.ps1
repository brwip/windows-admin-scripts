# Reset-LocalAdminPassword.ps1
# Written by Bill Stewart (bstewart@iname.com)

#requires -version 2

<#
.SYNOPSIS
Resets the local Administrator password on one or more computers.

.DESCRIPTION
Resets the local Administrator password on one or more computers. The local Administrator account is determined by its RID (-500), not its name.

.PARAMETER ComputerName
Specifies one or more computer names. The default is the current computer.

.PARAMETER Password
Specifes the password to use for the local Administrator account. If you don't specify this parameter, you will be prompted to enter a password.
#>

[CmdletBinding(SupportsShouldProcess=$TRUE)]
param(
  [parameter(ValueFromPipeline=$TRUE)]
    $ComputerName=[System.Net.Dns]::GetHostName(),
  [parameter(Mandatory=$TRUE)]
    [System.Security.SecureString] $Password
)

begin {
  $ScriptName = $MyInvocation.MyCommand.Name
  $PipelineInput = (-not $PSBoundParameters.ContainsKey("ComputerName")) -and (-not $ComputerName)

  # Returns a SecureString as a String.
  function ConvertTo-String {
    param(
      [System.Security.SecureString] $secureString
    )
    $marshal = [System.Runtime.InteropServices.Marshal]
    try {
      $intPtr = $marshal::SecureStringToBSTR($secureString)
      $string = $marshal::PtrToStringAuto($intPtr)
    }
    finally {
      if ( $intPtr ) {
        $marshal::ZeroFreeBSTR($intPtr)
      }
    }
    $string
  }

  # Writes a custom error to the error stream.
  function Write-CustomError {
    param(
      [System.Exception] $exception,
      $targetObject,
      [String] $errorID,
      [System.Management.Automation.ErrorCategory] $errorCategory="NotSpecified"
    )
    $errorRecord = new-object System.Management.Automation.ErrorRecord($exception,
      $errorID,$errorCategory,$targetObject)
    $PSCmdlet.WriteError($errorRecord)
  }

  # Resets the local Administrator password on the specified computer.
  function Reset-LocalAdminPassword {
    param(
      [String] $computerName,
      [System.Security.SecureString] $password
    )
    $adsPath = "WinNT://$computerName,Computer"
    try {
      if ( -not [ADSI]::Exists($adsPath) ) {
        $message = "Cannot connect to the computer '$computerName' because it does not exist."
        $exception = [Management.Automation.ItemNotFoundException] $message
        Write-CustomError $exception $computerName $ScriptName ObjectNotFound
        return
      }
    }
    catch [System.Management.Automation.MethodInvocationException] {
      $message = "Cannot connect to the computer '$computerName' due to the following error: '$($_.Exception.InnerException.Message)'"
      $exception = new-object ($_.Exception.GetType().FullName)($message,$_.Exception.InnerException)
      Write-CustomError $exception $computerName $ScriptName
      return
    }
    $computer = [ADSI] $adsPath
    $localUser = $NULL
    $localUserName = ""
    foreach ( $childObject in $computer.Children ) {
      if ( $childObject.Class -ne "User" ) {
        continue
      }
      $childObjectSID = new-object System.Security.Principal.SecurityIdentifier($childObject.objectSid[0],0)
      if ( $childObjectSID.Value.EndsWith("-500") ) {
        $localUser = $childObject
        $localUserName = $childObject.Name[0]
        break
      }
    }
    if ( -not $PSCmdlet.ShouldProcess("'$computerName\$localUserName'","Reset password") ) {
      return
    }
    try {
      $localUser.SetPassword((ConvertTo-String $password))
    }
    catch [System.Management.Automation.MethodInvocationException] {
      $message = "Cannot reset password for '$computerName\$localUserName' due the following error: '$($_.Exception.InnerException.Message)'"
      $exception = new-object ($_.Exception.GetType().FullName)($message,$_.Exception.InnerException)
      Write-CustomError $exception "$computerName\$user" $ScriptName
    }
  }
}

process {
  if ( $PipelineInput ) {
    Reset-LocalAdminPassword $_ $Password
  }
  else {
    $ComputerName | foreach-object {
      Reset-LocalAdminPassword $_ $Password
    }
  }
}
