#!/bin/bash

## DEVICE PASSTHROUGH

configfile=/etc/vfio-pci.cfg
vmname="windows10vm"

vfiobind() {
   dev="$1"
        vendor=$(cat /sys/bus/pci/devices/$dev/vendor)
        device=$(cat /sys/bus/pci/devices/$dev/device)
        if [ -e /sys/bus/pci/devices/$dev/driver ]; then
                echo $dev > /sys/bus/pci/devices/$dev/driver/unbind
        fi
        echo $vendor $device > /sys/bus/pci/drivers/vfio-pci/new_id
   
}

if ps -A | grep -q $vmname; then
   echo "$vmname is already running." &
   exit 1

else

   cat $configfile | while read line;do
   echo $line | grep ^# >/dev/null 2>&1 && continue
      vfiobind $line
   done

#cp /usr/share/OVMF/OVMF_VARS.fd /media/jakubowy/VM/$vmname.fd

## VM INITIALISATION

# use pulseaudio
#export QEMU_AUDIO_DRV=pa
#export QEMU_PA_SAMPLES=128
#export QEMU_AUDIO_TIMER_PERIOD=99
#export QEMU_PA_SERVER=/run/user/1000/pulse/native

#export QEMU_AUDIO_DRV=alsa
#export QEMU_ALSA_DAC_PERIOD_SIZE=170
#export QEMU_ALSA_DAC_BUFFER_SIZE=512

qemu-system-x86_64 \
  -enable-kvm \
  -M q35 \
  -m 8G \
  -mem-prealloc \
  -device nec-usb-xhci,id=xhci \
  -device usb-host,bus=xhci.0,vendorid=0x248a,productid=0x8367 \
  -device usb-host,bus=xhci.0,vendorid=0x413c,productid=0x2107 \
  -device usb-host,bus=xhci.0,vendorid=0x045e,productid=0x0719 \
  -cpu host,kvm=off,hv_vendor_id=1234567890ab,hv_vapic,hv_time,hv_relaxed,hv_spinlocks=0x1fff \
  -smp 6,sockets=1,cores=6,threads=1 \
  -bios /usr/share/seabios/bios.bin \
  -vga none \
  -device ioh3420,bus=pcie.0,addr=1c.0,multifunction=on,port=1,chassis=1,id=root.1 \
  -device vfio-pci,host=01:00.0,bus=root.1,addr=00.0,multifunction=on,x-vga=on \
  -device vfio-pci,host=01:00.1,bus=root.1,addr=00.1 \
  -device virtio-scsi-pci,id=scsi \
  -drive id=disk0,if=virtio,cache=none,format=raw,aio=native,file=/dev/xubuntu-vg/lvol0 \
  -boot menu=on \
  -netdev type=tap,id=net0,ifname=tap0,vhost=on \
  -device virtio-net-pci,netdev=net0,mac=00:16:3e:00:0e:01

   exit 0



fi

