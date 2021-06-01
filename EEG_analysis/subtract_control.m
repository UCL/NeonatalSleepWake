function dataCtrl_table = subtract_control(data_table, control_table, varargin)

params = inputParser;
addOptional(params, 'control_id', 1, @(x) isnumeric(x) && x >= 0);
addOptional(params, 'minval', 0.0, @(x) isnumeric(x));
addOptional(params, 'normalize', true, @(x) islogical(x));
parse(params, varargin{:});

variable_names = data_table.Properties.VariableNames;
n_variables = numel(variable_names) - 1;

dataCtrl_table = data_table(:,1);

for ivar = 1:n_variables
    
    varname = variable_names{ivar+1};
    new_varname = [varname 'Ctrl'];
    ctrlname = control_table.Properties.VariableNames{params.Results.control_id+1};
    
    if params.Results.normalize
        norm_factor = mean(data_table.(varname)) / mean(control_table.(ctrlname));
    else
        norm_factor = 1;
    end
    
    dataCtrl_table.(new_varname) = data_table.(varname) - control_table.(ctrlname) * norm_factor;
    dataCtrl_table.(new_varname) = max(params.Results.minval, dataCtrl_table.(new_varname));
end

end