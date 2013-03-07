function lptwrite(port, value)
% LPTWRITE write byte to port
%
% Description:
%   IOCTL call to porttalk.sys kernel mode driver (required) by Craig
%   Peacock
%
% Usage:
%   lptwrite(port, value)
%
% Arguments:
%   port  - double Port address (e.g., 888 = 0x378 for LPT1 on many
%           machines) 
%   value - double value to write (0-255)
%
% Examples:
%   lptwrite(888, 42);
%
% Author: Andreas Widmann, University of Leipzig, 2006

% PortTalk functions and driver:
% Copyright (C) 1999-2002 Craig Peacock, http://www.beyondlogic.org
%
% Copyright (C) 2006 Andreas Widmann, University of Leipzig, widmann@uni-leipzig.de
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307,
% USA
