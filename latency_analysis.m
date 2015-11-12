function timeShift=latency_analysis(behavData,neuralData,plotdata)

%% Latency Analysis
%
% We used an alignment algorithm to find a relative temporal offset for the
% neural and behavior data on each trial as follows. Single-trial PETHs
% were generated as described previously.
%
% We examined a 2 s window around the Go signal (-1.5 s pre, to +0.5 s
% post). Spikes from each trial were smoothed with a causal half-Gaussian
% kernel with a full-width SD of 200 ms�that is, the firing rate reported
% at time t averages over spikes in an  200-ms-long window preceding t. The
% resulting smooth traces were sampled every 10 ms.
%
% Then a trial-averaged PETH was generated for each cell. For each trial we
% found the time of the peak of the cross-correlation function between the
% PETH for that trial and the trial-averaged PETH. We then shifted each
% trial accordingly and iterated this process until the variance of the
% trial-averaged PETH converged. Usually this process required fewer than 5
% iterations. The output of this alignment procedure was an offset time for
% each trial, which indicated the relative neural latency for that trial.
% We performed the same alignment procedure on head-velocity data acquired
% with the video-tracking system, which produced a relative behavioral
% latency for each trial. We then tested whether the neural latency was
% correlated with the behavioral latency and whether for the population the
% average correlation was significantly different than zero (Bootstrapped
% confidence intervals of the mean). We also compared, in the same way, the
% neural latencies of pairs of simultaneously recorded neurons.
%
% Population analysis
% To perform population analyses of firing rates, we first normalized the
% perievent time histograms (PETHs) of each cell by computing the mean and
% standard deviation (over time and over trial classes) of the cell�s
% PETHs, and then subtracted that mean and divided by that standard
% deviation. The resulting zscored PETHs were then averaged across cells to
% obtain z-scored population PETHs.
%

switch nargin
    case 2
        plotdata=0;
end

%% recordings
% [pkOffsets]=cell(size(neuralData,1),1);
peth=cell(size(neuralData,1),2);
[sortedSac,sortedTgt]=deal(cell(size(neuralData,1),1));
start=1500;
stop=999;
sigma=200;
preAlign=min([(floor(min(cellfun(@(x) x{1}(1),neuralData(:,4,2)))/10)*10)-3*sigma start]); % keep as much trace as possible, typically ~900
postAlign=min([min(cellfun(@(x) size(x,2),neuralData(:,2,2))-cellfun(@(x) x{1}(1),neuralData(:,4,2)))-3*sigma-1 stop]); % typically 999
plotIdx=round((preAlign-400)/10):round((preAlign+799)/10); %plotting from 400ms before tgt to 800 ms after

for rec=1:size(neuralData,1)
    for trial=1:size(neuralData{rec,2,2},1)
        % trials aligned to sac
        % trialconv = fullgauss_filtconv(neuralData{rec,2}(trial,neuralData{rec,3}-(1000+3*sigma):neuralData{rec,3}+3*sigma+199),sigma,1).*1000;
        % trials aligned to tgt
        trialconv = fullgauss_filtconv(neuralData{rec,2,2}(trial,...
            neuralData{rec, 4,2}{1, trial}(1)-(preAlign+3*sigma):...
            neuralData{rec, 4,2}{1, trial}(1)+3*sigma+postAlign),sigma,1).*1000;
        peth{rec,1}(trial,:) = trialconv(1:10:end);%downsample
    end
    % sort trials by RT
    [sortedRT,sortedRTidx]=sort(behavData{rec, 3});% sort reation times
    peth{rec,1}=peth{rec,1}(sortedRTidx,:);        % sort PETHs accordingly
    % if aligned to saccades:
    %     sortedTgt{rec}=cellfun(@(x) x(1),neuralData{rec, 4}(sortedRTidx))-(neuralData{rec,3}-1000);
    %     sortedSac{rec}=sortedRT+sortedTgt{rec};
    % aligned to tgt:
    sortedSac{rec}=sortedRT+preAlign;
    sortedTgt{rec}=sortedSac{rec}-sortedRT;
    sortedTgt{rec}=round(sortedTgt{rec}/10);%downsample
    sortedSac{rec}=round(sortedSac{rec}/10);%downsample
end

