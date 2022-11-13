function thr = grey_threshold(h,verbose, ws)
if nargin == 1
    verbose = false;
    ws = 51; % window size
end
po = 3; % polynomial order
y = sgolayfilt(h,po,ws);
y = sgolayfilt(y,po,ws);
[pks,locs] = findpeaks(y,"MinPeakHeight",0.3);
[~,peak1] = max(pks);

[~,valleys] = findpeaks(-y, "MinPeakHeight",-pks(peak1));
vs = valleys(valleys<locs(peak1));
if ~isempty(vs)
    thr = vs(end);
else
    thr = 60; % default
end

if verbose % show the histogram and the threshold
    figure
    subplot(121), hold on
    plot(y,'k-')
    plot(locs,pks,'ko')
    plot(locs(peak1),y(locs(peak1)),'ro')
    title('Histogram')

    subplot(122),hold on
    plot(-y)
    plot(valleys,-y(valleys),'bo')
    plot(thr,-y(thr),'b.','MarkerSize',15)
    plot(thr,-y(thr),'ro','MarkerSize',14)
    title(sprintf('Threshold = %i',thr))
end

