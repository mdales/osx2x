//
// xcode.c
// osx2x
//
// Copyright (c) Michael Dales 2002, 2003
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of Michael Dales nor the names of its contributors may be
// used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
// IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED.  IN NO EVENT S HALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS I NTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#include <stdlib.h>
#include <stdio.h>
#include "xcode.h"
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/extensions/XTest.h>
#include <string.h>
#include <signal.h>
#include <setjmp.h>

static jmp_buf jump_env;

#define DATA_SIZE 1024
#define BUFFER_SIZE 8192

char copybuffer[BUFFER_SIZE];

#if 1
static char *event_names[] = {
    "",
    "",
    "KeyPress",
    "KeyRelease",
    "ButtonPress",
    "ButtonRelease",
    "MotionNotify",
    "EnterNotify",
    "LeaveNotify",
    "FocusIn",
    "FocusOut",
    "KeymapNotify",
    "Expose",
    "GraphicsExpose",
    "NoExpose",
    "VisibilityNotify",
    "CreateNotify",
    "DestroyNotify",
    "UnmapNotify",
    "MapNotify",
    "MapRequest",
    "ReparentNotify",
    "ConfigureNotify",
    "ConfigureRequest",
    "GravityNotify",
    "ResizeRequest",
    "CirculateNotify",
    "CirculateRequest",
    "PropertyNotify",
    "SelectionClear",
    "SelectionRequest",
    "SelectionNotify",
    "ColormapNotify",
    "ClientMessage",
    "MappingNotify" };
#endif

struct DPTAG {
    Display* display;
    Window window;
    char* selection;
    int width;
    int height;
    Window rootWindow;
    Atom targetAtom;
    XSelectionRequestEvent hmm;
};

int XXIOErrorHandler(Display* dpy)
{
    longjmp(jump_env, 42);
    return 42;
}


DPYINFO* XXConnectDisplay(char* hostname)
{
    DPYINFO* dpy;
    int    eventb, errorb;
    int    vmajor, vminor;
    int scrnum;
    Screen *screen;
    
    dpy = (DPYINFO*)malloc(sizeof(DPYINFO));

    // Connect to the remove display
    hostname = XDisplayName(hostname);

    if ((dpy->display = XOpenDisplay(hostname)) == NULL)
    {
        //printf("Failed to open display %s\n", hostname);
        free(dpy);
        return NULL;
    }

    // check that it supports the extentions we want
    if (!XTestQueryExtension(dpy->display, &eventb, &errorb, &vmajor, &vminor))
    {
        //printf("no extentions on display %s\n", hostname);
        free(dpy);
        return NULL;
    }

    // Create a window on the remote display
    scrnum = DefaultScreen(dpy->display);
    dpy->window = XCreateSimpleWindow(dpy->display, RootWindow(dpy->display, scrnum),
                                      0, 0, 100, 100, 1,
                                      BlackPixel(dpy->display, scrnum),
                                      WhitePixel(dpy->display, scrnum));

    // Lets us drag windows
    XTestGrabControl(dpy->display, True);

    XSetIOErrorHandler(XXIOErrorHandler);
    signal(SIGPIPE, SIG_IGN);

    // Get other useful information
    screen = XDefaultScreenOfDisplay(dpy->display);
    dpy->width = XWidthOfScreen(screen);
    dpy->height = XHeightOfScreen(screen);
    dpy->rootWindow = XRootWindowOfScreen(screen);
    dpy->targetAtom = XInternAtom(dpy->display, "TARGETS", False);
    
    return dpy;
}

void XXDisconnectDisplay(DPYINFO* dpy)
{
    // If ther e remote xserver has died then
    if (setjmp(jump_env) == 0)
    {
        XDestroyWindow(dpy->display, dpy->window);
        XCloseDisplay(dpy->display);
        signal(SIGPIPE, SIG_DFL);
    }

    
    free(dpy);
}


int XXSendKeyEvent(DPYINFO* pDpy, int key, int direction)
{
    int kcode;

    kcode = XKeysymToKeycode(pDpy->display, key);

    if (setjmp(jump_env) == 0)
    {
        XTestFakeKeyEvent(pDpy->display, kcode, direction, 0);
        XFlush(pDpy->display);
        return 0;
    }
    else
    {
        return -1;
    }
}


int XXSendRelativeMotionEvent(DPYINFO* dpy, int x, int y)
{
    if (setjmp(jump_env) == 0)
    {
        //XTestFakeRelativeMotionEvent(dpy->display, x, y, 0);
        XWarpPointer(dpy->display, None, None, 0, 0, 0, 0, x, y);
        XFlush(dpy->display);
        return 0;
    }
    else
    {
        return -1;
    }
}

int XXSendAbsoluteMouseLocation(DPYINFO* dpy, int x, int y)
{
    if (setjmp(jump_env) == 0)
    {
//        XTestFakeMotionEvent(dpy->display, -1, x, y, 0);
        XWarpPointer(dpy->display, dpy->rootWindow, dpy->rootWindow, 0, 0, 0, 0, x, y);
        XFlush(dpy->display);
        return 0;
    }
    else
        return -1;
}



int XXSendMouseButtonEvent(DPYINFO* dpy, int button, int direction)
{
    if (setjmp(jump_env) == 0)
    {
        XTestFakeButtonEvent(dpy->display, button, direction, 0);
        XFlush(dpy->display);
        return 0;
    }
    else
    {
        return -1;
    }
}


/*
 * The user has tried to paste to the X world
 */
int XXSetSelectionOwner(DPYINFO* dpy, char* data)
{
	printf("XXSetSelectionOwner\n");
	
    dpy->selection = data;

    if (setjmp(jump_env) == 0)
    {
        XSelectInput(dpy->display, dpy->window, PropertyChangeMask);
        XSetSelectionOwner(dpy->display, XA_PRIMARY, dpy->window, CurrentTime);
        XFlush(dpy->display);

        return 0;
    }
    else
        return -1;
}


int XXRequestSelection(DPYINFO* dpy)
{
    Atom type;

	printf("XXRequestSelection\n");
	
    if (setjmp(jump_env) == 0)
    {
        type = XInternAtom(dpy->display, "Hmmm", False);

        XConvertSelection(dpy->display, XA_PRIMARY, XA_STRING,
                          type, dpy->window, CurrentTime);
        XFlush(dpy->display);
        // Now we hold tight for the selection notify event
        printf("sending request\n");
        return 0;
    }
    else
        return -1;
}


XXSize XXGetDisplaySize(DPYINFO* dpy)
{
    XXSize rv;

    rv.width = dpy->width;
    rv.height = dpy->height;
    
    return rv;
}


