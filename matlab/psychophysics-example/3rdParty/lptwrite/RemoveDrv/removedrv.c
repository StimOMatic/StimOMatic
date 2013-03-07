/******************************************************************************/
/*                                                                            */
/*                       Remove Driver for PortTalk  V2.0                     */
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

char __cdecl main(void)
{
    SC_HANDLE       SchSCManager;
    SC_HANDLE       schService;
    BOOL            ret;
    SERVICE_STATUS  serviceStatus;

    printf("Uninstall for PortTalk V2.0\nCopyright 2002 Craig Peacock\nhttp://www.beyondlogic.org\n");

    /* Open Handle to Service Control Manager */    
    SchSCManager = OpenSCManager (NULL,                   // machine (NULL == local)
                                  NULL,                   // database (NULL == default)
                                  SC_MANAGER_ALL_ACCESS); // access required

    /* Open Handle to PortTalk Service Database */
    schService = OpenService (SchSCManager,
                              "PortTalk",
                              SERVICE_ALL_ACCESS);

    if (schService == NULL) {
        printf("Error while opening PortTalk service, has PortTalk been installed?\n");
        return(0);
    }

    /* Stop Service */
    ret = ControlService (schService,
                          SERVICE_CONTROL_STOP,
                          &serviceStatus);

    if (ret) printf("PortTalk service has been successfully stopped.\n");
    else     printf("Unknown error while stopping PortTalk service.\n");

    /* Delete Service */
    ret = DeleteService (schService);

    if (ret) printf("PortTalk service has been successfully deleted.\n");
    else     printf("Error removing PortTalk service - PortTalk has NOT been successfully removed.");

    printf("You may now re-install PortTalk.\n");
   
    /* Close Handle to Porttalk Service Database */
    CloseServiceHandle (schService);

    /* Close Handle to Service Control Manager */
    CloseServiceHandle(SchSCManager);
}
