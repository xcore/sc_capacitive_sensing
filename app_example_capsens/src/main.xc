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

on stdcore[0]: port leds = XS1_PORT_4F;
on stdcore[0]: port cap8 = XS1_PORT_8A;

on stdcore[0]: clock clk1 = XS1_CLKBLK_1;

int vals[8] = { 6840576, 6970368, 0, 7208192, 0, 8316672, 0, 9435488 };
int main(void) {
    timer t;
    int x;
    unsigned int avg[8];
    xscope_register(5,
                    XSCOPE_CONTINUOUS, "Capacitance0", XSCOPE_UINT, "Value",
                    XSCOPE_CONTINUOUS, "Capacitance1", XSCOPE_UINT, "Value",
                    XSCOPE_CONTINUOUS, "Capacitance3", XSCOPE_UINT, "Value",
                    XSCOPE_CONTINUOUS, "Capacitance5", XSCOPE_UINT, "Value",
                    XSCOPE_CONTINUOUS, "Capacitance7", XSCOPE_UINT, "Value"
        );


    while(1) {
        measureAverage(cap8, avg, 1);
            xscope_probe_data(0, avg[0] - vals[0]);
        for(int i = 1; i < 8; i+=2) {
         //   printf("%d: %d\n", i, avg[i]-vals[i]);
            xscope_probe_data((i>>1)+1, avg[i] - vals[i]);
        }
    }
    return 0;
}
