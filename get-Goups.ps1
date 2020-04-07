Import-Module ActiveDirectory
#$cred = get-credential
$DC='192.168.4.242'  # Domain Controller to Run Search Against
$groups= @('group1','domain admins') # Group or Groups to Evaluate
$recursive = $true # Recurive List Groups
$CustomGroups=@();  # Complete Array of All Groups
$global:groupNames = @()  # All Group Names, Prevents Getting Stuck in a Loop

Write-Host("-----------------------------------")
Write-Host("Domain Controller: " + $DC)
Write-Host("Groups:" + $groups)
Write-Host("Recursive: " + $recursive)
Write-Host("-----------------------------------")
Write-Host("`n")
$sw = [Diagnostics.Stopwatch]::StartNew()

function get-groupMembers(){
    [CmdletBinding()]
    param (
        [Parameter()]
        [array]
        $groups,  # Groups To Search For
        [Parameter()]
        [bool]
        $recursive = $false,  # Recursive Group Listing
        [Parameter()]
        [string]
        $childOf = 'IS ROOT SEARCH GROUP'
    )
    $CustomGroupsInt=@();  # Group Array thet is internl to this loop instance, gets returned to last instance.

    foreach($group in $groups){
        Write-Host("Evaluating: " + $group + "  (Child Of: " + $childOf + ")")
        $members=Get-ADGroupMember $group -Server $DC -Credential $cred
        foreach($member in $members){
            if($member.objectClass-eq'group' -and $recursive -eq $true){  # Object is a Group and we are doing a Recursive Search
                if ($global:groupNames -notcontains $member.name.ToUpper()){ # We have not already Evaluated This Group
                    $global:groupNames+= $member.name.ToUpper()  # Set Grou as Evaluated
                    $CustomGroupsInt+= get-groupMembers -groups $member.name -recursive $true -childOf $group  # Run this function for this group
                }
            }
            $CustomGroup=New-Object PSCustomObject
            $CustomGroup|Add-Member -MemberType NoteProperty -Name Group -Value $group
            $CustomGroup|Add-Member -MemberType NoteProperty -Name distinguishedName -Value $member.distinguishedName
            $CustomGroup|Add-Member -MemberType NoteProperty -Name name -Value $member.name
            $CustomGroup|Add-Member -MemberType NoteProperty -Name objectClass -Value $member.objectClass
            $CustomGroup|Add-Member -MemberType NoteProperty -Name objectGUID -Value $member.objectGUID
            $CustomGroup|Add-Member -MemberType NoteProperty -Name SamAccountName -Value $member.SamAccountName
            $CustomGroupsInt+=$CustomGroup
        }
    }   
    return $CustomGroupsInt
}
$CustomGroups = get-groupMembers -groups $groups -recursive $recursive
$CustomGroups | Out-GridView

$sw.Stop()
Write-Host("`n")
Write-Host("-----------------------------------")
Write-Host("Script Time Taken: " + $sw.Elapsed)
Write-Host("-----------------------------------")
