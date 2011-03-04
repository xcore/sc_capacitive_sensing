// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <stdio.h>
#include <xs1.h>
#include <print.h>
#include "slider.h"

port leds = XS1_PORT_4F;
port cap8 = XS1_PORT_8B;

clock clk1 = XS1_CLKBLK_1;

int main(void) {
    slider x;
    timer t;
    int time;
    int ov = 0;
    int lVal = 0;
    sliderInit(x, cap8, clk1);
    while(1) {
        int v = filterSlider(x, cap8);
        if (v != ov) {
            switch (v) {
            case 1:
                leds <: 0xF;
                break;
            case 2:
                t :> time;
                for(int i = 0; i < 10; i++) {
                    lVal = lVal == 8 ? 4 : 8;
                    leds <: lVal;
                    t when timerafter(time += 10000000) :> int _;
                }
                leds <: 0;
                break;
            case 3:
                t :> time;
                for(int i = 0; i < 10; i++) {
                    lVal = lVal == 1 ? 2 : 1;
                    leds <: lVal;
                    t when timerafter(time += 10000000) :> int _;
                }
                leds <: 0;
                break;
            case 4:
                leds <: 0x0;
                break;
            }
            ov = v;
        }
    }
    return 0;
}
