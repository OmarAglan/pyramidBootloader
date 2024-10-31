# Compiler and tools
ASM=nasm
CC=gcc
LD=ld
QEMU=qemu-system-x86_64

# Directories
SRC_DIR=src
BUILD_DIR=build

# UEFI compilation flags
EFIINC=/usr/include/efi
EFIINCS=-I$(EFIINC) -I$(EFIINC)/x86_64 -I$(EFIINC)/protocol
EFILIB=/usr/lib
EFI_CRT_OBJS=$(EFILIB)/crt0-efi-x86_64.o
EFI_LDS=$(EFILIB)/elf_x86_64_efi.lds

CFLAGS=-Wall -Wextra -Werror -fno-stack-protector -fno-stack-check \
       -fshort-wchar -mno-red-zone -DEFI_FUNCTION_WRAPPER \
       $(EFIINCS)

LDFLAGS=-nostdlib -znocombreloc -T $(EFI_LDS) -shared \
        -Bsymbolic -L $(EFILIB) $(EFI_CRT_OBJS)

# Targets
.PHONY: all clean legacy uefi hybrid directories

all: directories legacy uefi

directories:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/EFI/BOOT

# Legacy BIOS target
legacy: $(BUILD_DIR)/legacy.img

$(BUILD_DIR)/legacy.img: $(BUILD_DIR)/legacy.bin
	cp $(BUILD_DIR)/legacy.bin $(BUILD_DIR)/legacy.img
	truncate -s 1440K $(BUILD_DIR)/legacy.img

$(BUILD_DIR)/legacy.bin: $(SRC_DIR)/legacy/main.asm
	$(ASM) $(SRC_DIR)/legacy/main.asm -f bin -o $(BUILD_DIR)/legacy.bin

# UEFI target
uefi: directories $(BUILD_DIR)/EFI/BOOT/BOOTX64.EFI

$(BUILD_DIR)/EFI/BOOT/BOOTX64.EFI: $(BUILD_DIR)/main.so
	objcopy -j .text -j .sdata -j .data -j .dynamic \
		-j .dynsym -j .rel -j .rela -j .reloc \
		--target=efi-app-x86_64 $< $@

$(BUILD_DIR)/main.so: $(BUILD_DIR)/main.o
	$(LD) $(LDFLAGS) $< -o $@ -lefi -lgnuefi

$(BUILD_DIR)/main.o: $(SRC_DIR)/uefi/main.c
	$(CC) $(CFLAGS) -c $< -o $@

# Hybrid image (will contain both bootloaders)
hybrid: $(BUILD_DIR)/hybrid.img

$(BUILD_DIR)/hybrid.img: legacy uefi
	# Create a 100MB disk image
	dd if=/dev/zero of=$(BUILD_DIR)/hybrid.img bs=1M count=100
	
	# Create GPT disk with protective MBR
	parted -s $(BUILD_DIR)/hybrid.img mklabel gpt
	
	# Create ESP partition (for UEFI)
	parted -s $(BUILD_DIR)/hybrid.img mkpart ESP fat32 1MiB 50MiB
	parted -s $(BUILD_DIR)/hybrid.img set 1 esp on
	
	# Create legacy boot partition
	parted -s $(BUILD_DIR)/hybrid.img mkpart BIOS fat32 50MiB 51MiB
	parted -s $(BUILD_DIR)/hybrid.img set 2 bios_grub on
	
	# Format ESP partition
	dd if=/dev/zero of=$(BUILD_DIR)/esp.img bs=1M count=49
	mkfs.vfat $(BUILD_DIR)/esp.img
	# Create directory structure before copying
	mmd -i $(BUILD_DIR)/esp.img ::/EFI
	mmd -i $(BUILD_DIR)/esp.img ::/EFI/BOOT
	mcopy -i $(BUILD_DIR)/esp.img $(BUILD_DIR)/EFI/BOOT/BOOTX64.EFI ::EFI/BOOT/
	dd if=$(BUILD_DIR)/esp.img of=$(BUILD_DIR)/hybrid.img bs=1M seek=1 conv=notrunc

# ISO target for VirtualBox (Hybrid BIOS+UEFI)
iso: legacy uefi
	mkdir -p $(BUILD_DIR)/iso/EFI/BOOT
	mkdir -p $(BUILD_DIR)/iso/boot
	# Copy UEFI bootloader
	cp $(BUILD_DIR)/EFI/BOOT/BOOTX64.EFI $(BUILD_DIR)/iso/EFI/BOOT/
	# Copy Legacy bootloader
	cp $(BUILD_DIR)/legacy.bin $(BUILD_DIR)/iso/boot/
	xorriso -as mkisofs \
		-R -f \
		-b boot/legacy.bin \
		-no-emul-boot \
		-boot-load-size 4 \
		-boot-info-table \
		-eltorito-alt-boot \
		-e EFI/BOOT/BOOTX64.EFI \
		-no-emul-boot \
		-isohybrid-gpt-basdat \
		-partition_offset 16 \
		-J \
		-joliet-long \
		-c boot/boot.cat \
		-o $(BUILD_DIR)/bootloader.iso \
		$(BUILD_DIR)/iso
		
# QEMU testing targets
run-legacy: legacy
	$(QEMU) -fda $(BUILD_DIR)/legacy.img

run-uefi: uefi
	$(QEMU) -bios /usr/share/ovmf/OVMF.fd \
		-drive file=fat:rw:$(BUILD_DIR),format=raw,media=disk \
		-net none

run-hybrid: hybrid
	$(QEMU) -bios /usr/share/ovmf/OVMF.fd \
		-drive file=$(BUILD_DIR)/hybrid.img,format=raw \
		-net none

# Alternative UEFI run target (if the default path doesn't work)
run-uefi-alt: uefi
	$(QEMU) -bios /usr/share/OVMF/OVMF_CODE.fd \
		-drive file=fat:rw:$(BUILD_DIR),format=raw,media=disk \
		-net none

clean:
	rm -rf $(BUILD_DIR)/*
	rm -f $(BUILD_DIR)/bootloader.iso