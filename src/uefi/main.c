#include <gnu-efi/inc/efi.h>
#include <gnu-efi/inc/efilib.h>

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    EFI_INPUT_KEY Key;

    // Initialize UEFI environment
    InitializeLib(ImageHandle, SystemTable);
    
    // Print a simple message
    Print(L"Hello from UEFI bootloader!\n");
    Print(L"Press any key to continue...\n");
    
    // Wait for keypress
    SystemTable->ConIn->Reset(SystemTable->ConIn, FALSE);
    while (SystemTable->ConIn->ReadKeyStroke(SystemTable->ConIn, &Key) == EFI_NOT_READY)
        ;
    
    return EFI_SUCCESS;
}