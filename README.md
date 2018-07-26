# CoFFee
## Alex's Matlab toolbox for Multibeam Sonar data processing

To allow Matlab to find the data and functions composing this toolbox, you need to add the toolbox's folder and subfolders to Matlab's path.

1. Ensure the current folder is this toolbox root folder (the one containing this README.md file).

2. Run the following command to add the toolbox folder and its subolders to Matlab's path:

`addpath(genpath(cd));`

The toolbox is now ready to use for the current MATLAB session.

3. If you want to save this for all future MATLAB sessions, you can save the path by running the command:

`savepath;`

NOTE: Doing so will alter your path for future sessions. The MATLAB commands `restoredefaultpath;` followed by `savepath;` can be used to restore MATLAB's default path although you will then lose any modifications made to the default path prior to adding the path to this toolbox.
