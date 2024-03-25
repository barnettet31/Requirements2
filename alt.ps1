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
    } else {
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
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Email NVARCHAR(100),
    Phone NVARCHAR(20)
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
    
    $sqlQuery = "BULK INSERT [$databaseName].[dbo].[$tableName] FROM '$csvFilePath' WITH (FIELDTERMINATOR = ',', ROWTERMINATOR = '\n')"
    Invoke-Sqlcmd -ServerInstance $serverInstance -Database $databaseName -Query $sqlQuery
    Write-Output "Data inserted into table '$tableName' from CSV file."
}

# Main script
$serverInstance = ".\SQLEXPRESS"
$databaseName = "ClientDB"
$tableName = "Client_A_Contacts"
$csvFilePath = ".\Requirements2\NewClientData.csv"

# Check if database exists and delete if it does
CheckAndDeleteDatabase -serverInstance $serverInstance -databaseName $databaseName

# Create new database
CreateDatabase -serverInstance $serverInstance -databaseName $databaseName

# Create new table in the database
CreateTable -serverInstance $serverInstance -databaseName $databaseName -tableName $tableName

# Insert data from CSV into the table
InsertDataFromCSV -serverInstance $serverInstance -databaseName $databaseName -tableName $tableName -csvFilePath $csvFilePath

# Generate output file SqlResults.txt
Invoke-Sqlcmd -Database $databaseName -ServerInstance $serverInstance -Query "SELECT * FROM dbo.$tableName" > .\SqlResults.txt
Write-Output "Output file 'SqlResults.txt' generated."
