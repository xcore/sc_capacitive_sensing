// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <xscope.h>
#include <print.h>
#include <stdio.h>
#include "slider.h"
#include "capsens.h"

[[distributable]]
void slider(server slider_query_if i, client absolute_slider_if abs)
{
  timer tt;
  int state = IDLE;
  int lastTime;
  tt :> lastTime;
  int prev_coord = 0;
  int nomoves = 0, lefts = 0, rights = 0;
  while (1) {
    select {
    case i.get_coord() -> int coord:
      coord = abs.get_coord();
      break;
    case i.filter() -> sliderstate ret:
      int coord;
      unsigned time, timePassed;
      timer tt;
      ret = IDLE;

      tt :> time;
      timePassed = time - lastTime;
      coord = abs.get_coord();

      switch (state) {
      case IDLE:
        if (coord) {
          state = PRESSING;
          lastTime = time;
          prev_coord = coord;
          nomoves = lefts = rights = 0;
        }
        break;
      case PRESSING:
        if (timePassed > 500000 && coord) {
          int ms = timePassed / 100000;
          int speed = (coord - prev_coord)*1000/ms;
          //            printf("%3d %08x coord %4d speed %7d %2d %2d %2d\n", ms, cap, coord, speed, lefts, rights, nomoves);
          if (speed > 5000) {
            nomoves--;
            lefts--;
            rights+=2;
          } else if (speed < -5000) {
            lefts+=2;
            nomoves--;
            rights--;
          } else if (speed < 2000 && speed > -2000) {
            lefts--;
            rights--;
            nomoves+=2;
          }
          //            printf("%d %d %d\n", lefts, rights, nomoves);
          lastTime = time;
          prev_coord = coord;
          //     if (nomoves > lefts+3 && nomoves > rights+3 || abs(lefts - rights) < 3 && (lefts+rights) > 15) {
          //             state = PRESSED;
          //             ret = PRESSED;
          //         }
          if (rights > 6) {
            //                printf("Left\n");
            state = LEFTING;
            ret = LEFTING;
          }
          if (lefts > 6) {
            //                printf("Right\n");
            state = RIGHTING;
            ret = RIGHTING;
          }
        } else if (timePassed > 20000000 && !coord) {
          state = IDLE;
        } else {
          //printf("%3d %08x coord ---- speed ------- %2d %2d %2d\n", timePassed / 100000, cap, lefts, rights, nomoves);
        }
        break;
      case PRESSED:
      case LEFTING:
      case RIGHTING:
        if (!coord && (time - lastTime) > 10000000) {
          state = IDLE;
          lastTime = time;
          ret = RELEASED;
        }
        break;
      case RELEASED:
        // not reached
        break;
      }
      break;
    }
  }
}









#define SLIDER_POLL_PERIOD 200000

[[combinable]]
static void slider_periodic(server slider_if i,
                            client slider_query_if q)
{
  timer tmr;
  int t;
  sliderstate state = IDLE;
  tmr :> t;
  while (1) {
    select {
    case tmr when timerafter(t) :> void:
      sliderstate new_state = q.filter();
      if (new_state != state) {
        i.changed_state();
        state = new_state;
      }
      t += SLIDER_POLL_PERIOD;
      break;
    case i.get_slider_state() -> sliderstate ret:
      ret = state;
      break;
    case i.get_coord() -> int coord:
      coord = q.get_coord();
      break;
    }
  }
}

[[combinable]]
void slider_task(server slider_if i, port cap, const clock clk,
                 static const int n_elements,
                 static const int N,
                 int threshold_pressed, int threshold_unpressed)
{
  slider_query_if i_query;
  absolute_slider_if abs;
  [[combine]]
  par {
    absolute_slider(abs, cap, clk, n_elements, N, threshold_pressed,
                    threshold_unpressed);
    slider(i_query, abs);
    slider_periodic(i, i_query);
  }
}
