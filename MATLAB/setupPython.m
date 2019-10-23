% A very naive script to prepare MATLAB so that it calls Python from
% the correct environment.
% Normally this will needs to be run once, as the settings will remain in
% effect the next times MATLAB is loaded.

% TODO Check that this is what we have named the environment
environmentName = 'NeonatalSleepWake';

% See what interpreter is currently active
[version, executable, loaded] = pyversion;

% Assume that Anaconda is installed under the home directory...
% The environment variable giving the home directory, and the name of the
% Python executable both vary depending on the operating system.
if ispc  % For Windows
    homeDir = getenv('USERPROFILE');
    python = 'pythonw.exe'; %TODO Check if this should be python.exe instead
else
    homeDir = getenv('HOME');
    python = fullfile('bin', 'python');
end
% Construct the location of the Python executable we want
% TODO Check if in Windows the exe is under Scripts instead of bin
targetPython = fullfile(homeDir, 'anaconda3', 'envs', environmentName, ...
    python);
fprintf('Will use executable at: %s\n', targetPython);

pyversion(targetPython);

% If the interpreter was already loaded, the change won't take effect until
%  MATLAB is restarted.
if loaded
    fprintf('Restart MATLAB for the changes to take effect.');
end