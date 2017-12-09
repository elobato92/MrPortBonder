#!/bin/bash
#Sudo check
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
#Get the interfaces to bond, and make sure they exist
echo -e "\nWelcome to the automated port bonding tool\nType the first interface to bond \n"
read int1
if ! test -f /etc/sysconfig/network-scripts/ifcfg-$int1
then
	echo "Error! no interface script with that name! I will build a default one.."
	echo -e "DEVICE=$int1\nNAME=bond-slave1\nTYPE=Ethernet\nBOOTPROTO=none\nONBOOT=yes" > /etc/sysconfig/network-scripts/ifcfg-$int1
fi

echo -e "Now type the name of the second interface"
read int2
if ! test -f /etc/sysconfig/network-scripts/ifcfg-$int2
then
	echo "Error! no interface script with that name! I will build a default one.."
	echo -e "DEVICE=$int2\nNAME=bond-slave2\nTYPE=Ethernet\nBOOTPROTO=none\nONBOOT=yes" > /etc/sysconfig/network-scripts/ifcfg-$int2
fi

#Load the bonding kernel module
echo "Checking for the bonding kernel module..."
if modprobe bonding; then
	echo "kernel module loaded."
else
	echo "error, something went wrong, quitting!"
	exit
fi
#Name the new interface
echo "What would you like the bonded interface to be named?"
read bondname
echo "Bond interfaces need an IP address and subnet mask. Please list the IP address"
read bondip
echo "Now the subnet mask (CIDR form)"
read bondmask
#Final check
echo "Okay, I'm ready to start bonding $int1 to $int2 and name it $bondname"
read -p "Press Y to begin or anything else to quit " -n 1 -r
echo    
if [[ $REPLY =~ ^[Yy]$ ]]
then
	echo "Creating Bond Master..."
	echo -e "DEVICE=$bondname\nNAME=$bondname\nTYPE=Bond\nBONDING_MASTER=yes\nIPADDR=$bondip\nPREFIX=$bondmask\nONBOOT=yes\nBOOTPROTO=none " > /etc/sysconfig/network-scripts/ifcfg-$bondname
	echo "Done"
	echo "Creating Bond Slave for $int1"
	echo -e "MASTER=$bondname\nSLAVE=yes\n" >> /etc/sysconfig/network-scripts/ifcfg-$int1
	echo "Done"
	echo "Creating Bond Slave for $int2"
	echo -e "MASTER=$bondname\nSLAVE=yes\n" >> /etc/sysconfig/network-scripts/ifcfg-$int2
	echo "Done"
	##Reboot the slaves!
	echo "Restarting the network!"
	ifdown ifcfg-$int1
	ifdown ifcfg-$int2
	systemctl restart network
	echo "Complete! Enjoy your new interface!"
else
	echo "Quitting!!"
fi
