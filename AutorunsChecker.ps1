<#
.Synopsis
   Analyze autoruns and compare with previous checks. 
   If there is a difference you will receive an e-mail containing the path to the changed file, except the signature of the file contains: "Publisher:	Microsoft Windows"

   Requires Autorunsc.exe
   Requires SigCheck.exe

.NOTES  
    Function   : CheckAutoruns
    File Name  : AutorunsChecker.ps1 
    Author     : Christian B. - winscripting.blog 

.LINK  
        
    https://github.com/winscripting/Misc

.EXAMPLE  
    Configure this script in your scheduled tasks and execute it regularly:
    powershell.exe -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -file ".\AutorunsChecker.ps1"
     
#>

$PathToAutorunsc="C:\Sysinternals\autorunsc.exe" #Configure your Path to autorunsc.exe
$PathToSigcheck="C:\Sysinternals\sigcheck64.exe" #Configure your Path to sigcheck.exe
$Logpath="C:\temp\" #Configure your logpath

#Mailnotification:
$from="sender@company.com"    #sending e-mail
$to="recipient@company.com"   #receiving e-mail
$smtp="smtpserver"            #your smtp-server

function CheckAutoruns {

    if (-not (Test-Path -Path $LogPath)){
        New-Item $Logpath -ItemType Directory -Force
    }

    $i=0
    $LogFile="autorunslog.csv"

    while (Test-Path -Path $Logpath$LogFile){
        $LogFile="autorunslog$i.csv"
        $i++
    }

    $LogFile=$Logpath + $Logfile
    & $PathToAutorunsc -a * -c -nobanner > $LogFile



    $LogFiles=Get-ChildItem $Logpath -filter autorunslog*.csv | Sort-Object LastWriteTime | Select-Object -Last 2

    If ($LogFiles.Count -eq 2){
        #Compare the last logs
        $comparison=Compare-Object (Import-CSV $LogFiles[0].FullName) (Import-CSV $LogFiles[1].FullName) -Property 'Image Path'

        if ($comparison -ne $null){

           $signature= & $PathToSigcheck -m $comparison.'Image Path'

       
            if ($stdout -notmatch "Publisher:	Microsoft Windows"){
            
                if (($from -ne "") -and ($to -ne "") -and ($smtp -ne "")){
                    #Send a mail if there is a new entry which is not from Microsoft
                    Write-Host "Write E-Mail...."
                    Send-MailMessage -from $from -to $to -SmtpServer $smtp -Subject "A File in Autorun was added or removed which is not published by Microsoft!" -Body "$comparison.'Image Path'"
                }
                else{
                    Write-Host "Mail is not configured"
                }               
        
            }
    
        }
    }
    else{
  
        Write-Host "Not enough logs to compare autoruns"

    }

    $Logfiles=(Get-ChildItem $Logpath -filter autorunslog*.csv)
    if ($LogFiles.count -gt 2){
    
        foreach ($file in ($LogFiles | Sort-Object LastWriteTime -Descending | Select-Object -Skip 2)){
            Remove-Item -Path $file.fullname -force
        }

     }
}

CheckAutoruns