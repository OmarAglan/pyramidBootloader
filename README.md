Pyramid Bootloader

# About
This IsThe Leagcy Bootloader For OS Pyramid

# Setup
Install The Nessecry Requirments For this to work:
```
sudo apt-get install make gcc gnu-efi nasm qemu-system-x86 ovmf parted mtools dosfstools
```

## Building

### To Build Leagcy
```
make legacy
```
### To Build UEFI
```
make uefi
```
### To Build hybrid Image
```
make hybrid
```

## Runing On Vitrual Machine

### Linux
#### Run Leagcy
```
make run-legacy
```
#### Run UEFI
```
make run-uefi
```
#### Run Hybrid
```
make run-hybrid
```
### Windows
make an iso:
```
sudo apt-get install xorriso
```
Use The Oracle VirtualBox, VmWare or any simller program.

## Clean the Build DIR
```
make clean
```