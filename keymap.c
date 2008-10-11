//
// keymap.c
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


#include "keymap.h"
#include <X11/keysym.h>


const int keymap_us[128] = {
    XK_a,
    XK_s,
    XK_d,
    XK_f,
    XK_h,
    XK_g,
    XK_z,
    XK_x,
    XK_c,
    XK_v,
    -1,    // 10
    XK_b,
    XK_q,
    XK_w,
    XK_e,
    XK_r,
    XK_y,
    XK_t,
    XK_1,
    XK_2,
    XK_3, // 20
    XK_4,
    XK_6,
    XK_5,
    XK_equal,
    XK_9,
    XK_7,
    XK_minus,
    XK_8,
    XK_0,
    XK_bracketright, // 30
    XK_o,
    XK_u,
    XK_bracketleft,
    XK_i,
    XK_p,
    XK_Return,
    XK_l,
    XK_j,
    XK_apostrophe,
    XK_k, //40
    XK_semicolon,
    XK_backslash,
    XK_comma,
    XK_slash,
    XK_n,
    XK_m,
    XK_period,
    XK_Tab,
    XK_space,
    XK_quoteleft, //50
    XK_BackSpace,
    -1,
    XK_Escape,
    XK_Alt_R,
    XK_Alt_L, // 55 
    XK_Shift_L,
    XK_Caps_Lock,
    XK_Meta_L,
    XK_Control_L,
    XK_Shift_R, // 60
    XK_Meta_R,  // Should probably be XK_Meta_R, but that seems to crash things :(
    XK_Control_R,
    -1,
    -1,
    XK_KP_Decimal,
    -1,
    XK_KP_Multiply,
    -1,
    XK_KP_Add,
    -1, // 70
    -1,
    -1,
    -1,
    -1,
    XK_KP_Divide,
    XK_KP_Enter,
    XK_KP_Subtract,
    -1,
    -1,
    -1, // 80
    -1,
    XK_KP_0,
    XK_KP_1,
    XK_KP_2,
    XK_KP_3,
    XK_KP_4,
    XK_KP_5,
    XK_KP_6,
    XK_KP_7,
    -1, // 90
    XK_KP_8,
    XK_KP_9,
    -1,
    -1,
    -1,
    XK_F5,
    XK_F6,
    XK_F7,
    XK_F3,
    XK_F8, // 100
    XK_F9,
    -1,
    XK_F11,
    -1,
    -1,
    -1,
    -1,
    -1,
    XK_F10,
    -1, // 110
    XK_F12,
    -1,
    -1,
    -1,
    XK_Home,
    XK_Page_Up,
    XK_Delete,
    XK_F4,
    XK_End,
    XK_F2, // 120
    XK_Page_Down,
    XK_F1,
    XK_Left,
    XK_Right,
    XK_Down,
    XK_Up,
    -1,
};

const int keymap_shifted_us[128] = {
    XK_A,
    XK_S,
    XK_D,
    XK_F,
    XK_H,
    XK_G,
    XK_Z,
    XK_X,
    XK_C,
    XK_V,
    -1,    // 10
    XK_B,
    XK_Q,
    XK_W,
    XK_E,
    XK_R,
    XK_Y,
    XK_T,
    XK_exclam,
    XK_at,
    XK_numbersign, // 20
    XK_dollar,
    XK_asciicircum,
    XK_percent,
    XK_plus,
    XK_parenleft,
    XK_ampersand,
    XK_underscore,
    XK_asterisk,
    XK_parenright,
    XK_braceright, // 30
    XK_O,
    XK_U,
    XK_braceleft,
    XK_I,
    XK_P,
    XK_Return,
    XK_L,
    XK_J,
    XK_quotedbl,
    XK_K, //40
    XK_colon,
    XK_question,
    XK_less,
    XK_bar,
    XK_N,
    XK_M,
    XK_greater,
    XK_Tab,
    XK_space,
    XK_asciitilde, //50
    XK_BackSpace,
    -1,
    XK_Escape,
    XK_Alt_R,
    XK_Alt_L,
    XK_Shift_L,
    XK_Caps_Lock,
    XK_Meta_L,
    XK_Control_L,
    XK_Shift_R, // 60
    XK_Meta_R,  // Should probably be XK_Meta_R, but that seems to crash things :(
    XK_Control_R,
    -1,
    -1,
    XK_KP_Decimal,
    -1,
    XK_KP_Multiply,
    -1,
    XK_KP_Add,
    -1, // 70
    -1,
    -1,
    -1,
    -1,
    XK_KP_Divide,
    XK_KP_Enter,
    XK_KP_Subtract,
    -1,
    -1,
    -1, // 80
    -1,
    XK_KP_0,
    XK_KP_1,
    XK_KP_2,
    XK_KP_3,
    XK_KP_4,
    XK_KP_5,
    XK_KP_6,
    XK_KP_7,
    -1, // 90
    XK_KP_8,
    XK_KP_9,
    -1,
    -1,
    -1,
    XK_F5,
    XK_F6,
    XK_F7,
    XK_F3,
    XK_F8, // 100
    XK_F9,
    -1,
    XK_F11,
    -1,
    -1,
    -1,
    -1,
    -1,
    XK_F10,
    -1, // 110
    XK_F12,
    -1,
    -1,
    -1,
    XK_Home,
    XK_Page_Up,
    XK_Delete,
    XK_F4,
    XK_End,
    XK_F2, // 120
    XK_Page_Down,
    XK_F1,
    XK_Left,
    XK_Right,
    XK_Down,
    XK_Up,
    -1,
};



const int *keymap;
const int *keymap_shifted;
const int *keymap_alted;

extern const int keymap_us[128];
extern const int keymap_de[128];
extern const int keymap_shifted_us[128];
extern const int keymap_shifted_de[128];
extern const int keymap_alted_de[128];

static const int* maplist[2] = {keymap_us, keymap_de};
static const int* maplist_shifted[2] = {keymap_shifted_us, keymap_shifted_de};
static const int* maplist_alted[2] = {keymap_us, keymap_alted_de};

void keymap_init()
{
    keymap_set(KEYMAP_US);
}


void keymap_set(int map)
{
    keymap = maplist[map];
    keymap_shifted = maplist_shifted[map];
    keymap_alted = maplist_alted[map];
}