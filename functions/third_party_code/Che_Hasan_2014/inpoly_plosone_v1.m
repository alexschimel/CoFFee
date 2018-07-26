function inpoly_plosone_v1

% A user interface Matlab program to compute angular response from homogenenous region
% Require two main inputs (1) Proc files processed using CMST MB Process
%                         (matlab format)- all proc files need to be in one single folder
%                         (2) An ESRI/ArcGIS shapefile consists of all polygons that assumed to be homogenenous.
%                         (single file but need to have MORE than 1 polygon)
%
% Note: This program also used a matlab function 'shape_read.m' (Arc_mat toolbox) available from
%       http://www.spatial-econometrics.com/html/download.html) to read ESRI shapefile. Therefore, make sure
%       this function is copied in your matlab path or in the same directory with 'inpoly_plosone_v1.m'.
%       After reading the shapefile, the program use Matlab built-in function
%       'inpolygon.m' to compute angular response from each polygon.
%
% Before start, make sure to put all the Proc files in a single folder (default
% folder created from CMST MB Process would do the job).
%
% Steps:
% 1)  Run this code in Matlab (e.g. by typing 'inpoly_plosone_v1' in the Matlab command window)
%
% 2)  Run inpoly button by clicking '1.Run inpoly'. This function will ask
% for your shapefile and also the folder of your Proc files. The program works
% by testing the first proc file with all the polygons in the shapefile. It then move to the second
% shapefile and test with all polygons again (repeat for all proc files). For each of the proc file, a new
% matlab file will be created called inpoly file (by adding inpoly to the
% previous proc file name) in the proc files folder.
% (NOTE: this process will take some times depends on the size of the Proc
% files and also the number of polygons (e.g. large number of polygons
% especially derived from oversegmentation process can result in longer
% time)
%
% 3)  Combine all the inpoly files by clicking the button '2.Combine
% inpoly'. This function will produce a matlab file named
% 'combined_poly.mat'. It consists of all incidence angles and intensity
% levels that are located inside a polygon. The are two variables
% (cell);(a)combined_angles, and (b) combined_dB. The row number indicate
% polygon sorted according to the shapefile ID number.
%
% 4)  Generate mean Angular response curve for each polygon by clicking the
% button '3.Compute AR'. A file named 'AR_mat.mat' will be produced
% consists of a variable name 'ARmat' which consist of angular backscatter intensity levels (dB).
% Row in ARmat refers to polygon number (ID) and column is the incidence angle starting from 0 deg (e.g.
% column 1=intensity level at 0 deg, column 2=intensity level at 1 deg and
% so on). If the user used matlab command such as  plot(ARmat(1,:)), it
% will plot mean Angular Response curve for the first polygon.
%
% ADDITIONAL FUNCTIONS
% Note: Except for the least square slope, users need to have Matlab Statistics Toolbox to run this process
% (i.e. for mean,skewness and kurtosis)
%
% This interface also provide additional function to compute basic features
% from the angular response curves (e.g. mean, least square slope, skewness
% and kurtosis) for all polygons. Users need to specify the angular domain
% such as from 30 deg to 50 deg incidence angles.
% To do this, first users have to generate a centroid file in ArcMap
% using the same shapefile used before to produce ARmat (use 'Export Feature Attribute to Ascii' in ArcMap).
% Centroid file is a comma separated ASCII file consists of row data according to these header;
% FID,ID,GRIDCODE,X,Y
% FID, ID and GRIDCODE are automatic IDs from ArcMap while X and Y are the
% coordinates of the polygon centroid (Note: the centroids are not use in
% any calculations, but because it was previously used with k-nearest
% neighbour to find nearest classes from the polygon centroid), so the format is not changed and
% maintained.
%
% STEPS to generate angular response derivatives:
% To execute the function, select one of the derivatives (mean,slope, skewness or kurtosis),
% click the button 'Derivatives' and specify the 'start' and 'to' angles.
% Select the centroid file and then the ARmat file. An output file will be saved - ASCII
% file similar to centroid file except the header is changed as follows:
% ID,Gridcode,X,Y,derivatives
% the first FOUR columns are similar as in the centroid file, the last column
% refers to the angular response derivatives (e.g. mean).
%
% Note: For matching the AR derivatives file with polygon (in shapefile), used the ID number
% in this file. ID number in polygon = ID number in AR derivative file = row number in ARmat file.
%
% Rozaimi Che Hasan
% Feb 2014
% emails:rozaimi@ic.utm.my,rozaimi.kl@utm.my,rozaimichehasan@gmail.com


%display the main figure
f1=figure('position',[50 100 700 500],...
    'Name','Homogenenous angular response',...
    'Numbertitle','off');

%display the Run inpoly button
pb_run_inpoly=uicontrol(f1,'style','pushbutton','position',[50,450,100,30],...
    'string','1.Run inpoly','callback',{@pb_run_inpoly_callback},...
    'HorizontalAlignment','left');

%display the Combine inpoly button
pb_combine=uicontrol(f1,'style','pushbutton','position',[50,400,100,30],...
    'string','2.Combine inpoly','callback',{@pb_combine_callback},...
    'HorizontalAlignment','left');

%display the Compute AR button
pb_compAR=uicontrol(f1,'style','pushbutton','position',[50,350,100,30],...
    'string','3.Compute AR','callback',{@pb_compAR_callback},...
    'HorizontalAlignment','left');

%display the Compute derivative button
pb_compDer=uicontrol(f1,'style','pushbutton','position',[260,280,80,30],...
    'string','Derivatives','callback',{@pb_compDer_callback},...
    'HorizontalAlignment','left');

%display and configure all the options buttons for computing derivatives
g = uibuttongroup('Parent',f1,'Position',[0.35 0.55 0.15 0.4]);

u1 = uicontrol('Style','Radiobutton','String','Mean',...
    'Units','normalized','pos',[0 0.8 .7 .2],'parent',g,'Tag','Mean');
u2 = uicontrol('Style','Radiobutton','String','Slope',...
    'Units','normalized','pos',[0 0.6 .7 .2],'parent',g,'Tag','Slope');
u3 = uicontrol('Style','Radiobutton','String','Skewness',...
    'Units','normalized','pos',[0 0.4 .7 .2],'parent',g,'Tag','Skewness');
u4 = uicontrol('Style','Radiobutton','String','Kurtosis',...
    'Units','normalized','pos',[0 0.2 .7 .2],'parent',g,'Tag','Kurtosis');



%%
    function pb_run_inpoly_callback(hObject,eventdata)
        
        % read ESRI shapefile - polygons (e.g. constructed from automatic  spatial
        % segmentation or manual segmentation/delineation)
        
        [FileName,PathName] = uigetfile('*.shp','Select Polygon (shape file)');
        
        if isequal(FileName,0)
            msgbox('Please try again!','Error!','Modal');
            errordlg('Shape file not found','Error');
            return;
        end
        
        cd(PathName);
        
        [~,name,~] = fileparts(FileName);
        
        if license('test','map_toolbox')
            
            % new bit of code to use mapping toolbox to read the shapefile instead
            
            P = shaperead(name);
            c = length(P); % number of polygons
            xpoly = cell(c,1); % preallocating
            ypoly = cell(c,1); % preallocating
            for ii= 1:c
                xpoly{ii,1} = P(ii).X;
                ypoly{ii,1} = P(ii).Y;
            end
            
        else
            
            %%% ORIGINAL CODE BY ROZAIMI
            % use the function shape_read to read ESRI shapefile
            p=shape_read(name);
            
            % get the number of polygon vertices
            n_vert=p.nvertices;
            
            % get the coordinates
            xcoor=p.x;
            ycoor=p.y;
            
            % remove the NaN data
            xcoor(isnan(xcoor))=[];
            ycoor(isnan(ycoor))=[];
            
            % get cumulative sum of the number of vertices
            csum_nv=cumsum(n_vert);
            
            % create new cell for x and y coordinates
            xpoly=[];
            ypoly=[];
            
            %get the size of n_vert
            [~,c]=size(n_vert);
            
            % put the x and y coordinates for the first and last
            xpoly{1,1}=xcoor(1:csum_nv(1),1);
            xpoly{c,1}=xcoor(csum_nv(c-1)+1:csum_nv(c),1);
            ypoly{1,1}=ycoor(1:csum_nv(1),1);
            ypoly{c,1}=ycoor(csum_nv(c-1)+1:csum_nv(c),1);
            
            % get the rest of the x y coordinates
            for i=2:c-1
                xpoly{i,1}=xcoor(csum_nv(i-1)+1:csum_nv(i),1);
                ypoly{i,1}=ycoor(csum_nv(i-1)+1:csum_nv(i),1);
            end
            
        end
        
        % open and search for proc files
        
        % get the directory
        dirname=pwd;
        dirname = uigetdir(dirname,'Select Proc file directory');
        
        if isequal(dirname,0)
            msgbox('Please try again!','Error!','Modal');
            errordlg('Directory not found','Error');
            return;
        end
        
        % only scan for files that have the word 'Proc' (proc files)
        cd(dirname);
        f=dir('*Proc*');
        [r_f,~]=size(f);
        
        h = waitbar(0,'Please wait...');
        
        % loops to search data inside a polygon
        
        % first/outside loop is for loading a proc file
        % to get three variables: incidence angle(ThetCor),Easting (X),Northing (Y)
        % and intensity levels (SSCE->Energy intensity - refer to CMST MB Process).
        % If one to test with SSCI or SSCube,change the varxy.SSCE to varxy.SSCI or
        % varxy.SSCube
        
        for i=1:r_f
            
            waitbar(0,h, ['Processing file ' num2str(i) ' from ' num2str(r_f) '...Please wait...']);
            
            varxy=load(f(i,1).name,'X','Y','ThetaCor','SSCE');
            varxy.X=reshape(varxy.X,[],1);
            varxy.Y=reshape(varxy.Y,[],1);
            varxy.ThetaCor=uint8(varxy.ThetaCor);
            varxy.ThetaCor=reshape(varxy.ThetaCor,[],1);
            varxy.SSCE=single(varxy.SSCE);
            varxy.SSCE=reshape(varxy.SSCE,[],1);
            
            % second/inside loop is to test if the X,Y data are located inside each
            % polygon using the matlab built-in function 'inpolygon'
            
            for j=1:c
                in= inpolygon(varxy.X,varxy.Y,xpoly{j,1},ypoly{j,1}); % Test if data is inside a polygon!!
                %in= inpoly([varxy.X varxy.Y],[xpoly{j,1} ypoly{j,1}]);
                [r_in,~]=find(in==1); % find the index that fell inside
                index_poly{j}=r_in;
                angle{j}=varxy.ThetaCor(r_in,1); % get the angle listed by the index
                dB{j}=varxy.SSCE(r_in,1); % get the intensity listed by the index
                waitbar(j/c,h)
            end
            
            % generate a filename for the inpoly file and save it
            [~,c_name]=size(f(i,1).name);
            
            out_name=['inpoly_' f(i,1).name(:,11:c_name)];
            save(out_name,'index_poly','angle','dB');
            
        end
        close(h);
        
        if dirname~=0
            msgbox('Finished inpoly!','Point in polygon','Modal');
        end
        
    end

