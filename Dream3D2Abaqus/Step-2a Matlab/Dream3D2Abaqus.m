function Dream3D2Abaqus(filename,matID,noDepvar)



  
%% Input
% filename - name of the material parameter file 

% Set material ID:
% - enter "0" to use Dream3D number output
% - enter "1-10" material ID number if user defined!


% Number of state variables
% Number of outputs
% noDepvar




% The name of the excel file:
% inputfile_info.xlsx
    
% --------------------------
% Convert the Dream3D outputs to Abaqus input file
% Designed for input structure of DBF_code - A UMAT subroutine for crystal
% plasticity

% Jan. 29th, 2022
% written by
% Eralp Demir
% eralp.demir@eng.ox.ac.uk
% --------------------------
    
tic  

format shortg

fid = fopen([filename '.vox'],'r+');

rawData = textscan(fid, '%f %f %f %f %f %f %d %d','delimiter',' ');
fclose(fid);

% load euler angles, coordinates, grain and phase IDs
euler   = cell2mat(rawData(1:3));
xyz     = cell2mat(rawData(4:6));
grains  = cell2mat(rawData(7));
phases  = cell2mat(rawData(8));


clear max_value
clear total_els
%calculate the maximum value of elements and nodes
max_value=max(cell2mat(rawData(4)));
total_els=size(euler,1);

% Material-ID
materials = ones(total_els,1)*matID;






[grain_order, grain_record]=unique(grains);

grain_order=grain_order';

grain_record=grain_record';



phase_order=phases(grain_record);


material_order=materials(grain_record);

euler_angle1=euler(grain_record,1);
euler_angle2=euler(grain_record,2);
euler_angle3=euler(grain_record,3);
%     



% %% Generate the rotation matrix        
% for ii=1:length(grain_order)
%     %%
%     %need to create the rotation matrix for each euler angle for each
%     %grain.  This matrix is then used to rotate a global orientation to
%     %the what is is n the local orientation.
%     zrot=[cosd(euler_angle1(ii)), sind(euler_angle1(ii)), 0; -sind(euler_angle1(ii)), cosd(euler_angle1(ii)),0; 0,0,1];
%     xrot=[1,0,0;0,cosd(euler_angle2(ii)),sind(euler_angle2(ii));0,-sind(euler_angle2(ii)),cosd(euler_angle2(ii))];
%     zrot2=[cosd(euler_angle3(ii)),sind(euler_angle3(ii)),0;-sind(euler_angle3(ii)),cosd(euler_angle3(ii)),0;0,0,1];
% 
%     %total rotation matrix - crystal to sample transformation
%     total_rot=transpose(zrot2*xrot*zrot);
% 
% 
% 
% end



format long
% import node coordinates
fid = fopen([filename '_nodes.inp'],'r+');
indata = textscan(fid, '%d %f %f %f', 'HeaderLines',4,'delimiter',',');
fclose(fid);

% Dream3D output is in micrometers - NOT converted to mm    
nodes = [double(indata{1,1}), indata{1,2} indata{1,3}, indata{1,4}];
nodes = nodes(1:end-1,:);

% import connectivity
fid = fopen([filename '_elems.inp'],'r+');
indata = textscan(fid, '%d %d %d %d %d %d %d %d %d', 'HeaderLines',4,'delimiter',',');
fclose(fid);

% Connectivity
elem = [indata{1,1}, indata{1,2}, indata{1,3}, indata{1,4}, indata{1,5}, indata{1,6}, indata{1,7}, indata{1,8}, indata{1,9}];



%% Write the overall element and node sets to input file
% open inp file and write keywords 
inpFile = fopen([filename '.inp'],'wt');
fprintf(inpFile,'** Generated by Dream3D and modified by: Dream3D2Abaqus.m\n');
fprintf(inpFile,'**PARTS\n**\n');
fprintf(inpFile,'*Part, name=DREAM3D\n');

