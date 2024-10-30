$root_path = Split-Path $PSScriptRoot -Parent

#region functions
function New-Password {
    param(
        [int] $length = 15
    )

    $punc = 46..46
    $digits = 48..57
    $lcLetters = 65..90
    $ucLetters = 97..122
    $password = `
        [char](Get-Random -Count 1 -InputObject ($lcLetters)) + `
        [char](Get-Random -Count 1 -InputObject ($ucLetters)) + `
        [char](Get-Random -Count 1 -InputObject ($digits)) + `
        [char](Get-Random -Count 1 -InputObject ($punc))
    $password += get-random -Count ($length - 4) `
        -InputObject ($punc + $digits + $lcLetters + $ucLetters) |`
        ForEach-Object -begin { $aa = $null } -process { $aa += [char] $_ } -end { $aa }

    return $password
}

function Get-EnvironmentHash {
    param(
        [int] $hash_length = 8
    )
    $env_hash = (New-Guid).Guid.Replace('-', '').Substring(0, $hash_length).ToLower()

    return $env_hash
}

function Set-EnvironmentHash {
    param(
        [int] $hash_length = 4
    )
    $script:env_hash = Get-EnvironmentHash -hash_length $hash_length
}

function Set-AzureAccount {
    param()

    Write-Host
    Write-Host "Retrieving your current Azure subscription..."
    Start-Sleep -Milliseconds 500

    $account = az account show | ConvertFrom-Json

    $option = Get-InputSelection `
        -options @("Yes", "No. I want to use a different subscription") `
        -text "You are currently using the Azure subscription '$($account.name)'. Do you want to keep using it?" `
        -default_index 1
    
    if ($option -eq 2) {
        $accounts = az account list | ConvertFrom-Json | Sort-Object -Property name

        $account_list = $accounts | Select-Object -Property @{ label="displayName"; expression={ "$($_.name): $($_.id)" } }
        $option = Get-InputSelection `
            -options $account_list.displayName `
            -text "Choose a subscription to use from this list (using its Index):" `
            -separator "`r`n`r`n"

        $account = $accounts[$option - 1]

        Write-Host "Switching to Azure subscription '$($account.name)' with id '$($account.id)'."
        az account set -s $account.id
    }
}

function Read-CliVersion {
    param (
        [version]$min_version = "2.50"  # Updated CLI version
    )

    $az_version = az version | ConvertFrom-Json
    [version]$cli_version = $az_version.'azure-cli'

    Write-Host
    Write-Host "Verifying your Azure CLI installation version..."
    Start-Sleep -Milliseconds 500

    if ($min_version -gt $cli_version) {
        Write-Host
        Write-Host "You are currently using the Azure CLI version $($cli_version) and this wizard requires version $($min_version) or later. You can update your CLI installation with 'az upgrade' and come back at a later time."

        return $false
    }
    else {
        Write-Host
        Write-Host "Great! You are using a supported Azure CLI version."

        return $true
    }
}

function Read-CliExtensionVersion {
    param(
        [string]$name,
        [version]$min_version,
        [bool]$auto_update = $true
    )

    $az_version = az version | ConvertFrom-Json
    [version]$extension_version = $az_version.extensions.$name

    Write-Host
    Write-Host "Verifying '$name' extension version..."
    Start-Sleep -Milliseconds 500

    if ($null -eq $extension_version) {
        Write-Host
        Write-Host "You currently don't have the '$name' CLI extension. Installing it now..."
        az extension add --name $name

        return $true
    }
    elseif ($min_version -gt $extension_version) {
        Write-Host
        Write-Host "You are currently using the version $($extension_version) of the extension '$($name)' and this wizard requires version $($min_version) or later."
        if ($auto_update) {
            az extension update -n $name
            return $true
        }
        else {
            Write-Host "You can find more details to manage extensions with Azure CLI here. https://docs.microsoft.com/en-us/cli/azure/azure-cli-extensions-overview"
            return $false
        }
    }
    else {
        Write-Host "Great! You are using a supported version of the extension '$name'."
        return $true
    }
}

function New-Deployment() {
    # Set environment's unique hash
    Set-EnvironmentHash -hash_length 8

    Write-Host "################################################"
    Write-Host "#### Unreal Engine and Azure Digital Twins (ADT) & Azure Data Explorer (ADX) Integration ####"
    Write-Host "################################################"

    #region validate CLI version
    $cli_valid = Read-CliVersion -min_version "2.50"
    if (!$cli_valid) { return $null }

    $adt_ext_valid = Read-CliExtensionVersion -min_version "0.10.0" -name 'azure-iot' -auto_update $true
    $adx_ext_valid = Read-CliExtensionVersion -min_version "0.8.0" -name 'kusto' -auto_update $true
    if (!$adt_ext_valid -or !$adx_ext_valid) { return $null }
    #endregion

    Set-AzureAccount

    Write-Host "Registering required ADT and ADX providers in your subscription"
    az provider register --namespace 'Microsoft.DigitalTwins'
    az provider register --namespace 'Microsoft.Kusto'

    # Deployment logic for ADT, ADX, and Unreal Engine integration setup follows.
}
