# Display the header
Write-Host "   PPPPP    AAAAA   TTTTT   CCCCC   H   H   EEEEE   RRRRR"
Write-Host "   P   P   A     A    T     C       H   H   E       R   R"
Write-Host "   PPPPP   AAAAAAA    T     C       HHHHH   EEEE    RRRRR"
Write-Host "   P       A     A    T     C       H   H   E       R  R"
Write-Host "   P       A     A    T     CCCCC   H   H   EEEEE   R   R"
Write-Host ""

# Automatically detect the installed JetBrains IDEs in the Roaming directory
$ideDirectory = [System.Environment]::GetEnvironmentVariable("APPDATA") + "\JetBrains"
$ideName = ""

# Initialize counter
$count = 0

# Loop through the directories and get the second one
Get-ChildItem -Path $ideDirectory -Directory | ForEach-Object {
    $count++
    Write-Host "Checking directory: $($_.Name)"
    if ($count -eq 2) {
        $ideName = $_.Name
        return
    }
}

# Check if an IDE was found
if (-not $ideName) {
    Write-Host "No JetBrains IDE found. Exiting..."
    Exit
}

Write-Host "Found IDE: $ideName"

# Construct the .vmoptions file path using the detected ideName
$vmOptionsPath = [System.Environment]::GetEnvironmentVariable("USERPROFILE") + "\AppData\Roaming\JetBrains\$ideName\idea64.exe.vmoptions"
Write-Host "vmOptionsPath is: $vmOptionsPath"

# Check if the .vmoptions file exists
if (-not (Test-Path $vmOptionsPath)) {
    Write-Host "Error: The .vmoptions file does not exist. Please check the path and try again."
    Exit
}

# Ask the user if they want to start patching
$userChoice = Read-Host "Do you want to start patching (y/n)?"
while ($userChoice.ToLower() -notin @('y', 'n')) {
    Write-Host "Invalid choice. Please enter 'y' to patch or 'n' to exit."
    $userChoice = Read-Host "Do you want to start patching (y/n)?"
}
if ($userChoice.ToLower() -ne 'y') {
    Write-Host "Patching aborted."
    Exit
}

# Construct the path to the ja-netfilter.jar file using the user profile
$agentPath = [System.Environment]::GetEnvironmentVariable("USERPROFILE") + "\Desktop\Jetbrains Ultimate Tool\jetbra\ja-netfilter.jar"

# Convert backslashes to forward slashes in the file path
$agentPath = $agentPath -replace '\\', '/'

Write-Host "Corrected agent path: $agentPath"

# Get the Java version using java -version and parse it to extract the major version
Write-Host "Running java -version..."
$javaVersionOutput = & java -version 2>&1

# Capture the java version output and extract the version number
$javaVersionMatch = $javaVersionOutput | Select-String -Pattern '"(\d+)\.' 
if ($javaVersionMatch) {
    $javaVersion = $javaVersionMatch.Matches.Groups[1].Value
    Write-Host "Final Java version is: $javaVersion"
} else {
    Write-Host "Error: Unable to detect Java version."
    Exit
}

# Debug check for correct java version
if ($javaVersion -eq '21') {
    Write-Host "Java version 21 detected."
} else {
    Write-Host "Java version is not 21. Detected version: $javaVersion"
}

# Function to check if a line already exists in the .vmoptions file
function Check-IfLineExists {
    param (
        [string]$filePath,
        [string]$line
    )
    
    $fileContent = Get-Content $filePath
    return $fileContent -contains $line
}

# Updating the .vmoptions file for the detected IDE
Write-Host "Updating the .vmoptions file for $ideName..."

# Check if the -javaagent line already exists
$javaAgentLine = "-javaagent:$agentPath=jetbrains"
if (-not (Check-IfLineExists -filePath $vmOptionsPath -line $javaAgentLine)) {
    Add-Content -Path $vmOptionsPath -Value $javaAgentLine
    Write-Host "Added -javaagent line to vmoptions."
} else {
    Write-Host "-javaagent line already exists in vmoptions. Skipping."
}

# If Java version is greater than 17, check and add the --add-opens lines
if ([int]$javaVersion -gt 17) {
    $addOpens1 = "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED"
    $addOpens2 = "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED"

    if (-not (Check-IfLineExists -filePath $vmOptionsPath -line $addOpens1)) {
        Add-Content -Path $vmOptionsPath -Value $addOpens1
        Write-Host "Added --add-opens line 1 to vmoptions."
    } else {
        Write-Host "--add-opens line 1 already exists in vmoptions. Skipping."
    }

    if (-not (Check-IfLineExists -filePath $vmOptionsPath -line $addOpens2)) {
        Add-Content -Path $vmOptionsPath -Value $addOpens2
        Write-Host "Added --add-opens line 2 to vmoptions."
    } else {
        Write-Host "--add-opens line 2 already exists in vmoptions. Skipping."
    }
}

Write-Host "Patch complete for $ideName!"

# Open the .vmoptions file for the user to review
Start-Process $vmOptionsPath

# Ask the user if they want to launch the IDE now (after patching)
$launchChoice = Read-Host "Do you want to launch the IDE now (y/n)?"
while ($launchChoice.ToLower() -notin @('y', 'n')) {
    Write-Host "Invalid choice. Please enter 'y' to launch or 'n' to skip."
    $launchChoice = Read-Host "Do you want to launch the IDE now (y/n)?"
}

if ($launchChoice.ToLower() -eq 'y') {
    # Specify the path to the executable directly in the bin directory
    $programFilesPath = "C:\Program Files\JetBrains\IntelliJ IDEA 2024.3.1\bin"
    $ideExePath = Join-Path -Path $programFilesPath -ChildPath "idea64.exe"

    if (Test-Path $ideExePath) {
        Write-Host "Launching IDE: $ideExePath"
        Start-Process $ideExePath
    } else {
        Write-Host "Error: IntelliJ IDEA executable not found in $programFilesPath. Please check the installation."
    }
}


