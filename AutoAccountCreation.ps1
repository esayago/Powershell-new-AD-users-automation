#---Enable running scripts---#
Set-ExecutionPolicy RemoteSigned
#---ENTER ADM CREDENTIALS---#
$UserCredential = Get-Credential
#---ENTER O365 CREDENTIALS---#
$cred = Get-Credential

$csv = Import-Csv #path to csv file
#---Connect to Exchange Server---#
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://(server FQDN/PowerShell/) -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session

#---CREATE ACCOUNTS IN AD-EXCHANGE---#
ForEach ($line in $csv) {

    $password = ConvertTo-SecureString $line.Password -AsPlainText -Force
        
    New-RemoteMailbox -Alias $line.Alias `
    -Name $line.Name `
    -FirstName $line.FirstName `
    -LastName $line.LastName `
    -DisplayName $line.DisplayName `
    -UserPrincipalName $line.UserPrincipalName `
    -OnPremisesOrganizationalUnit $line.Ou `
    -Password $password
}
#NO CONDITIONS, JUST A NOTE AFTER FIRST STEP#
Write-Host "AD ACCOUNTS HAVE BEEN CREATED" -BackgroundColor Green -ForegroundColor Black
Start-Sleep 5
Start-Sleep -Milliseconds 10000


#---CHANGE USER PROPERTIES GROUP MEMBERSHIP---#
Import-Module ActiveDirectory

ForEach ($line in $csv) {
 Get-ADUser -Filter "saMaccountname -eq '$($line.Alias)'" |            
 Set-ADUser `
-Description ($line.Description) `
-Office $line.Office `
-Title $line.Tittle `
-Company $line.Company `
-Department $line.Department `
-Credential $UserCredential
Add-ADGroupMember -Identity $line.Group1 -Members $line.Alias -Credential $UserCredential
Add-ADGroupMember -Identity $line.Group2 -Members $line.Alias -Credential $UserCredential
}
#NO CONDITIONS, JUST A NOTE AFTER SECOND STEP#
Write-Host "PROPERTIES AND GROUPS UPDATED" -BackgroundColor Green -ForegroundColor Black
Write-Host "---RUNNING O365 LICENSE SCRIPT (25 MINUTES)" -BackgroundColor DarkRed -ForegroundColor White
#25 minute wait before last script#
Start-Sleep 5
Start-Sleep -Milliseconds 1500000


#---CONNECT TO O365---#
Import-Module MSOnline
Connect-MsolService -Credential $cred
$s = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $cred -Authentication Basic -AllowRedirection
$importresults = Import-PSSession $s


#---ASSIGN LICENSE---#

ForEach ($line in $csv) {

Set-MsolUser -UserPrincipalName $line.UserPrincipalName -UsageLocation #your location
Set-MsolUserLicense -UserPrincipalName $line.UserPrincipalName -AddLicenses #YOUR LICENSE
Get-MsolUser -UserPrincipalName $line.UserPrincipalName
}

#NO CONDITIONS, JUST A NOTE AFTER LAST STEP#
Write-Host "O365 License" -BackgroundColor Green -ForegroundColor Black
