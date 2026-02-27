clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0 0];

vars = [2.238395981 0 0; 0 3.634386845 0;0 0 0.003625];
%vars = [530.8026913 389.7811979 0; 389.7811979 1465.625944 0;0 0 0.003625];

model = recsmodel('drccarCF.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [20 30 0.14];

smax = [35 50 0.40]; 

[interp,s] = recsinterpinit(5,smin,smax)

%interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
%[interp,x] = recsSolveREE(interp,model,s)

%interp = rmfield(interp,{'cx','cz'})

x      = zeros(125,8);
epsilon = -0.066;
BeeC = 32.12672;
BeeI = 32.12672;
for i=1:125;
    x(i,3) = s(i,3)+0.0991;
    x(i,4) = s(i,3)+0.0991+0.0337;
    %x(i,3) = (s(i,1)/BeeC)^(1/epsilon);
    %x(i,4) = (s(i,2)/BeeI)^(1/epsilon);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [26.60775731 36.03684528 0.142894053];
eHc = [1.57256145217026 0.843848462185989 0.145820748164645 -0.528271522854595 -1.17909110882249 -1.80822218364987 -2.41683091215977 0.217140774033556 0.82113801801508];
eHi = [-2.50426214207138 0.686540151869742 -1.01344886051591 0.0413351071192665 1.02330343620994 1.44881023929185 0.369668054944007 1.98569638041047 1.7772644137435];
ePw = [0.00413730920899999 0.0111668581686667 0.0378952151943333 0.092158188413 0.0285199779346667 -0.053313217566 0.061173836561 0.0421476656546667 0.0208311781];
shocks = zeros (1,3,9);
shocks(1,1,1:9) = eHc(1,1:9);
shocks(1,2,1:9) = eHi(1,1:9);
shocks(1,3,1:9) = ePw(1,1:9);
shocks

%[ssim,xsim] = recsSimul(model,interp,s0,nper,shocks);
[ssim,xsim] = recsSimul(model,interp,s0,10,shocks,struct('simulmethod','solve'))

SPMX = zeros(10,8);
for i=1:10;
    for j=1:8;
        SPMX(i,j) = xsim(1,j,i);
    end;
end;
SPMX

Hmean = [24.27585104 0;0  39.85175206];
foil = ones(10,2);
Hfoil = foil*Hmean;
Spct = zeros(10,2);
for i=1:10;
    for j=1:2;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct