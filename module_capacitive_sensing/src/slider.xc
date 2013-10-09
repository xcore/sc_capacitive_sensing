// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <xscope.h>

#include <stdio.h>
#include "slider.h"
#include "capsens.h"

void slider_init(slider & this, port cap, clock k, int n_elements,
                          int threshold_pressed, int threshold_unpressed) {
    timer tt;
    this.state = IDLE;
    this.old_state = IDLE;
    tt :> this.lastTime;
    this.coord = 0;
    this.nomoves = this.lefts = this.rights = 0;
    absolute_slider_init(this.pos, cap, k, n_elements,
                         threshold_pressed, threshold_unpressed);
}

sliderstate slider_filter(slider &this, port cap) {
    int coord;
    unsigned time, timePassed;
    timer tt;

    tt :> time;
    timePassed = time - this.lastTime;
    coord = absolute_slider(this.pos, cap);

    switch (this.state) {
    case IDLE:
        if (this.pos.pressed) {
            this.state = PRESSING;
            this.lastTime = time;
            this.coord = coord;
            this.nomoves = this.lefts = this.rights = 0;
        }
        break;
    case PRESSING:
        if (timePassed > 500000 && this.pos.pressed) {
            int ms = timePassed / 100000;
            int speed = (coord - this.coord)*1000/ms;
//            printf("%3d %08x coord %4d speed %7d %2d %2d %2d\n", ms, cap, coord, speed, this.lefts, this.rights, this.nomoves);
            if (speed > 5000) {
                this.nomoves--;
                this.lefts--;
                this.rights+=2;
            } else if (speed < -5000) {
                this.lefts+=2;
                this.nomoves--;
                this.rights--;
            } else if (speed < 2000 && speed > -2000) {
                this.lefts--;
                this.rights--;
                this.nomoves+=2;
            }
//            printf("%d %d %d\n", this.lefts, this.rights, this.nomoves);
            this.lastTime = time;
            this.coord = coord;
            //     if (this.nomoves > this.lefts+3 && this.nomoves > this.rights+3 || abs(this.lefts - this.rights) < 3 && (this.lefts+this.rights) > 15) {
            //             this.state = PRESSED;
            //             return PRESSED;
            //         }
            if (this.rights > 6) {
//                printf("Left\n");
                this.state = LEFTING;
                return LEFTING;
            }
            if (this.lefts > 6) {
//                printf("Right\n");
                this.state = RIGHTING;
                return RIGHTING;
            }
        } else if (timePassed > 20000000 && !this.pos.pressed) {
            this.state = IDLE;
        } else {
            printf("%3d %08x coord ---- speed ------- %2d %2d %2d\n", timePassed / 100000, cap, this.lefts, this.rights, this.nomoves);
        }
        break;
    case PRESSED:
    case LEFTING:
    case RIGHTING:
        if (!this.pos.pressed && (time - this.lastTime) > 10000000) {
            this.state = IDLE;
            this.lastTime = time;
            return RELEASED;
        }
        break;
    case RELEASED:
        // not reached
        break;
    }
    return IDLE;
}
