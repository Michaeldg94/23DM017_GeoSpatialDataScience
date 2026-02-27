clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0];

vars = [0.026659665 0;0 0.003625];

model = recsmodel('cng.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [2 0.20];

smax = [4 0.65]; 

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
    x(i,2) = 1;
    %x(i,2) = (s(i,1)/Bee)^(1/epsilon);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [2.894377089 0.211493333]; 
eH = [0.0151766592854345 -0.056529520100522 -0.109471414273096 -0.165577049975948 -0.111736768219223 -0.0868415627565082 -0.0697252628888188 0.217256943174716 0.353302227985923];
ePw = [0.05713 0.02316 0.0173383333333333 0.195530833333333 0.126545833333333 -0.114135833333333 -0.0185025 0.0790775000000001 -0.0014791666666667];
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

Hmean = [2.880231341];
foil = ones(10,1);
Hfoil = foil*Hmean;
Spct = zeros(10,1);
for i=1:10;
    for j=1:1;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct


