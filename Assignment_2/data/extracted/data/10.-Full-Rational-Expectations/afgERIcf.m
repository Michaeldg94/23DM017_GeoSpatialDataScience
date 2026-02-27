clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0];

vars = [299.186426 0;0 0.003625];

model = recsmodel('eriCF.yaml',struct('Mu',means,'Sigma',vars,'order',2))

smin = [10 0.095];

smax = [90 0.30]; 

[interp,s] = recsinterpinit(4,smin,smax)
%increase from 10 to ?

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(16,4);
epsilon = -0.066;
Bee = 38.25806;
for i=1:16;
    x(i,3) = Bee - s(i,1);
    x(i,2) = s(i,2) + 0.0555;
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [14.32320343 0.118380833]; 
eH = [-10.4883613543722 15.2360127704026 21.363196281234 35.4150282409435 -10.0203778661543 -12.0016204771137 -11.5642017433312 -10.0095125698607 -9.60237918035542];
ePw = [-0.0185508333333333 0.0134516666666667 0.0520058333333333 0.0526841666666667 -0.0649283333333333 0.0219691666666667 0.0969625 -0.00720416666666668 -0.00063249999999998];
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

Hmean = [22.65098753];
foil = ones(10,1);
Hfoil = foil*Hmean;
Spct = zeros(10,1);
for i=1:10;
    for j=1:1;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct


