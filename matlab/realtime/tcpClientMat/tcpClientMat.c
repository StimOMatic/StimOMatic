/* 
 'tcpClientMat.c' to be used with 'tcpServerMmap.py'
 
 1. HOW TO COMPILE:

 1.1 compile on Linux:
 $ '/usr/local/MATLAB/R2011a/bin/mex tcpClientMat.c'

 1.2 compile on Windows:
 $ mex tcpClientMat.c wsock32.lib

 In case the code won't compile on Windows, try to add
 "C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Include" to 'INCLUDE' in your
 'mexopts.bat' file.


 2. HOW TO USE:
 # call from matlab: 'tcpClientMat('MESSAGE', 'HOST', PORT, VERBOSE)'
 #
 # 'MESSAGE' must be string
 # 'HOST' must be string, is hostname or IP address.
 # 'PORT' is scalar
 # 'VERBOSE' is scalar
 #
 $ tic; tcpClientMat('12', 'localhost', 9999, 1); toc
   using host localhost / value 12 port 9999 
   Sent:      12
   Received:  OK
   Elapsed time is 0.001699 seconds.


 3. RETURN VALUE:
 # program returns 1 if server replies 'ok', and -1 otherwise.

*/
#if defined _WIN64 || defined _WIN32
#include <sys/types.h>
#include <winsock2.h>
#include <windows.h>
#define    WINSOCKVERSION    MAKEWORD( 2,2 )        
#else
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#endif

#include <stdio.h>
#include <string.h>
#include <mex.h>

#define MAX_BUFFER    128
#define HOST        "127.0.0.1" 

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{

	/* hostname & port */
	char* hostname = "127.0.0.1";
	int port = 9999;

	/* verbose mode? */
	int verbose = 0;

	/* setup string to send */
	char* string_to_write = "00";
	char* string_from_cmd_line;

	int connectionFd, rc, index = 0, limit = MAX_BUFFER;
	struct sockaddr_in servAddr, localAddr;
	char buffer[MAX_BUFFER+1];

	/* counter variable to examine inputs to this function */
	int i;
    
	/* default return value from this program */
	int retVal = -1;

	#if defined _WIN64 || defined _WIN32
	/* Start up WinSock2 */
	WSADATA wsaData;
	if( WSAStartup( WINSOCKVERSION, &wsaData) != 0 ) 
		/*  no returns in mex file!
			return ERROR;        
		*/
	#endif

	/* Examine input (right-hand-side) arguments.
	mexPrintf("\nThere are %d right-hand-side argument(s).", nrhs);
	for (i=0; i<nrhs; i++)  {
		mexPrintf("\n\tInput Arg %i is of type:\t%s ",i,mxGetClassName(prhs[i]));
		mexPrintf("\n\tValue %s ", mxArrayToString(prhs[i]));
	}
	mexPrintf("\n\n");
	*/

	#if defined _WIN64 || defined _WIN32
	/* this line is needed on windows, otherwise the input arguments don't get 
	   parsed - I don't really understand why. */
	mexPrintf("\n\n");
	#endif

	/* check valid number of input arguments */
	if (nrhs!=3 && nrhs!=4) {
		mexErrMsgTxt("tcpClientMat MEX file; Needs at least 3 cmd line arguments: CmdToSend Hostname Port Verbose (optional)\n");
	}


	/* 
	 * BEGIN assign input arguments to variables 
	 */

	/* check if command is a string, otherwise use default value */
	string_from_cmd_line = mxArrayToString(prhs[0]);
	if (string_from_cmd_line != NULL)
		string_to_write = string_from_cmd_line;

	/* hostname and port number. If mex file is not called like function, 
	   then port number becomes 48 to 57 (depending on input value, don't know why */
	hostname = mxArrayToString(prhs[1]);
	port = mxGetScalar(prhs[2]);

	if (nrhs > 3) {
		verbose = mxGetScalar(prhs[3]);
	}

	if (verbose) {
		mexPrintf("using host %s / value %s port %i \n", hostname, string_to_write, port);
	}

	/* 
	 * END assign input arguments to variables 
	 */


	/* setup network parameters */
	memset(&servAddr, 0, sizeof(servAddr));
	servAddr.sin_family = AF_INET;
	servAddr.sin_port = htons(port);
	servAddr.sin_addr.s_addr = inet_addr(hostname);

	/* Create socket */
	connectionFd = socket(AF_INET, SOCK_STREAM, 0);

	/* bind any port number */
	localAddr.sin_family = AF_INET;
	localAddr.sin_addr.s_addr = htonl(INADDR_ANY);
	localAddr.sin_port = htons(0);

	rc = bind(connectionFd, 
	  (struct sockaddr *) &localAddr, sizeof(localAddr));

	/* Connect to Server */
	connect(connectionFd, 
	  (struct sockaddr *)&servAddr, sizeof(servAddr));

	/* Send request to Server */
	sprintf(buffer, "%s", string_to_write);
	send(connectionFd, buffer, strlen(buffer), 0);

	if (verbose) {
		printf("Sent:      %s\n", buffer);
	}

	/* Receive data from Server */
	sprintf(buffer, "%s", "" );
	recv(connectionFd, buffer, MAX_BUFFER, 0);

	if (verbose) {
		printf("Received:  %s\n", buffer);
	}

	/* check if server replied 'OK' */
	if (strcmp(buffer, "OK") == 0) {
		retVal = 1;
	}

	/* assign return variable value of 'retVal' */
	plhs[0] = mxCreateDoubleScalar(retVal); 
	
	/* close socket */
	#if defined _WIN64 || defined _WIN32
	closesocket(connectionFd);
	#else
	close(connectionFd);
	#endif

}


