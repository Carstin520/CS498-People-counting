clear; clc;
close all;

for envName = {'20211007'}
    %% Target files
    infolderName = ['../OriginalData/' envName{:} '/cs498'];
    outfolderName = ['../PostProcessData/' envName{:}];
    
    if ~exist(outfolderName, 'dir')
        mkdir(outfolderName);
    end

    for targetIndex = 1:1
        targetName = ['adc_data_' num2str(targetIndex)];

        logFile = [infolderName '/' targetName '_LogFile.txt'];
        if ~isfile(logFile)
            continue;
        end
        
        disp(logFile);

        dataFile = [infolderName '/' targetName '.bin'];
        paraFile = [infolderName '/parameters.m'];

        %% Load parameters
        if ~isfile(paraFile)
            error('Parameter file does not exist!');
        else
            run(paraFile);
        end

        %% Compute variables
        % Range resolution
        Lc = c / Fc;
        adcSampleTime = nSamples / Fs;
        bw = adcSampleTime * slope;
        F1 = Fc + slope * adcStartTime;
        F2 = F1 + bw;
        dRes = c / (2*bw);
        dMax = dRes * nSamples;
        % Velocity resolution
        Tc = idleTime + rampEndTime;
        Tf = nChirps * Tc;
        vMax = Lc / (4*Tc);
        vRes = Lc / (2*Tf);
        % Angle resolution
        dRx = Lc / 2;
        phaseFFT = 256;

        % resolution
        dRange = 0:dRes:dMax-dRes;
        vRange = -vMax:vRes:vMax-vRes;
        vNzRange = vRange(vRange ~= 0);
        phaseRes = 2*pi / phaseFFT;
        phaseRange = -pi:phaseRes:pi-phaseRes;
        thetaRange = asin(phaseRange/(2*pi) * Lc/dRx);

        %% Raw data process
        if ~isfile(postFile)
            %%
            fprintf('Post process start.\n'); tic;
            if isfile(dataFile)
                adcData = readDCA1000(dataFile);
            else
                dataFilePre = [infolderName '/' targetName];
                if ~isfile([dataFilePre '_0.bin'])
                    dataFilePre = [infolderName '/' targetName '_Raw'];
                end
                
                adcData = [];
                fileIndex = 0;
                dataFileTemp = [dataFilePre '_' num2str(fileIndex) '.bin'];
                while isfile(dataFileTemp)
                    adcDataTemp = readDCA1000(dataFileTemp);
                    adcData = [adcData adcDataTemp];
                    fileIndex = fileIndex + 1;
                    dataFileTemp = [infolderName '/' targetName '_' num2str(fileIndex) '.bin'];
                end
                clear('fileIndex', 'dataFileTemp', 'adcDataTemp');
            end
            adcData = reshape(adcData.'', nSamples, nTx, nChirps, [], nLanes);
            if nTx == 3
                adcData(:, 3, :, :, :) = [];
                nTx = 2;
            end
            

        %     writerObj = VideoWriter([folderName '/' targetName '.mp4'], 'MPEG-4');
        %     writerObj.FrameRate = 1/Tp;
        %     open(writerObj);
        %     for iFrame = 0:nFrames-1
        %         t1.String = [num2str(Tp*iFrame) ' sec'];
        %         h1.CData = vMxvdb(:,:,iFrame+1);
        %         h2.CData = vZMxvdb(:,:,iFrame+1);
        %         h3.CData = vNzMxvdb(:,:,iFrame+1);
        %         writeVideo(writerObj, getframe(gcf));
        %     end
        %     close(writerObj);
        end
    end
end