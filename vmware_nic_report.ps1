##
## Title: Get ESXi Host Info  
## Date: 03/06/2018
## Version: 1.00
## Author: Ted Emoto    
## This script will retrieve a series of information from esxi host(s). ** Require a connection to vcenter
##

$vcenter = ""


#Import VMWare PowerCli module
Install-Module VMWare.PowerCLI
#Connect to Vcenter ***You need to to add credentials
Connect-VIServer -Server $vcenter 
#Initiate an array to gather information
$dataSets = @()
#Get basic host info from all hosts
$hosts = Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected"}

foreach ($esxhost in $hosts) {

    #Write-Output $esxhost
    $esxcli = Get-EsxCli -VMHost $esxhost
    $esxhostView = Get-VMHost $esxhost | Get-View
    $esxNetwork = $esxhostView.ConfigManager.NetworkSystem
    $esxNetworkView = Get-View $esxNetwork

    $vmNics = $esxhost | Get-VMHostNetworkAdapter -Physical
    
    Foreach ($vmNic in $vmNics) {
    
        $nicInfo = $esxNetworkView.QueryNetworkHint($vmNic)
        $pNics = $esxcli.network.nic.list() | where-object {$vmnic.name -eq $_.name} | Select-Object Description, Link           
        $description = $esxcli.network.nic.list()
        $cdpExtended = $nicInfo.connectedswitchport
        
        $vSwitchName = $esxhost | Get-VirtualSwitch | Where-object {$_.nic -eq $VMnic.DeviceName}  
        $vSwitch = $vSwitchName.name
        
          
       $cdpDetails = New-Object PSObject  
       $cdpDetails | Add-Member -Name EsxName -Value $esxhost.Name -MemberType NoteProperty  
       $cdpDetails | Add-Member -Name VMNic -Value $vmNic -MemberType NoteProperty  
       $cdpDetails | Add-Member -Name vSwitch -Value $vSwitch -MemberType NoteProperty  
       $cdpDetails | Add-Member -Name Link -Value $pNics.Link -MemberType NoteProperty   
       $cdpDetails | Add-Member -Name PortNo -Value $cdpExtended.PortId -MemberType NoteProperty  
       $cdpDetails | Add-Member -Name Device-ID -Value $cdpExtended.devID -MemberType NoteProperty  
       $cdpDetails | Add-Member -Name Switch-IP -Value $cdpExtended.Address -MemberType NoteProperty  
       $cdpDetails | Add-Member -Name MacAddress -Value $vmNic.Mac -MemberType NoteProperty  
       $cdpDetails | Add-Member -Name SpeedMB -Value $vmNic.ExtensionData.LinkSpeed.SpeedMB -MemberType NoteProperty  
       $cdpDetails | Add-Member -Name Duplex -Value $vmNic.ExtensionData.LinkSpeed.Duplex -MemberType NoteProperty  
       $cdpDetails | Add-Member -Name Pnic-Vendor -Value $pNics.Description -MemberType NoteProperty  
       $cdpDetails | Add-Member -Name Pnic-drivers -Value $vmNic.ExtensionData.Driver -MemberType NoteProperty  
       $cdpDetails | Add-Member -Name PCI-Slot -Value $vmNic.ExtensionData.Pci -MemberType NoteProperty  
       $dataSets += $cdpDetails  
    }



}

$dataSets | export-csv -NoTypeInformation -Path C:\temp\vmhost_nic_report.csv