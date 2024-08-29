/*
Compile as an obj file and extract shellcode from it.
cl /O2 /Ob1 /c /GS- /std:c++20 /d1reportSingleClassLayoutCaretPosHookData GetCaretPosFromHook.cpp
*/
#include <Windows.h>
#include <msctf.h>

#define FAILED_OR_NULLPTR(hr, p) (FAILED(hr) || p == NULL)
#define SUCCEEDED_AND_GOODPTR(hr, p) (SUCCEEDED(hr) && p != NULL)

enum CARET_POS_HOOK_ERROR : DWORD {
    CPH_E_SUCCEEDED,
    CPH_E_NONEXIST_FUNC,
    CPH_E_SETWINDOWSHOOK,
    CPH_E_SENDMESSAGE,
    CPH_E_TSF,
};

typedef LRESULT(CALLBACK *PCALLWNDPROC)(int nCode, WPARAM wParam, LPARAM lParam);
typedef HHOOK(WINAPI *PSETWINDOWSHOOKEX)(int idHook, HOOKPROC lpfn, HINSTANCE hmod, DWORD dwThreadId);
typedef BOOL(WINAPI *PUNHOOKWINDOWSHOOKEX)(HHOOK hhk);
typedef LRESULT(WINAPI *PCALLNEXTHOOKEX)(HHOOK hhk, int nCode, WPARAM wParam, LPARAM lParam);
typedef LRESULT(WINAPI *PSENDMESSAGETIMEOUTW)(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam, UINT fuFlags, UINT uTimeout, PDWORD_PTR lpdwResult);
typedef HRESULT(WINAPI *PCOCREATEINSTANCE)(const CLSID *rclsid, LPUNKNOWN pUnkOuter, DWORD dwClsContext, const IID *riid, LPVOID *ppv);

struct CaretPosHookEditSession {
    LPVOID pVtable;
    ITfContext *pTfContext;
    RECT rect;
};

struct CaretPosHookEditSessionVTable {
    LPVOID pQueryInterface;
    LPVOID pAddRef;
    LPVOID pRelease;
    LPVOID pDoEditSession;
};

struct CaretPosHookData {
    LPVOID user32Base;
    LPVOID combaseBase;
    HWND hwnd;
    DWORD tid;
    UINT msg;
    DWORD exitCode;
    CaretPosHookEditSession caretPosEditSession;
    CaretPosHookEditSessionVTable caretPosEditSessionVTable;
    CLSID CLSID_TF_ThreadMgr;
    IID IID_ITfThreadMgr;
    char sSetWindowsHookExW[20];
    char sUnhookWindowsHookEx[20];
    char sCallNextHookEx[20];
    char sSendMessageTimeoutW[20];
    char sCoCreateInstance[20];
};

DWORD WINAPI ThreadProc(CaretPosHookData *pData);
LRESULT CALLBACK CallWndProc(int nCode, WPARAM wParam, LPARAM lParam);
DWORD GetCaretPosFromTsf(CaretPosHookData *pData);
FARPROC MyGetProcAddress(LPVOID moduleBase, const char *pProcName);
HRESULT STDMETHODCALLTYPE CaretPosEditSession_QueryInterface(CaretPosHookEditSession *This, IID *riid, void **ppvObject);
ULONG STDMETHODCALLTYPE CaretPosEditSession_AddRef_Release(CaretPosHookEditSession *This);
HRESULT STDMETHODCALLTYPE CaretPosEditSession_DoEditSession(CaretPosHookEditSession *This, TfEditCookie ec);
#ifndef _WIN64
CaretPosHookData *GetDataAddress();
#endif // _WIN64

CaretPosHookData gData = {
    .exitCode = CPH_E_SUCCEEDED,
    .CLSID_TF_ThreadMgr = {0x529a9e6b, 0x6587, 0x4f23, {0xab, 0x9e, 0x9c, 0x7d, 0x68, 0x3e, 0x3c, 0x50}},
    .IID_ITfThreadMgr = {0xaa80e801, 0x2021, 0x11d2, {0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e}},
    .sSetWindowsHookExW = "SetWindowsHookExW",
    .sUnhookWindowsHookEx = "UnhookWindowsHookEx",
    .sCallNextHookEx = "CallNextHookEx",
    .sSendMessageTimeoutW = "SendMessageTimeoutW",
    .sCoCreateInstance = "CoCreateInstance",
};

