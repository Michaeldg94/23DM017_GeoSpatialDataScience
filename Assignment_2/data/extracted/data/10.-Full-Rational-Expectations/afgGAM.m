clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0];

vars = [1007.128785 0;0 0.003625];

model = recsmodel('gam.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [90 0.18];

smax = [220 0.52]; 

[interp,s] = recsinterpinit(10,smin,smax)
%increase from 10 to ?

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(100,4);
epsilon = -0.066;
Bee = 170.6498;
for i=1:100;
    x(i,2) = (s(i,1)/Bee)^(1/epsilon);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [146.0422618 0.191365033]; 
eH = [13.6757208138499 -0.11111458506582 -1.0170201595399 -42.9627107432371 1.51429523942016 34.8248828022656 56.2190023442936 -43.7172542325849 -26.149508453756];
ePw = [0.0357849674578999 0.0172258158030184 0.0247146387439521 0.234178480709182 -0.0506242218722442 -0.0504898341981927 0.0525653695675146 0.0388927226521032 -0.0197031240446768];

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

Hmean = [138.3185548];
foil = ones(10,1);
Hfoil = foil*Hmean;
Spct = zeros(10,1);
for i=1:10;
    for j=1:1;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct


