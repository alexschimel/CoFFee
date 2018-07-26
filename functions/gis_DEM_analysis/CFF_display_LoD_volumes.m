function CFF_display_LoD_volumes(factors,fixedLOD,variableLOD,displayStruct)
% CFF_display_LoD_volumes(factors,fixedLODvolume,variableLoDvolume,displayStruct)
%
% DESCRIPTION
%
% disaply and or print, LoD volumes (fixed and variable) on same graph
%
% USE
%
% ...
%
% PROCESSING SUMMARY
%
% - ...
% - ...
% - ...
%
% INPUT VARIABLES
%
% - varagin
%
% OUTPUT VARIABLES
%
% - NA
%
% RESEARCH NOTES
%
% ...
%
% NEW FEATURES
%
% YYYY-MM-DD: second version.
% YYYY-MM-DD: first version.
%
% EXAMPLE
%
%%%
% Alex Schimel, Deakin University
%%%


% get the data
fixedVolumeNetChange = [fixedLOD(:).volumeNetChange];
fixedVolumeEroded = [fixedLOD(:).volumeEroded];
fixedVolumeDeposited = [fixedLOD(:).volumeDeposited];
fixedUncertaintyVolumeEroded = [fixedLOD(:).uncertaintyVolumeEroded_sum];
fixedUncertaintyVolumeDeposited = [fixedLOD(:).uncertaintyVolumeDeposited_sum];

variableVolumeNetChange = [variableLOD(:).volumeNetChange];
variableVolumeEroded = [variableLOD(:).volumeEroded];
variableVolumeDeposited = [variableLOD(:).volumeDeposited];
variableUncertaintyVolumeEroded = [variableLOD(:).uncertaintyVolumeEroded_sum];
variableUncertaintyVolumeDeposited = [variableLOD(:).uncertaintyVolumeDeposited_sum];

% display deposition
if displayStruct(1).display
    
    figure
    
    errorbar(factors - 0.05, fixedVolumeDeposited, fixedUncertaintyVolumeDeposited ,'Color',[0.4 0.4 0.4],'LineWidth',1,'Marker','*','MarkerSize',4,'LineStyle','none')
    hold on
    errorbar(factors + 0.05, variableVolumeDeposited, variableUncertaintyVolumeDeposited ,'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker','o','MarkerSize',4,'LineStyle','none')
    
    vmaxDeposited = max([ max(fixedVolumeDeposited+fixedUncertaintyVolumeDeposited) max(variableVolumeDeposited+variableUncertaintyVolumeDeposited) ]);
    vminDeposited = min([ min(fixedVolumeDeposited-fixedUncertaintyVolumeDeposited) min(variableVolumeDeposited-variableUncertaintyVolumeDeposited) ]);
    
    grid on
    xlabel('threshold factor k')
    ylabel('volume deposited (m^3)')
    ylim([vminDeposited vmaxDeposited])
    xlim([min(factors)-0.5 max(factors)+0.5])
    legend('fixed LoD','variable LoD')
    
    % print
    if displayStruct(1).print
        
        % adjust font size first
        set(gca, 'FontSize',displayStruct(1).fontSize)
        
        % then the window position and size
        set(gcf, 'Units', 'centimeters');
        pos = get(gcf, 'Position');
        set(gcf, 'Position', [pos(1) pos(2) displayStruct(1).size]);
        
        % make the print position and size the same
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'centimeters');
        set(gcf, 'PaperPosition', [0.1 0.1 displayStruct(1).size]);
        
        % get nice tick labels
        CFF_nice_easting_northing(5)
        
        % finally print
        print(['-d' displayStruct(1).format],['-r' displayStruct(1).resolution],[displayStruct(1).filename '.' displayStruct(1).format])
        
    end
    
end



% display derosion
if displayStruct(2).display
    
    figure
    
    errorbar(factors - 0.05, fixedVolumeEroded, fixedUncertaintyVolumeEroded ,'Color',[0.4 0.4 0.4],'LineWidth',1,'Marker','*','MarkerSize',4,'LineStyle','none')
    hold on
    errorbar(factors + 0.05, variableVolumeEroded, variableUncertaintyVolumeEroded ,'Color',[0.7 0.7 0.7],'LineWidth',1,'Marker','o','MarkerSize',4,'LineStyle','none')
    
    vmaxEroded = max([ max(fixedVolumeEroded+fixedUncertaintyVolumeEroded) max(variableVolumeEroded+variableUncertaintyVolumeEroded) ]);
    vminEroded = min([ min(fixedVolumeEroded-fixedUncertaintyVolumeEroded) min(variableVolumeEroded-variableUncertaintyVolumeEroded) ]);
    
    grid on
    xlabel('threshold factor k')
    ylabel('volume eroded (m^3)')
    ylim([vminEroded vmaxEroded])
    xlim([min(factors)-0.5 max(factors)+0.5])
    legend('fixed LoD','variable LoD','location','southeast')
    
    % print
    if displayStruct(2).print
        
        % adjust font size first
        set(gca, 'FontSize',displayStruct(2).fontSize)
        
        % then the window position and size
        set(gcf, 'Units', 'centimeters');
        pos = get(gcf, 'Position');
        set(gcf, 'Position', [pos(1) pos(2) displayStruct(2).size]);
        
        % make the print position and size the same
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'centimeters');
        set(gcf, 'PaperPosition', [0.1 0.1 displayStruct(2).size]);
        
        % get nice tick labels
        CFF_nice_easting_northing(5)
        
        % finally print
        print(['-d' displayStruct(2).format],['-r' displayStruct(2).resolution],[displayStruct(2).filename '.' displayStruct(2).format])
        
    end
    
end

