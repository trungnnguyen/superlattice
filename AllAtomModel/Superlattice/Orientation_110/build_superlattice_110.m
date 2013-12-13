%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% BUILD NANOPARTICLE SUPERLATTICE FROM INDIVIDUAL NANOPARITLCES %%%%%%
%%% SUPERLATTICE ORIENTs ALONG [110] DIRECTION
%%% Written by Wenbin Li, MIT, Nov. 2013
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% The program reads the relaxed coordinates of a single gold-alkanethiol
%%% nanopartile. These coordinates are written in the file "SingleNP.cfg"
%%% "SingleNP.cfg" can be obtained by running LAMMPS simulation of
%%% alkanethiol self-assembly on gold nanocrystal surface.
%%% The input files needed for such simulation can be generated by running
%%% the MATLAB code in the directory AllAtomModel/SingleNanoParticle

%%% The program outputs a CFG configuration files of gold nanopartilce superlattice,
%%% whose file name will be "gold_np_thiol.cfg". The CFG configuration file
%%% can be visualized by Ju Li's Atomeye program. Atomeye is a free, fast software
%%% for visualization of atomic configurations. Atomeye can be downloaded from
%%% http://li.mit.edu/Archive/Graphics/A/

%%% The program also outputs a LAMMPS data file 'data.fusion',
%%% which serves as initial conditions for molecular dynamics simulation
%%% package LAMMPS (http://lammps.sandia.gov/)

%%% Allinger et al's MM3 force field will be used to model alkanethiols
%%% Reference: Allinger, N. L., Yuh, Y. H., & Lii, J-H. (1989) 
%%% "Molecular Mechanics. The MM3 Force Field for Hydrocarbons. 1."
%%% J. Am. Chem. Soc. 111, 8551-8565. 

%%% Input CFG configuration file name
inputfile = 'SingleNP.cfg';
%%% total number of Au atoms per nanoparticle
natom_Au  = 561;
%%% total number of Sulfur atoms per nanoparticle
natom_S   = 136;
%%% total number of carbon atoms per nanoparticle
natom_C   = 1088;
%%% total nubmer of hydrogen atoms per nanoparticle
natom_H   = 2312;

%%%  number of gold atoms per nanoparticle, same as natom_Au
n_gold  = natom_Au;
%%%  number of thiol molecules contained in 'SingleNP.cfg'
n_thiol = 136;
%%%  number of carbon atoms per thiol molecules
%%%  here we work with octane-thiol (SC8H17)
%%%  hence natom_thiol_C = 8, but you can change it
%%%  for example if you work with dodecanethiol
%%%  then natom_thiol_C = 12
natom_thiol_C  = 8;
%%%  number of hydrogen atoms per thiol molecules
natom_thiol_H  = 2*natom_thiol_C+1;
%%%  number of combined atoms of sulfur and carbon
natom_thiol_SC = natom_thiol_C + 1;
%%%  total nubmer of atoms per thiol
natom_thiol    = natom_thiol_SC + natom_thiol_H;

%%%  open the file 'SingleNP.cfg'
fid = fopen(inputfile, 'r');

%%%  read data
natom = fscanf(fid, '%*s %*s %*s %*s %g\n',1);
line1 = fgets(fid);
%%%  supercell matrix
H0    = fscanf(fid, '%*s %*s %g %*s\n', [3 3])';
fgets(fid);
line2 = fgets(fid); fgets(fid); fgets(fid); fgets(fid);

%%%  Mass and Symbol of Au
Au_mass   = fscanf(fid, '%g\n');
Au_symbol = fgets(fid);

%%%  Coordinates of Au
Pos_gold = fscanf(fid, '%g %g %g %d %d\n', [5, natom_Au])';

%%%  Mass and symbol of Sulfur
S_mass   = fgets(fid);
S_symbol = fgets(fid);

%%%  Coordinates of Sulfur atoms
Pos_S = fscanf(fid, '%g %g %g %d %d\n', [5, natom_S])';

%%%  Mass and symbol of Carbon
C_mass   = fgets(fid);
C_symbol = fgets(fid);

%%%  Coordinates of Carbon atoms
Pos_C = fscanf(fid, '%g %g %g %d %d\n', [5, natom_C])';

%%%  Mass and symbol of Hydrogen 
H_mass   = fgets(fid);
H_symbol = fgets(fid);

%%%  Coordinates of Hydrogen atoms
Pos_H = fscanf(fid, '%g %g %g %d %d\n', [5, natom_H])';

%%%  Close file
fclose(fid);

%%%  only keep the coordinate data
Pos_gold   = Pos_gold(:,1:3);

%%%  Coordinates of center atom of gold
ref_center = Pos_gold(1,:);

%%%  Shift coordinates of central gold atom to origin
for i = 1:n_gold
  Pos_gold(i,:) = Pos_gold(i,:) - ref_center;
end

%%%  Position coordinates of thiol molecules   
Pos_chain = zeros(natom_thiol,3,n_thiol);

for i = 1:n_thiol
  Pos_chain(1,:,i) = Pos_S(i,1:3);
  Pos_chain(2:natom_thiol_SC, :, i) = Pos_C((natom_thiol_C*(i-1)+1):(natom_thiol_C*i), 1:3);
  Pos_chain((natom_thiol_SC+1):natom_thiol, :, i) = Pos_H((natom_thiol_H*(i-1)+1):(natom_thiol_H*i), 1:3);
  
  %%% Shift the coordinates of thiols
  for j = 1:natom_thiol
    Pos_chain(j,:,i) = Pos_chain(j,:,i)-ref_center;
  end
end
  
%%%  Convert to absolute coordinates
Pos_gold = Pos_gold*H0;

for k = 1:n_thiol
  Pos_chain(:,:,k)=Pos_chain(:,:,k)*H0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Determine the Center of Mass Coordiantes of the Nanoparticles in
%%% [110] oriented Nanoparticle Superlattice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% "primitive cell" dimension: (2*a) times (2*a) times (sqrt(2)*a)
%%% where a = np_distance is the original distance between two
%%% nanoparticles

%%% distance between two nearest neighbor nanoparticles at the beginning
np_distance = 60;

%%% How many periods along X, Y, and Z dimensions
xperiod = 2; yperiod = 2; zperiod = 3;

%%% each "primitive cell" contains 8 nanoparticles
np_total = xperiod*yperiod*zperiod*8;

%%% "primitive cell" dimensions
lx = 2*np_distance; ly = 2*np_distance; lz = sqrt(2)*np_distance;

%%% superbox dimensions
H11 = xperiod*lx; H22 = yperiod*ly; H33 = zperiod*lz;

H = diag([H11 H22 H33]);

%%% Center of Mass coordinates of the nanoparticles
Nanoxtal_Center = zeros(np_total, 3);

NP2Now = 0;

for i = 0:xperiod-1
  for j = 0:yperiod-1
    for k = 0:zperiod-1
      Nanoxtal_Center(NP2Now+1 , :) = [0 0 0]              + [lx 0 0]*i + [0 ly 0]*j + [0 0 lz]*k;
      Nanoxtal_Center(NP2Now+2 , :) = [lx/2 0 0]           + [lx 0 0]*i + [0 ly 0]*j + [0 0 lz]*k;
      Nanoxtal_Center(NP2Now+3 , :) = [0 ly/2 0]           + [lx 0 0]*i + [0 ly 0]*j + [0 0 lz]*k;
      Nanoxtal_Center(NP2Now+4 , :) = [lx/2 ly/2 0]        + [lx 0 0]*i + [0 ly 0]*j + [0 0 lz]*k;
      Nanoxtal_Center(NP2Now+5 , :) = [lx/4 ly/4 lz/2]     + [lx 0 0]*i + [0 ly 0]*j + [0 0 lz]*k;
      Nanoxtal_Center(NP2Now+6 , :) = [lx/4 3*ly/4 lz/2]   + [lx 0 0]*i + [0 ly 0]*j + [0 0 lz]*k;
      Nanoxtal_Center(NP2Now+7 , :) = [3*lx/4 ly/4 lz/2]   + [lx 0 0]*i + [0 ly 0]*j + [0 0 lz]*k;
      Nanoxtal_Center(NP2Now+8 , :) = [3*lx/4 3*ly/4 lz/2] + [lx 0 0]*i + [0 ly 0]*j + [0 0 lz]*k;
      
      NP2Now = NP2Now + 8;
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% COORDINATES DETERMINATION ENDS HERE, NEXT OUTPUT CFG COORDINATE FILE

atom_name_Au = 'Au';
atom_mass_Au = 196.967;

atom_name_S = 'S';
atom_mass_S = 31.972;

atom_name_C = 'C';
atom_mass_C = 12.000;

atom_name_H = 'H';
atom_mass_H = 1.008;

natom_total = (n_gold + natom_thiol*n_thiol)*np_total;

cfg_name = 'gold_np_thiol.cfg';
cfg = fopen(cfg_name, 'w');
 
fprintf(cfg, 'Number of particles = %d\n', natom_total);
fprintf(cfg, 'H0(1,1)= %.5g A\n', H(1,1));
fprintf(cfg, 'H0(1,2)= %.5g A\n', H(1,2));
fprintf(cfg, 'H0(1,3)= %.5g A\n', H(1,3));
fprintf(cfg, 'H0(2,1)= %.5g A\n', H(2,1));
fprintf(cfg, 'H0(2,2)= %.5g A\n', H(2,2));
fprintf(cfg, 'H0(2,3)= %.5g A\n', H(2,3));
fprintf(cfg, 'H0(3,1)= %.5g A\n', H(3,1));
fprintf(cfg, 'H0(3,2)= %.5g A\n', H(3,2));
fprintf(cfg, 'H0(3,3)= %.5g A\n', H(3,3));
fprintf(cfg, '.NO_VELOCITY.\n');
fprintf(cfg, 'entry_count = 3\n');

%%%  Print Gold atomic coordinates

fprintf(cfg, '%g\n', atom_mass_Au);
fprintf(cfg, '%2s\n', atom_name_Au);

for N = 1:np_total
  for i=1: n_gold
    fprintf(cfg, '%.5g %.5g %.5g\n', (Pos_gold(i,1)+Nanoxtal_Center(N,1))/H(1,1), ...
            (Pos_gold(i,2)+Nanoxtal_Center(N,2))/H(2,2), (Pos_gold(i,3)+Nanoxtal_Center(N,3))/H(3,3));
  end
end

%%%  Print Sulfur atomic coordinates

fprintf(cfg, '%g\n', atom_mass_S);
fprintf(cfg, '%2s\n', atom_name_S);

for N = 1:np_total
  for k = 1:n_thiol
    fprintf(cfg, '%.5g %.5g %.5g\n', (Pos_chain(1,1,k)+Nanoxtal_Center(N,1))/H(1,1), ...
            (Pos_chain(1,2,k)+Nanoxtal_Center(N,2))/H(2,2), (Pos_chain(1,3,k)+Nanoxtal_Center(N,3))/H(3,3));
  end
end

%%% Print Carbon atomic coordinates
  
fprintf(cfg, '%g\n', atom_mass_C);
fprintf(cfg, '%2s\n', atom_name_C);

for N = 1:np_total
  for k = 1:n_thiol
    for i = 2:natom_thiol_SC
      fprintf(cfg, '%.5g %.5g %.5g\n', (Pos_chain(i,1,k)+Nanoxtal_Center(N,1))/H(1,1), ...
          (Pos_chain(i,2,k)+Nanoxtal_Center(N,2))/H(2,2), (Pos_chain(i,3,k)+Nanoxtal_Center(N,3))/H(3,3));
      end
  end
end

%%% Print Hydrogen atomic coordinates

fprintf(cfg, '%g\n', atom_mass_H);
fprintf(cfg, '%2s\n', atom_name_H);

for N = 1:np_total
  for k = 1:n_thiol
    for i = (natom_thiol_SC+1):natom_thiol
      fprintf(cfg, '%.5g %.5g %.5g\n', (Pos_chain(i,1,k)+Nanoxtal_Center(N,1))/H(1,1), ...
          (Pos_chain(i,2,k)+Nanoxtal_Center(N,2))/H(2,2), (Pos_chain(i,3,k)+Nanoxtal_Center(N,3))/H(3,3));
      end
  end
end

fclose(cfg);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NEXT OUTPUT DATA FILE 'DATA.FUSION' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%  total atoms per nanoparticle
total_atoms_per_np     = n_gold + natom_thiol*n_thiol;

%%%  total molecules per nanoparticle
total_molecules_per_np = 1 + n_thiol;

%%%  total bonds per thiol
n_bonds_per_thiol      = natom_thiol_C + natom_thiol_C*2 + 1;
%%%  total bonds per nanoparticle
total_bonds_per_np     = n_bonds_per_thiol*n_thiol;

%%%  total angles per thiol
n_angles_per_thiol     = natom_thiol_C*6;
%%%  total angles per nanoparticle
total_angles_per_np    = n_angles_per_thiol*n_thiol;

%%%  total dihedral per thiol
n_dihedrals_per_thiol  = (natom_thiol_C-1)*9;
%%%  total dihedrals per nanoparticle
total_dihedrals_per_np = n_dihedrals_per_thiol*n_thiol;

%%%  atoms types:
%%%  Au-1
%%%  S-2
%%%  C-3
%%%  H-4
atom_types = 4;

%%%  bonds types:
%%%  1  S-C
%%%  2  C-C
%%%  3  C-H
bond_types = 3;

%%%  angle types:
%%%  1  C-C-C
%%%  2  C-C-H  the middle C connects with two hydrogens
%%%  3  C-C-H  the middle C connects with three hydrogens
%%%  4  H-C-H  the middle C connects with two hydrogens
%%%  5  H-C-H  the middle C connects with three hydrogens
%%%  6  S-C-C
%%%  7  S-C-H
angle_types = 7;

%%%  dihedral types
%%%  1  C-C-C-C
%%%  2  CH2-CH2-CH2-H
%%%  3  H-CH2-CH2-H
%%%  4  S-C-C-C
%%%  5  S-C-C-H
%%%  6  CH2-CH2-CH3-H
%%%  7  H-CH2-CH3-H
dihedral_types = 7;

atom_mass_Au = 196.967;
atom_mass_S =  31.972;
atom_mass_C =  12.000;
atom_mass_H =  1.008;

%%%  lammps output file name
file_name = 'data.fusion';

fp = fopen(file_name, 'w');

fprintf(fp, 'Gold Nanoparticle - Thiol System\n');
fprintf(fp, '\n');
fprintf(fp, '        %d   atoms\n',     total_atoms_per_np*np_total);
fprintf(fp, '        %d   bonds\n',     total_bonds_per_np*np_total);
fprintf(fp, '        %d   angles\n',    total_angles_per_np*np_total);
fprintf(fp, '        %d   dihedrals\n', total_dihedrals_per_np*np_total);
fprintf(fp, '\n');
fprintf(fp, '        %d   atom types\n',     atom_types);
fprintf(fp, '        %d   bond types\n',     bond_types);
fprintf(fp, '        %d   angle types\n',    angle_types);
fprintf(fp, '        %d   dihedral types\n', dihedral_types);

fprintf(fp, '\n');
fprintf(fp, '  0.00  %.5g        xlo xhi\n', H(1,1));
fprintf(fp, '  0.00  %.5g        ylo yhi\n', H(2,2));
fprintf(fp, '  0.00  %.5g        zlo zhi\n', H(3,3));

fprintf(fp, '\n');
fprintf(fp, 'Masses\n');
fprintf(fp, '\n');

fprintf(fp, ' 1 %g\n', atom_mass_Au);
fprintf(fp, ' 2 %g\n', atom_mass_S);
fprintf(fp, ' 3 %g\n', atom_mass_C);
fprintf(fp, ' 4 %g\n', atom_mass_H);

%%%%%%%%%%%%%%%%%%%%%
%%%  PRINT ATOMS  %%%
%%%%%%%%%%%%%%%%%%%%%
 
fprintf(fp, '\n');
fprintf(fp, 'Atoms\n');
fprintf(fp, '\n');

%%% PRINT FORMAT: ATOM_ID MOLECULE_ID ATOM_TYPE POSITION_X POSITON_Y POSITION_Z

for N = 1:np_total
  
  %%% print coordinates of gold atoms
  for i = 1: n_gold
    fprintf(fp, '   %d    %d   1   %.5g  %.5g  %.5g\n', i + total_atoms_per_np*(N-1), 1 + total_molecules_per_np*(N-1), ...
            Pos_gold(i,1)+Nanoxtal_Center(N,1), Pos_gold(i,2) + Nanoxtal_Center(N,2), Pos_gold(i,3) + Nanoxtal_Center(N,3));
  end
  
  %%% print coordinates of thiol atoms
  for k = 1:n_thiol
    
    %%% print sulfur atoms
    fprintf(fp,   '   %d     %d   2  %.5g  %.5g  %.5g\n', total_atoms_per_np*(N-1)+ n_gold + (k-1)*natom_thiol+1, ...
            total_molecules_per_np*(N-1) + 1 + k, ...
            Pos_chain(1,1,k) + Nanoxtal_Center(N,1), Pos_chain(1,2,k) + Nanoxtal_Center(N,2), Pos_chain(1,3,k) + Nanoxtal_Center(N,3));
    
    %%% print carbon atoms
    for i=2:natom_thiol_SC
      fprintf(fp, '   %d     %d   3  %.5g  %.5g  %.5g\n', total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i,...
              total_molecules_per_np*(N-1) + 1 + k, ...
              Pos_chain(i,1,k) + Nanoxtal_Center(N,1), Pos_chain(i,2,k) + Nanoxtal_Center(N,2), Pos_chain(i,3,k) + Nanoxtal_Center(N,3));
    end
    
    %%% print hydrogen atoms
    for i=(natom_thiol_SC+1):natom_thiol
      fprintf(fp, '   %d     %d   4  %.5g  %.5g  %.5g\n', total_atoms_per_np*(N-1) + n_gold+ (k-1)*natom_thiol+i,...
              total_molecules_per_np*(N-1) + 1 + k, ...
              Pos_chain(i,1,k) + Nanoxtal_Center(N,1), Pos_chain(i,2,k) + Nanoxtal_Center(N,2), Pos_chain(i,3,k) + Nanoxtal_Center(N,3));
    end
  end
  
end

 
%%%%%%%%%%%%%%%%%%%%%
%%%  PRINT BONDS  %%%
%%%%%%%%%%%%%%%%%%%%%

fprintf(fp, '\n');
fprintf(fp, 'Bonds\n');
fprintf(fp, '\n');

%%% PRINT FORMAT: BOND_NUMBER BOND_TYPE ATOM_ID1 ATOM_ID2

for N = 1:np_total
  
  for k = 1: n_thiol
    
    %%% print S-C bonds
    fprintf(fp, '     %d   %d     %d     %d\n', total_bonds_per_np*(N-1)+(k-1)*n_bonds_per_thiol+1, 1, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+1, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+2);
    
    %%% print C-C bonds
    for i = 2:natom_thiol_C
      fprintf(fp, '     %d   %d     %d     %d\n', total_bonds_per_np*(N-1)+(k-1)*n_bonds_per_thiol+i, 2, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i+1);
    end
    
    %%% print C-H bonds
    for i = 1:natom_thiol_C
      fprintf(fp, '     %d   %d     %d     %d\n',  total_bonds_per_np*(N-1)+(k-1)*n_bonds_per_thiol + natom_thiol_C + 2*i-1, 3, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i-1);
      fprintf(fp, '     %d   %d     %d     %d\n',  total_bonds_per_np*(N-1)+(k-1)*n_bonds_per_thiol + natom_thiol_C + 2*i,   3, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i);
    end
    
    %%% print the last C-H bond in each thiol molecule
    fprintf(fp,   '     %d   %d     %d     %d\n',  total_bonds_per_np*(N-1)+ (k-1)*n_bonds_per_thiol+ 3*natom_thiol_C + 1, 3, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_C + 1, ...
            total_atoms_per_np*(N-1) + n_gold + k*natom_thiol);
  end
  
end

%%%%%%%%%%%%%%%%%%%%%%
%%%  Print Angles  %%%
%%%%%%%%%%%%%%%%%%%%%%

fprintf(fp, '\n');
fprintf(fp, 'Angles\n');
fprintf(fp, '\n');

%%% PRINT FORMAT: ANGLE_NUMBER ANGLE_TYPE ATOM_ID1 ATOM_ID2 ATOM_ID3

for N = 1:np_total
  
  for k = 1: n_thiol
    
    % S-C-C
    
    fprintf(fp, '     %d   %d     %d     %d     %d\n',  total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 1, 6, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+1, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+3);
    % S-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d\n',  total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 2, 7, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+1, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 1);
    % S-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d\n',  total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 3, 7, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+1, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2);
    % C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d\n',  total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 4, 2, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+3, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 1);
    % C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d\n',  total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 5, 2, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+3, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2);
    % H-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d\n', total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 6, 4, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 1, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2);
    

    for i = 2:(natom_thiol_C-1)
      % C-C-C
      fprintf(fp, '     %d   %d     %d     %d     %d\n', total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 6*(i-1)+1, 1, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i+2);
      % C-C-H
      fprintf(fp, '     %d   %d     %d     %d     %d\n', total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 6*(i-1)+2, 2, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i -1);
      % C-C-H
      fprintf(fp, '     %d   %d     %d     %d     %d\n', total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 6*(i-1)+3, 2, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i);   
      % C-C-H
      fprintf(fp, '     %d   %d     %d     %d     %d\n', total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 6*(i-1)+4, 2, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i+2, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i -1);
      % C-C-H
      fprintf(fp, '     %d   %d     %d     %d     %d\n', total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 6*(i-1)+5, 2, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i+2, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i);
      % H-C-H
      fprintf(fp, '     %d   %d     %d     %d     %d\n', total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 6*(i-1)+6, 4, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i -1, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i);
    end
    
  
    % C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d\n', total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 6*natom_thiol_C-5, 3, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+natom_thiol_C, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1) + n_gold+ k*natom_thiol - 2);
    % C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d\n', total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 6*natom_thiol_C-4, 3, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+natom_thiol_C, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1) + n_gold+ k*natom_thiol - 1);
    % C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d\n', total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 6*natom_thiol_C-3, 3, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+natom_thiol_C, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1) + n_gold+ k*natom_thiol);
    % H-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d\n', total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 6*natom_thiol_C-2, 5, ...
            total_atoms_per_np*(N-1) + n_gold+ k*natom_thiol - 2, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1) + n_gold+ k*natom_thiol - 1);
    % H-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d\n', total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 6*natom_thiol_C-1, 5, ...
            total_atoms_per_np*(N-1) + n_gold+ k*natom_thiol - 2, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1) + n_gold+ k*natom_thiol);
    % H-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d\n', total_angles_per_np*(N-1) + (k-1)*n_angles_per_thiol + 6*natom_thiol_C,   5, ...
            total_atoms_per_np*(N-1) + n_gold+ k*natom_thiol - 1, ...
            total_atoms_per_np*(N-1) + n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1) + n_gold+ k*natom_thiol);  
    
  end
  
end


%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   PRINT DIHEDRALS  %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(fp, '\n');
fprintf(fp, 'Dihedrals\n');
fprintf(fp, '\n');

%%% PRINT FORMAT: DIHEDRAL_N_GOLD DIHEDRAL_TYPE ATOM_ID1 ATOM_ID2 ATOM_ID3

for N = 1:np_total
  
  for k = 1: n_thiol
  
    % S-C-C-C
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 1, 4, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+1, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+4);
    % S-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 2, 5, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+1, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 3);
    % S-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 3, 5, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+1, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 4);
    % C-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 4, 2, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+4, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 1);
    % H-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 5, 3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 1, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 3);
    % H-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 6, 3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 1, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 4);
    % C-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 7, 2, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+4, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2);
    % H-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 8, 3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC +3);
    % H-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 9, 3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+2, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 4);
  
    
    for i = 2:(natom_thiol_C-2)
      % C-C-C-C
      fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 9*(i-1)+1, 1, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+2, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+3);
      % C-C-C-H
      fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 9*(i-1)+2, 2, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+2, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i + 1);
      % C-C-C-H
      fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 9*(i-1)+3, 2, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+2, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i + 2);
      
      % C-C-C-H
      fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 9*(i-1)+4, 2, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+3, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+2, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i -1);    
      % H-C-C-H
      fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 9*(i-1)+5, 3, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i -1, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+2, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i + 1);
      % H-C-C-H
      fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 9*(i-1)+6, 3, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i -1, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+2, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i + 2);    
      % C-C-C-H
      fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 9*(i-1)+7, 2, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+3, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+2, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i);
      
      % H-C-C-H
      fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 9*(i-1)+8, 3, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+2, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i + 1);
    
      % H-C-C-H
      fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + (k-1)*n_dihedrals_per_thiol + 9*(i-1)+9, 3, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+1, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+i+2, ...
              total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol + natom_thiol_SC + 2*i + 2);
    
    end
  
    % C-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + k*n_dihedrals_per_thiol - 8, 6, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C-1, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol-2);
    % C-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + k*n_dihedrals_per_thiol - 7, 6, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C-1, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol-1);
    % C-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + k*n_dihedrals_per_thiol - 6, 6, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C-1, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol);
    % H-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + k*n_dihedrals_per_thiol - 5, 7, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol-4, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol-2);
    % H-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + k*n_dihedrals_per_thiol - 4, 7, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol-4, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol-1);
    % H-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + k*n_dihedrals_per_thiol - 3, 7, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol-4, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol);
    % H-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + k*n_dihedrals_per_thiol - 2, 7, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol-3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol-2);
    % H-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + k*n_dihedrals_per_thiol - 1, 7, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol-3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol-1);
    % H-C-C-H
    fprintf(fp, '     %d   %d     %d     %d     %d     %d\n', total_dihedrals_per_np*(N-1) + k*n_dihedrals_per_thiol, 7, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol-3, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C, ...
            total_atoms_per_np*(N-1)+n_gold+(k-1)*natom_thiol+natom_thiol_C+1, ...
            total_atoms_per_np*(N-1)+n_gold+k*natom_thiol);
  end
  
end

fclose(fp);
