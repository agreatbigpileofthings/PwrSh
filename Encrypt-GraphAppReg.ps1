<#
.Synopsis
   Create a Key and Encrypt Azure App Registration Value
.DESCRIPTION
   Quick and Dirty two part chunks to encrypt the app registration value.
.EXAMPLE
   Run this manually
#>


<# Part One #>
# Generate a 32-byte (256-bit) AES key
$key = New-Object byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($key)

# Save the key to a file (replace path if you want)
$keyFilePath = "C:\Scripts\Info\graphAes.key"
$key | Set-Content -Path $keyFilePath -Encoding Byte

Write-Host "AES key saved to $keyFilePath"

<# Part Two #>
# Read the key you saved earlier
$keyFilePath = "C:\Scripts\Info\graphAes.key"
$key = Get-Content -Path $keyFilePath -Encoding Byte

# Prompt for your client secret securely
$secureSecret = Read-Host "Enter your Azure AD App Client Secret" -AsSecureString ## when prompted enter in the Value info from the app registration

# Encrypt the secret using the AES key and convert to string
$encryptedSecret = $secureSecret | ConvertFrom-SecureString -Key $key

# Save the encrypted secret to a file (replace path if needed)
$secretFilePath = "C:\Scripts\Info\graphSecret.txt"
Set-Content -Path $secretFilePath -Value $encryptedSecret

Write-Host "Encrypted client secret saved to $secretFilePath"
