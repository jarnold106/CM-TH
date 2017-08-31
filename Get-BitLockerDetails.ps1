FUNCTION Get-BitLockerDetails {
    <#
    .Synopsis 
        Gets the current BitLocker details of a given system.

    .Description 
        Gets the current BitLocker details to include recovery key of a given system.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Example 
        Get-BitlockerDetails
        '<COMPUTERNAME>','<COMPUTERNAME>','<COMPUTERNAME>' | Get-BitlockerDetails 
        Get-BitlockerDetails SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-BitlockerDetails
        Get-BitLockerDetails $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-BitlockerDetails

    .Notes 
        Updated: 2017-08-20
        LEGAL: Copyright (C) 2017  Jeremy Arnold
        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
    
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/>.
    #>

        PARAM(
    	    [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
            $Computer='.'
        )

	    BEGIN{

            $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
            Write-Information -MessageData "Started at $datetime" -InformationAction Continue
            $stopwatch = New-Object System.Diagnostics.Stopwatch
            $stopwatch.Start()
            $total = 0
	    }

        PROCESS{
            $intOne = 0
            $Computer = $computer.ToString()
            $drives = Invoke-Command -ComputerName $Computer -ScriptBlock { Get-PSDrive | Where-Object {$_.root -match "\w{1}:\\" } } #get a list of drives on a given computer
            $driveLetters = $drives.Root.ToString() #convert to string
            $driveLetters = $driveLetters.Trim("\") #trim for input to manage-bde.exe
            $bitLockerStatus = Invoke-Command -ComputerName $Computer -ScriptBlock {c:\windows\system32\manage-bde.exe -status } #get bitlocker status (need debug for multiple drives)
            $bitLockerStatus = $bitLockerStatus | Select-String ":" | ConvertFrom-String -Delimiter ":" -PropertyNames "Property","Value" #convert text string to PS custom object using ":" as string delimiter
            $objectProp = $bitLockerStatus | Get-Member -MemberType Properties | Select-Object -Property name # create a list of the object's properties
            foreach ($object in $bitLockerStatus){
                    
                    foreach ($property in $objectProp){
                        
                        $bitLockerStatus[$intOne].($property.name) = ($bitLockerStatus[$intOne].($property.name)).ToString()
                        $bitLockerStatus[$intOne].($property.name) = ($bitLockerStatus[$intOne].($property.name)).trim()

                    }
            $intOne ++
            }# foreach through each object and trim the unwanted null characaters

            $keys = @() #build a key array for all drives

            foreach ($drive in $driveLetters){
                    $bitLockerKey = Invoke-Command -ComputerName $Computer -ScriptBlock {c:\windows\system32\manage-bde.exe -protectors -get $drive -type recoverypassword } #get bitlocker key
                    $bitLockerKey = ($bitLockerKey | ConvertFrom-String).p2[-1]
                    $key = [pscustomObject]@{
                    
                            Property = $drive
                            Value = $bitLockerKey
                    }
            $keys += $key
            }
            
            $bitLockerStatus += $keys #add the bitlocker password to the custom powershell object that will be returned
            $output = [pscustomObject]@{
            
                    Computer = $Computer
                    Disks = $bitLockerStatus | Select-Object -Skip 2
            
            }
            
            $elapsed = $stopwatch.Elapsed
            $total++
            
            Write-Information -MessageData "System $total `t $ThisComputer `t Time Elapsed: $elapsed" -InformationAction Continue

        $output #return the custom powershell object with properties Computer and Disks ( an array of info per disk on the Computer)
        }

        END{
            $elapsed = $stopwatch.Elapsed

            Write-Information -MessageData "Total Systems: $total `t Total time elapsed: $elapsed" -InformationAction Continue
	    }
}    
