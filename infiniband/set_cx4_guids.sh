#!/bin/bash 

# assign GUID to virtual card and port

# Globals
MELLANOX_PCI_INFO=`lspci | grep Mel -m 1 | awk -F '.' '{print $1}'`
SRIOV_NIC_NUM=2
IB_INTERFACE=`ls /sys/class/infiniband | grep ib`

# SRIOV DEBUG
#echo "${MELLANOX_PCI_INFO}"
#echo "${SRIOV_NIC_NUM}"
#echo "${IB_INTERFACE}"

# Mac addresses
mac_addresses[0]="52:54:00:2F:D6:CD"
mac_addresses[1]="52:54:00:7A:6F:C0"

# ibstat output
echo "ibstat output"
echo "------"
ibstat
echo "------"
echo 
sleep 1.25

# Clean up SRIOV entries
echo "Cleaning up orphan SRIOV devices"
VFIO_RESULTS=`ls /sys/bus/pci/drivers/vfio-pci/ | grep "${MELLANOX_PCI_INFO}"`
echo "${VFIO_RESULTS}"
if ! [ -z "${VFIO_RESULTS}" ]; then
    # unbind from vfio
    lspci | grep Mel  | grep -v "\.0" | awk '{print $1}' | while read LINE;
    do 
        echo "UNBINDING ${LINE}"
        echo "0000:${LINE}" > "/sys/bus/pci/devices/0000:${LINE}/driver/unbind"
    done

    # remove all mellanox
    echo "0x15b3" "0x1014" > /sys/bus/pci/drivers/vfio-pci/remove_id

    # set sriov entries to 0
    echo 0 > "/sys/class/infiniband/${IB_INTERFACE}/device/sriov_numvfs"
fi

# Create SRIOV entries
echo "Creating ${SRIOV_NIC_NUM} SRIOV NIC(s)"
echo "${SRIOV_NIC_NUM}" > "/sys/class/infiniband/${IB_INTERFACE}/device/sriov_numvfs"

# for loop to kick shit off
echo "Modifying GUIDs and State"
for ((x=0; x < ${SRIOV_NIC_NUM}; x++))
do
    # modify guids and state 
    echo "USING: ${mac_addresses[x]}"
    ip link set dev ${IB_INTERFACE} vf ${x} node_guid ba:be:${mac_addresses[x]}
    ip link set dev ${IB_INTERFACE} vf ${x} port_guid ca:fe:${mac_addresses[x]}
    ip link set dev ${IB_INTERFACE} vf ${x} state auto
done

## reinit
echo "Reinitializing sriov device for updated guids"
echo 0 > "/sys/class/infiniband/${IB_INTERFACE}/device/sriov_numvfs"
echo "${SRIOV_NIC_NUM}" > "/sys/class/infiniband/${IB_INTERFACE}/device/sriov_numvfs"

echo "Please wait ..."
sleep 3
ibstat

## Unbind 
echo "Removing enties"
echo 0 > "/sys/class/infiniband/${IB_INTERFACE}/device/sriov_numvfs"
