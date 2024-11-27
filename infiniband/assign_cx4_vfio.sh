#!/bin/bash

# assign vfio driver to new SRIOV entries
# globals
SRIOV_NIC_NUM=2
IB_INTERFACE=`ls /sys/class/infiniband | grep ib`

# ibstat output
echo "ibstat output"
echo "------"
ibstat
echo "------"
echo 


# Create SRIOV entries
echo "Creating ${SRIOV_NIC_NUM} SRIOV NIC(s)"
echo "${SRIOV_NIC_NUM}" > "/sys/class/infiniband/${IB_INTERFACE}/device/sriov_numvfs"

# run ibstat
echo "Please wait ..."
sleep 3
ibstat

echo -n "Should we bind to VFIO (Y/N)? : "
read VFIO_CONFIRM
VFIO_CONFIRM=`echo ${VFIO_CONFIRM^^}`

if [ "$VFIO_CONFIRM" = "Y" ]; then
    echo "UNBINDING CURRENT DRIVER"

    lspci | grep Mel  | grep -v "\.0" | awk '{print $1}' | while read LINE;
    do 
        echo "0000:${LINE}" > "/sys/bus/pci/devices/0000:${LINE}/driver/unbind"
    done

    # bind all to vfio
    echo "0x15b3" "0x1014" > /sys/bus/pci/drivers/vfio-pci/new_id

    # confirm
    lspci | grep Mel  | grep -v "\.0" | awk '{print $1}' | while read LINE;
    do 
        lspci  -s ${LINE} -vv | grep -iE "${LINE}|kernel"
    done
else
    echo "EXITING ..."
fi
