function control_flag = tag_control_series(data_table)
% function control_flag = tag_control_series(data_table)
%
% Return a logical array with a value for each time series; true if the
% series name contains 'control', false if it doesn't.
%
% Input:
%   - data_table: table with Time in the first column and 2 or more signals
%                 in the columns 2:end
% Output:
%   - control_flag: Logical array

variable_names = data_table.Properties.VariableNames;
n_variables = numel(variable_names) - 1;

control_flag = false(n_variables, 1);

for ivar = 1:n_variables

    control_flag(ivar) = contains(lower(variable_names{ivar+1}), 'control');
    
end

end