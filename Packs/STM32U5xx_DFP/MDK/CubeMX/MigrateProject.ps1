# Migration script
#  Invoke from CMD: powershell.exe \MigrateProject.ps1 -deviceName STM32U585AIIx -uvprojxPath D:\ProjectFolder\Blinky.uvprojx

param 
(
    $deviceName,        # Device name
    $uvprojxPath,       # uvprojx path
    $boardName          # Board name
)

    
Write-Output "**************** Migration Script ****************"

# Project is not compatible with current DFP        
Write-Output "Project was created with an older version of the STM32U5xx_DFP and is not compatible."

# Set project migration result string
$ret = "ProjectMigrationFailed"

$path = Split-Path -Path $uvprojxPath

# Get Software model
$swModel = Get-Content $uvprojxPath | Where-Object {$_ -like ("*<nSecure>*")} 
$swModel = $swModel -replace '\D+([0-9]*).*','$1'
if ($swModel -ne 2) {
    # Software model: NonSecure or Secure
    # No Proper support in older DFP, not able to migrate 
    
    # Display the PopUp window to notify the user.
    $wshell = New-Object -ComObject Wscript.Shell
    $Output = $wshell.Popup(
"Project was created with an earlier version of the STM32U5xx_DFP and is not compatible.
Automatic migration to new STM32U5xx_DFP is not possible for NonSecure/Secure projects.

Do you anyway want to open new empty STM32CubeMX project?", 0, "Note", 4 + 32 + 65536)
    if ($Output -eq 6)
    {
        # Close all uVision project instances
        $ReopenUVision = 0
        [System.Diagnostics.Process[]]$uVisionProcess = Get-Process UV4 -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -and $_.MainWindowTitle -like ("*" + $uvprojxPath + "*")}
        foreach ($uVision in $uVisionProcess)
        {
            Write-Output ("Close " + $uvprojxPath + ".")
            $uVision.CloseMainWindow()
            Sleep 3
            if (!$uVision.HasExited)
            {
                $uVision | Stop-Process -Force
            }
            $ReopenUVision = 1
        }
        
        # Rename old STCubeGenerated folder to STCubeGenerated_old
        $temp_path = $path + "\RTE\Device\" + $deviceName + "\STCubeGenerated\"
        if (Test-Path -Path $temp_path)
        {
            Rename-Item -Path $temp_path -NewName "STCubeGenerated_old" -Force
        }
        # Delete old MX_Device.h
        $temp_path = $path + "\RTE\Device\" + $deviceName + "\MX_Device.h"
        if (Test-Path -Path $temp_path)
        {
            Remove-Item -Path $temp_path -Force
        }
        # Delete old FrameworkCubeMX.gpdsc
        $temp_path = $path + "\RTE\Device\" + $deviceName + "\FrameworkCubeMX.gpdsc"
        if (Test-Path -Path $temp_path)
        {
            Remove-Item -Path $temp_path -Force
        }
        
        # Modify_uVisionProject - uvprojx
        Write-Output ("Update " + $uvprojxPath + ".")
        $Content = (Get-Content $uvprojxPath -Raw) -replace "(?ms)^\s*<Group>\s*(\r|\n|\r\n|\n\r)\s*<GroupName>:STM32CubeMX:Common Sources</GroupName>.*?</Group>\s*(\r|\n|\r\n|\n\r)", ''
        Set-Content $uvprojxPath -value $Content

        # Modify_uVisionProject - uvoptx
        $uvoptxPath = $uvprojxPath -replace ".uvprojx", ".uvoptx"
        Write-Output ("Update " + $uvoptxPath + ".")
        (Get-Content $uvoptxPath -Raw) -replace "(?ms)^\s*<Group>\s*(\r|\n|\r\n|\n\r)\s*<GroupName>:STM32CubeMX:Common Sources</GroupName>.*?</Group>\s*(\r|\n|\r\n|\n\r)", '' | Set-Content $uvoptxPath

        #Reopen uVision
        if ($ReopenUVision -eq 1)
        {
            Write-Output "Reopen $uvprojxPath."
            Start-Process -FilePath "$uvprojxPath"
        }
        
        $ret = "ProjectMigrationSucceeded"
    }
}
else 
{
    # Software model: no Trust Zone
    # Display the PopUp window to notify the user and decide whether to migrate to new DFP.
    $wshell = New-Object -ComObject Wscript.Shell
    $popUpMessage = 
@'
Project was created with an older version of the STM32U5xx_DFP and is not compatible.
Do you want to migrate the project to new STM32U5xx_DFP?
'@
    $Output = $wshell.Popup($popUpMessage, 0, "Note", 4 + 32 + 4096 + 65536)

    if ($Output -eq 6)
    {
        #Migration confirmed by the user            
        Write-Output "Migrating to new DFP..."

        # Close all uVision project instances
        $ReopenUVision = 0
        [System.Diagnostics.Process[]]$uVisionProcess = Get-Process UV4 -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -and $_.MainWindowTitle -like ("*" + $uvprojxPath + "*")}
        foreach ($uVision in $uVisionProcess)
        {
            Write-Output ("Close " + $uvprojxPath + ".")
            $uVision.CloseMainWindow()
            Sleep 3
            if (!$uVision.HasExited)
            {
                $uVision | Stop-Process -Force
            }
            $ReopenUVision = 1
        }

        $oldPath = $path + "\RTE\Device\" + $deviceName

        # Update FrameworkCubeMX.gpdsc
        Write-Output ("Update " + $oldPath + "\FrameworkCubeMX.gpdsc.")
        # Remove "<command>..." line 
        $Content = Get-Content ($oldPath + "\FrameworkCubeMX.gpdsc") | Where-Object {$_ -notlike ("*<command>*")}

        # Replace "<workingDir>.." line
        $LineNumber = $Content | Select-String "<workingDir>" | Select-Object -ExpandProperty 'LineNumber'
        $Content[$LineNumber-1] = 
@'
      <workingDir>$PBoard/$B/STM32CubeMX</workingDir>               <!-- path is specified either absolute or relative to PDSC or GPDSC file -->
      <exe>
        <command>$SMDK/CubeMX/STM32CubeMxLauncher.exe</command>
        <argument>$D</argument>                                     <!-- D = Device (Dname/Dvariant as configured by environment) -->
        <argument>#P</argument>                                     <!-- Project path and project name (as configured by environment) -->
        <argument>$SMDK/CubeMX/noTZ</argument>                      <!-- absolute or relative to ftl templates. $S = Device Family Pack base folder -->
        <argument>$B</argument>                                     <!-- B = Board name -->
      </exe>
'@


        # Update generator component version
        $LineNumber = $Content | Select-String "<component\s+generator\s*=\s*`"STM32CubeMX`"" | Select-Object -ExpandProperty 'LineNumber'
        $Content[$LineNumber-1] = 
@'
    <component generator="STM32CubeMX" Cvendor="Keil" Cclass="Device" Cgroup="STM32Cube Framework" Csub="STM32CubeMX" Cversion="2.0.0" condition="STCubeMX">
'@
        Set-Content ($oldPath + "\FrameworkCubeMX.gpdsc") -value $Content

        #Replace Project files
        $Content = (Get-Content($oldPath + "\FrameworkCubeMX.gpdsc") -Raw) -replace "(?ms)^\s*<project_files>\s*(\r|\n|\r\n|\n\r)\s*.*?</project_files>",
@'
      <project_files>
        <file category="include" name="Inc/"/>
        <file category="source" name="Src/main.c"/>
        <file category="header" name="Inc/stm32u5xx_it.h"/>
        <file category="source" name="Src/stm32u5xx_it.c"/>
        <file category="other" name="STM32CubeMX.ioc"/>
      </project_files>
'@
        $Content = $Content -replace 'name="STCubeGenerated/', 'name="'
    
        # Save updated FrameworkCubeMX.gpdsc
        Set-Content ($oldPath + "\FrameworkCubeMX.gpdsc") -value $Content

        # Move STM32CubeMX things from "..RTE\Device\Device name\" to "..Board\BoardName\STM32CubeMX"
        $newPath = $path + "\Board\"
        $relativeNewPath = ".\Board\"
        if ((Test-Path -Path $newPath) -eq $false)
        {
          New-Item -Path $newPath -ItemType Directory -Force
        }
        if ($boardName)
        {
          $newPath = $newPath + $boardName + "\"
          $relativeNewPath = $relativeNewPath  + $boardName + "\"
          if ((Test-Path -Path $newPath) -eq $false)
          {
            New-Item -Path $newPath -ItemType Directory
          }
        }
        $newPath = $newPath + "STM32CubeMX\"
        $relativeNewPath = $relativeNewPath  + "STM32CubeMX\"

        if ((Test-Path -Path $newPath) -eq $false)
        {
          New-Item -Path $newPath -ItemType Directory
        }

        Write-Output ("Move STM32CubeMX files to " + $newPath + "STM32CubeMX")

        Move-Item -path ($oldPath + "\STCubeGenerated\*") -Destination ($newPath)
        Remove-Item -path ($oldPath + "\STCubeGenerated")
        Rename-Item -path ($newPath + "STCubeGenerated.ioc") -NewName "STM32CubeMX.ioc"        
        
        Move-Item -path ($oldPath + "\FrameworkCubeMX.gpdsc") -Destination ($newPath + "\FrameworkCubeMX.gpdsc")
        Move-Item -path ($oldPath + "\MX_Device.h") -Destination ($newPath + "\MX_Device.h")      

        # Modify_uVisionProject - uvprojx
        Write-Output ("Update " + $uvprojxPath + ".")
        #Copy-Item -Path $uvprojxPath -Destination ($uvprojxPath + "_old")
        $Content = (Get-Content $uvprojxPath -Raw) -replace "(?ms)^\s*<Group>\s*(\r|\n|\r\n|\n\r)\s*<GroupName>:STM32CubeMX:Common Sources</GroupName>.*?</Group>\s*(\r|\n|\r\n|\n\r)", ''
        $Content = $Content -replace "<gpdsc name=`"RTE.*?gpdsc`">", ('<gpdsc name="' + $relativeNewPath + 'FrameworkCubeMX.gpdsc">')
        Set-Content $uvprojxPath -value $Content

        # Modify_uVisionProject - uvoptx
        $uvoptxPath = $uvprojxPath -replace ".uvprojx", ".uvoptx"
        Write-Output ("Update " + $uvoptxPath + ".")
        #Copy-Item -Path $uvoptxPath -Destination ($uvoptxPath + "_old")
        (Get-Content $uvoptxPath -Raw) -replace "(?ms)^\s*<Group>\s*(\r|\n|\r\n|\n\r)\s*<GroupName>:STM32CubeMX:Common Sources</GroupName>.*?</Group>\s*(\r|\n|\r\n|\n\r)", '' | Set-Content $uvoptxPath

        #Reopen uVision
        if ($ReopenUVision -eq 1)
        {
            Write-Output "Reopen $uvprojxPath."
            Start-Process -FilePath "$uvprojxPath"
        }
        
        $ret = "ProjectMigrationSucceeded"
    }
}

# Save result in temp file
New-Item -Path $path -Name "MigrateProject_Result.txt" -ItemType File -Value $ret