int XXEventHandler(DPYINFO* dpy)
{
    XEvent event;
    XEvent ev2;
    XSelectionEvent *se;

    if (dpy == NULL)
        return -1;
    
    if (setjmp(jump_env) == 0)
    {    
		
        //if (XEventsQueued(dpy->display, QueuedAfterReading) == 0)
        //    return 0;
		while (XEventsQueued(dpy->display, QueuedAfterReading) != 0)
		{
        
        se = (XSelectionEvent*)&ev2;
    
        XNextEvent(dpy->display, &event);

#if 1
        printf("In main loop, got a %s event\n", event_names[event.type]);
#endif

        dpy->hmm = event.xselectionrequest;
        
        switch (event.type)
        {
            case SelectionRequest:
                // Some weirdo app has requested the selection
#if 1
                printf("selection request dpy :%08x %08x %08x %s %s %08x\n", dpy->display, 
					   event.xselectionrequest.target, XA_LAST_PREDEFINED, 
					   XGetAtomName(dpy->display, event.xselectionrequest.selection), 
					   XGetAtomName(dpy->display, event.xselectionrequest.target), dpy->targetAtom);
#endif

                // For now we only offer strings...
                if (event.xselectionrequest.target == XA_STRING)
                {
    
                    // Set the info
                    XChangeProperty(dpy->display, event.xselectionrequest.requestor,
                                    event.xselectionrequest.property, XA_STRING, 8,
                                    PropModeReplace, dpy->selection, strlen(dpy->selection) + 1);
                    
                    // Inform ye that asked for it about the new info
                    se->display = event.xselectionrequest.display;
                    se->property = event.xselectionrequest.property;
                    se->selection = event.xselectionrequest.selection;
                    se->target    = event.xselectionrequest.target;
                    se->type      = SelectionNotify;
                    se->requestor = event.xselectionrequest.requestor;
                    se->time      = event.xselectionrequest.time;
                    se->send_event = True;
    
                    XSendEvent(dpy->display, event.xselectionrequest.requestor,
                                            False, 0, (XEvent*)se);
                    XFlush(dpy->display);
                }
                else if (event.xselectionrequest.target == dpy->targetAtom)
                {
                    Atom stringAtom = XA_STRING;
                    
                    XChangeProperty(dpy->display,
                                    event.xselectionrequest.requestor,
                                    event.xselectionrequest.property,
                                    XA_ATOM, 32, PropModeReplace,
                                    (unsigned char*)&stringAtom, 1);

                    se->display   = event.xselectionrequest.display;
                    se->property  = event.xselectionrequest.property;
                    se->selection = event.xselectionrequest.selection;
                    se->target    = event.xselectionrequest.target;
                    se->type      = SelectionNotify;
                    se->requestor = event.xselectionrequest.requestor;
                    se->time      = event.xselectionrequest.time;
                    se->send_event = True;

                    XSendEvent(dpy->display, event.xselectionrequest.requestor,
                               False, 0, (XEvent*)se);
                    XFlush(dpy->display);
                }
                else
                {
                    // Inform ye that asked for it about the new info
                    se->display = event.xselectionrequest.display;
                    se->property = None;
                    se->selection = event.xselectionrequest.selection;
                    se->target    = event.xselectionrequest.target;
                    se->type      = SelectionNotify;
                    se->requestor = event.xselectionrequest.requestor;
                    se->time      = event.xselectionrequest.time;
                    se->send_event = True;
    
                    XSendEvent(dpy->display, event.xselectionrequest.requestor,
                            False, 0, (XEvent*)se);
                    XFlush(dpy->display);
                }
                break;
    
            case SelectionClear:
                // Some other app 0WNZ the selection now
#if 1
				printf("selection clean request\n");
#endif				
                free (dpy->selection);
                dpy->selection = NULL;
                break;
    
            case SelectionNotify:
#if 1
                printf("selection notify dpy :%08x %08x %08x %s %s %s %08x\n", dpy->display, event.xselection.requestor, XA_LAST_PREDEFINED, 
					   XGetAtomName(dpy->display, event.xselection.selection), 
					   XGetAtomName(dpy->display, event.xselection.target),
					   XGetAtomName(dpy->display, event.xselection.property), dpy->targetAtom);
#endif
				
                if (event.xselection.property != None)
                {            
                    unsigned long bytesrem = 0;
                    unsigned int offset = 0;
                    unsigned long nItems;
                    unsigned char *data, *p;
                    Atom type;
                    int from;
    
                    memset(copybuffer, 0, BUFFER_SIZE);
                    p = copybuffer;
                    do
                    {
                        if ((XGetWindowProperty(dpy->display, event.xselection.requestor,
                                                event.xselection.property, offset, DATA_SIZE,
                                                True, AnyPropertyType, &type, &from,
                                                &nItems, &bytesrem, &data) == Success) &&
                            (type == XA_STRING))
                        {
                            memcpy(p, data, nItems);                    
                            XFree(data);
    
                            p += nItems;
                            offset += nItems >> 2;
                        }
						printf("bo\n");
                    }
                    while (bytesrem);
					
					
					printf("The notify gave us (%d) %s\n", offset, copybuffer);
    
                    XXCopyCallback(copybuffer);
                }
                break;
#if 0
            case PropertyNotify:
#if 1
                printf("Propity notify of type %s\n", XGetAtomName(dpy->display,
                                                                   event.xproperty.atom));
#endif

                //XConvertSelection(dpy->display, XA_PRIMARY, XA_STRING,
                            //      XA_PRIMARY, dpy->window, event.xproperty.time);
                break;
#endif
        }
        }
        return 0;
    }
    else
        return -1;
}

int XXGetConnectionFD(DPYINFO* dpy)
{
    return XConnectionNumber(dpy->display);
}