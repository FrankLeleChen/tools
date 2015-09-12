function colorrasth=Raster_sdf_colorevents(rasters,event_times,start,stop,alignmtt,conv_sigma,conditions)
global directory slash;

if start < 1
    start = 1;
end
if stop > size(rasters,2)
    stop = size(rasters,2);
end

%     if ~conditions.evtsort %% that's for plotting multiple rasters / sdfs, with all
%     rasters pooled together in chronological order
%        cut_chrasters=zeros(length([alignedata.trials]),plotstart+plotstop+1);
%        %listing relevant trials in a continuous series with other rasters
%        chronoidx=ismember(sort([alignedata.trials]),alignedata(rastnum).trials);
%         cut_chrasters=zeros(size(rasters,1),stop-start-6*conv_sigma+1);
%         chronoidx=1:size(rasters,1);
%     end

colorrasth=figure('Name',conditions.recname,'NumberTitle','off');
colormap lines;
cmap = colormap(gcf);
rastnum=1;
hrastplot(rastnum)=subplot(2,1,1,'Layer','top', ...
    'XTick',[],'YTick',[],'XColor','white','YColor','white');
try
    %reducing spacing between rasters
    if rastnum>1 && ~conditions.evtsort
        rastpos=get(gca,'position');
        rastpos(2)=rastpos(2)+rastpos(4)*0.5;
        set(gca,'position',rastpos);
    end
    
    % build event times "masks" over rasters
    % event order is 'cue' 'eyemvt' 'fix' 'rew' 'fail'
    rast_mask=zeros(size(rasters,1),size(rasters,2),4);
    %visual cue mask
    rast_mask(:,:,1)=cell2mat(rot90(cellfun(@(x) [zeros(1,x(1,1)-1) ones(1,x(1,2)-x(1,1)) zeros(1,size(rasters,2)+1-x(1,2))], event_times,'UniformOutput',false)));
    %veye movement mask
    rast_mask(:,:,2)=cell2mat(rot90(cellfun(@(x) [zeros(1,x(2,1)-1) ones(1,x(2,2)-x(2,1)) zeros(1,size(rasters,2)+1-x(2,2))], event_times,'UniformOutput',false)));
    %fixation mask
    rast_mask(:,:,3)=cell2mat(rot90(cellfun(@(x) [zeros(1,x(3,1)-1) ones(1,x(3,2)-x(3,1)) zeros(1,size(rasters,2)+1-x(3,2))], event_times,'UniformOutput',false)));
    %reward mask
    rast_mask(:,:,4)=cell2mat(rot90(cellfun(@(x) [zeros(1,x(4,1)-1) ones(1,x(4,2)-x(4,1)) zeros(1,size(rasters,2)+1-x(4,2))], event_times,'UniformOutput',false)));
    
    if conditions.evtsort
        % sorting rasters according event time
        evtstarts=cellfun(@(x) x(conditions.evtsort,1), event_times,'UniformOutput',true);
        [~,sortidx]=sort(evtstarts,'descend');
        rasters=rasters(sortidx,:);
        rast_mask=rast_mask(sortidx,:,:);
    end
    
    hold on
    
    cut_rasters = rasters(:,start+3*conv_sigma:stop-3*conv_sigma); % Isolate rasters of interest
    rast_mask = rast_mask(:,start+3*conv_sigma:stop-3*conv_sigma,:);
    isnantrial = isnan(sum(cut_rasters,2)); % Identify nantrials
    cut_rasters(isnan(cut_rasters)) = 0; % take nans out so they don't get plotted
    % if ~conditions.evtsort
    %     cut_chrasters(chronoidx,:)=cut_rasters;
    %     [indy, indx] = ind2sub(size(cut_chrasters),find(cut_chrasters)); %find row and column coordinates of spikes
    % else
    %     [indy, indx] = ind2sub(size(cut_rasters),find(cut_rasters)); %find row and column coordinates of spikes
    %     [indy, indx, indz] = ind2sub(size(rast_mask),find(rast_mask));
    
    %"masked" rasters record event times for every trial
    % event order is 'cue' 'eyemvt' 'fix' 'rew' 'fail'
    [indy{1}, indx{1}] = ind2sub(size(cut_rasters),find(cut_rasters & rast_mask(:,:,1)));
    [indy{2}, indx{2}] = ind2sub(size(cut_rasters),find(cut_rasters & rast_mask(:,:,2)));
    [indy{3}, indx{3}] = ind2sub(size(cut_rasters),find(cut_rasters & rast_mask(:,:,3)));
    [indy{4}, indx{4}] = ind2sub(size(cut_rasters),find(cut_rasters & rast_mask(:,:,4)));
    % regular (not "masked") rasters
    [indy{5}, indx{5}] = ind2sub(size(cut_rasters),find(cut_rasters));
    % end
    
    if isempty(rasters)
        close(gcf);
        disp([conditions.recname ', alignment' conditions.alignment ' : empty rasters']);
    else
        if(size(rasters,1) == 1)
            rastlines{1}=plot([indx{5};indx{5}],[indy{5};indy{5}+1],'color',cmap(1,:),'LineStyle','-'); % plot rasters
        else
            rastlines{1}=plot([indx{5}';indx{5}'],[indy{5}';indy{5}'+1],'color','k','LineStyle','-'); % plot "raw" rasters
            
            %plot bi-color rasters pre/post event
            % get raster indx referenced to alignement time, for standard two-color plot
            % evtlimidx={indx{5}<=alignmtt-(start+3*conv_sigma),indx{5}>alignmtt-(start+3*conv_sigma)};
            %     plot([indx{5}(evtlimidx{1})';indx{5}(evtlimidx{1})'],...
            %         [indy{5}(evtlimidx{1})';indy{5}(evtlimidx{1})'+1],'color',cmap(1,:),'LineStyle','-'); % plot < align event rasters
            %     plot([indx{5}(evtlimidx{2})';indx{5}(evtlimidx{2})'],...
            %         [indy{5}(evtlimidx{2})';indy{5}(evtlimidx{2})'+1],'color',cmap(4,:),'LineStyle','-'); % plot > align event rasters
            
            % plot "masked" rasters
            rastlines{2}=plot([indx{1}';indx{1}'],[indy{1}';indy{1}'+1],'color',cmap(1,:),'LineStyle','-'); % plot cue rasters
            rastlines{3}=plot([indx{2}';indx{2}'],[indy{2}';indy{2}'+1],'color',cmap(2,:),'LineStyle','-'); % plot eye mvt rasters
            rastlines{4}=plot([indx{3}';indx{3}'],[indy{3}';indy{3}'+1],'color',cmap(4,:),'LineStyle','-'); % plot fix rasters
            rastlines{5}=plot([indx{4}';indx{4}'],[indy{4}';indy{4}'+1],'color',cmap(7,:),'LineStyle','-'); % plot rew rasters
        end
        % keep plot position
        rastplotpos=hrastplot.Position;
        rastlineprop=cellfun(@(x) x(1), rastlines(~cellfun('isempty',rastlines)),'UniformOutput',false);
        rasterevtlegtxt={'raw','cue','eye mvt','fix','rew'};rasterevtlegtxt=rasterevtlegtxt(~cellfun('isempty',rastlines));
        [rastlegh,rastlegicons]=legend([rastlineprop{:}],rasterevtlegtxt,'Location','northoutside');%,'FontSize',8,'FontWeight','bold',
        %refine legend
        % Style
        [rastlegicons([5,7,9,11]).LineStyle]=deal([':']);
        [rastlegicons([5,7,9,11]).LineWidth]=deal(3);
        [rastlegicons([5,7,9,11]).LineWidth]=deal(3);
        % Position
        set(rastlegh,'Orientation','horizontal');
        rastlegicons(2).Position=(rastlegicons(2).Position)-[0.25 0 0];
        rastlegicons(4).Position=(rastlegicons(4).Position)-[0.25 0 0];
        rastlegicons(1).Position(2)=rastlegicons(2).Position(2);
        rastlegicons(5).YData=[rastlegicons(2).Position(2) rastlegicons(2).Position(2)];
        rastlegicons(3).Position(2)=rastlegicons(4).Position(2);
        rastlegicons(9).YData=[rastlegicons(4).Position(2) rastlegicons(4).Position(2)];
        [rastlegicons([5,7,9,11]).XData]=deal([rastlegicons(5).XData(end)/2-0.05 rastlegicons(5).XData(end)/2]);
        [rastlegicons([5,9]).XData]=deal([rastlegicons(5).XData(1)+0.25 rastlegicons(5).XData(2)+0.25]);
        % [rastlegicons([2,4]).Position]=deal(rasterevtlegtxtcol{1:4});
        % Color
        rasterevtlegtxtcol=cellfun(@(x) x.Color, rastlineprop(~cellfun('isempty',rastlines)),'UniformOutput',false);
        [rastlegicons([1:4]).Color]=deal(rasterevtlegtxtcol{1:4});
        rastlegh.Box='off';
        set(hrastplot,'Position',rastplotpos);
        set(gca,'xlim',[1 length(start+3*conv_sigma:stop-3*conv_sigma)]);
        % axis(gca, 'off');
        
        % drawing the alignment bar
        if ~isempty(rasters)
            alignbarh=patch([repmat((alignmtt-(start+3*conv_sigma))-2,1,2) repmat((alignmtt-(start+3*conv_sigma))+2,1,2)], ...
                [[0 max(get(gca,'YLim'))] fliplr([0 max(get(gca,'YLim'))])], ...
                [0 0 0 0],[1 1 0],'EdgeColor','none','FaceAlpha',0.5);
            %     uistack(alignbarh,top);
        end
        
        %% Plot sdf
        sdfplot=subplot(2,1,2,'Layer','top');
        %sdfh = axes('Position', [.15 .65 .2 .2], 'Layer','top');
        title(['Cluster ' conditions.clus ', ' conditions.recname ', ' conditions.trialtype...
            ' trial aligned to ' conditions.alignment],'FontName','calibri','FontSize',11,'Interpreter','none');
        hold on;
        if size(rasters(~isnantrial,:),1)<5 %if less than 5 good trials
            %useless plotting this
            sumall=NaN;
        else
            sumall=sum(rasters(~isnantrial,start:stop));
        end
        [sdf, ~, rastsem]=conv_raster(rasters,conv_sigma,start,stop); %(sumall,conv_sigma,causker)./length(find(~isnantrial)).*1000;
        
        if size(rasters(~isnantrial,:),1)>=5
            %    plot confidence intervals
            patch([1:length(sdf),fliplr(1:length(sdf))],[sdf-rastsem,fliplr(sdf+rastsem)],cmap(rastnum,:),'EdgeColor','none','FaceAlpha',0.1);
            %plot sdf
            plot(sdf,'Color',cmap(rastnum,:),'LineWidth',1.8);
        end
        
        set(gca,'XTick',[0:100:(stop-start-6*conv_sigma)]);
        set(gca,'XTickLabel',-(alignmtt-(start+3*conv_sigma)):100:stop-(alignmtt+3*conv_sigma));
        axis(gca,'tight'); box off;
        set(gca,'Color','white','TickDir','out','FontName','Cambria','FontSize',10);
        hxlabel=xlabel(gca,'Time (ms)','FontName','Cambria','FontSize',10);
        hylabel=ylabel(gca,'Firing rate (spikes/s)','FontName','Cambria','FontSize',10);
        %     legh=legend(lineh(1:3),{'No Stop Signal','Stop Signal: Cancelled', 'Stop Signal: Non Cancelled'});
        %     set(legh,'Interpreter','none','Location','SouthWest','Box','off','LineWidth',1.5,'FontName','Cambria','FontSize',9); % Interpreter prevents underscores turning character into subscript
        %     title(['Cluster' num2str(clusnum) ' Aligned to saccade'],'FontName','Cambria','FontSize',15);
        
        % set(gca,'Color','white','TickDir','out','FontName','calibri','FontSize',8); %'YAxisLocation','rigth'
        % hylabel=ylabel(gca,'Firing rate (spikes/s)','FontName','calibri','FontSize',8);
        
        
        if ~isempty(rasters)
            currylim=get(gca,'YLim');
            % drawing the alignment bar
            patch([repmat((alignmtt-(start+3*conv_sigma))-2,1,2) repmat((alignmtt-(start+3*conv_sigma))+2,1,2)], ...
                [[0 currylim(2)] fliplr([0 currylim(2)])], ...
                [0 0 0 0],[1 0 0],'EdgeColor','none','FaceAlpha',0.5);
        end
        
        if conditions.save
            %print plots
            plotdir=[cell2mat(regexp(directory,'\w\:\\\w+(?=\\\w+)','match'))... %get dir root
                slash 'Analysis\Countermanding\indiv_files' slash];
            plotfilename=['Clus' conditions.clus '_' conditions.recname...
                '_' conditions.trialtype '_' conditions.alignment];
            print(gcf, '-dpng', '-noui', '-opengl','-r600',...
                [plotdir plotfilename]);
%             close(gcf);
        end
    end
catch
    close(colorrasth);
end
end
