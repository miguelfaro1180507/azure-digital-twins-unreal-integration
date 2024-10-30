param (
    [string]$resourceGroupName = "YourResourceGroupName",      # Replace with your desired resource group name
    [string]$location = "YourLocation",                        # Replace with your desired Azure region
    [string]$digitalTwinName = "YourDigitalTwinName",        # Replace with your desired digital twin name
    [string]$adxClusterName = "YourADXClusterName",          # Replace with your desired ADX cluster name
    [string]$adxDatabaseName = "YourADXDatabaseName"         # Replace with your desired ADX database name
)

# Function to create a resource group
function Create-ResourceGroup {
    param (
        [string]$resourceGroupName,
        [string]$location
    )

    Write-Host "Creating Resource Group: $resourceGroupName in $location"
    az group create --name $resourceGroupName --location $location
}

# Function to create a digital twin
function Create-DigitalTwin {
    param (
        [string]$resourceGroupName,
        [string]$digitalTwinName
    )

    Write-Host "Creating Digital Twin: $digitalTwinName in Resource Group: $resourceGroupName"
    az dt create --resource-group $resourceGroupName --name $digitalTwinName
}

# Function to create an ADX cluster
function Create-ADXCluster {
    param (
        [string]$resourceGroupName,
        [string]$adxClusterName,
        [string]$location
    )

    Write-Host "Creating Azure Data Explorer (ADX) Cluster: $adxClusterName in Resource Group: $resourceGroupName"
    az kusto cluster create --name $adxClusterName --resource-group $resourceGroupName --location $location --sku "Dev(NoSLA)_Standard_D11"
}

# Function to create an ADX database
function Create-ADXDatabase {
    param (
        [string]$resourceGroupName,
        [string]$adxClusterName,
        [string]$adxDatabaseName
    )

    Write-Host "Creating Azure Data Explorer (ADX) Database: $adxDatabaseName in Cluster: $adxClusterName"
    az kusto database create --cluster-name $adxClusterName --database-name $adxDatabaseName --resource-group $resourceGroupName --read-write-database
}

# Function to prompt for AAD credentials
function Prompt-AADCredentials {
    Write-Host "Please enter your Azure Active Directory (AAD) credentials:"
    $username = Read-Host -Prompt "Username"
    $password = Read-Host -Prompt "Password" -AsSecureString

    # Authenticate with AAD
    $aadCredential = New-Object System.Management.Automation.PSCredential($username, $password)
    Connect-AzAccount -Credential $aadCredential
}

# Main script execution
try {
    # Prompt for AAD credentials
    Prompt-AADCredentials

    # Create resource group
    Create-ResourceGroup -resourceGroupName $resourceGroupName -location $location
    
    # Create digital twin
    Create-DigitalTwin -resourceGroupName $resourceGroupName -digitalTwinName $digitalTwinName
    
    # Create ADX cluster
    Create-ADXCluster -resourceGroupName $resourceGroupName -adxClusterName $adxClusterName -location $location
    
    # Create ADX database
    Create-ADXDatabase -resourceGroupName $resourceGroupName -adxClusterName $adxClusterName -adxDatabaseName $adxDatabaseName

    # Output Unreal configuration paths and success message
    Write-Host "##############################################"
    Write-Host "##############################################"
    Write-Host "####                                      ####"
    Write-Host "####        Deployment Succeeded          ####"
    Write-Host "####                                      ####"
    Write-Host "##############################################"
    Write-Host "##############################################"
    Write-Host "Unreal config file path: /home/user/azure-digital-twins-unreal-integration/output/unreal-plugin-config.json"
    Write-Host "Mock devices config file path: /home/user/azure-digital-twins-unreal-integration/output/mock-devices.json"
} catch {
    Write-Host "An error occurred: $_"
}
