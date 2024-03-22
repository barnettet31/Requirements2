#### Travis Barnette 011143725
<# 
Function Description: 

Handler for checkign for the active directory "Finance", stating if it exists or not
and deleting the AD if it does. TO BE CALLED BEFORE OTHER HANDLERS 

#>
function ActiveDirectoryCheck{
    ## Check for Active Directory 
    $financeOUExists = Get-ADOrganizationalUnit -Filter {Name -eq "Finance"} -SearchBase "DC=consultingfirm,DC=com" -ErrorAction SilentlyContinue
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
        $firstName = $user.First_Name
        $lastName = $user.Last_Name
        $samAccountName = $user.samAccount
        $city = $user.City
        $postalCode = $user.PostalCode
        $officePhone = $user.OfficePhone
        $mobilePhone = $user.MobilePhone

        # Assuming OUPath is provided in the format "OU=Finance,DC=consultingfirm,DC=com"
        New-ADUser -Name "$firstName $lastName" -DisplayName "$firstName $lastName" -GivenName $firstName -Surname $lastName `
            -SamAccountName $samAccountName -City $city -County $county -PostalCode $postalCode `
            -OfficePhone $officePhone -MobilePhone $mobilePhone -Path $OUPath -AccountPassword (ConvertTo-SecureString "Password123!" -AsPlainText -Force) `
            -Enabled $true -ChangePasswordAtLogon $true -PasswordNeverExpires $false
    }
}


ActiveDirectoryCheck
CreateFinanceOU -OUName "Finance" -Domain "consultingfirm,DC=com"
ImportAndCreateADUsers -CSVPath "$PWD/financePersonnel.csv" -OUPath "OU=Finance,DC=consultingfirm,DC=com"

# Requirement for 4... looks like it's getting a user from the active directory and putting it into a txt file. 
Get-ADUser -Filter * -SearchBase "ou=Finance,dc=consultingfirm,dc=com" -Properties DisplayName,PostalCode,OfficePhone,MobilePhone > .\AdResults.txt