DWORD WINAPI ThreadProc(CaretPosHookData *pData) {
    PSETWINDOWSHOOKEX pSetWindowsHookEx = (PSETWINDOWSHOOKEX)MyGetProcAddress(pData->user32Base, pData->sSetWindowsHookExW);
    PSENDMESSAGETIMEOUTW pSendMessageTimeoutW = (PSENDMESSAGETIMEOUTW)MyGetProcAddress(pData->user32Base, pData->sSendMessageTimeoutW);
    PUNHOOKWINDOWSHOOKEX pUnhookWindowsHookEx = (PUNHOOKWINDOWSHOOKEX)MyGetProcAddress(pData->user32Base, pData->sUnhookWindowsHookEx);
    if (!pSetWindowsHookEx || !pSendMessageTimeoutW || !pUnhookWindowsHookEx)
        return CPH_E_NONEXIST_FUNC;
#ifdef _WIN64
    HHOOK hook = pSetWindowsHookEx(WH_CALLWNDPROC, CallWndProc, 0, pData->tid);
#else
    *(LPVOID *)((DWORD)pData + (DWORD)GetDataAddress + 1) = pData;
    HHOOK hook = pSetWindowsHookEx(WH_CALLWNDPROC, (PCALLWNDPROC)((DWORD)pData + (DWORD)CallWndProc), 0, pData->tid);
#endif // _WIN64
    if (hook == NULL)
        return CPH_E_SETWINDOWSHOOK;
    LRESULT sent = pSendMessageTimeoutW(pData->hwnd, pData->msg, 0, 0, 0, 200, NULL);
    pUnhookWindowsHookEx(hook);
    if (sent == 0)
        return CPH_E_SENDMESSAGE;
    return pData->exitCode;
}

LRESULT CALLBACK CallWndProc(int nCode, WPARAM wParam, LPARAM lParam) {
#ifdef _WIN64
    CaretPosHookData *pData = &gData;
#else
    CaretPosHookData *pData = GetDataAddress();
#endif // _WIN64
    if (nCode >= 0 && lParam != NULL) {
        PCWPSTRUCT pcwps = (PCWPSTRUCT)lParam;
        if (pcwps->message == pData->msg) {
            pData->exitCode = GetCaretPosFromTsf(pData);
        }
    }
    PCALLNEXTHOOKEX pCallNextHookEx = (PCALLNEXTHOOKEX)MyGetProcAddress(pData->user32Base, pData->sCallNextHookEx);
    if (!pCallNextHookEx)
        return 0;
    return pCallNextHookEx(NULL, nCode, wParam, lParam);
}

DWORD GetCaretPosFromTsf(CaretPosHookData *pData) {
    PCOCREATEINSTANCE pCoCreateInstance = (PCOCREATEINSTANCE)MyGetProcAddress(pData->combaseBase, pData->sCoCreateInstance);
    if (!pCoCreateInstance)
        return CPH_E_NONEXIST_FUNC;

    ITfThreadMgr *pThreadMgr = NULL;
    ITfDocumentMgr *pDocMgr = NULL;
    ITfContext *pContext = NULL;
    TfClientId clientId = 0;
    HRESULT hrSession = S_FALSE;

    HRESULT hr = pCoCreateInstance(&pData->CLSID_TF_ThreadMgr, NULL, CLSCTX_ALL, &pData->IID_ITfThreadMgr, (void **)&pThreadMgr);
    if (FAILED_OR_NULLPTR(hr, pThreadMgr))
        return CPH_E_TSF;

    hr = pThreadMgr->Activate(&clientId);
    if (FAILED(hr))
        goto end;

    hr = pThreadMgr->GetFocus(&pDocMgr);
    if (FAILED_OR_NULLPTR(hr, pDocMgr))
        goto end;

    hr = pDocMgr->GetTop(&pContext);
    if (FAILED_OR_NULLPTR(hr, pContext))
        goto end;

    pData->caretPosEditSession.pTfContext = pContext;
    pData->caretPosEditSession.pVtable = &pData->caretPosEditSessionVTable;
#ifdef _WIN64
    pData->caretPosEditSessionVTable.pQueryInterface = CaretPosEditSession_QueryInterface;
    pData->caretPosEditSessionVTable.pAddRef = CaretPosEditSession_AddRef_Release;
    pData->caretPosEditSessionVTable.pRelease = CaretPosEditSession_AddRef_Release;
    pData->caretPosEditSessionVTable.pDoEditSession = CaretPosEditSession_DoEditSession;
#else
    pData->caretPosEditSessionVTable.pQueryInterface = (LPVOID)((DWORD)pData + (DWORD)CaretPosEditSession_QueryInterface);
    pData->caretPosEditSessionVTable.pAddRef = (LPVOID)((DWORD)pData + (DWORD)CaretPosEditSession_AddRef_Release);
    pData->caretPosEditSessionVTable.pRelease = (LPVOID)((DWORD)pData + (DWORD)CaretPosEditSession_AddRef_Release);
    pData->caretPosEditSessionVTable.pDoEditSession = (LPVOID)((DWORD)pData + (DWORD)CaretPosEditSession_DoEditSession);
#endif // _WIN64
    hr = pContext->RequestEditSession(clientId, (ITfEditSession *)&pData->caretPosEditSession, TF_ES_READ | TF_ES_SYNC, &hrSession);

end:
    if (pContext)
        pContext->Release();
    if (pDocMgr)
        pDocMgr->Release();
    if (pThreadMgr)
        pThreadMgr->Release();
    return hrSession == S_OK ? CPH_E_SUCCEEDED : CPH_E_TSF;
}

