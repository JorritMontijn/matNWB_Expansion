function sSub = PruneStruct(objSub,strLocation)
	%PruneStruct Removes all empty entries from input structure
	%   structPruned = PruneStruct(struct)
	%
	%Input: MATLAB structure
	%
	%Output: Pruned MATLAB structure
	
	%location
	if ~exist('strLocation','var') || isempty(strLocation)
		strLocation = '';
	end
	
	%set special types
	cellOverloadCellInput = {'cell'};
	
	cellExpandDataTypes = {'struct',...
		'cell'};
	
	%determine data type
	fprintf('%s\n',strLocation);
	sSub = [];
	strClass = class(objSub);
	if contains(strClass,cellOverloadCellInput)
		vecNonEmpty = flat(find(~cellfun(@isempty,objSub)))';
		sSub = cell(size(vecNonEmpty));
		for intCell=1:numel(vecNonEmpty)
			sSub{intCell} = PruneStruct(objSub{vecNonEmpty(intCell)},strLocation);
		end
	elseif contains(strClass,cellExpandDataTypes)
		cellFields = fieldnames(objSub);
		vecNonEmpty = flat(find(~structfun(@isempty,objSub)))';
		for intField=1:numel(vecNonEmpty)
			strField = cellFields{vecNonEmpty(intField)};
			sSub.(strField) = PruneStruct(objSub.(strField),strcat(strLocation,'.',cellFields{intField}));
		end
	else
		sSub = objSub;
	end
end