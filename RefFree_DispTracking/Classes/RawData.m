classdef RawData
    properties
        pSpaceXY
        pSpaceZ
        data
        dataKey 
    end
        methods
            function obj = RawData(metadata,autoChk)
            [obj.dataKey] = InputSelector(metadata,autoChk);    
            end
            
            function obj = rawPx2um(obj)
                obj.data(:,2:3) = obj.dataKey(9,1) * obj.data(:,2:3);
                obj.data(:,9) = obj.dataKey(10,1) * obj.data(:,4);
            end
        end
end