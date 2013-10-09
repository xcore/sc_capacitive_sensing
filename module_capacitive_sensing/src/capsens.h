// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef CAPSENS_H

#define CAPSENSE_H 1

#include <xs1.h>

#define CAPSENSE_WIDTH      4
#define CAPSENSE_PULLDOWN   1    // Set to zero for pull-ups.

void setupNbit(port cap, clock k);
void measureNbit(port cap, unsigned int times[]);
void measureAverage(port cap, unsigned int avg[CAPSENSE_WIDTH]);
void measureAveragePrint(port cap, unsigned int avg[CAPSENSE_WIDTH]);

#endif
