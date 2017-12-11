%%Bar graph of mean distances 

set(0,'defaultfigurecolor',[1 1 1])
dist = figure;
AxisFontSize = 28;
AxisTitleFontSize = 28;
LegendFontSize = 20;
bar(meanDists(1,1:3),'FaceColor',[.6 .6 .6])
hold on
errorbar(meanDists(1,1:3),meanDists(2,1:3),'.','color',[0 0 0],'MarkerSize',1)
set(gca,'fontsize',AxisFontSize)
xt = 'Dimension';% input('enter the xaxis label','s');
yt = {'Average'; 'Center-to-Center'; 'Distance (\mum)'}; %input('enter the yaxis label','s');
tt = 'Line-Profile Displacements';%input('enter the title','s');
le = 'Shear'; %input('enter the legend','s');
le2 = 'Normal';
le3 = 'Border';
xl = xlabel(xt);
yl = ylabel(yt); 
%tl = title(tt);
set(gca,'xticklabel', {'X' 'Y' 'Z'})
set(xl, 'fontweight','bold','fontsize',AxisTitleFontSize); 
set(yl,'fontweight','bold','fontsize',AxisTitleFontSize);
%leg = legend([p1 p2 p3],le,le2,le3,'location','northwest');
%leg.FontSize = LegendFontSize;
%set(tl,'fontweight','bold','fontsize',title_font_size)
ylim([0 6])
filePath=cd;
title = '\Center-to-Center Spacing';
savefile = [filePath title];
export_fig(dist,savefile,'-native');