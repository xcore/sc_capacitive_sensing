// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <stdio.h>
#include <xs1.h>
#include <print.h>
#include <platform.h>
#include <xscope.h>
#include "capsens.h"
#include "absolute.h"

on stdcore[0]: port cap4 = XS1_PORT_4A;
on stdcore[0]: port cap4y = XS1_PORT_4B;
on stdcore[0]: port p32 = XS1_PORT_32A;
on stdcore[0]: clock clk1 = XS1_CLKBLK_1;

void xscope_user_init(void) {
    xscope_config_io(XSCOPE_IO_BASIC);
}

int main3(void) {
    absolute_pos a, ay;
    timer t;
    int tt, to;
    
    absolute_slider_init(a, cap4, clk1, 4, 100, 50);
    absolute_slider_init(ay, cap4y, clk1, 4, 100, 50);
    t :> to;
    while(1) {
        t :> tt;
        int x = absolute_slider(a, cap4);
        int y = absolute_slider(ay, cap4y);
        printf("%9d %7d %7d\n", tt - to, x, y);
    }
    return 0;
}

int main1(void) {
    unsigned int avg[4];
    timer t;
    int tt, to;

    setupNbit(cap4, clk1);
    t :> to;
    while(1) {
        t :> tt;
        printf("%9d ", tt - to);
        measureAveragePrint(cap4, avg);
    }
    return 0;
}

int main2(void) {
    timer t;
    int tt;
    int i = 0;
    int delay = 150;
    int up = 1;
    t :> tt;
    while(1) {
        tt += delay;
        delay += up;
        if (delay > 1000) {
            up = -1;
        }
        if (delay < 50) {
            up = 1;
        }
        t when timerafter(tt) :> void;
        p32 <: ~0; // p32 <: i
        i++;        
    }
}

int main() {
    par {
        main3();
        main2();
    }
}
