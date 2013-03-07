/*
lptread.c

Compile in MATLAB with mex lptread.c [-O] [-g] [-v]
(lcc is picky that this file ends in a blank line)
For description see lptread.m

Copyright (C) 2006 Erik Flister, UCSD, e_flister@REMOVEME.yahoo.com
Adapted from Andreas Widmann.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include "stdio.h"
#include "windows.h"
#include "mex.h"
#include "pt_ioctl.c"

void __cdecl mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
    double *port;
    int mrows, ncols;
    double *val;

/* Check for proper number of arguments. */
    if (nrhs != 1) {
        mexErrMsgTxt("One input argument required.");
    } else if (nlhs != 1) {
        mexErrMsgTxt("One output argument required.");
    }

/* The input must be noncomplex scalar double.*/
    mrows = mxGetM(prhs[0]);
    ncols = mxGetN(prhs[0]);
    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) || !(mrows == 1 && ncols ==1)) {
        mexErrMsgTxt("Input must be noncomplex scalar double.");
    }

/* Assign pointers. */
    port = mxGetData(prhs[0]);
    plhs[0] = mxCreateScalarDouble(0);
    val = mxGetPr(plhs[0]);

/* Call PortTalk. */
    OpenPortTalk();
    *val = inportb(*port);
    ClosePortTalk();
}