FUNCTION Get-AppLockerEvents {
    <#
    .Synopsis 
        Gets AppLocker Events 8002, 8003, and 8004 from a given system.

    .Description 
        Gets AppLocker Events 8002, 8003, and 8004 from a given system.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Get-AppLockerEvents
        Get-AppLockerEvents SomeHostName.domain.com
        Get-AppLockerEvents| Select-Object Fqbn
        Get-Content C:\hosts.csv | Get-AppLockerEvents
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-AppLockerEvents

    .Notes 
        Updated: 2017-08-30
        LEGAL: Copyright (C) 2017  Anthony Phipps
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
            $Computer = $env:COMPUTERNAME,
            [Parameter()]
            $Fails

        );

	BEGIN{

            $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
            Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

            $stopwatch = New-Object System.Diagnostics.Stopwatch;
            $stopwatch.Start();

            $total = 0;

            class Event
            {
                # Internal Fields
                [String] $Computer
                [String] $DateScanned

                # Base Event fields
                [String] $Message
                [String] $Id
                [String] $Version
                [String] $Qualifiers
                [String] $Level
                [String] $Task
                [String] $Opcode
                [String] $Keywords
                [String] $RecordId
                [String] $ProviderName
                [String] $ProviderId
                [String] $LogName
                [String] $ProcessId
                [String] $ThreadId
                [String] $MachineName
                [String] $UserId
                [String] $TimeCreated
                [String] $ActivityId
                [String] $RelatedActivityId
                [String] $ContainerLog
                [String] $LevelDisplayName
                [String] $OpcodeDisplayName
                [String] $TaskDisplayName

                # AppLocker log fields
                [String] $PolicyNameLength
                [String] $PolicyNameBuffer
                [String] $RuleId
                [String] $RuleNameLength
                [String] $RuleNameBuffer
                [String] $RuleSddlLength
                [String] $RuleSddlBuffer
                [String] $TargetUser
                [String] $TargetProcessId
                [String] $FilePathLength
                [String] $FilePathBuffer
                [String] $FileHashLength
                [String] $FileHash
                [String] $FqbnLength
                [String] $Fqbn
                [String] $TargetLogonId
            }
	    }

    PROCESS{
            
            $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
            

            $Events = Get-WinEvent -ComputerName $Computer -FilterHashTable @{LogName="Microsoft-Windows-AppLocker/EXE and DLL"; ID="8002","8003","8004"}

            $Events |
                Foreach-Object {
                    $output = $null;
                    $output = [Event]::new();

                    $EventXML = [xml]$_.ToXml();

                    $output.Computer = $Computer;
                    $output.DateScanned = Get-Date -Format u;

                    $output.Message = $_.Message;
                    $output.Id = $_.Id;
                    $output.Version = $_.Version;
                    $output.Qualifiers = $_.Qualifiers;
                    $output.Level = $_.Level;
                    $output.Task = $_.Task;
                    $output.Opcode = $_.Opcode;
                    $output.Keywords = $_.Keywords;
                    $output.RecordId = $_.RecordId;
                    $output.ProviderName = $_.ProviderName;
                    $output.ProviderId = $_.ProviderId;
                    $output.LogName = $_.LogName;
                    $output.ProcessId = $_.ProcessId;
                    $output.ThreadId = $_.ThreadId;
                    $output.MachineName = $_.MachineName;
                    $output.UserId = $_.UserId;
                    $output.TimeCreated = $_.TimeCreated;
                    $output.ActivityId = $_.ActivityId;
                    $output.RelatedActivityId = $_.RelatedActivityId;
                    $output.ContainerLog = $_.ContainerLog;
                    $output.LevelDisplayName = $_.LevelDisplayName;
                    $output.OpcodeDisplayName = $_.OpcodeDisplayName;
                    $output.TaskDisplayName = $_.TaskDisplayName;

                    # AppLocker fields
                    $output.PolicyNameLength = $EventXML.Event.UserData.RuleAndFileData.PolicyNameLength;
                    $output.PolicyNameBuffer = $EventXML.Event.UserData.RuleAndFileData.PolicyNameBuffer;
                    $output.RuleId = $EventXML.Event.UserData.RuleAndFileData.RuleId;
                    $output.RuleNameLength = $EventXML.Event.UserData.RuleAndFileData.RuleNameLength;
                    $output.RuleNameBuffer = $EventXML.Event.UserData.RuleAndFileData.RuleNameBuffer;
                    $output.RuleSddlLength = $EventXML.Event.UserData.RuleAndFileData.RuleSddlLength;
                    $output.RuleSddlBuffer = $EventXML.Event.UserData.RuleAndFileData.RuleSddlBuffer;
                    $output.TargetUser = $EventXML.Event.UserData.RuleAndFileData.TargetUser;
                    $output.TargetProcessId = $EventXML.Event.UserData.RuleAndFileData.TargetProcessId;
                    $output.FilePathLength = $EventXML.Event.UserData.RuleAndFileData.FilePathLength;
                    $output.FilePathBuffer = $EventXML.Event.UserData.RuleAndFileData.FilePathBuffer;
                    $output.FileHashLength = $EventXML.Event.UserData.RuleAndFileData.FileHashLength;
                    $output.FileHash = $EventXML.Event.UserData.RuleAndFileData.FileHash;
                    $output.FqbnLength = $EventXML.Event.UserData.RuleAndFileData.FqbnLength;
                    $output.Fqbn = $EventXML.Event.UserData.RuleAndFileData.Fqbn;
                    $output.TargetLogonId = $EventXML.Event.UserData.RuleAndFileData.TargetLogonId;

                    Return $output;
               }
        }

    END{
        $elapsed = $stopwatch.Elapsed;

        Write-Information -MessageData "Total Systems: $total `t Total time elapsed: $elapsed" -InformationAction Continue;
	};
};


