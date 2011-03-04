// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "capsens.h"

#define N 200

void setupNbit(port cap, clock k) {
  stop_clock(k);
  set_clock_div(k, 1);
  configure_in_port(cap, k);
  start_clock(k);
}

void measureNbit(port cap, unsigned int times[], int pullDown) {
    int values[N];
    int curCaps, notSeen, curTime, newCaps, newBits;
    int t1, t0;
    int width = 8;
    int mask = 0xFF;
    
#ifdef PULLDOWN
    set_port_drive(cap);
#endif
    asm("setc res[%0], 8" :: "r"(cap));            // reset port - for flipping around
    cap <: pullDown ? ~0 : 0 @ t0;
    t0 += 10;                                      // Charge for 10 clock ticks.
    cap @ t0 <: pullDown ? ~0 : 0;
    sync(cap);
    asm("setc res[%0], 8" :: "r"(cap));            // reset port
    asm("setc res[%0], 0x200f" :: "r"(cap));       // set to buffering
    asm("settw res[%0], %1" :: "r"(cap), "r"(32)); // and set transfer width to 32
#ifdef PULLDOWN
    if (pullDown) set_port_pull_down(cap);
#endif
    
    cap :> void;                                   // Drain first two values, and record time
    cap :> void @ t1;                              // Then record values; find changes later
#pragma unsafe arrays
#pragma loop unroll(4)
    for(int i = 0; i < N; i++) {                   // Record up to N values.
        cap :> values[i];                            // Too high a value of N costs memory and time
    }                                              // Low low a value of N will miss large caps
    notSeen = mask;                                // Caps that are not yet Low
    curCaps = pullDown ? mask : 0;                 // Caps that are High
    curTime = (t1 - t0) & 0xffff;                  // Time of first measurement
    for(int i = 0; i < N && notSeen != 0; i++) {
        for(int k = 0; k < 32; k += width) {
            newCaps = (values[i]>>k) & mask;       // Extract measurement
            newBits = (curCaps^newCaps)&notSeen;   // Changed caps
            if (newBits != 0) {
                for(int j = 0; j < width; j ++) {
                    if(((newBits >> j) & 1) != 0) {
                        times[j] = curTime;      // Record time for
                    }                          // each changed cap
                }
                notSeen &= ~ newBits;        // And remember that
            }                               // this cap is low
            curCaps = newCaps;
            curTime++;
        }
    }
}

#pragma unsafe arrays
void measureAverage(port cap, unsigned int avg[8], int pullDown) {
    for(int k = 0; k < 8; k++) {
        avg[k] = 0;
    }
    for(int i = 0; i < 64; i++) {
        unsigned int t[8];
        for(int k = 0; k < 8; k++) {
            t[k] = 0x0000ffff;
        }
        measureNbit(cap, t, pullDown);
        for(int k = 0; k < 8; k++) {
            avg[k] += t[k];
        }
    }
    for(int k = 0; k < 8; k++) {
        avg[k]<<= 8;
    }
}