%% plotting rec trials
if plotdata
    if round((preAlign+stop)/10) ~= size(peth{rec,1},2) %round((preAlign+stop)/10) should be = to size(peth{rec,1},2)
        %something wrong
        disp('check error in plotIdx, latency_analysis');
        return;
    end
    figure; hold on;
    imagesc(1:size(peth{rec,1}(:,plotIdx),2),1:size(peth{rec,1}(:,plotIdx),1),peth{rec,1}(:,plotIdx));
    colormap(parula)
    tgth=plot(sortedTgt{rec}-round((preAlign-400)/10),1:size(peth{rec,1},1),'Marker','s','MarkerSize',4,'MarkerEdgeColor','k','MarkerFaceColor',[0.7, 0.9, 1]);
    sach=plot(sortedSac{rec}-round((preAlign-400)/10),1:size(peth{rec,1},1),'Marker','.','MarkerFaceColor',[0, 0.5, 0.1]);
    cbh=colorbar;
    cbh.Label.String = 'Firing rate (Hz)';
    set(gca,'xticklabel',-200:200:800,'TickDir','out','FontSize',10); %'xtick',1:100:max ... xticklabel misses 1st mark for some reason
    xlabel('Time, aligned to target')
    ylabel('Trial # - Trials sorted by reaction time')
    legend([tgth sach],{'Target On', 'Saccade Onset'},'location','Southeast')
    title('Recording sdf - Native alignement')
    axis('tight');
    % close(gcf)
end

