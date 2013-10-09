// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "capsens.h"

#include <xs1.h>
#include <print.h>
#include <stdio.h>

#define N (20 * CAPSENSE_WIDTH)

void setupNbit(port cap, clock k) {
  stop_clock(k);
  set_clock_div(k, 1);
  configure_in_port(cap, k);
  start_clock(k);
}

void measureNbit(port cap, unsigned int times[]) {
    int values[N];
    int curCaps, notSeen, curTime, newCaps, newBits;
    int t1, t0;
    int mask = (1 << CAPSENSE_WIDTH) - 1;
    
    asm("setc res[%0], 0" :: "r"(cap));            // reset port
    asm("setc res[%0], 8" :: "r"(cap));            // reset port - for flipping around
    cap <: CAPSENSE_PULLDOWN ? ~0 : 0 @ t0;
    t0 += 10;                                      // Charge for 10 clock ticks.
    cap @ t0 <: CAPSENSE_PULLDOWN ? ~0 : 0;
    sync(cap);
    asm("setc res[%0], 0" :: "r"(cap));            // reset port
    asm("setc res[%0], 8" :: "r"(cap));            // reset port
    asm("setc res[%0], 0x200f" :: "r"(cap));       // set to buffering
    asm("settw res[%0], %1" :: "r"(cap), "r"(32)); // and set transfer width to 32
    
    cap :> void;                                   // Drain first two values, and record time
    cap :> void @ t1;                              // Then record values; find changes later
#pragma unsafe arrays
#pragma loop unroll(4)
    for(int i = 0; i < N; i++) {                   // Record up to N values.
        cap :> values[i];                          // Too high a value of N costs memory and time
    }                                              // Low low a value of N will miss large caps
    notSeen = mask;                                // Caps that are not yet Low
    curCaps = CAPSENSE_PULLDOWN ? mask : 0;                 // Caps that are High
    curTime = (t1 - t0) & 0xffff;                  // Time of first measurement
    for(int i = 0; i < N && notSeen != 0; i++) {
        for(int k = 0; k < 32; k += CAPSENSE_WIDTH) {
            newCaps = (values[i]>>k) & mask;       // Extract measurement
            newBits = (curCaps^newCaps)&notSeen;   // Changed caps
            if (newBits != 0) {
                for(int j = 0; j < CAPSENSE_WIDTH; j ++) {
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

#define AVERAGE_BITS 6
#define AVERAGE_SIZE (1<<AVERAGE_BITS)

#pragma unsafe arrays
void measureAverageBoth(port cap, unsigned int avg[CAPSENSE_WIDTH], int print) {
    int a2[CAPSENSE_WIDTH];
    for(int k = 0; k < CAPSENSE_WIDTH; k++) {
        avg[k] = 0;
        a2[k] = 0;
    }
    for(int i = 0; i < AVERAGE_SIZE; i++) {
        unsigned int t[CAPSENSE_WIDTH];
        for(int k = 0; k < CAPSENSE_WIDTH; k++) {
            t[k] = N * 32 / CAPSENSE_WIDTH;
        }
        measureNbit(cap, t);
        for(int k = 0; k < CAPSENSE_WIDTH; k++) {
            a2[k] += t[k]*t[k];                  // sum of squares for standard dev
            avg[k] += t[k];
        }
    }
    for(int k = 0; k < CAPSENSE_WIDTH; k++) {
        avg[k] >>= AVERAGE_BITS;
        a2[k] >>= AVERAGE_BITS;
        int sdev = a2[k] - avg[k] * avg[k];   // standard deviation unusued at present
        if (print) {
            printf("%6d %6d  ", avg[k], sdev);
        }
    }
    if (print) {
        printf("\n");
    }
}

void measureAveragePrint(port cap, unsigned int avg[CAPSENSE_WIDTH]) {
    measureAverageBoth(cap, avg, 1);
}

void measureAverage(port cap, unsigned int avg[CAPSENSE_WIDTH]) {
    measureAverageBoth(cap, avg, 0);
}
