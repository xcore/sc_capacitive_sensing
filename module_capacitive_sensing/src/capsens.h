// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef CAPSENS_H
#define CAPSENSE_H 1

#include <xs1.h>
#ifdef __capsense_conf_h_exists__
#include "capsense_conf.h"
#endif

#ifndef CAPSENSE_PULLDOWN
#define CAPSENSE_PULLDOWN   1    // Set to zero for pull-ups.
#endif

void capsenseInitClock(clock k);

void setupNbit(port cap, const clock k);

void measureNbit(port cap, unsigned int times[width],
                 static const unsigned width,
                 static const unsigned N);

void measureAverage(port cap, unsigned int avg[width],
                    static const unsigned width,
                    static const unsigned N);

void measureAveragePrint(port cap, unsigned int avg[width],
                         static const unsigned width,
                         static const unsigned N);

#endif
