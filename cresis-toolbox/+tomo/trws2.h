// trws.h: Some very helpful variables and functions.
// By Mingze Xu, November 2016
//
// Minor style changes to comply with new C++ standards: Victor Berger 2018
//
#ifndef _INSTANCES_H_
#define _INSTANCES_H_
#define _USE_MATH_DEFINES
 
#include <cmath>
#include <stddef.h>

// Compute square value
template <class T> inline T sqr(T x) { return x*x; }

// THE CODE BELOW THIS POINT WAS TAKEN FROM DAVID CRANDALL
// Distance transform
// -- Every index from d1 to d2 will be set in dst
// -- dst will contain the minimum value for that destination
// -- dst_ind will contain the minimum source index for that destination
void dt(const float *src, float *dst, int s1, int s2,
        int d1, int d2, float scale, int off = 0) {
    
    int d = (d1 + d2) >> 1, s = s1; // Find the midpoint of the destination
    for (int p = s1; p <= s2; p++) { // Search through all the sources and find the minimum
        if (src[s] + sqr(s-d-off) * scale > src[p] + sqr(p-d-off) * scale) {
            s = p;
        }
    }
    dst[d] = src[s] + sqr(s-d-off) * scale; // Minimum value to the midpoint
    if(d2 >= d + 1) { // Recursive call, binary search (top half of destinations)
        dt(src, dst, s, s2, d+1, d2, scale, off);
    }
    if(d-1 >= d1) { // Recursive call, binary search (bottom half of destinations)
        dt(src, dst, s1, s, d1, d-1, scale, off);
    }
}
// END CODE FROM DAVID CRANDALL	

#endif
