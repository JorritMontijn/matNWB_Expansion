function sSub = ExpandNWB(objSub,strLocation)
	%ExpandNWB Recursively converts NWB data to native MATLAB data formats
	%   sNWB = ExpandNWB(objNWB)
	%
	%Input: NWB data format
	%
	%Output: MATLAB structure
	%
	%Tested on Allen Brain Ecephys NWB data set, v2.2.2
	
	%track missing classes
	global cellMissingClasses;
	
	%location
	if ~exist('strLocation','var') || isempty(strLocation)
		cellMissingClasses = {};
		strLocation = '';
		fprintf('Starting NWB expansion at %s\n',getTime);
	end
	
	
	%set special types
	cellLoadDataTypes = {'types.hdmf_common.VectorIndex',...
		'types.hdmf_common.VectorData',...
		'types.hdmf_common.ElementIdentifiers'};
	
	cellOverloadCellInput = {'cell'};
	
	cellSetDataTypes = {'types.untyped.Set',...
		'types.core.ProcessingModule'};
	
	cellDataContainers = {'types.untyped.DataStub'};
	
	cellProcModule = {'types.core.ProcessingModule'};
	
	cellDataPointers = {'types.untyped.SoftLink'};
	
	cellNormalDataTypes = {'single',...
		'double',...
		'int8',...
		'int16',...
		'int32',...
		'int64',...
		'uint8',...
		'uint16',...
		'uint32',...
		'uint64',...
		'logical',...
		'char',...
		'string',...
		'datetime',...
		'table',...
		'types.ndx_aibs_ecephys.EcephysProbe',...
		'types.ndx_aibs_ecephys.EcephysElectrodeGroup',...
		'types.untyped.ObjectView',...
		'function_handle'};
	
	cellExpandDataTypes = {'NwbFile',...
		'types.hdmf_common.DynamicTable',...
		'types.ndx_aibs_ecephys.EcephysSpecimen',...
		'types.core.TimeSeries',...
		'types.core.TimeIntervals',...
		'types.core.Units',...
		'struct',...
		'cell'};
	
	%determine data type
	fprintf('%s\n',strLocation);
	sSub = [];
	strClass = class(objSub);
	if contains(strClass,cellOverloadCellInput)
		sSub = cell(size(objSub));
		for intCell=1:numel(objSub)
			sSub{intCell} = ExpandNWB(objSub{intCell},strLocation);
		end
	elseif contains(strClass,cellExpandDataTypes)
		cellFields = fieldnames(objSub);
		for intField=1:numel(cellFields)
			sSub.(cellFields{intField}) = ExpandNWB(objSub.(cellFields{intField}),strcat(strLocation,'.',cellFields{intField}));
		end
	elseif contains(strClass,cellLoadDataTypes)
		try
			sSub = objSub.data.load;
		catch
			sSub = objSub.data;
		end
	elseif contains(strClass,cellSetDataTypes)
		%get fields
		cellKeys = objSub.keys;
		cellVals = objSub.values;
		
		%loop through fields
		for intKey=1:numel(cellKeys)
			if contains(class(cellVals{intKey}),cellProcModule)
				class(cellVals{intKey}) 
				cellSubKeys = objSub.get(cellKeys{intKey}).nwbdatainterface.keys;
				for intSubKey=1:numel(cellSubKeys)
					sSub.(cellKeys{intKey}).(cellSubKeys{intSubKey}) = ExpandNWB(objSub.get(cellKeys{intKey}).nwbdatainterface.get(cellSubKeys{intSubKey}),strcat(strLocation,'.',(cellKeys{intKey})'.',(cellSubKeys{intSubKey})));
				end
			elseif contains(class(cellVals{intKey}),cellSetDataTypes)
				if cellVals{intKey}.dynamictable.Count == 0 && cellVals{intKey}.nwbdatainterface.Count == 1
					sSub.(cellKeys{intKey}) = cellVals{intKey}.nwbdatainterface.values{1}.load;
				elseif cellVals{intKey}.dynamictable.Count == 1 && cellVals{intKey}.nwbdatainterface.Count == 0
					sSub.(cellKeys{intKey}) = cellVals{intKey}.dynamictable.values{1}.load;
				else
					sSub.(cellKeys{intKey}).data = ExpandNWB(cellVals{intKey}.nwbdatainterface,strcat(strLocation,'.',(cellKeys{intKey})));
					sSub.(cellKeys{intKey}).table = ExpandNWB(cellVals{intKey}.dynamictable,strcat(strLocation,'.',(cellKeys{intKey})));
				end
			else
				sSub.(cellKeys{intKey}) = ExpandNWB(cellVals{intKey},strcat(strLocation,'.',(cellKeys{intKey})));
			end
		end
	elseif contains(strClass,cellNormalDataTypes)
		sSub = objSub;
	elseif contains(strClass,cellDataContainers)
		sSub = objSub.load;
	elseif contains(strClass,cellDataPointers) 
		sSub.Comment = 'Duplicate data; see soft-link';
		sSub.SoftLink = objSub.path;
		
	else
		%try various expansions
		cellKeys = [];
		try
			cellKeys = fieldnames(objSub);
		end
		try
			cellKeys = keys(objSub);
		end
		if ~isempty(cellKeys)
			for intKey=1:numel(cellKeys)
				varSub = [];
				try
					varSub = ExpandNWB(objSub.(cellKeys{intKey}));
				catch
					varSub = ExpandNWB(objSub.get(cellKeys{intKey}));
				end
				if ~isempty(varSub)
					sSub.(cellKeys{intKey}) = varSub;
				else
					sSub.(cellKeys{intKey}).CLASS = strClass;
					sSub.(cellKeys{intKey}).VALUE = objSub;
					fprintf('>>> Found unknown class: %s\n',strClass);
					cellMissingClasses(end+1) = {strClass};
				end
			end
		else
			sSub.VALUE = objSub;
			sSub.CLASS = strClass;
			fprintf('>>> Found unknown class: %s\n',strClass);
			cellMissingClasses(end+1) = {strClass};
		end
	end
	
	%display missing classes
	if isempty(strLocation)
		strMissingClasses = '';
		for intC=1:numel(cellMissingClasses)
			strMissingClasses = strcat(strMissingClasses,cellMissingClasses{intC},';');
		end
		fprintf('%d missing classes; %s Expansion finished at %s\n',numel(cellMissingClasses),strMissingClasses,getTime);
	end
end
function strTime = getTime()
	vecTime = fix(clock);
	strTime = sprintf('%02d:%02d:%02d',vecTime(4:6));
end

