/******************************************************************************/
/*                                                                            */
/*                          AllowIO for PortTalk V2.0                         */
/*                        Version 2.0, 12th January 2002                      */
/*                          http://www.beyondlogic.org                        */
/*                                                                            */
/* Copyright © 2002 Craig Peacock. Craig.Peacock@beyondlogic.org              */
/* Any publication or distribution of this code in source form is prohibited  */
/* without prior written permission of the copyright holder. This source code */
/* is provided "as is", without any guarantee made as to its suitability or   */
/* fitness for any particular use. Permission is herby granted to modify or   */
/* enhance this sample code to produce a derivative program which may only be */
/* distributed in compiled object form only.                                  */
/******************************************************************************/

#include <stdio.h>
#include <windows.h>
#include <winioctl.h>
#include <porttalk_IOCTL.h>

void InstallPortTalkDriver(void);
unsigned char StartPortTalkDriver(void);

int __cdecl main(int argc, char ** argv)
{
    HANDLE PortTalk_Handle;   /* Handle for PortTalk Driver */
    int error;                /* Error Handling for DeviceIoControl() */
    int count;                /* Temp Variable to process Auguments */
    int value;
    int offset;

    char filename[80] = {""}; /* Filename of Executable */
    DWORD BytesReturned;      /* Bytes Returned for DeviceIoControl() */

    STARTUPINFO si;           /* Startup Info Structure */
    PROCESS_INFORMATION pi;   /* Process Info Structure - Contains Process ID Information */
 
    printf("AllowIO for PortTalk V2.0\nCopyright 2002 Craig Peacock\nhttp://www.beyondlogic.org\n");

    /* No Arguments, Display product info and help */

    if (argc <= 1)
        {
         printf("Grants the specified executable exclusive access to specified I/O Ports\nunder Windows NT/2000/XP\n");
         printf("Usage : AllowIO <executable> <addresses(Hex)> <switches>\n");
         printf("Switches : /a - Grants exclusive access to ALL Ports\n");
         return 0;
        }
    
    /* Open PortTalk Driver. If we cannot open it, try installing and starting it */

    PortTalk_Handle = CreateFile("\\\\.\\PortTalk", 
                                 GENERIC_READ, 
                                 0, 
                                 NULL,
                                 OPEN_EXISTING, 
                                 FILE_ATTRIBUTE_NORMAL, 
                                 NULL);

    if(PortTalk_Handle == INVALID_HANDLE_VALUE) {
            /* Start or Install PortTalk Driver */
            StartPortTalkDriver();
            /* Then try to open once more, before failing */
            PortTalk_Handle = CreateFile("\\\\.\\PortTalk", 
                                         GENERIC_READ, 
                                         0, 
                                         NULL,
                                         OPEN_EXISTING, 
                                         FILE_ATTRIBUTE_NORMAL, 
                                         NULL);
               
            if(PortTalk_Handle == INVALID_HANDLE_VALUE) {
                    printf("PortTalk: Couldn't access PortTalk Driver, Please ensure driver is loaded.\n\n");
                    return -1;
            }
    }

    /* Once we have successfully opened a handle to the PortTalk Driver, we must fill the */
    /* driver's IOPM with 0xFF to restrict access to all ports */

    error = DeviceIoControl(PortTalk_Handle,
                            IOCTL_IOPM_RESTRICT_ALL_ACCESS,   
                            NULL,
                            0,    
                            NULL,
                            0,
                            &BytesReturned,
                            NULL);

    if (!error) printf("PortTalk: error %d occured in IOCTL_IOPM_RESTRICT_ALL_ACCESS\n",GetLastError());
    
    /* Now we start processing arguments and sending them to the driver */    

    for (count = 1; count < argc; count++) { 
        /* If argument starts with '0x' */
        if (argv[count][0] == '0' & argv[count][1] =='x') {
                sscanf(argv[count],"%x", &value);
                offset = value / 8;
                error = DeviceIoControl(PortTalk_Handle,
                                        IOCTL_SET_IOPM,
                                        &offset,
                                        3,    
                                        NULL,
                                        0,
                                        &BytesReturned,
                                        NULL);

                if (!error) printf("Error %d granting access to Address 0x%03X\n",GetLastError(),value);
                else        printf("Address 0x%03X (IOPM Offset 0x%02X) has been granted access.\n",value,offset);
        }
        else if (argv[count][0] == '/' & argv[count][1] =='a') {
                /*  Set Entire IOPM */
                printf("Granting exclusive access to all I/O Ports\n");
                error = DeviceIoControl(PortTalk_Handle,
                                        IOCTL_IOPM_ALLOW_EXCUSIVE_ACCESS,
                                        NULL,
                                        0,    
                                        NULL,
                                        0,
                                        &BytesReturned,
                                        NULL);
        } else {
                /* Must be a Filename */
                if (strlen(filename) + strlen(argv[count]) > 80) { 
                     printf("Command line exceeds 80 Characters\n");
                     return 0;
                    }
                strcat(filename,argv[count]);
                strcat(filename," ");
                }
    }

    /* Start Executable */
    printf("Executing %swith a ",filename);

    ZeroMemory( &si, sizeof(si) ); /* Zero Startup Info */
    si.cb = sizeof(si);            /* Set Size */

    if( !CreateProcess(NULL,       /* No module name (use command line). */
                       filename,   /* Command line. */
                       NULL,       /* Process handle not inheritable. */
                       NULL,       /* Thread handle not inheritable. */
                       FALSE,      /* Set handle inheritance to FALSE. */
                       0,          /* No creation flags. */
                       NULL,       /* Use parent's environment block. */
                       NULL,       /* Use parent's starting directory. */
                       &si,        /* Pointer to STARTUPINFO structure. */
                       &pi)        /* Pointer to PROCESS_INFORMATION structure. */
                   ) printf("Error in CreateProcess\n\n");    

    printf("ProcessID of %d\n",pi.dwProcessId);

    error = DeviceIoControl(PortTalk_Handle,
                            IOCTL_ENABLE_IOPM_ON_PROCESSID,
                            &pi.dwProcessId,
                            4,
                            NULL,
                            0,
                            &BytesReturned,
                            NULL);

    if (!error) printf("Error Occured talking to Device Driver %d\n",GetLastError());
    else        printf("PortTalk Device Driver has set IOPM for ProcessID %d.\n",pi.dwProcessId);

    CloseHandle(PortTalk_Handle);
    return 0;
}

unsigned char StartPortTalkDriver(void)
{
    SC_HANDLE  SchSCManager;
    SC_HANDLE  schService;
    BOOL       ret;
    DWORD      err;

    /* Open Handle to Service Control Manager */
    SchSCManager = OpenSCManager (NULL,                        /* machine (NULL == local) */
                                  NULL,                        /* database (NULL == default) */
                                  SC_MANAGER_ALL_ACCESS);      /* access required */
                         
    if (SchSCManager == NULL)
      if (GetLastError() == ERROR_ACCESS_DENIED) {
         /* We do not have enough rights to open the SCM, therefore we must */
         /* be a poor user with only user rights. */
         printf("PortTalk: You do not have rights to access the Service Control Manager and\n");
         printf("PortTalk: the PortTalk driver is not installed or started. Please ask \n");
         printf("PortTalk: your administrator to install the driver on your behalf.\n");
         return(0);
         }

    do {
         /* Open a Handle to the PortTalk Service Database */
         schService = OpenService(SchSCManager,         /* handle to service control manager database */
                                  "PortTalk",           /* pointer to name of service to start */
                                  SERVICE_ALL_ACCESS);  /* type of access to service */

         if (schService == NULL)
            switch (GetLastError()){
                case ERROR_ACCESS_DENIED:
                        printf("PortTalk: You do not have rights to the PortTalk service database\n");
                        return(0);
                case ERROR_INVALID_NAME:
                        printf("PortTalk: The specified service name is invalid.\n");
                        return(0);
                case ERROR_SERVICE_DOES_NOT_EXIST:
                        printf("PortTalk: The PortTalk driver does not exist. Installing driver.\n");
                        printf("PortTalk: This can take up to 30 seconds on some machines . .\n");
                        InstallPortTalkDriver();
                        break;
            }
         } while (schService == NULL);

    /* Start the PortTalk Driver. Errors will occur here if PortTalk.SYS file doesn't exist */
    
    ret = StartService (schService,    /* service identifier */
                        0,             /* number of arguments */
                        NULL);         /* pointer to arguments */
                    
    if (ret) printf("PortTalk: The PortTalk driver has been successfully started.\n");
    else {
        err = GetLastError();
        if (err == ERROR_SERVICE_ALREADY_RUNNING)
          printf("PortTalk: The PortTalk driver is already running.\n");
        else {
          printf("PortTalk: Unknown error while starting PortTalk driver service.\n");
          printf("PortTalk: Does PortTalk.SYS exist in your \\System32\\Drivers Directory?\n");
          return(0);
        }
    }

    /* Close handle to Service Control Manager */
    CloseServiceHandle (schService);
    return(TRUE);
}

