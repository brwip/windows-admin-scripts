set-strictmode -version latest
$ErrorActionPreference = "Stop"

$wshell = New-Object -ComObject wscript.shell;
$temp = $wshell.AppActivate('defeat-screensaver');
while ($true) {
  $wshell.SendKeys("{NUMLOCK}{NUMLOCK}");
  start-sleep -s 6
}

