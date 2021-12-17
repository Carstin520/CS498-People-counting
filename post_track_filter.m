% clear; clc;
close all;

%% Target files
infolderName = '../OriginalData/csl462';
outfolderName = '../PostProcessData/csl462';

% targetName = 'adc_data_0';
dataFile = [infolderName '/' targetName '.bin'];
paraFile = [outfolderName '/parameters.mat'];
postFile = [outfolderName '/' targetName '_post.mat'];
trackFile = [outfolderName '/' targetName '_track.mat'];

if isfile(postFile)
    fprintf('Load post process file.\n');
    load(postFile);
    phaseFFT = size(vMxv, 2);
    phaseRes = 2*pi / phaseFFT;
    phaseRange = -pi:phaseRes:pi-phaseRes;
    thetaRange = asin(phaseRange/(2*pi) * Lc/dRx);
else
    fprintf('Post process not done!');
    exit;
end

%% Radar heatmap process
% rotate
thetaRange2 = pi/2 - thetaRange;
% to dB
vMxvdb = mag2db(abs(vMxv));
vZMxvdb = mag2db(abs(vZMxv));
vNzMxvdb = mag2db(abs(vNzMxv));

if ~isfile(trackFile)
    %% multi object tracker
    fprintf('Tracking start.\n'); tic;
    % detect
    dShow = 7;
    detections = cell(1, nFrames);
    objectDetections = cell(1, nFrames);
    for iFrame = 0:nFrames-1
        vNzMxvFrame = vNzMxvdb(:,:,iFrame+1);
        [mxv, idx] = max(vNzMxvFrame, [], 2);
        [pks, locs] = findpeaks(mxv(dRange<dShow), ...
            'SortStr', 'descend', ...
            'MinPeakProminence', 12);
        
        locsR = dRange(locs);
        locsT = thetaRange2(idx(locs));
        [locsX, locsY] = pol2cart(locsT, locsR);
        detections{iFrame+1} = [locsX; locsY];
        objectDetections{iFrame+1} = cell(numel(pks), 1);
        for i = 1:numel(pks)
            objectDetections{iFrame+1}{i} = objectDetection( ...
                Tp * iFrame, detections{iFrame+1}(:,i));
        end
    end
    
    % track
    tracker = multiObjectTracker(...
        'FilterInitializationFcn', @initDemoFilter, ...
        'AssignmentThreshold', 8, ...
        'MaxNumSensors', 1, ...
        'ConfirmationThreshold', [20 25], ...
        'DeletionThreshold', 40);
    positions = cell(1, nFrames);
    for iFrame = 0:nFrames-1
        confirmedTracks = updateTracks(tracker, objectDetections{iFrame+1}, Tp * iFrame);
        positions{iFrame+1} = zeros(2, numel(confirmedTracks));
        for i = 1:numel(confirmedTracks)
            positions{iFrame+1}(:,i) = [confirmedTracks(i).State(1); confirmedTracks(i).State(3)];
        end
    end
    fprintf('Tracking end. '); toc;
    
    clear('objectDetections', 'vNzMxvFrame', ...
        'mxv', 'idx', 'pks', 'locs', ...
        'locsR', 'locsT', 'locsX', 'locsY', ...
        'tracker', 'i');
    save(trackFile, 'detections', 'positions');
else
    fprintf('Load track file.\n');
    load(trackFile);
end