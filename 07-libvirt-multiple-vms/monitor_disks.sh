#!/bin/bash
echo "Monitoring disk sizes during VM creation..."
echo "=========================================="

while true; do
    clear
    echo "$(date): Disk sizes in /mnt/datos1/00-Soft/libvirt/images/"
    echo "=========================================="
    
    # Mostrar todos los archivos qcow2
    ls -lh /mnt/datos1/00-Soft/libvirt/images/*.qcow2 2>/dev/null | while read line; do
        file=$(echo $line | awk '{print $NF}' | xargs basename)
        size=$(echo $line | awk '{print $5}')
        echo "$file: $size"
    done
    
    echo ""
    echo "Total space used:"
    du -sh /mnt/datos1/00-Soft/libvirt/images/
    
    echo ""
    echo "VMs status:"
    virsh list --all 2>/dev/null | grep -E "(web-|database-)" || echo "No VMs found"
    
    sleep 3
done
