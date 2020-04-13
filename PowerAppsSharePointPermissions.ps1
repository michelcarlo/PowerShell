<##### Script Settings #####>
$currSiteCollectionUrl = "https://contoso.sharepoint.com/sites/yoursite" 
#Array with the names for the lists you want to apply the permissions, add more list names if needed 
$listNames = @("Test List", "Second Test List")
#Group names
$readersGroup = "Power Apps Readers"
$membersGroup = "Power Apps Contributors"
#Permission level names
$powerAppsContributeLevel = "Contribute from Power Apps"
$powerAppsReadLevel = "Read from Power Apps"
<##### Script Settings #####>

#Connect to your site
Connect-PnPOnline -Url $currSiteCollectionUrl  -UseWebLogin

##Assign the next calls to variables to avoid the unecessary format-output errors: 
#Custom permission levels
$roleDefContribute = Add-PnPRoleDefinition -RoleName $powerAppsContributeLevel -Clone "Contribute" -Exclude  ViewFormPages 
$roleDefRead = Add-PnPRoleDefinition -RoleName $powerAppsReadLevel -Clone "Read" -Exclude ViewFormPages

##Creates the two new groups: 
$readers = New-PnPGroup -Title $readersGroup 
$members = New-PnPGroup -Title $membersGroup 

##Iterates through the specified lists and do the configuration in each
$listNames | ForEach-Object {
    $listName = $_
    $list = Get-PnPList -Identity $listName 
    
    ##Excludes from search results
    $list.NoCrawl = $True    
    $list.Update()
    Invoke-PnPQuery    
  
    ##Breaks role inheritance (removing current access): 
    Set-PnPList -Identity $listName -BreakRoleInheritance
    
    ##Grants permissions to new groups
    Set-PnPListPermission -Identity $listName -Group  $membersGroup -AddRole $powerAppsContributeLevel 
    Set-PnPListPermission -Identity $listName -Group  $readersGroup -AddRole $powerAppsReadLevel 
} 

Disconnect-PnPOnline