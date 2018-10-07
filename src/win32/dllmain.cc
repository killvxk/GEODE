#include <Windows.h>

BOOL WINAPI
DllMain
(
    HINSTANCE instance, 
    DWORD  call_reason, 
    LPVOID    reserved
)
{
    UNREFERENCED_PARAMETER(instance);
    UNREFERENCED_PARAMETER(call_reason);
    UNREFERENCED_PARAMETER(reserved);
    return TRUE;
}

