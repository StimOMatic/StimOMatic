%
%downsample a raw data trace. P/Q factors are calculated by designDownsampleFactors.m
%
%warning: this creates edge effects. the first and last few datapoints will
%be inaccurate and should be discarded. see the help of resample.m for
%details.
%
%urut/feb08
function downsampled = downsampleRawTrace( dataRaw, P, Q )
downsampled = resample(dataRaw, P, Q);