% write nodes
fprintf(inpFile,'*NODE\n');
fprintf(inpFile,'%d,\t%e,\t%e, \t%e\n',nodes');

% write elements
fprintf(inpFile,['*Element, type=C3D8\n']);
fprintf(inpFile,'%8d,%8d,%8d,%8d,%8d,%8d,%8d,%8d,%8d\n',elem');


%% Write the elements sets for each grain to the input file
% create element sets containing grains
for ii = 1:numel(unique(grains))
    %%
    fprintf(inpFile,'\n*Elset, elset=GRAIN-%d\n',grain_order(ii));
    fprintf(inpFile,'%d, %d, %d, %d, %d, %d, %d, %d, %d\n',elem(grains==grain_order(ii))');
    numels=0;

    for tt=1:length(elem(grains==grain_order(ii)))
        %%
        numels=numels+1;
    end
   numels_total(grain_order(ii))=numels;
end

%% Write element set for each phase to input file
uniPhases = unique(phases);
for ii = 1:numel(unique(phases))
    fprintf(inpFile,'\n*Elset, elset=Phase-%d\n',ii);
    fprintf(inpFile,'%d, %d, %d, %d, %d, %d, %d, %d, %d\n',elem(phases==uniPhases(ii))');
end

% %% Calculate grain spherical equivalent diameter
% % calulate diamater in microns
% % additionally, the dimaters for each ground are written to a separate
% % text file to be used to developed a grain size histogram
% diameterID=fopen('diameter.txt','w');
% for ii=1:numel(unique(grains))
%     %%
%     diameter(grain_order(ii))=((((6.0/pi)*(numels_total(grain_order(ii))))^(1/3)));
%     fprintf(diameterID, '%d\n', diameter(grain_order(ii)));
% end
% fclose(diameterID);

%% write sections to each grain
for ii=1:length(grain_order)
    %%
    fprintf(inpFile,'\n**Section: Section_Grain-%d\n*Solid Section, elset=GRAIN-%d, material=MATERIAL-GRAIN%d\n,\n',grain_order(ii),grain_order(ii),grain_order(ii));
end
%% Continue writing the input file with assembly information
% write a closing keyword
fprintf(inpFile,'*End Part');

%writing assembly
fprintf(inpFile,'\n**\n**ASSEMBLY\n**');
fprintf(inpFile,'\n*Assembly, name=Assembly\n**');
fprintf(inpFile,'\n*Instance, name=DREAM3D-1, part=DREAM3D\n');

% write nodes
fprintf(inpFile,'*NODE\n');
fprintf(inpFile,'%d,\t%e,\t%e, \t%e\n',nodes');

% write elements
fprintf(inpFile,'*Element, type=C3D8\n');
fprintf(inpFile,'%8d,%8d,%8d,%8d,%8d,%8d,%8d,%8d,%8d\n',elem');

fprintf(inpFile,'\n*End Instance\n**');


%% Closing the assembly component of the input file

fprintf(inpFile,'\n*End Assembly');
fprintf(inpFile, '\n**MATERIALS\n**');

%import material parameters to be used in the development of materials
%for each grain.
xlRange='A1:A6';
[A16]=readmatrix('PROPS.xlsx','Sheet','Material_parameters','DataRange',xlRange);


%% Finalising the input file

% Flag for reading the inputs from the file or material library
% "0": material library in usermaterial.f will be used
% "1": use the material parameters in excel file



% Are the material properties given in the excel file?
% Read from excel file (if read_all_props==true)
if A16(6)==0
    
    
    A = strings(6,1);

    

    
    % Flag for reading the inputs from the file or material library
    % "0": material library in usermaterial.f will be used
    % "1": use the material parameters in excel file
    A(6)=0;
    
    % Number variables in DEPVAR
    noPROPS = 6;
    
    % Do not define anything further
    
else
    
    A = strings(250,1);


        
    % Flag for reading the inputs from the file or material library
    % "0": material library in usermaterial.f will be used
    % "1": use the material parameters in excel file
    A(6)=1;   
    
    
    % Number variables in DEPVAR
    % Has a fixed size - including additional space for extra variables
    noPROPS = 250;
    
    
    
end








for ii=1:length(grain_order)

    fprintf(inpFile, '\n*Material, name=MATERIAL-GRAIN%d',grain_order(ii));
    fprintf(inpFile, ['\n*Depvar\n', num2str(noDepvar), ',']);
    fprintf(inpFile, ['\n*User Material, constants=',num2str(noPROPS),'\n']);

    % Euler angles
    A(1:3) = [euler_angle1(ii), euler_angle2(ii), euler_angle3(ii)];
    % Grain - ID
    A(4) = grain_order(ii);
    
    
    % Phase - ID
    % IF DEFINED BY THE USER (>0)
    if matID>0
        
        A(5) = material_order(ii);
        
    % Use Dream3D output 
    else
        
        A(5) = phase_order(ii);
        
    end

%     % Adding the centroid information in x,y,z coordinates
%     A(9:11)=centroid(grain_order(ii),:);
%     % center element

%     %adding the calculated equivalent spherical diameter for each grain
%     A(13)=diameter(grain_order(ii));

    % Read the properties from the PROPS if desired
    if A16(6) ==1
        
        % Loop through all different phases
        for iph = 1:uniPhases
            
            % Column character (read next column for each phase)
            letter = char(iph+ 64);

            xlRange = [letter,'1:', letter, '250']; % A1-A250
            [B]=readmatrix('PROPS.xlsx','Sheet','Material_parameters','DataRange',xlRange);
            

            % All parameters
            A(7:250) = B(7:250);
            
            
        end
        
    end





    % Printing this information to file
    fprintf(inpFile, '%s, %s, %s, %s, %s, %s, %s, %s\n',A);

end

fprintf(inpFile,'\n**');
fprintf(inpFile, '\n**\n** STEP: Loading\n**\n*Step, name=Loading, nlgeom=YES, inc=10000\n*Static\n0.01, 10., 1e-05, 1.');
fprintf(inpFile, '\n**\n** OUTPUT REQUESTS\n**');
fprintf(inpFile, '\n*Restart, write, frequency=0\n**');
fprintf(inpFile, '\n** FIELD OUTPUT: F-Output-1\n**\n*Output, field, variable=PRESELECT\n**');
if noDepvar>0
    fprintf(inpFile, '\n** FIELD OUTPUT: F-Output-2\n**\n*Element Output, directions=YES\nSDV,\n**');
end
fprintf(inpFile, '\n** HISTORY OUTPUT: H-Output-1\n**\n*Output, history, variable=PRESELECT\n**');
fprintf(inpFile, '\n*End Step');

% close the file
fclose(inpFile);


toc

return

end




