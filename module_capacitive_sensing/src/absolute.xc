#include "absolute.h"

#include <xs1.h>
#include <stdio.h>
#include "capsens.h"
#include <print.h>
[[distributable]]
void absolute_slider(server absolute_slider_if i, port cap, const clock k,
                     static const int n_elements,
                     static const int N,
                     int threshold_press, int threshold_unpress) {
  int pressed = 0;
  unsigned int base[n_elements];
  unsigned int t[n_elements];
  setupNbit(cap, k);
  measureAverage(cap, base, n_elements, N);
  for(int k = 0; k < n_elements; k++) {
    base[k] >>= 1;
  }
  while (1) {
    select {
    case i.get_coord() -> int coord:
      int avg = 0, n = 0;
      int minoffset = 999;

      measureAverage(cap, t, n_elements, N);
      for(int k = 0; k < n_elements; k++) {
        t[k] >>= 1;
      }
#if 0
      for(int k = 0; k < n_elements; k++) {
        int offset = t[k]-base[k];
        if (offset < minoffset) {
          minoffset = offset;
        }
      }
#endif
      for(int k = 0; k < n_elements; k++) {
        int offset = (t[k]-base[k]);// - minoffset;
        unsigned int h, l, correctionSpeed;
        //            printf(" %8d ", t[k] - base[k]);
        avg = avg + k * offset;
        n += offset;
        if (base[k] > t[k]) {
          correctionSpeed = 10;        // Lower sample found - adapt quickly
        } else {
          correctionSpeed = 10;       // Higher sample found - adapt slowly
        }                               // compute base = ((2^cs - 1) * base + t) 2^-cs
        {h,l} = mac( (1<<correctionSpeed) - 1, base[k], 0, t[k]);
        base[k] = h << (32-correctionSpeed) | l >> correctionSpeed;
      }
      if (pressed) {
        if (n < threshold_unpress) {
          pressed = 0;
        }
      } else {
        if (n > threshold_press) {
          pressed = 1;
        }
      }
      coord = pressed ? ABSOLUTE_SLIDER_ELEMENT*avg/n : 0;
      //    printf("%6d %d %8d %8d\n", coord, pressed, avg, n);
      break;
    }
  }
}
