function [data, dataCtrl, control] = split_control_columns(full_table)

control_flag = tag_control_series(full_table);

if any(control_flag)

    control = full_table(:,[true; control_flag]);
    data = full_table(:,[true; ~control_flag]);

    dataCtrl = subtract_control(data, control);

else

    data = full_table;
    control = table();
    dataCtrl = data;

end

end