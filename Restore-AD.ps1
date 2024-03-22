#### Travis Barnette 011143725
<# 
Function Description: 

Handler for checkign for the active directory "Finance", stating if it exists or not
and deleting the AD if it does. TO BE CALLED BEFORE OTHER HANDLERS 

#>
function ActiveDirectoryCheck{
    ## Check for Active Directory 
    $financeOUExists = Get-ADOrganizationalUnit -Filter {Name -eq "Finance"}
    if($financeOUExists){
        Write-Output "Finance AD Does Not Exist"
        Write-Output "Removing Organizational Unit"
        Remove-ADOrganizationalUnit -Identity 'OU=Finance' -Confirm:$false
    }else{
        Write-Output "Finance AD Does Not Exist"
    }
}

<# 
Function Description: 

Handler function for creating the Finance Organizational unit, 
takes in 2 parameters that are both strings and creates 
the AD unit with the specified name fome params

#>
function CreateFinanceOU {
    param (
        [string]$OUName,
        [string]$Domain
    )

    New-ADOrganizationalUnit -Name $OUName -Path "DC=$Domain"
    Write-Output "$OUName OU created successfully."
}

<#
Function Description: 

Used to import local csv file and create users for the finance ou. 
Takes in 2 parameters for the csv path and the Organizational Unit target
#>
function ImportAndCreateADUsers {
    param (
        [string]$CSVPath,
        [string]$OUPath
    )

    $csvData = Import-Csv $CSVPath
    foreach ($user in $csvData) {
        $firstName = $user.'First Name'
        $lastName = $user.'Last Name'
        $displayName = "$firstName $lastName"
        $postalCode = $user.'Postal Code'
        $officePhone = $user.'Office Phone'
        $mobilePhone = $user.'Mobile Phone'

        New-ADUser -Name $displayName -GivenName $firstName -Surname $lastName `
                   -DisplayName $displayName -SamAccountName $firstName.ToLower() `
                   -Path $OUPath -AccountPassword (ConvertTo-SecureString "Password123!" -AsPlainText -Force) `
                   -Enabled $true -ChangePasswordAtLogon $true -PasswordNeverExpires $false `
                   -OfficePhone $officePhone -MobilePhone $mobilePhone -PostalCode $postalCode
    }
}


ActiveDirectoryCheck
CreateFinanceOU -OUName "Finance" -Domain "consultingfirm,DC=com"
ImportAndCreateADUsers -CSVPath "" -OUPath "OU=Finance,DC=consultingfirm,DC=com"

# Requirement for 4... looks like it's getting a user from the active directory and putting it into a txt file. 
Get-ADUser -Filter * -SearchBase "ou=Finance,dc=consultingfirm,dc=com" -Properties DisplayName,PostalCode,OfficePhone,MobilePhone > .\AdResults.txt