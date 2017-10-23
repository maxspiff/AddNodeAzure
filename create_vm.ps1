#
# create_vm.ps1
#
### Variables
$myLocation = "westeurope"
$myResourceGroup = "testVM-Deployment"
$mySubnet = "testVM-subnet"
$MYvNET = "testVM-VNet"
$myDNSPDomain = "cloudapp.azure.com"
$mypublicdns = $myVM.$myLocation.$myDNSPDomain
$myNetworkSecurityGroup = "testVM-NetSecurityGrp"
$myHostname = "testVM-communicator"

### after login ### Create resource group

New-AzureRmResourceGroup -Name $myResourceGroup -Location $myLocation

####  create network resources 

# Create a subnet configuration
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $mySubnet -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $myResourceGroup -Location $myLocation `
-Name $MYvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzureRmPublicIpAddress -ResourceGroupName $myResourceGroup -Location $myLocation `
-AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "$mypublicdns$(Get-Random)"

#### create network security group

# Create an inbound network security group rule for port 22
$nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp `
-Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
-DestinationPortRange 22 -Access Allow

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleWWW  -Protocol Tcp `
-Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
-DestinationPortRange 8080 -Access Allow

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $myResourceGroup -Location $myLocation `
-Name $myNetworkSecurityGroup -SecurityRules $nsgRuleSSH,$nsgRuleWeb
 
#### Create a virtual network card and associate with public IP address and NSG
$nic = New-AzureRmNetworkInterface -Name myNic -ResourceGroupName $myResourceGroup -Location $myLocation `
-SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

########## create VM configuration

# Define a credential object
$securePassword = ConvertTo-SecureString 'Welkom_01' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("locadm", $securePassword)

# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName $myHostname -VMSize Standard_D1 | `
Set-AzureRmVMOperatingSystem -Linux -ComputerName $myHostname -Credential $cred | `
Set-AzureRmVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 16.04-LTS -Version latest | `
Add-AzureRmVMNetworkInterface -Id $nic.Id

# Configure SSH Keys
#$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"
#Add-AzureRmVMSshPublicKey -VM $vmconfig -KeyData $sshPublicKey -Path "/home/azureuser/.ssh/authorized_keys"

######## Create VM

New-AzureRmVM -ResourceGroupName $myResourceGroup -Location $myLocation -VM $vmConfig

####### Get Public IP

Get-AzureRmPublicIpAddress -ResourceGroupName $myResourceGroup | Select IpAddress

#