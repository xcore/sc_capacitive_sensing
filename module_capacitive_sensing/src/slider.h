// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "absolute.h"

/** Type that enumerates the possible activities that may have happened on a slider.
 */
typedef enum {IDLE, PRESSED, LEFTING, RIGHTING, RELEASED, PRESSING} sliderstate;

/** Type that encapsulates the internal state of a slider. The only element
 * that is of possible interest in the structure is the coord field, which
 * holds the last absolute position; see absolute.h for an explanation of
 * the value.
 */
typedef struct {
    absolute_pos pos;
    int state;
    int lastTime;
    int coord;
    int lefts, rights, nomoves;
    int old_state;
} slider;

/** Function to initialise the slider structure. FOr each slider that is of
 * interest to the application, a slider variable should be declared and
 * initialised using this function.
 *
 * \param this     slider structure that will hold the state that is initialised
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
void slider_init(slider & this, port cap, clock k, int n_elements,
                          int threshold_pressed, int threshold_unpressed);

/** Function to perform a measurement on the slider and to check if
 * anything has happened. Clal this function regularly.
 *
 * \returns one of the activities that may have happened to the slider.
 */
sliderstate slider_filter(slider &this, port cap);

