# VortexOS
VortexOS

## Pre-requestes 
* cmkae
* nasm
* qemu / any virual box

## Step 1: 
Clone project
```
git clone https://github.com/PMAnanthu/VortexOS.git
cd VortexOS
git checkout branch_name
``` 

## Step 2:
Build project
```
make
```

## Step 3:
Run project
```
qemu-system-x86_64 -fda build/boot_disk.img
```
