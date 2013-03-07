%NLXGETCHEETAHOBJECTSANDTYPES   Retrieves all objects defined in Cheetah's object list, 
%							 along with their corresponding types.  The NetCom client
%							 must be connected, or this function will fail.
%
%   [SUCCEEDED, CHEETAHOBJECTS, CHEETAHTYPES] = NLXGETCHEETAHOBJECTSANDTYPES() 
%
%   Example:  [succeeded, cheetahObjects, cheetahTypes] NlxGetCheetahObjectsAndTypes();
%	
%
%	succeeded:	1 means the operation completed successfully
%				0 means the operation failed
%
%	cheetahObjecs: This cell string array will be filled with strings for each object 
%				   in Cheetah's object list.
%
%	cheetahTypes:  This cell string array will be filled with String objects for each 
%				   object's type in Cheetah's object list.  The type specified will 
%				   have a one-to-one mapping with the cheetahObjectList.
%				   (i.e. cheetahObjects(1) will be of type cheetahTypes(1) ).
%


function [succeeded, cheetahObjects, cheetahTypes] = NlxGetCheetahObjectsAndTypes()  

  MAX_OBJECTS = 5000; %limit on number of objects returned
  MAX_STRING_LENGTH = 100; %limit on length of strings for each returned object
  STRING_PLACEHOLDER = blanks(MAX_STRING_LENGTH);  %ensures enough space is allocated for each AE name
  
  cheetahObjects = 0;
  cheetahTypes = 0;
  succeeded = libisloaded('MatlabNetComClient');
  if succeeded == 0
    disp 'Not Connected'
    return;
  end
  
  str = cell(1,MAX_OBJECTS);
  for index = 1:MAX_OBJECTS
    str{1,index} = STRING_PLACEHOLDER;
  end
  
  cheetahObjectsPointer = libpointer('stringPtrPtr', str);
  cheetahTypesPointer = libpointer('stringPtrPtr', str);
  if succeeded == 1
    [succeeded, cheetahObjects, cheetahTypes, stringLength, numObjects] = calllib('MatlabNetComClient', 'GetCheetahObjectsAndTypes', cheetahObjectsPointer, cheetahTypesPointer, MAX_STRING_LENGTH, MAX_OBJECTS);
    end;
    
    if succeeded == 1
      cheetahObjects = cheetahObjects(1:numObjects);
      cheetahTypes = cheetahTypes(1:numObjects);
    end;
    
end