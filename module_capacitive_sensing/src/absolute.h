// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef ABSOLUTE_H
#define ABSOLUTE_H 1

#include <xs1.h>

#include "capsens.h"

#define ABSOLUTE_SLIDER_ELEMENT   1000

typedef struct {
    unsigned int base[CAPSENSE_WIDTH];
    unsigned int t[CAPSENSE_WIDTH];
    int n_elements;
    int pressed;
    int threshold_press;
    int threshold_unpress;
} absolute_pos;

/** Function that initiates an absolute position slider with multiple elements. The slider is
 * connected to a port with its own clock block, and there are two
 * thresholds to govern press and unpress events.
 *
 * \param this     absolute position structure that will hold the state that is initialised
 *
 * \param cap      port on which the cap sense is connected
 *
 * \param clk      clock block to be used.
 * 
 * \param n_elements number of segments on this slider. Typically 4 or 8.
 * Note that at present this is hardcoded in the capsens.h file too and set
 * to 4.
 *
 * \param threshold_pressed   Value above which something is pressed. Set to 1000
 *
 * \param threshold_unpressed Value below which something is no longer pressed. Set to 200
 */
void absolute_slider_init(absolute_pos & this, port cap, clock k, int n_elements,
                          int threshold_pressed, int threshold_unpressed);

/** Function that returns where a slider is touched, or 0 if not touched.
 * The return value is a fixed point number with a precision of
 * ABSOLUTE_SLIDER_ELEMENT.
 */
int absolute_slider(absolute_pos &this, port cap);

#endif
