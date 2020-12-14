classdef PlanesData
    properties
        nbors
        preplanes % to speed up plane growth
        raw
        refined
        final
        pos
        groups
        loc
        loc2
        gloc
        gloc2
        sizes
        locMean
        locComma
        locFilt
        locFiltList
        locTxt
    end
    methods
        function obj = PlanesData(raw3D)
            try
                %this should separate data into 'Preplanes' to narrow feature
                %lists in growPlanes step
                bins = 0:.8:max(raw3D.Z)+1;
                hcs = histcounts(raw3D.Z,bins);
                centers = find(hcs>prctile(hcs,80));
                count = 0;
                
                %Find Dense regions through Z
                for i = 1:size(centers,2)
                    j = i-count;
                    if j<size(centers,2)
                        if centers(1,j+1) - centers(1,j) == 1
                            centers(1,j) = mean(centers(1,j:j+1));
                            centers(:,j+1) = [];
                            j;
                            count = count+1;
                        end
                    end
                end
                
                for i = 1:size(centers,2)-1
                    ceSpaces(1,i) = mean(centers(1,i:i+1));
                end
                
                %Establish Pre-Plane Limits
                for i = 1:size(centers,2)
                    if i == 1
                        ppRegions(1,1) = 0;
                        ppRegions(1,2) = ceSpaces(1,1) + .5;
                    elseif i == size(centers,2)
                        ppRegions(i,1) = ceSpaces(1,i-1) - .5;
                        ppRegions(i,2) = (max(raw3D.Z)+1)/.8;
                    else
                        ppRegions(i,1) = ceSpaces(1,i-1) - .5;
                        ppRegions(i,2) = ceSpaces(1,i) + .5;
                    end
                end
                ppRegions = ppRegions*.8; %convert index back to microns
                
                %Populate Pre-Planes
                index = 1:size(raw3D.Z)';
                for i = 1:size(ppRegions,1)
                    temp = index(raw3D.Z>ppRegions(i,1) & raw3D.Z<ppRegions(i,2))';
                    obj.preplanes(1:size(temp),i) = temp;
                end
            catch
                
                obj.preplanes(:,1) = 1:max(size(raw3D.Z))';
            end
        end
        %%
        
        function obj = nborsPlanes(obj,raw3D,radXY,radZ)
            
            clear obj.nbors
            disp('Finding Neighbors')
            for i = 1:size(raw3D.X,1)
                %iteratitvely finds all markers in close proximity to
                %marker(i) using input search window
                topX = raw3D.X(i)+ radXY;
                botX = raw3D.X(i)- radXY;
                topY = raw3D.Y(i)+ radXY;
                botY = raw3D.Y(i)- radXY;
                topZ = raw3D.Z(i)+ radZ;
                botZ = raw3D.Z(i)- radZ;
                temp = find(raw3D.X(:)<topX & raw3D.X(:)>botX & raw3D.Y(:)<topY & raw3D.Y(:)>botY& raw3D.Z(:)<topZ & raw3D.Z(:)>botZ);
                obj.nbors(i,1:size(temp)) = temp;
                
            end
            
        end
        
        
        %%
        function obj = nborsPlanesF(obj,raw3D,radXY,radZ)
            %%
            clear obj.nbors
            disp('Finding Neighbors')
            for j = 1:size(obj.preplanes,2)
                pptemp = obj.preplanes(1:nnz(obj.preplanes(:,j)),j);
                dTemp = raw3D.r(pptemp,1:3);
                for i = 1:size(pptemp,1)
                    
                    clear temp
                    %iteratitvely finds all markers in close proximity to
                    %marker(i) using input search window
                    topX = dTemp(i,1)+ radXY;
                    botX = dTemp(i,1)- radXY;
                    topY = dTemp(i,2)+ radXY;
                    botY = dTemp(i,2)- radXY;
                    topZ = dTemp(i,3)+ radZ;
                    botZ = dTemp(i,3)- radZ;
                    
                    temp = pptemp(dTemp(:,1)<topX & dTemp(:,1)>botX & dTemp(:,2)<topY & dTemp(:,2)>botY& dTemp(:,3)<topZ & dTemp(:,3)>botZ);
                    
                    if size(obj.nbors,1) < pptemp(i)
                        obj.nbors(pptemp(i),1:size(temp)) = temp;
                    elseif nnz(obj.nbors(pptemp(i),:)) == 0
                        obj.nbors(pptemp(i),1:size(temp)) = temp;
                    else
                        tempidx = nnz(obj.nbors(pptemp(i),:))+1;
                        tempidx2 = (tempidx+size(temp,1))-1;
                        obj.nbors(pptemp(i),tempidx:tempidx2) = temp;
                    end
                    
                end
            end
            
        end
        
        
        
        function obj = growPlanes(obj,raw3D)
            clear planesTemp
            disp('Growing Planes')
            
            working = 1;
            searched = 1:raw3D.l;
            ss =size(searched,1);
            %start at first row in preplane
            planes = obj.nbors(1,1:nnz(obj.nbors(1,:)))';
            progressbar('Growing Planes')
            j=1; %designates starting at plane 1
            progressbar(1/raw3D.l)
            progress = size(planes,1);
            while working == 1
                newlist = intersect(searched,planes);
                if size(newlist,2)>0
                    for i = 1:size(newlist,1)
                        if i == 1
                            clear new
                            searched((newlist(i,1)==searched)) = [];
                            new(:,1) = obj.nbors(newlist(i,1),1:nnz(obj.nbors(newlist(i,1),:)));
                            
                        else
                            clear newtemp
                            searched((newlist(i,1)==searched)) = [];
                            newtemp(:,1) = obj.nbors(newlist(i,1),1:nnz(obj.nbors(newlist(i,1),:)));
                            new = cat(1,new,newtemp);
                        end
                    end
                end
                sBefore = size(planes,1);
                planes = unique(cat(1,planes,new));
                sAfter = size(planes,1);
                if sBefore == sAfter
                    progress = progress + size(planes,1);
                    progressbar(progress/raw3D.l)
                    %if j == 1
                    obj.raw(1:size(planes,1),j) = planes(:,1);
                    j=j+1;
                    %                     elseif size(intersect(obj.raw(:,j-1),planes),2)>0
                    %                             intersect(obj.raw(:,j-1),planes)
                    %                             planes = unique(cat(1,planes(:,1),obj.raw(:,j-1)));
                    %                             obj.raw(1:size(planes,1),j-1) = planes(:,1);
                    %                     else
                    %                     obj.raw(1:size(planes,1),j) = planes(:,1);
                    %                     j=j+1;
                    %                     end
                    
                    clear planes
                    %check to see if any unmatched objects exist
                    
                    finCheck = find(searched,1,'first');
                    if size(finCheck,2) ==0
                        working = 0;
                    else
                        k = searched(find(searched,1,'first'));
                        planes(:,1) = obj.nbors(k,1:nnz(obj.nbors(k,:)));
                        
                    end
                end
                
            end
            obj.raw = unique(obj.raw','rows')';
        end
        
        
        function [obj,r] = cleanPlanes(obj,raw3D)
            
            %The goal of this function is to remove objects that are
            %members of planes with very few members. This should clean
            %outputs be removing "noise" or unreliable detections.
            r = raw3D.r;
            count =1;
            obj.final = obj.raw;                                    
            [planesLoc2,planesLoc,planesGroups,planeSizes] = updateSizes(obj,r);            
            %-----------------
            %Remove planes with less than 50 members
            for j = 1:size(obj.final,2)
                if nnz(obj.final(:,j)) < 50
                    for k = 1:nnz(obj.raw(:,j))
                        r(obj.final(k,j),:) =[]; %clear row in r
                        obj.final((obj.final>obj.final(k,j))) = obj.final((obj.final>obj.final(k,j)))-1; % repeat for obj.final
                    end
                    remove(count) = j;
                    count = count +1;
                end
            end
            
            try
                obj.final(:,remove) = [];
            catch
            end
            
            
            [planesLoc2,planesLoc,planesGroups,planeSizes] = updateSizes(obj,r);
            [obj,r] = trimPlanes(obj,planesGroups,planeSizes,planesLoc2,r);           
            [obj] = sortPlanes(obj,r);
            [planesLoc2,planesLoc,planesGroups,planeSizes] = updateSizes(obj,r);
            [obj,r] = trimPlanes(obj,planesGroups,planeSizes,planesLoc2,r);
            [obj] = sortPlanes(obj,r);
            [planesLoc2,planesLoc,planesGroups,planeSizes] = updateSizes(obj,r);
            
            
            for i =1:size(obj.final,2)
                for j =1:size(obj.final,2)
                    if j > i
                        dupes = intersect(obj.final(:,i),obj.final(:,j));
                        if nnz(dupes) > 0
                            for k = 1:size(dupes,1)
                                currentZ = r(dupes(k),3);
                                planej = planesLoc(1,j);
                                planei = planesLoc(1,i);
                                distj = abs(planej-currentZ);                                
                                disti = abs(planei-currentZ);
                                if distj<disti
                                    tempidx = find(obj.final(:,i)==dupes(k),1,'first');
                                    obj.final(tempidx:end-1,i) = obj.final(tempidx+1:end,i);
                                else                                    
                                    tempidx = find(obj.final(:,j)==dupes(k),1,'first');
                                    obj.final(tempidx:end-1,j) = obj.final(tempidx+1:end,j);
                                end
                            end
                        end
                    end
                end
            end
            
            
            %----------------
            
            obj.groups = planesGroups;
            obj.loc = planesLoc;
            obj.gloc = planesLoc2;
            obj.sizes = planeSizes;
            
            
            
            function [obj] = sortPlanes(obj,r)
                for m = 1:size(obj.final,2)
                    clear temp
                    temp = obj.final(1:nnz(obj.final(:,m)),m);
                    planesLocIni(m) = mean(mean(r(temp,3)));
                end
                [~,order] = sort(planesLocIni,'descend');
                clear temp
                temp = obj.final;
                for m = 1:size(order(:))
                    obj.final(1:end,m) = temp(1:end,order(m));
                end
            end
            %%
            function [obj,r] = trimPlanes(obj,pgs,ps,pl2,r)              
                ct = 1;
                clear rem
                %-----------------
                %Remove top or bottom plane if there are too few members                
                for m = 1:size(pgs,1)
                    clear planeIdx
                    planeIdx = pgs(m,1:nnz(pgs(m,:))); % assign group member planes a number
                    %if current grouped planes are (either the top or bottom
                    %plane, and have less than half the members of the largest
                    %planes), delete all members.
                    % ALSO, delete entire plane if it is too low (could have
                    % inaccurate centroids due to clipping)
                    if  ((nnz(obj.final(:,planeIdx))<(max(ps))/2) && (pl2(m) == max(pl2) || pl2(m) == min(pl2))) || pl2(m)<1.5
                        for n = 1:nnz(planeIdx)
                            for o = 1:nnz(obj.final(:,planeIdx(n)))
                                r(obj.final(o,planeIdx(n)),:) =[];
                                obj.final((obj.final>obj.final(o,planeIdx(n)))) = obj.final((obj.final>obj.final(o,planeIdx(n))))-1;
                                rem(ct) = planeIdx(n);
                                ct = ct +1;
                            end
                        end
                    end
                end
                
                % If objects have been marked for removal, remove them
                try
                    obj.final(:,rem) = [];
                catch
                end
                
                %remove duplicates
                for i2 =1:size(obj.final,2)
                    tempPlane = unique(obj.final(1:nnz(obj.final(:,i2)),i2));
                    obj.final(:,i2) = 0;
                    obj.final(1:size(tempPlane,1),i2) = tempPlane;
                end
            end
            %%
            function [planesLoc2,planesLoc,planesGroups,planeSizes] = updateSizes(obj,r)
                
                for m = 1:size(obj.final,2)
                    planeSizes(m) = nnz(obj.final(:,m));
                end
                
                %Determine average plane location
                %size(obj.raw,2)
                for m = 1:size(obj.final,2)
                    clear temp
                    temp = obj.final(1:nnz(obj.final(:,m)),m);
                    planesLoc(m) = mean(mean(r(temp,3)));
                end
                
                %Group planes which are close in Z, and which do not
                %overlap in XY. These groups should alleviate issues
                %occuring due to cells spanning two or more sections of
                %patterned regions.
                clear planesGroups
                for m = 1:size(planesLoc,2)
                    meanLoc(m,1) = mean(r(obj.final(1:nnz(obj.final(:,m)),m),1));
                    meanLoc(m,2) = mean(r(obj.final(1:nnz(obj.final(:,m)),m),2));                    
                    differences(m,:) = planesLoc - planesLoc(1,m);                    
                    %planesGroups(m,1:size(find(abs(differences)<2),2)) = find(abs(differences)<3)';
                end
                zCheck = abs(differences)<5;
                for m = 1:size(planesLoc,2)
                    for n = 1:size(planesLoc,2)
                        if m~=n
                            [~,dist] = dsearchn([r(obj.final(1:nnz(obj.final(:,m)),m),1), r(obj.final(1:nnz(obj.final(:,m)),m),2)],meanLoc(n,1:2));
                            [~,dist2] = dsearchn([r(obj.final(1:nnz(obj.final(:,n)),n),1), r(obj.final(1:nnz(obj.final(:,n)),n),2)],meanLoc(m,1:2));
                            if dist>4 && dist2>4
                                xyCheck(m,n) = 1;
                            else
                                xyCheck(m,n) = 0;
                            end
                        end    
                    end
                end
                
                xyCheck = xyCheck>0;
                fCheck = zCheck & xyCheck;
                usedPlanes = ones(size(planesLoc));
                pgCount = 0;
                for m =1:size(fCheck,1)
                    if usedPlanes(m)>0
                        pgCount = pgCount+1;
                        planesGroups(pgCount,1) = m;
                        fCheck(:,m) = 0; %clear column 'm' so it is no matched again later
                        matchIdx = find(fCheck(m,:)>0);
                        n=1;
                        while size(matchIdx,2)>0                        
                            planesGroups(pgCount,n+1) = matchIdx(1); %add plane to group
                            n = n+1; %increase plane group member count
                            fCheck(m,:) = fCheck(m,:).*fCheck(matchIdx(1),:); %apply the added plane's restrictions to the origin plane
                            fCheck(matchIdx(1),:) = 0; %clear rows of added planes so they are not double counted
                            fCheck(:,matchIdx(1)) = 0; %clear cols of added planes so they are not double counted
                            usedPlanes(matchIdx(1)) = 0;
                            matchIdx = find(fCheck(m,:)>0);
                        end
                    end
                end                
                planesGroups = unique(planesGroups,'rows');
                
                for m = 1:size(planesGroups)
                    planesGroupsSize(m,1) = nnz(planesGroups(m,:));
                end
                %find planes that are members of more than 1 group and remove
                %them from the smaller groups
                Ui = unique(planesGroups(:));
                U = Ui(1<histc(planesGroups(:),unique(planesGroups(:))));
                for m = 1:size(U,1)
                    clear U2 bigGroup
                    for n = 1:size(planesGroups,1)
                        U2(n) = ismember(U(m),planesGroups(n,:));
                    end
                    if nnz(U2)>0
                        bigGroup = max(planesGroupsSize(U2));
                        
                        for n = 1:size(planesGroups,1)
                            if planesGroupsSize(n,1) ~= bigGroup && U2(n) == 1
                                clear tempGroup
                                tempGroup = planesGroups(n,1:planesGroupsSize(n,1));
                                tempGroup(tempGroup==U(m)) = [];
                                tempGroup(1,planesGroupsSize(n,1)) = 0;
                                planesGroups(n,1:planesGroupsSize(n,1)) = tempGroup(1,1:planesGroupsSize(n,1));
                            end
                        end
                    end
                end
                
                %Repeat average Z plane location with merged planes
                for m = 1:size(planesGroups,1)
                    planesLoc2(m) = mean(planesLoc(planesGroups(m,1:nnz(planesGroups(m,:)))));
                end
            end
        end
        %%
        function ViewAllPlanes(obj,raw3D)
            % View all detected planes
            figure
            hold on
            for i = 1:size(obj.raw,2)
                scatter3(raw3D.X(obj.raw(1:nnz(obj.raw(:,i)),i)),raw3D.Y(obj.raw(1:nnz(obj.raw(:,i)),i)),raw3D.Z(obj.raw(1:nnz(obj.raw(:,i)),i)))
            end
            hold off
        end
        %%
        function ViewFilteredPlanes(obj,r)
            %View Filtered Planes
            pf = figure;
            hold on
            for i = 1:size(obj.final,2)
                scatter3(r.X(obj.final(1:nnz(obj.final(:,i)),i)),r.Y(obj.final(1:nnz(obj.final(:,i)),i)),r.Z(obj.final(1:nnz(obj.final(:,i)),i)))
             end
%             bcolor = 'white';
%             fcolor = 'black';
            
            bcolor = 'black';
            fcolor = 'white';
            AxisFontSize = 12;
            LegendFontSize = 14;
            xt = 'X \mum';% input('enter the xaxis label','s');
            yt = 'Y \mum'; %input('enter the yaxis label','s');
            zt = 'Z \mum';
            label{1} = xlabel(xt);
            label{2} = ylabel(yt);
            label{3} = zlabel(zt);
            set(gca,'YMinorTick','on','color',bcolor)
            ytickformat('%.1f')
            le{1} = 'plane 1'; %input('enter the legend','s');
            le{2} = 'plane 2';
            ColorScheme(fcolor,bcolor,label,le,AxisFontSize,LegendFontSize,1,[0 0])
            %errorbar(meanDisplacements(1,1:3),meanDisplacements(2,1:3),'.','color',[0 0 0],'MarkerSize',1)
            axis([0 max(r.X) 0 max(r.Y) 0 ceil(max(r.Z))])
            legend off
            hold off
            view(45,15)
            savefile = 'XZ Indent.tif';
            export_fig(pf,savefile,'-native');
        end
    end
end