%% eye movement plots
ev_peth=cell(size(behavData,1),2);
startEV=200; %(we don't want to include pre-fix eye mvt when shifting)
stopEV=max([behavData{:, 3}])+200;
sigmaEV=20;
preAlignEV=min([(floor(min(cellfun(@(x) x{1}(1),neuralData(:,4,2)))/10)*10)-3*sigmaEV startEV]);
postAlignEV=min([min(cellfun(@(x) size(x,2),neuralData(:,2,2))-cellfun(@(x) x{1}(1),neuralData(:,4,2)))-3*sigmaEV-1 stopEV]);
plotIdxEV=round((preAlignEV-100)/10):round((preAlignEV+min([postAlignEV 799]))/10); %plotting from 100ms before tgt to 800 ms after

for rec=1:size(behavData,1)
    for trial=1:size(behavData{rec,5},1)
        trial_ev = fullgauss_filtconv(behavData{rec,5}(trial,...
            neuralData{rec, 4,2}{1, trial}(1)-(preAlignEV+3*sigmaEV):... % 400ms before tgt
            neuralData{rec, 4,2}{1, trial}(1)+3*sigmaEV+postAlignEV),sigmaEV,1).*1000;    % 800 ms after
        %         trial_ev = behavData{rec,5}(trial,...
        %             neuralData{rec, 4,2}{1, trial}(1)-preAlignEV:... % 400ms before tgt
        %             neuralData{rec, 4,2}{1, trial}(1)+postAlignEV).*1000;    % 800 ms after
        ev_peth{rec,1}(trial,:) = trial_ev(1:10:end);%downsample
    end
    % sort trials by RT
    [~,sortedRTidx]=sort(behavData{rec, 3});        % sort reation times
    ev_peth{rec,1}=ev_peth{rec,1}(sortedRTidx,:);   % sort ev_PETHs accordingly
end
%% plotting eye vel trials
if plotdata
    figure('position',[1950 570 560 420]); hold on;
    imagesc(1:size(ev_peth{rec,1}(:,plotIdxEV),2),1:size(ev_peth{rec,1}(:,plotIdxEV),1),ev_peth{rec,1}(:,plotIdxEV));
    colormap(copper)
    % using preAlign below because startEV ~= start, and thus need preAlignEV+(preAlign-preAlignEV)
    tgth=plot(sortedTgt{rec}-round((preAlign-100)/10),1:size(ev_peth{rec,1},1),'Marker','o','MarkerSize',4,'MarkerEdgeColor','k','MarkerFaceColor',[0.7, 0.9, 1]);
    sach=plot(sortedSac{rec}-round((preAlign-100)/10),1:size(ev_peth{rec,1},1),'Marker','.','MarkerFaceColor',[0, 0.5, 0.1]);
    cbh=colorbar;
    cbh.Label.String = 'Eye velocity (Degree/sec)';
    set(gca,'xticklabel',0:100:800,'TickDir','out','FontSize',10); %'xtick',1:100:max ...
    xlabel('Time, aligned to target')
    ylabel('Trial # - Trials sorted by reaction time')
    legend([tgth sach],{'Target On', 'Saccade Onset'},'location','Southeast')
    title('Neuronal activity - Native alignement')
    axis('tight');
    % close(gcf)
end

%% time-shifting to maximize similarity (and check later if smoothing eyevel over 200ms changes anything)
% Then a trial-averaged PETH was generated for each cell. For each trial we
% found the time of the peak of the cross-correlation function between the
% PETH for that trial and the trial-averaged PETH. We then shifted each
% trial accordingly and iterated this process until the variance of the
% trial-averaged PETH converged. Usually this process required fewer than 5
% iterations. The output of this alignment procedure was an offset time for
% each trial, which indicated the relative neural latency for that trial.

timeShift=cell(size(neuralData,1),2);
trials=cell(size(neuralData,1),1);
% time-shifting recordings
for rec=1:size(neuralData,1)
    trials{rec}=1:size(peth{rec,1},1); %keep track of those removed
    nonNanTrials=~isnan(mean(peth{rec,1},2));
    trials{rec}=trials{rec}(nonNanTrials); % remove nan trials
    indivTrials=peth{rec,1}(nonNanTrials,:);
    peth_av=mean(zscore(indivTrials,0,2));
    pkCc=min([round(size(neuralData{rec,2,2}(nonNanTrials,:),1)/10) 5])*ones(size(neuralData{rec,2,2}(nonNanTrials,:),1),1);
    thld=sum(min([round(size(neuralData{rec,2,2}(nonNanTrials,:),1)/10) 5])*ones(size(neuralData{rec,2,2}(nonNanTrials,:),1),1))/100;
    pkCcsum=sum(pkCc);
    iter=0;
    timeShift{rec,1}=zeros(size(indivTrials,1),1);
    boundShift=zeros(1,2);
    while abs(pkCcsum)>1 && iter<10
        iter= iter + 1;
        for trial=1:size(indivTrials,1)
            % figure;hold on; plot(peth{rec,1}(trial,:));plot(peth{rec,2});
            if pkCc(trial)>0
                pkCc(trial) = min([siglag(zscore(indivTrials(trial,:),0,2),peth_av) pkCc(trial)]); %prevent further drifting
            elseif pkCc(trial)<0
                pkCc(trial) = max([siglag(zscore(indivTrials(trial,:),0,2),peth_av) pkCc(trial)]); % idem
            else
                % well, don't touch it
            end
        end
        %shift trials
        %dampen shift by discounting outliers
        %     shift_bounds=[min(pkCc(abs(pkCc)<2*std(pkCc))) max(pkCc(abs(pkCc)<2*std(pkCc)))];
        %dampening only doesn't work well enough. So take out outliers
        %(unless that empties the trials)
        if sum(abs(pkCc)<2*std(pkCc))>0
            indivTrials=indivTrials(abs(pkCc)<2*std(pkCc),:);trials{rec}=trials{rec}(abs(pkCc)<2*std(pkCc));timeShift{rec,1}=timeShift{rec,1}(abs(pkCc)<2*std(pkCc),:);
            pkCc=pkCc(abs(pkCc)<2*std(pkCc),:);
        end
        % then set shift bounds
        %         shift_bounds=[min([min(pkCc(abs(pkCc)<2*std(pkCc))) 0]) max([max(pkCc(abs(pkCc)<2*std(pkCc))) 0])]; boundShift=boundShift+shift_bounds;
        
        if sum(abs(pkCc))>thld
            shift_bounds=[min([min(pkCc(abs(pkCc)<3*std(pkCc))) 0]) max([max(pkCc(abs(pkCc)<3*std(pkCc))) 0])]; boundShift=boundShift+shift_bounds;
        else
            shift_bounds=[min(pkCc) max(pkCc)]; boundShift=boundShift+shift_bounds;
        end
        
        %pre-allocate
        indivTrials_realigned=zeros(size(indivTrials,1),size(indivTrials,2)+abs(min(shift_bounds))+abs(max(shift_bounds)));
        %     indivTrials_realigned=repmat(median(indivTrials,2),1,size(indivTrials,2)+abs(min(shift_bounds))+abs(max(shift_bounds))).*ones(size(indivTrials,1),size(indivTrials,2)+abs(min(shift_bounds))+abs(max(shift_bounds)));
        for trial=1:size(indivTrials)
            %             if pkCc(trial)<min(shift_bounds)
            %                 pkCc(trial)=min(shift_bounds);
            %             elseif pkCc(trial)>max(shift_bounds)
            %                 pkCc(trial)=max(shift_bounds);
            %             end
            if pkCc(trial)<min(shift_bounds)
                if sum(abs(pkCc))>thld
                    pkCc(trial)=min(shift_bounds);
                else
                    shift_bounds=[pkCc(trial) shift_bounds(2)];
                    boundShift=boundShift+shift_bounds;
                end
            elseif pkCc(trial)>max(shift_bounds)
                if sum(abs(pkCc))>thld
                    pkCc(trial)=max(shift_bounds);
                else
                    shift_bounds=[shift_bounds(1) pkCc(trial)];
                    boundShift=boundShift+shift_bounds;
                end
            end
            timeShift{rec,1}(trial)=timeShift{rec,1}(trial)-pkCc(trial);% positive pkCc: later than the average peak, so pushed back.
            indivTrials_realigned(trial,abs(max(shift_bounds))-pkCc(trial)+1:length(indivTrials(trial,:))+abs(max(shift_bounds))-pkCc(trial))=indivTrials(trial,:);
        end
        indivTrials=indivTrials_realigned; %(:,abs(min(pkCc))+1:size(indivTrials,2)+abs(min(pkCc)));
        peth_av=mean(zscore(indivTrials,0,2));
        pkCcsum=sum(abs(pkCc)); % to prevent execution stops mid-loop
    end
%     figure; hold on;
%     imagesc(1:size(indivTrials(:,plotIdx+boundShift(2)),2),1:size(indivTrials,1),indivTrials(:,plotIdx+boundShift(2)));
%     colormap(parula)
%     tgth=plot(sortedTgt{rec}(trials{rec})-round((preAlign-400)/10)+timeShift{rec,1}',1:size(timeShift{rec,1},1),'Marker','s','MarkerSize',4,'MarkerEdgeColor','k','MarkerFaceColor',[0.7, 0.9, 1]);
%     sach=plot(sortedSac{rec}(trials{rec})-round((preAlign-400)/10)+timeShift{rec,1}',1:size(timeShift{rec,1},1),'Marker','.','MarkerFaceColor',[0, 0.5, 0.1]);
%     cbh=colorbar;
%     cbh.Label.String = 'Firing rate (Hz)';
%     set(gca,'xticklabel',-200:200:800,'TickDir','out','FontSize',10); %'xtick',1:100:max ... xticklabel misses 1st mark for some reason
%     xlabel('Time shifted rasters')
%     ylabel('Trial # - Trials sorted by reaction time')
%     legend([tgth sach],{'Target On', 'Saccade Onset'},'location','Southeast')
%     title('Recording sdf - Native alignement')
%     axis('tight');
%     close(gcf);
end

%% plotting shifted rec trials
if plotdata
    figure; hold on;
    imagesc(1:size(indivTrials(:,plotIdx+boundShift(2)),2),1:size(indivTrials,1),indivTrials(:,plotIdx+boundShift(2)));
    colormap(parula)
    tgth=plot(sortedTgt{rec}(trials{rec})-round((preAlign-400)/10)+timeShift{rec,1}',1:size(timeShift{rec,1},1),'Marker','s','MarkerSize',4,'MarkerEdgeColor','k','MarkerFaceColor',[0.7, 0.9, 1]);
    sach=plot(sortedSac{rec}(trials{rec})-round((preAlign-400)/10)+timeShift{rec,1}',1:size(timeShift{rec,1},1),'Marker','.','MarkerFaceColor',[0, 0.5, 0.1]);
    cbh=colorbar;
    cbh.Label.String = 'Firing rate (Hz)';
    set(gca,'xticklabel',-200:200:800,'TickDir','out','FontSize',10); %'xtick',1:100:max ... xticklabel misses 1st mark for some reason
    xlabel('Time shifted rasters')
    ylabel('Trial # - Trials sorted by reaction time')
    legend([tgth sach],{'Target On', 'Saccade Onset'},'location','Southeast')
    title('Recording sdf - Native alignement')
    axis('tight');
    % close(gcf);
end

%% time-shifting eye vel
% simply align all RTs%
for rec=1:size(neuralData,1)
    timeShift{rec,2}=ceil((mean(sort(behavData{rec, 3}))'-sort(behavData{rec, 3}))'/10);
    %     indivTrials=ev_peth{rec,1};
    %     boundShift=[min(-timeShift{rec,2}) max(-timeShift{rec,2})];
    %     %pre-allocate
    %     indivTrials_realigned=zeros(size(indivTrials,1),size(indivTrials,2)+abs(min(boundShift))+abs(max(boundShift)));
    %     for trial=1:size(indivTrials,1)
    %         indivTrials_realigned(trial,abs(max(boundShift))+timeShift{rec,2}(trial)+1:length(indivTrials(trial,:))+abs(max(boundShift))+timeShift{rec,2}(trial))=indivTrials(trial,:);
    %     end
    %     indivTrials=indivTrials_realigned; %(:,abs(min(pkCc))+1:size(indivTrials,2)+abs(min(pkCc)));
    timeShift{rec,2}=timeShift{rec,2}(trials{rec});
end
if plotdata
    figure('position',[2528 570 560 420]); hold on;
    imagesc(1:size(indivTrials(trials{rec},plotIdxEV+boundShift(2)),2),1:size(indivTrials(trials{rec}),1),indivTrials(trials{rec},plotIdxEV+boundShift(2)));
    colormap(copper)
    tgth=plot(sortedTgt{rec}(trials{rec})-round((preAlign-100)/10)+timeShift{rec,2}',1:size(timeShift{rec,2},1),'Marker','s','MarkerSize',4,'MarkerEdgeColor','k','MarkerFaceColor',[0.7, 0.9, 1]);
    sach=plot(sortedSac{rec}(trials{rec})-round((preAlign-100)/10)+timeShift{rec,2}',1:size(timeShift{rec,2},1),'Marker','.','MarkerFaceColor',[0, 0.5, 0.1]);
    cbh=colorbar;
    cbh.Label.String = 'Firing rate (Hz)';
    set(gca,'xticklabel',0:100:800,'TickDir','out','FontSize',10); %'xtick',1:100:max ... xticklabel misses 1st mark for some reason
    xlabel('Time shifted rasters')
    ylabel('Trial # - Trials sorted by reaction time')
    legend([tgth sach],{'Target On', 'Saccade Onset'},'location','Southeast')
    title('Eye velocity - Native alignement')
    axis('tight');
    %     close(gcf);
end

%% [sanity check]  time-shifting eye vel the same way as recordings
% for rec=1:size(neuralData,1)
%     %     peth_av=mean(zscore(ev_peth{rec,1},0,2));% figure, plot(mean(ev_peth{rec,1}))
%     peth_av=mean(ev_peth{rec,1});
%     indivTrials=ev_peth{rec,1};
%     pkCc=min([round(size(neuralData{rec,2,2},1)/10) 5])*ones(size(neuralData{rec,2,2},1),1);
%     thld=sum(min([round(size(neuralData{rec,2,2},1)/10) 5])*ones(size(neuralData{rec,2,2},1),1))/100;
%     pkCcsum=sum(pkCc);
%     iter=0;
%     trials{rec}=1:size(indivTrials,1); %keep track of those removed
%     timeShift{rec,2}=zeros(size(indivTrials,1),1);
%     boundShift=zeros(1,2);
%     while abs(pkCcsum)>1 && iter<10
%         iter= iter + 1;
%         for trial=1:size(indivTrials,1)
%             %             figure;hold on; plot(indivTrials(trial,:));plot(mean(ev_peth{rec,1}));
%             %             figure;hold on; plot(zscore(indivTrials(trial,:),0,2));plot(peth_av);
%             if pkCc(trial)>0
%                 %                   pkCc(trial) = min([siglag(zscore(indivTrials(trial,:),0,2),peth_av) pkCc(trial)]); %prevent further drifting
%                 %                   pkCc(trial) = min([siglag(indivTrials(trial,:),peth_av) pkCc(trial)]);
%                 pkCc(trial) = siglag(indivTrials(trial,:),peth_av);
%             elseif pkCc(trial)<0
%                 %                   pkCc(trial) = max([siglag(zscore(indivTrials(trial,:),0,2),peth_av) pkCc(trial)]); % idem
%                 %                   pkCc(trial) = max([siglag(indivTrials(trial,:),peth_av) pkCc(trial)]);
%                 pkCc(trial) = siglag(indivTrials(trial,:),peth_av);
%             else
%                 pkCc(trial) = siglag(indivTrials(trial,:),peth_av);
%                 % well, don't touch it
%             end
%         end
%         %shift trials
%         %dampen shift by discounting outliers
%         %     shift_bounds=[min(pkCc(abs(pkCc)<2*std(pkCc))) max(pkCc(abs(pkCc)<2*std(pkCc)))];
%         %dampening only doesn't work well enough. So take out outliers
%         %(unless that empties the trials)
%         %         if sum(abs(pkCc)<2*std(pkCc))>0
%         %             indivTrials=indivTrials(abs(pkCc)<2*std(pkCc),:);trials{rec}=trials{rec}(abs(pkCc)<2*std(pkCc));timeShift{rec,2}=timeShift{rec,2}(abs(pkCc)<2*std(pkCc),:);
%         %             pkCc=pkCc(abs(pkCc)<2*std(pkCc),:);
%         %         end
%         % then set shift bounds
%         if sum(abs(pkCc))>thld
%             shift_bounds=[min([min(pkCc(abs(pkCc)<3*std(pkCc))) 0]) max([max(pkCc(abs(pkCc)<3*std(pkCc))) 0])]; boundShift=boundShift+shift_bounds;
%         else
%             shift_bounds=[min(pkCc) max(pkCc)]; boundShift=boundShift+shift_bounds;
%         end
%         %pre-allocate
%         indivTrials_realigned=zeros(size(indivTrials,1),size(indivTrials,2)+abs(min(shift_bounds))+abs(max(shift_bounds)));
%         %     indivTrials_realigned=repmat(median(indivTrials,2),1,size(indivTrials,2)+abs(min(shift_bounds))+abs(max(shift_bounds))).*ones(size(indivTrials,1),size(indivTrials,2)+abs(min(shift_bounds))+abs(max(shift_bounds)));
%         for trial=1:size(indivTrials)
%             if pkCc(trial)<min(shift_bounds)
%                 if sum(abs(pkCc))>thld
%                     pkCc(trial)=min(shift_bounds);
%                 else
%                     shift_bounds=[pkCc(trial) shift_bounds(2)];
%                     boundShift=boundShift+shift_bounds;
%                 end
%             elseif pkCc(trial)>max(shift_bounds)
%                 if sum(abs(pkCc))>thld
%                     pkCc(trial)=max(shift_bounds);
%                 else
%                     shift_bounds=[shift_bounds(1) pkCc(trial)];
%                     boundShift=boundShift+shift_bounds;
%                 end
%             end
%             timeShift{rec,2}(trial)=timeShift{rec,2}(trial)-pkCc(trial);
%             indivTrials_realigned(trial,abs(max(shift_bounds))-pkCc(trial)+1:length(indivTrials(trial,:))+abs(max(shift_bounds))-pkCc(trial))=indivTrials(trial,:);
%         end
%         indivTrials=indivTrials_realigned; %(:,abs(min(pkCc))+1:size(indivTrials,2)+abs(min(pkCc)));
%         peth_av=mean(zscore(indivTrials,0,2));
%         pkCcsum=sum(abs(pkCc)); % to prevent execution stops mid-loop
%     end
%
%     %% plotting shifted eye vel trials
%     figure; hold on;
%     imagesc(1:size(indivTrials(:,plotIdxEV+boundShift(2)),2),1:size(indivTrials,1),indivTrials(:,plotIdxEV+boundShift(2)));
%     colormap(copper)
%     tgth=plot(sortedTgt{rec}(trials{rec})-round((preAlign-100)/10)+timeShift{rec,2}',1:size(timeShift{rec,2},1),'Marker','s','MarkerSize',4,'MarkerEdgeColor','k','MarkerFaceColor',[0.7, 0.9, 1]);
%     sach=plot(sortedSac{rec}(trials{rec})-round((preAlign-100)/10)+timeShift{rec,2}',1:size(timeShift{rec,2},1),'Marker','.','MarkerFaceColor',[0, 0.5, 0.1]);
%     cbh=colorbar;
%     cbh.Label.String = 'Firing rate (Hz)';
%     set(gca,'xticklabel',0:100:800,'TickDir','out','FontSize',10); %'xtick',1:100:max ... xticklabel misses 1st mark for some reason
%     xlabel('Time shifted rasters')
%     ylabel('Trial # - Trials sorted by reaction time')
%     legend([tgth sach],{'Target On', 'Saccade Onset'},'location','Southeast')
%     title('Eye velocity - Native alignement')
%     axis('tight');
%     close(gcf);
% end



