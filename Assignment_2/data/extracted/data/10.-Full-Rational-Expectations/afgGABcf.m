clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0];

vars = [0.003655435 0;0 0.003625];

model = recsmodel('gabCF.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [0.45 0.20];

smax = [0.9 0.65]; 

[interp,s] = recsinterpinit(10,smin,smax)
%increase from 10 to ?

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(100,4);
epsilon = -0.066;
Bee = 40.57946;
for i=1:100;
    x(i,3) = Bee - s(i,1);
    x(i,2) = s(i,2) + 0.05;
    %x(i,2) = (s(i,1)/Bee)^(1/epsilon);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [0.582207293 0.221889167]; 
eH = [-0.0483883198303723 0.0192332196782322 -0.0404268114708596 -0.10121731751947 -0.0489697624655078 0.0228338842318079 0.0342028593457993 0.0893133427227629 0.0788223504598198];
ePw = [0.0578383333333333 0.0195141666666667 0.0137408333333334 0.305150833333333 -0.04686 -0.0745858333333332 0.0289975 0.0554316666666668 -0.0285100000000001];
shocks = zeros (1,2,9);
shocks(1,1,1:9) = eH(1,1:9);
shocks(1,2,1:9) = ePw(1,1:9);
shocks

%[ssim,xsim] = recsSimul(model,interp,s0,nper,shocks);
[ssim,xsim] = recsSimul(model,interp,s0,10,shocks,struct('simulmethod','solve'))

SPMX = zeros(10,4);
for i=1:10;
    for j=1:4;
        SPMX(i,j) = xsim(1,j,i);
    end;
end;
SPMX

Hmean = [0.587610738];
foil = ones(10,1);
Hfoil = foil*Hmean;
Spct = zeros(10,1);
for i=1:10;
    for j=1:1;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct


