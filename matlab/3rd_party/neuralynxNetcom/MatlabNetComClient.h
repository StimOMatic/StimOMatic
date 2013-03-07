#pragma once

#ifdef __cplusplus
	extern "C" {
#endif

//client functions
__declspec(dllexport) int ConnectToServer(const char* serverName);
__declspec(dllexport) int DisconnectFromServer();
__declspec(dllexport) int OpenStream(const char* cheetahObjectName);
__declspec(dllexport) int CloseStream(const char* cheetahObjectName);
__declspec(dllexport) int SendCommand(const char* command, char** reply, int* numBytesAvailable);

//setter functions
__declspec(dllexport) int SetApplicationName(const char* myApplicationName);
//extern "C" __declspec(dllexport) bool SetLogFileName(string filename);

//getter functions
__declspec(dllexport) int GetCheetahObjectsAndTypes(char** cheetahObjects, char** cheetahTypes, int* pNumBytesPerString, int* pNumStrings);

//getter status functions
__declspec(dllexport) char* GetServerPCName();
__declspec(dllexport) char* GetServerIPAddress();
__declspec(dllexport) char* GetServerApplicationName();
__declspec(dllexport) int AreWeConnected();

//setup functions for data retrieval
__declspec(dllexport) int GetRecordBufferSize(void);
__declspec(dllexport) int SetRecordBufferSize(int numRecordsToBuffer);
__declspec(dllexport) int GetMaxCSCSamples(void);
__declspec(dllexport) int GetSpikeSampleWindowSize(void);
__declspec(dllexport) int GetMaxSpikeFeatures(void);
__declspec(dllexport) int GetMaxEventStringLength(void);


//data retrieval functions
__declspec(dllexport) int GetNewCSCData( const char* acqEntName, __int64* timeStamps, int* channelNumbers, int* samplingFrequency, int* numValidSamples, short* samples, int* numRecordsReturned, int* numDroppedRecords);
__declspec(dllexport) int GetNewSEData(const char* acqEntName, __int64* timeStamps, int* scNumbers, int* cellNumbers, int* featureValues, short* samples, int* numRecordsReturned, int* numDroppedRecords); 
__declspec(dllexport) int GetNewSTData(const char* acqEntName, __int64* timeStamps, int* scNumbers, int* cellNumbers, int* featureValues, short* samples, int* numRecordsReturned, int* numDroppedRecords); 
__declspec(dllexport) int GetNewTTData(const char* acqEntName, __int64* timeStamps, int* scNumbers, int* cellNumbers, int* featureValues, short* samples, int* numRecordsReturned, int* numDroppedRecords); 
__declspec(dllexport) int GetNewEventData(const char* acqEntName, __int64* timeStamps, int* eventIDs, int* ttlValues, char** eventStrings, int* numRecordsReturned, int* numDroppedRecords);
__declspec(dllexport) int GetNewVTData(const char* acqEntName, __int64* timeStamps, int* extractedLocations, int* extractedAngles, int* numRecordsReturned, int* numDroppedRecords);


#ifdef __cplusplus
	}
#endif
