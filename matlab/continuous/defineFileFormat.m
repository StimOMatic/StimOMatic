%
%defines properties which depend on the raw file version
%some file formats have a fixed sampling rate. if not, the sampling rate is not modified
%
%samplingFreq: the sampling frequency in Hz
%limit: what is the maximal absolute valid value for this file format (bigger/smaller than this is treated as out of range)
%postfix: postfix (e.g. ".Ncs") of the filename
%
%urut/april07
function [samplingFreq, limit, postfix] = defineFileFormat(rawFileVersion, samplingFreq)
if nargin==1
	samplingFreq=25000;
end

    switch ( rawFileVersion )
        case 5 %mat file
            limit = 99999;
            postfix='.mat';
        case 4 %txt file, 24khz
            limit=32768;
            postfix='.bin';
        case 3 %txt file, 24khz
            limit=2000;
            postfix='.txt';
        case 2 %NCS from digital cheetah
            samplingFreq=32556;
            limit=32767;
            postfix='.Ncs';
        case 1 %NCS from analog cheetah
            samplingFreq=25000;
            limit=2046;
            postfix='.Ncs';
        otherwise
            error('invalid file version, unknown sampling rate');
    end
