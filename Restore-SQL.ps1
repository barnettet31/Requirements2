# Function to check if a database exists, delete it if it does, and create a new one
function ManageDatabase {
    param(
        [string]$serverInstance,
        [string]$databaseName
    )

    # Check if the database exists
    $databaseExists = Get-DbaDatabase -SqlInstance $serverInstance -Name $databaseName -ErrorAction SilentlyContinue

    if ($databaseExists) {
        Write-Output "Database '$databaseName' already exists. Deleting..."
        Remove-DbaDatabase -SqlInstance $serverInstance -Database $databaseName -Confirm:$false
        Write-Output "Database '$databaseName' was deleted."
    }

    # Create the new database
    Write-Output "Creating database '$databaseName'..."
    New-DbaDatabase -SqlInstance $serverInstance -Name $databaseName
    Write-Output "Database '$databaseName' was created."
}

# Function to create a new table in the database
function CreateTable {
    param(
        [string]$serverInstance,
        [string]$databaseName,
        [string]$tableName
    )

    # Create the new table
    Write-Output "Creating table '$tableName' in database '$databaseName'..."
    Invoke-DbaQuery -SqlInstance $serverInstance -Database $databaseName -Query "CREATE TABLE $tableName (ID INT PRIMARY KEY, Name NVARCHAR(50), Email NVARCHAR(50))"
    Write-Output "Table '$tableName' was created."
}

# Function to insert data into the table from a CSV file
function InsertData {
    param(
        [string]$serverInstance,
        [string]$databaseName,
        [string]$tableName,
        [string]$csvFilePath
    )

    # Insert data into the table from the CSV file
    Write-Output "Inserting data into table '$tableName' from CSV file '$csvFilePath'..."
    $query = "BULK INSERT $tableName FROM '$csvFilePath' WITH (FORMAT='CSV', FIRSTROW=2)"
    Invoke-DbaQuery -SqlInstance $serverInstance -Database $databaseName -Query $query
    Write-Output "Data inserted into table '$tableName'."
}

try {
    # Set variables
    $serverInstance = ".\SQLEXPRESS"
    $databaseName = "ClientDB"
    $tableName = "Client_A_Contacts"
    $csvFilePath = "$PWD\NewClientData.csv"

    # Check for and manage the database
    ManageDatabase -serverInstance $serverInstance -databaseName $databaseName

    # Create the table
    CreateTable -serverInstance $serverInstance -databaseName $databaseName -tableName $tableName

    # Insert data into the table
    InsertData -serverInstance $serverInstance -databaseName $databaseName -tableName $tableName -csvFilePath $csvFilePath

    # Generate output file
    Invoke-Sqlcmd -Database $databaseName -ServerInstance $serverInstance -Query "SELECT * FROM dbo.$tableName" > .\SqlResults.txt

    Write-Output "Script execution completed successfully."
} catch {
    Write-Error $_.Exception.Message
}
