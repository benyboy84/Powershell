Connect-AzAccount

#Get-AzLocation

#Set-AzContext -SubscriptionId "Azure subscription 1"

#Ressource Group
New-AzResourceGroup -Name RG-NET-CAQC-PROD-001 -Location "Canada East"
New-AzResourceGroup -Name RG-NET-USVA2-PROD-001 -Location "East US 2"

#Vnet
$Subnet1 = New-AzVirtualNetworkSubnetConfig -Name AzureBastionSubnet -AddressPrefix 10.0.1.0/24 
$Subnet2 = New-AzVirtualNetworkSubnetConfig -Name AzureFirewallSubnet -AddressPrefix 10.0.2.0/24
New-AzVirtualNetwork -Name VNET-CAQC-PROD-001 -ResourceGroupName RG-NET-CAQC-PROD-001 -Location "Canada East" -AddressPrefix 10.0.0.0/16 -Subnet $Subnet1, $Subnet2

$Subnet1 = New-AzVirtualNetworkSubnetConfig -Name ServerSubnet -AddressPrefix 10.1.1.0/24 
$Subnet2 = New-AzVirtualNetworkSubnetConfig -Name PrivateSubnet -AddressPrefix 10.1.2.0/24 
New-AzVirtualNetwork -Name VNET-USVA2-PROD-001 -ResourceGroupName RG-NET-USVA2-PROD-001 -Location "East US 2" -AddressPrefix 10.1.0.0/16 -Subnet $Subnet1, $Subnet2

#Public IP
New-AzPublicIpAddress -Name IP-FW-CAQC-PROD-001 -ResourceGroupName RG-NET-CAQC-PROD-001 -Location "Canada East" -IpAddressVersion IPv4 -Sku Standard -Tier Regional -AllocationMethod Static 

#Virtual Network Gateway
$VNET = Get-AzVirtualNetwork -ResourceGroupName RG-NET-CAQC-PROD-001 -Name VNET-CAQC-PROD-001
Add-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix 10.0.3.0/27 -VirtualNetwork $VNET
$VNET | Set-AzVirtualNetwork
$IP = New-AzPublicIpAddress -Name IP-VGW-CAQC-PROD-001 -ResourceGroupName RG-NET-CAQC-PROD-001 -Location "Canada East" -IpAddressVersion IPv4 -Sku Standard -Tier Regional -AllocationMethod Static 
$SUBNET = Get-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $VNET
$GWCONFIG = New-AzVirtualNetworkGatewayIpConfig -Name VGW-CAQC-PROD-001_Conf -SubnetId $SUBNET.Id -PublicIpAddressId $IP.Id
New-AzVirtualNetworkGateway -Name VGW-CAQC-PROD-001 -ResourceGroupName RG-NET-CAQC-PROD-001 -Location "Canada East" -IpConfigurations $GWCONFIG -GatewayType VPN -VpnType RouteBased -GatewaySku VpnGw2

#Local Network Gateway
New-AzLocalNetworkGateway -Name LGW-CAQC-PROD-001 -ResourceGroupName RG-NET-CAQC-PROD-001 -Location "Canada East" -GatewayIpAddress 192.226.160.133 -AddressPrefix 192.168.0.0/24

#VPN connection
$GATEWAY = Get-AzVirtualNetworkGateway -Name VGW-CAQC-PROD-001 -ResourceGroupName RG-NET-CAQC-PROD-001
$LOCAL = Get-AzLocalNetworkGateway -Name LGW-CAQC-PROD-001 -ResourceGroupName RG-NET-CAQC-PROD-001
New-AzVirtualNetworkGatewayConnection -Name CN_VGW-CAQC-PROD-001_TO_LGW-CAQC-PROD-001 -ResourceGroupName RG-NET-CAQC-PROD-001 -Location "Canada East" -VirtualNetworkGateway1 $GATEWAY -LocalNetworkGateway2 $LOCAL -ConnectionType IPsec -SharedKey 'abc123'

#Network peering
$VNET1 = Get-AzVirtualNetwork -ResourceGroupName RG-NET-CAQC-PROD-001 -Name VNET-CAQC-PROD-001
$VNET2 = Get-AzVirtualNetwork -ResourceGroupName RG-NET-USVA2-PROD-001 -Name VNET-USVA2-PROD-001
Add-AzVirtualNetworkPeering -Name CN_VNET-CAQC-PROD-001_TO_VNET-USVA2-PROD-001 -VirtualNetwork $VNET1 -RemoteVirtualNetworkId $VNET2.Id -AllowForwardedTraffic -AllowGatewayTransit
Add-AzVirtualNetworkPeering -Name CN_VNET-USVA2-PROD-001_TO_VNET-CAQC-PROD-001 -VirtualNetwork $VNET2 -RemoteVirtualNetworkId $VNET1.Id -AllowForwardedTraffic -UseRemoteGateways

