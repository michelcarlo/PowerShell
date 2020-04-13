<########################### PnPPowerShell modules check ###########################>
if (Get-Module -ListAvailable -Name SharePointPnPPowerShell*) {
    Write-Host "Module exists"
}
else {
    Write-Host "Module doesn't exist. Installing module."
    Install-Module SharePointPnPPowerShellOnline -SkipPublisherCheck -AllowClobber
}


<########################### Script Settings ###########################>
$sitePath = "powerappsdemo025"
$currSiteCollectionUrl = "https://themichel.sharepoint.com/sites/$sitePath"

###############TESTS##############

Connect-PnPOnline -Url "https://themichel-admin.sharepoint.com" -Credentials "TheMichel"

<#
Get-PnPTenantSite | 
Where-Object { $_.Url.Contains("powerappsdemo") } | 
ForEach-Object { Remove-PnPTenantSite -Url $_.Url }#>

New-PnPSite -Type CommunicationSite -Title $sitePath -Url $currSiteCollectionUrl
Disconnect-PnPOnline

Connect-PnPOnline -Url $currSiteCollectionUrl  -Credentials "TheMichel"
$listNames = @("Test List", "Second Test List")

$listNames | ForEach-Object {
    $listName = $_; 
    New-PnPList -Title $listName -Template GenericList
}
Disconnect-PnPOnline
<########################### Script Settings ###########################>
Connect-PnPOnline -Url $currSiteCollectionUrl  -Credentials "TheMichel"
#Array with the names for the lists you want to apply the permissions 
$listNames = @("Test List", "Second Test List")

#Group Names
$readersGroup = "Power Apps Readers";
$membersGroup = "Power Apps Contributors";
#Permission Level names
$powerAppsContributeLevel = "Contribute from Power Apps";
$powerAppsReadLevel = "Read from Power Apps";

#Custom permission levels

Add-PnPRoleDefinition -RoleName $powerAppsContributeLevel -Clone "Contribute" -Exclude ViewFormPages -Description "Allows users to collaborate on list data from Power Apps or APIs only. Blocks users accessing data using the browser."
Add-PnPRoleDefinition -RoleName $powerAppsReadLevel -Clone "Read" -Exclude ViewFormPages -Description "Allows users to read list data from Power Apps or APIs only. Blocks users accessing data using the browser."
Write-Host "Created Permission Levels"

New-PnpGroup -Title $readersGroup
New-PnpGroup -Title $membersGroup
Write-Host "Created Groups"

Set-PnpWebPermission -Group  $membersGroup -AddRole $powerAppsReadLevel
Write-host "Added site Power Apps read for for $membersGroup"

Set-PnpWebPermission -Group  $readersGroup -AddRole $powerAppsReadLevel
Write-host "Added site Power Apps permissions for for $readersGroup"


#Make hidden too?
$listNames | ForEach-Object {
    $listName = $_;

    Write-Host "Managing list: $listName"

    Set-PnPList -Identity $listName -BreakRoleInheritance:$true -ClearSubscopes -Hidden:$true
    
    Write-Host "Broke Permissions and hid list"    

    $list = Get-PnPList -Identity $listName 
    
    ##Exclude from Search Results
    $list.NoCrawl = $True
    $list.Update
    $list.Context.Load($list);
    $list.Context.ExecuteQuery();
 

    ##Adds a navigation node for admins to find the list easier
   
    Add-PnPNavigationNode -Title $list.Title -Location QuickLaunch -Url $list.RootFolder.ServerRelativeUrl

   
    Set-PnPListPermission -Identity $listName -Group  $membersGroup -AddRole $powerAppsContributeLevel 
    Write-host "Added contribute permissions on $listName for $membersGroup"

    Set-PnPListPermission -Identity $listName -Group  $readersGroup -AddRole $powerAppsReadLevel 
    Write-host "Added read permissions on $listName for $readersGroup"    

} 



Disconnect-PnPOnline