%% function to combine all inpoly files into one
    function pb_combine_callback(hObject,eventdata)
        
        %search inpoly file
        dirname = pwd;
        dirname = uigetdir(dirname,'Select Inpoly file directory');
        
        if isequal(dirname,0)
            msgbox('Please try again!','Error!','Modal');
            errordlg('Directory not found','Error');
            return;
        end
        
        cd(dirname);
        f=dir('*inpoly*');
        [r_f,~]=size(f);
        
        s=whos('-file',f(1,1).name);
        c_poly=s(1,1).size(1,2);
        
        combined_angle{c_poly,1}=[];
        combined_dB{c_poly,1}=[];
        allangle{r_f,1}=[];
        alldB{r_f,1}=[];
        
        %combine data from inpoly files
        h = waitbar(0,'Please wait...');
        for i=1:r_f
            waitbar(0,h, ['Processing file ' num2str(i) ' from ' num2str(r_f) '...Please wait...']);
            allangle{i,1}=load(f(i,1).name,'angle');
            alldB{i,1}=load(f(i,1).name,'dB');
            for j=1:c_poly
                x=allangle{i,1}.angle{1,j};
                y=alldB{i,1}.dB{1,j};
                combined_angle{j,1}=[combined_angle{j,1} ; x];
                combined_dB{j,1}=[combined_dB{j,1} ; y];
                waitbar(j/c_poly,h)
            end
        end
        
        close(h);
        
        save('combined_poly','combined_angle','combined_dB');
        
        if dirname~=0
            msgbox('Finished combine!','Combine poly','Modal');
        end
        
    end % end combine inpoly function

%% load combined_poly file and compute AR for each polygon
    function pb_compAR_callback(hObject,evendata)
        
        [FileName,PathName] = uigetfile('*.mat','Select combined poly file');
        
        if isequal(FileName,0)
            msgbox('Please try again!','Error!','Modal');
            errordlg('mat file not found','Error');
            return;
        end
        
        cd(PathName);
        
        [~,name,~] = fileparts(FileName);
        
        %load file
        load(name);
        
        [r,~]=size(combined_angle);
        
        h = waitbar(0,'Please wait...');
        
        for i=1:r
            waitbar(0,h, ['Processing polygon ' num2str(i) ' from ' num2str(r) '...Please wait...']);
            combined_angle{i,1}=combined_angle{i,1}+1;
            min_angle=min(combined_angle{i,1});
            max_angle=max(combined_angle{i,1});
            if ~isempty(max_angle)
                for j=1:max_angle
                    [a,~]=find(combined_angle{i,1}==j);
                    meandB(j)=mean(combined_dB{i,1}(a,:));
                    waitbar(j/double(max_angle),h)
                end
                AR{i,1}=meandB;
            else
                AR{i,1}=[];
            end
        end
        
        clearvars combined_angle combined_dB
        
        %convert AR from cell to mat, pad with NaN
        maxSize = max(cellfun(@numel,AR));
        fcn = @(x) [x nan(1,maxSize-numel(x))];
        ARmat = cellfun(fcn,AR,'UniformOutput',false);
        ARmat = vertcat(ARmat{:});
        
        save('AR_mat','ARmat');
        
        close(h);
        
        if FileName~=0
            msgbox('Finished compute Angular Response!','Create AR','Modal');
        end
        
    end

%%
    function pb_compDer_callback(hObject,evendata) % function to compute AR derivatives
        
        %get the current directory
        s=pwd;
        % select centroid file
        [filename1, pathname1] = uigetfile('*.csv','select Centroid xy file');
        
        if isequal(filename1,0)
            msgbox('Please try again!','Error!','Modal');
            errordlg('Centroid file not found','File Error');
            return;
        end
        
        full_path1=[pathname1 filename1];
        centroid=importdata(full_path1);
        
        % load ARmat file
        
        [FileName,PathName] = uigetfile('*.mat','Select combined AR file');
        
        if isequal(FileName,0)
            msgbox('Please try again!','Error!','Modal');
            errordlg('AR file file not found','Error');
            return;
        end
        
        cd(s);
        
        [pathstr, name, ext] = fileparts(FileName);
        [pathstr1, name1, ext1] = fileparts(filename1);
        
        full_pathAR=[PathName FileName];
        
        data=load(full_pathAR);
        
        % enter angular domain (start and end angles)
        
        prompt = {'From incidence angle:','To incidence angle:'};
        dlg_title = 'Set angular domain';
        num_lines = 1;
        def = {'30','50'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        
        a1=str2double(answer{1,1})+1; %start angle
        a2=str2double(answer{2,1})+1; %stop angle
        
        % compute derivative according to user's selection and export to ascii
        % file
        switch get(get(g,'SelectedObject'),'Tag')
            
            case 'Mean'
                
                meanAR=nanmean(data.ARmat(:,a1:a2),2);
                xypoly=[centroid.data(:,2:5) meanAR];
                [r,~]=size(xypoly);
                outfile=['mean' num2str(a1-1) 'to' num2str(a2-1) name1 '.txt'];
                a=fopen(outfile,'w+');
                fprintf(a,'ID,Gridcode,X,Y,mean\n');
                
                for i=1:r
                    fprintf(a,'%.0f,%.0f,%f,%f,%f\n',xypoly(i,:));
                end
                
                fclose(a);
                msgbox('Finished exporting mean to ASCII file!','Mean','Modal');
                
            case 'Slope'
                
                x=a1-1:a2-1;
                n=length(data.ARmat);
                for i=1:n
                    p(i,:)=polyfit(x,data.ARmat(i,a1:a2),1);
                end
                slopeAR=p(:,1);
                xypoly=[centroid.data(:,2:5) slopeAR];
                [r,~]=size(xypoly);
                outfile=['slope' num2str(a1-1) 'to' num2str(a2-1) name1 '.txt'];
                a=fopen(outfile,'w+');
                fprintf(a,'ID,Gridcode,X,Y,slope\n');
                
                for i=1:r
                    fprintf(a,'%.0f,%.0f,%f,%f,%f\n',xypoly(i,:));
                end
                
                fclose(a);
                msgbox('Finished exporting slope to ASCII file!','Slope','Modal');
                
            case 'Skewness'
                
                skewAR=skewness(data.ARmat(:,a1:a2),0,2);
                xypoly=[centroid.data(:,2:5) skewAR];
                [r,~]=size(xypoly);
                outfile=['skew' num2str(a1-1) 'to' num2str(a2-1) name1 '.txt'];
                a=fopen(outfile,'w+');
                fprintf(a,'ID,Gridcode,X,Y,skewness\n');
                
                for i=1:r
                    fprintf(a,'%.0f,%.0f,%f,%f,%f\n',xypoly(i,:));
                end
                
                fclose(a);
                msgbox('Finished exporting skewness to ASCII file!','Skewness','Modal');
                
            case 'Kurtosis'
                
                kurAR=kurtosis(data.ARmat(:,a1:a2),0,2);
                xypoly=[centroid.data(:,2:5) kurAR];
                [r,~]=size(xypoly);
                outfile=['kur' num2str(a1-1) 'to' num2str(a2-1) name1 '.txt'];
                a=fopen(outfile,'w+');
                fprintf(a,'ID,Gridcode,X,Y,kurtosis\n');
                
                for i=1:r
                    fprintf(a,'%.0f,%.0f,%f,%f,%f\n',xypoly(i,:));
                end
                
                fclose(a);
                msgbox('Finished exporting kurtosis to ASCII file!','Kurtosis','Modal');
                
        end

    end

end