HRESULT STDMETHODCALLTYPE CaretPosEditSession_QueryInterface(CaretPosHookEditSession *This, IID *riid, void **ppvObject) {
    if (!This || !riid || !ppvObject)
        return E_INVALIDARG;
    PINT64 p = (PINT64)riid;
    if ((p[0] == 0 && p[1] == 0x46000000000000C0) || (p[0] == 0X11D22021AA80E803 && p[1] == 0X6EB867B06000E093)) {
        *ppvObject = This;
        return S_OK;
    }
    *ppvObject = NULL;
    return E_NOINTERFACE;
}

ULONG STDMETHODCALLTYPE CaretPosEditSession_AddRef_Release(CaretPosHookEditSession *This) {
    return 0;
}

HRESULT STDMETHODCALLTYPE CaretPosEditSession_DoEditSession(CaretPosHookEditSession *This, TfEditCookie ec) {
    if (!This)
        return E_INVALIDARG;
    TF_SELECTION selection;
    ULONG fetched = 0;
    HRESULT hr = This->pTfContext->GetSelection(ec, TF_DEFAULT_SELECTION, 1, &selection, &fetched);
    if (FAILED_OR_NULLPTR(hr, selection.range) || fetched == 0)
        return S_FALSE;
    ITfContextView *pView = NULL;
    hr = This->pTfContext->GetActiveView(&pView);
    if (SUCCEEDED_AND_GOODPTR(hr, pView)) {
        BOOL clipped;
        hr = pView->GetTextExt(ec, selection.range, &This->rect, &clipped);
        pView->Release();
    }
    selection.range->Release();
    return hr;
}

FARPROC MyGetProcAddress(LPVOID moduleBase, const char *pProcName) {
    if (moduleBase == NULL || pProcName == NULL)
        return NULL;
    PIMAGE_DOS_HEADER lpDosHeader = (PIMAGE_DOS_HEADER)moduleBase;
    PIMAGE_NT_HEADERS lpNtHeader = (PIMAGE_NT_HEADERS)((DWORD_PTR)moduleBase + lpDosHeader->e_lfanew);
    if (!lpNtHeader->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].Size)
        return NULL;
    if (!lpNtHeader->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress)
        return NULL;
    PIMAGE_EXPORT_DIRECTORY lpExports = (PIMAGE_EXPORT_DIRECTORY)((DWORD_PTR)moduleBase + lpNtHeader->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress);
    PDWORD lpdwFunName = (PDWORD)((DWORD_PTR)moduleBase + lpExports->AddressOfNames);
    PWORD lpword = (PWORD)((DWORD_PTR)moduleBase + lpExports->AddressOfNameOrdinals);
    PDWORD lpdwFunAddr = (PDWORD)((DWORD_PTR)moduleBase + lpExports->AddressOfFunctions);

    for (int i = 0; i <= lpExports->NumberOfNames - 1; i++) {
        char *pProcName_ = (char *)((DWORD_PTR)moduleBase + lpdwFunName[i]);
        for (int j = 0; pProcName[j] == pProcName_[j]; j++) {
            if (pProcName[j] == 0) {
                return (FARPROC)((DWORD_PTR)moduleBase + lpdwFunAddr[lpword[i]]);
            }
        }
    }
    return NULL;
}

#ifndef _WIN64
__declspec(naked) CaretPosHookData *GetDataAddress() {
    __asm {
        mov eax, dword ptr 0
        ret
    }
}
#endif // _WIN64