void InstallPortTalkDriver(void)
{
    SC_HANDLE  SchSCManager;
    SC_HANDLE  schService;
    DWORD      err;
    CHAR         DriverFileName[80];

    /* Get Current Directory. Assumes PortTalk.SYS driver is in this directory.    */
    /* Doesn't detect if file exists, nor if file is on removable media - if this  */
    /* is the case then when windows next boots, the driver will fail to load and  */
    /* a error entry is made in the event viewer to reflect this */

    /* Get System Directory. This should be something like c:\windows\system32 or  */
    /* c:\winnt\system32 with a Maximum Character lenght of 20. As we have a       */
    /* buffer of 80 bytes and a string of 24 bytes to append, we can go for a max  */
    /* of 55 bytes */

    if (!GetSystemDirectory(DriverFileName, 55))
        {
         printf("PortTalk: Failed to get System Directory. Is System Directory Path > 55 Characters?\n");
         printf("PortTalk: Please manually copy driver to your system32/driver directory.\n");
        }

    /* Append our Driver Name */
    lstrcat(DriverFileName,"\\Drivers\\PortTalk.sys");
    printf("PortTalk: Copying driver to %s\n",DriverFileName);

    /* Copy Driver to System32/drivers directory. This fails if the file doesn't exist. */

    if (!CopyFile("PortTalk.sys", DriverFileName, FALSE))
        {
         printf("PortTalk: Failed to copy driver to %s\n",DriverFileName);
         printf("PortTalk: Please manually copy driver to your system32/driver directory.\n");
        }

    /* Open Handle to Service Control Manager */
    SchSCManager = OpenSCManager (NULL,                   /* machine (NULL == local) */
                                  NULL,                   /* database (NULL == default) */
                                  SC_MANAGER_ALL_ACCESS); /* access required */

    /* Create Service/Driver - This adds the appropriate registry keys in */
    /* HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services - It doesn't  */
    /* care if the driver exists, or if the path is correct.              */

    schService = CreateService (SchSCManager,                      /* SCManager database */
                                "PortTalk",                        /* name of service */
                                "PortTalk",                        /* name to display */
                                SERVICE_ALL_ACCESS,                /* desired access */
                                SERVICE_KERNEL_DRIVER,             /* service type */
                                SERVICE_DEMAND_START,              /* start type */
                                SERVICE_ERROR_NORMAL,              /* error control type */
                                "System32\\Drivers\\PortTalk.sys", /* service's binary */
                                NULL,                              /* no load ordering group */
                                NULL,                              /* no tag identifier */
                                NULL,                              /* no dependencies */
                                NULL,                              /* LocalSystem account */
                                NULL                               /* no password */
                                );

    if (schService == NULL) {
         err = GetLastError();
         if (err == ERROR_SERVICE_EXISTS)
               printf("PortTalk: Driver already exists. No action taken.\n");
         else  printf("PortTalk: Unknown error while creating Service.\n");    
    }
    else printf("PortTalk: Driver successfully installed.\n");

    /* Close Handle to Service Control Manager */
    CloseServiceHandle (schService);
}