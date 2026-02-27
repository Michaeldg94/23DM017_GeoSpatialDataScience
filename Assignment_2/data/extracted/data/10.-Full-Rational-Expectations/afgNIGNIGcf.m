clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0 0];

vars = [722.7305789 0 0; 0 1583.519947 0;0 0 0.003625];
%vars = [530.8026913 389.7811979 0; 389.7811979 1465.625944 0;0 0 0.003625];

model = recsmodel('nignigCF.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [120 200 0.13];

smax = [220 400 0.40]; 

[interp,s] = recsinterpinit(5,smin,smax)

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(125,8);
epsilon = -0.066;
BeeC = 166.9375;
BeeI = 251.2102;
for i=1:125;
    x(i,3) = (s(i,1)/BeeC)^(1/epsilon);
    x(i,4) = (s(i,2)/BeeI)^(1/epsilon);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [162.0008778 285.8241037 0.148093455];
eHc = [11.2148263073987 18.3941972706191 32.4554808465234 18.300988833309 31.2811572618694 -30.073536373631 -14.6622665742571 -34.2786622333196 -36.8928400273604];
eHi = [-61.3032834208047 3.97033204522432 19.0492099539521 -4.17283442749664 53.3497475290501 -45.5527747101189 55.101043290866 -42.6991959491474 5.2451085963753];
ePw = [0.00407946 0.014449366 0.040561222 0.130317121 -0.057421422 -0.012241775 0.082682649 0.013642065 -0.007765647]; 

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

Hmean = [157.7402231 0;0  268.8114566];
foil = ones(10,2);
Hfoil = foil*Hmean;
Spct = zeros(10,2);
for i=1:10;
    for j=1:2;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct