%
function [dataFlat] = dataBufferFramed_retrieve_all( dataFramedObj  )

dataFlat = dataFramedObj.data(:, dataFramedObj.frameOrder);
dataFlat=dataFlat(:);
dataFlat=dataFlat';