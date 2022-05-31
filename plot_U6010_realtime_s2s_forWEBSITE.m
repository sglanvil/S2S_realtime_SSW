clear; clc; close all;

cd /glade/work/sglanvil/CCR/S2S/scripts 

for ilag=1:10
    lastMonday=dateshift(datetime('now'),'dayofweek','monday','previous')-7*(ilag-1);
    lastMonday
    dateInS2Sformat=lower(datestr(lastMonday,'ddmmmyyyy'));
    if strcmp(dateInS2Sformat,'27dec2021')
        display('SKIP: this forecast was never created')
        continue
    end
    dateReadable=datestr(lastMonday,'yyyy-mm-dd');
    yearReadable=dateReadable(1:4);
    printName=sprintf('/glade/work/sglanvil/CCR/S2S/figures/U6010/%s/FINAL_U6010_realtime_%s',yearReadable,dateReadable);

    date0_FPIT=datetime(dateInS2Sformat,'InputFormat','ddMMMyyyy');
    Nyear=year(date0_FPIT);
    Nmonth=month(date0_FPIT);
    date1_FPIT=datetime(date)-1; % most recent FPIT file will be yesterday
    dates_FPIT=string(datestr(date0_FPIT:date1_FPIT,'yyyymmdd'));
    for idate=1:length(dates_FPIT)
        fil=sprintf('/glade/scratch/ssfcst/FPIT/FPIT_final_%s.nc',dates_FPIT{idate});
        disp(fil)
        U=ncread(fil,'U');
        lon=ncread(fil,'lon');
        lat=ncread(fil,'lat');
        lev=ncread(fil,'lev');
        Uzm=squeeze(nanmean(nanmean(U,1),4)); % zonal mean & time mean
        U6010_FPIT(idate)=squeeze(nanmean(Uzm(lat>59 & lat<61,lev<11 & lev>9,:),1));
    end

    modelName={'70Lwaccm6','cesm2cam6v2'};
    modelColor={'blue','red'};

    clear SSWcountSave
    figure; hold on;
    for imodel=1:2
        SSWcount=0;
        clear U6010save
        dateStrPrevious='01jan1000'; % just a random old date that doesn't exist
        for imem=0:20
            fil=sprintf('/glade/scratch/ssfcst/%s/U/%.4d/%.2d/U_%s_%s00z_d01_d46_m%.2d.nc',...
                modelName{imodel},Nyear,Nmonth,modelName{imodel},dateInS2Sformat,imem);
            disp(fil)
            dateStr=extractBetween(fil,[modelName{imodel},'_'],"00z_d01_d46");
            starttime=datetime(dateStr,'InputFormat','ddMMMyyyy');
            time=starttime:starttime+45;
            lon=ncread(fil,'lon');
            lat=ncread(fil,'lat');
            lev=ncread(fil,'lev_p');
            U=ncread(fil,'U');
            Uzm=squeeze(nanmean(U,1));
            U6010=squeeze(nanmean(Uzm(lat>59 & lat<61,lev<11 & lev>9,:),1));
            if strcmp(dateStr{1},dateStrPrevious)==1
                x=x+1;
                avg=(avg*(x-1)+U6010)/x;
            else
                avg=U6010;
                x=1;
            end
            dateStrPrevious=dateStr{1};
            U6010save(:,imem+1)=U6010;
            if nanmin(U6010)<0
                SSWcount=SSWcount+1;
                plot(time,U6010,'color',modelColor{imodel},'linestyle','--');
            end
        end
        SSWcountSave(imodel)=SSWcount;
        U6010maxLine=nanmax(U6010save,[],2);
        U6010minLine=nanmin(U6010save,[],2);
        fill([time fliplr(time)],[U6010minLine' fliplr(U6010maxLine')],...
            modelColor{imodel},'facealpha',0.15,'linestyle','none');
        plot(time,avg,'color',modelColor{imodel},'linewidth',4); % plot the ensemble mean
    end
    plot(datetime(dates_FPIT,'InputFormat','yyyyMMdd'),U6010_FPIT,'color','k','linewidth',4);
    plot([time(1) time(end)],[0 0],'color',[.5 .5 .5],'linewidth',2,'linestyle','--');

    text(time(3),-15,'CESM2(WACCM6)','color','blue','fontweight','bold','fontsize',12);
    text(time(7),-10,join([num2str(SSWcountSave(1)) ' SSW']),'color','blue','fontweight','bold','fontsize',12);
    text(time(20),-15,'CESM2(CAM6)' ,'color','red','fontweight','bold','fontsize',12);
    text(time(23),-10,join([num2str(SSWcountSave(2)) ' SSW']),'color','red','fontweight','bold','fontsize',12);
    text(time(35),-15,'Observations','color','black','fontweight','bold','fontsize',12);
    ylabel('m/s');
    title('Zonal Mean Zonal Wind (60N, 10hPa)');
    [logo, ~, logoAlpha]=imread('NCAR-contemp-logo-blue.png'); % location:/glade/work/sglanvil/CCR/S2S/scripts/
    image([1 16],[77 72],logo,'AlphaData',1)
    xtickangle(45);
    xlim([time(1) time(end)]);
    ylim([-20 80]);
    set(gca,'fontsize',12);
    set(gca,'box','on');
    
%     % control the image pixel size by manipulating the paper size and number of dots per inch
%     output_size = [800 600]; %Size in pixels
%     resolution = 100; %Resolution in DPI
%     set(gcf,'paperunits','inches','paperposition',[0 0 output_size/resolution]);
%     % use 100 DPI
%     print(printName,'-r100','-dpng');

    print(printName,'-r300','-dpng');
    
    clear; clc; close all;
end