#Network security group
New-AzNetworkSecurityGroup -Name NSG-ICMPALLOW-USVA2-PROD-001 -ResourceGroupName RG-NET-USVA2-PROD-001 -Location "East US 2"
$NSG = Get-AzNetworkSecurityGroup -Name NSG-ICMPALLOW-USVA2-PROD-001 -ResourceGroupName RG-NET-USVA2-PROD-001
$NSG | Add-AzNetworkSecurityRuleConfig -Name icmp-allow -Description "Allow ICMP" -Access Allow -Protocol Icmp -Direction Inbound -Priority 101 -SourceAddressPrefix "*" -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *
$NSG | Set-AzNetworkSecurityGroup
$VNET = Get-AzVirtualNetwork -ResourceGroupName RG-NET-USVA2-PROD-001 -Name VNET-USVA2-PROD-001
Set-AzVirtualNetworkSubnetConfig -Name ServerSubnet -VirtualNetwork $VNET -AddressPrefix 10.1.1.0/24 -NetworkSecurityGroup $NSG
$VNET | Set-AzVirtualNetwork

#Configure Vnet DNS
$VNET = Get-AzVirtualNetwork -ResourceGroupName RG-NET-CAQC-PROD-001 -Name VNET-CAQC-PROD-001
$ARRAY = @("8.8.8.8")
$NEWOBJECT = New-Object -Type PSObject -Property @{"DnsServers" = $array}
$VNET.DhcpOptions = $NEWOBJECT
$VNET | Set-AzVirtualNetwork
$VNET = Get-AzVirtualNetwork -ResourceGroupName RG-NET-USVA2-PROD-001 -Name VNET-USVA2-PROD-001
$ARRAY = @("8.8.8.8")
$NEWOBJECT = New-Object -Type PSObject -Property @{"DnsServers" = $array}
$VNET.DhcpOptions = $NEWOBJECT
$VNET | Set-AzVirtualNetwork

#Bastion
New-AzPublicIpAddress -Name IP-BS-CAQC-PROD-001 -ResourceGroupName RG-NET-CAQC-PROD-001 -Location "Canada East" -IpAddressVersion IPv4 -Sku Standard -Tier Regional -AllocationMethod Static 
New-AzBastion -Name BS-CAQC-PROD-001 -ResourceGroupName RG-NET-CAQC-PROD-001 -PublicIpAddressRgName RG-NET-CAQC-PROD-001 -PublicIpAddressName IP-BS-CAQC-PROD-001 -VirtualNetworkRgName RG-NET-CAQC-PROD-001 -VirtualNetworkName VNET-CAQC-PROD-001 -Sku Standard

#Nat Gateway
$IP = New-AzPublicIpAddress -Name IP-NGW-USVA2-PROD-001 -ResourceGroupName RG-NET-USVA2-PROD-001 -Location "East US 2" -IpAddressVersion IPv4 -Sku Standard -Tier Regional -AllocationMethod Static 
$NAT = New-AzNatGateway -Name NGW-USVA2-PROD-001 -ResourceGroupName RG-NET-USVA2-PROD-001 -Location "East US 2" -Sku Standard -PublicIpAddress $IP 
$VNET = Get-AzVirtualNetwork -ResourceGroupName RG-NET-USVA2-PROD-001 -Name VNET-USVA2-PROD-001
Set-AzVirtualNetworkSubnetConfig -Name PrivateSubnet -VirtualNetwork $VNET -AddressPrefix 10.1.2.0/24 -InputObject $NAT
$VNET | Set-AzVirtualNetwork

#Firewall
$IP = Get-AzPublicIpAddress -Name IP-FW-CAQC-PROD-001 -ResourceGroupName RG-NET-CAQC-PROD-001
$VNET = Get-AzVirtualNetwork -ResourceGroupName RG-NET-CAQC-PROD-001 -Name VNET-CAQC-PROD-001
$FW = New-AzFirewall -Name FW-CAQC-PROD-001 -ResourceGroupName RG-NET-CAQC-PROD-001 -Location "Canada East" -VirtualNetwork $VNET -PublicIpAddress $IP -SkuTier Premium 
$FWPRIVATEIP = $FW.IpConfigurations.privateipaddress

#Route table
New-AzRouteTable -Name ROUTE-USVA2-PROD-001 -ResourceGroupName RG-NET-USVA2-PROD-001 -Location "East US 2"