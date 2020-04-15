<##### Script Settings #####>
$currSiteCollectionUrl = "https://contoso.sharepoint.com/sites/yoursite" 
#Array with the names for the lists you want to apply the permissions, add more list names if needed 
$listNames = @("Test List", "Second Test List")
#Group names: Change to existing group names if you want to update existing group permissions instead of creating new groups
#For existing groups, they are not removed from root site. Permissions updated at list level only
$readersName = "Power Apps Readers"
$membersName = "Power Apps Contributors"
##keeps current permissions for other groups in the list
$keepOtherGroupsPemissions = $false 
$readersName = "Power Apps Readers"
$membersName = "Power Apps Contributors"
<##### Script Settings #####>

#Connect to your site
Connect-PnPOnline -Url $currSiteCollectionUrl -UseWebLogin

#Permission level names
$paContribute = "Contribute from Power Apps"
$paRead = "Read from Power Apps"
$existingRoleDefinitions = Get-PnPRoleDefinition
##Custom permission levels (Assign the next calls to variables to avoid the dummy format-output errors): 
$roleDefContribute = Add-PnPRoleDefinition -RoleName $paContribute -Clone "Contribute" -Exclude ViewFormPages 
$roleDefRead = Add-PnPRoleDefinition -RoleName $paRead -Clone "Read" -Exclude ViewFormPages

##Creates the two new groups: 
$readers = Get-PnPGroup -Identity $readersName -ErrorAction Ignore
$members = Get-PnPGroup -Identity $membersName -ErrorAction Ignore

$readersExisted = ($readers -ne $null)
$membersExisted = ($members -ne $null)

if(!$readersExisted){ $readers = New-PnPGroup -Title $readersName }
if(!$membersExisted){ $members = New-PnPGroup -Title $membersName }

##Iterates through the specified lists and do the configuration in each
$listNames | ForEach-Object {
  $listName = $_   
  $list = Get-PnPList -Identity $listName -Includes HasUniqueRoleAssignments,Title
  if($list.HasUniqueRoleAssignments -and !$keepOtherGroupsPemissions){
    ##Resets role inheritance to break it later clearing it
    $list.ResetRoleInheritance()
    $list.Context.Load($list)
    Invoke-PnPQuery   
  }
  ##Excludes from search results
  $list.NoCrawl = $True  
  $list.Update()   
  ##Breaks role inheritance if it was not done before
  if(!$list.HasUniqueRoleAssignments){
    $list.BreakRoleInheritance($keepOtherGroupsPemissions,$false)
  }
  $list.Context.Load($list)
  Invoke-PnPQuery  
  if($keepOtherGroupsPemissions -and ($membersExisted -or $readersExisted)){     
    ##If not clearing current permissions, remove any for current groups to add them later
    $existingRoleDefinitions | ForEach-Object { 
      if($readersExisted){            
        Set-PnPListPermission -Identity $listName -Group  $membersName -RemoveRole $_.Name -ErrorAction Ignore
      }
      if($membersExisted){   
        Set-PnPListPermission -Identity $listName -Group  $readersName -RemoveRole $_.Name -ErrorAction Ignore
      }
    }        
  } 
  ##Grants right permisisons to groups
  Set-PnPListPermission -Identity $listName -Group  $membersName -AddRole $paContribute 
  Set-PnPListPermission -Identity $listName -Group  $readersName -AddRole $paRead 
} 

Disconnect-PnPOnline
