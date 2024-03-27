#### Travis Barnette 011143725
# Function to check if a database exists and delete it if it does
function CheckAndDeleteDatabase {
    param(
        [string]$serverInstance,
        [string]$databaseName
    )
    
    $sqlQuery = "SELECT COUNT(*) FROM sys.databases WHERE name = '$databaseName'"
    $databaseExists = Invoke-Sqlcmd -ServerInstance $serverInstance -Query $sqlQuery -ErrorAction SilentlyContinue
    
    if ($databaseExists -ne $null) {
        Write-Output "Database '$databaseName' exists. Deleting..."
        Invoke-Sqlcmd -ServerInstance $serverInstance -Query "DROP DATABASE [$databaseName]"
        Write-Output "Database '$databaseName' deleted."
    }
    else {
        Write-Output "Database '$databaseName' does not exist."
    }
}

# Function to create a new database
function CreateDatabase {
    param(
        [string]$serverInstance,
        [string]$databaseName
    )
    
    $sqlQuery = "CREATE DATABASE [$databaseName]"
    Invoke-Sqlcmd -ServerInstance $serverInstance -Query $sqlQuery
    Write-Output "Database '$databaseName' created."
}

# Function to create a new table in the specified database
function CreateTable {
    param(
        [string]$serverInstance,
        [string]$databaseName,
        [string]$tableName
    )
    
    $sqlQuery = @"
CREATE TABLE [$databaseName].[dbo].[$tableName] (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(100),
    City NVARCHAR(100),
    County NVARCHAR(100),
    Zip NVARCHAR(100),
    OfficePhone NVARCHAR(100),
    MobilePhone NVARCHAR(100),
)
"@
    
    Invoke-Sqlcmd -ServerInstance $serverInstance -Database $databaseName -Query $sqlQuery
    Write-Output "Table '$tableName' created in database '$databaseName'."
}

# Function to insert data from CSV into a table
function InsertDataFromCSV {
    param(
        [string]$serverInstance,
        [string]$databaseName,
        [string]$tableName,
        [string]$csvFilePath
    )
    
    $data = Import-Csv -Path $csvFilePath
    $sqlQuery = @()
    foreach ($row in $data) {
        # Write-Output "Adding Row for $row"
        $first_name = $row.first_name
        # Write-Output "First Name: $first_name"
        $last_name = $row.last_name
        # Write-Output "Last Name: $last_name"
        $city = $row.city
        $county = $row.county
        $zip = $row.zip
        $officePhone = $row.officePhone
        $mobilePhone = $row.mobilePhone
        $sqlQuery += @"
        INSERT INTO [$databaseName].[dbo].[$tableName] (FirstName, LastName, City, County, Zip, OfficePhone, MobilePhone)
        VALUES ('$first_name',
       '$last_name',
       '$city',
       '$county',
       '$zip',
       '$officePhone',
       '$mobilePhone');
"@
    }
    foreach($query in $sqlQuery){

        Invoke-Sqlcmd -ServerInstance $serverInstance -Database $databaseName -Query $query
    }
    Write-Output "Data inserted into table '$tableName' from CSV file."
}

# Main script
$serverInstance = ".\SQLEXPRESS"
$databaseName = "ClientDB"
$tableName = "Client_A_Contacts"
$csvFilePath = "$PWD\NewClientData.csv"
try {

    # Check if database exists and delete if it does
    CheckAndDeleteDatabase -serverInstance $serverInstance -databaseName $databaseName
    
    # Create new database
    CreateDatabase -serverInstance $serverInstance -databaseName $databaseName
    
    # Create new table in the database
    CreateTable -serverInstance $serverInstance -databaseName $databaseName -tableName $tableName
    
    # Insert data from CSV into the table
    InsertDataFromCSV -serverInstance $serverInstance -databaseName $databaseName -tableName $tableName -csvFilePath $csvFilePath
    
    # # Generate output file SqlResults.txt
    Invoke-Sqlcmd -Database $databaseName -ServerInstance $serverInstance -Query "SELECT * FROM dbo.$tableName" > .\SqlResults.txt
    Write-Output "Output file 'SqlResults.txt' generated."
}
catch {
    Write-Error "Error Encountered: $_"
}
