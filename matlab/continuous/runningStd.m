%
%calculates a running std (fast, with convolution).
%
%
%urut/april04
function runStd = runningStd( rawSignal, k)

coef = ones(1, k) / k;
run_mean_1 = filter(coef, 1, rawSignal.^2);
run_mean_2 = filter(coef, 1, rawSignal).^2;
run_mean_1 = run_mean_1(k : end);
run_mean_2 = run_mean_2(k : end);
runStd = (k / (k - 1)) * (run_mean_1 - run_mean_2);
runStd = sqrt(runStd);