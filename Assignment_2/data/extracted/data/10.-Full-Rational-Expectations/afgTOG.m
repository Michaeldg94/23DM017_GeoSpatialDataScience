clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0];

vars = [103.8375046 0;0 0.003625];

model = recsmodel('tog.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [130 0.15];

smax = [170 0.42]; 

[interp,s] = recsinterpinit(10,smin,smax)
%increase from 10 to ?

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(100,4);
epsilon = -0.066;
Bee = 158.8753;
for i=1:100;
    x(i,2) = (s(i,1)/Bee)^(1/epsilon);
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [139.4268596 0.159549953]; 
eH = [-9.72947457582987 -8.75378598560479 -3.27418086829576 -8.48069969467403 -3.33404328489792 11.0660496878472 4.85192487409299 2.92316738921915 21.6210882190643];
ePw = [0.0128429813328814 0.0147940869684087 0.0361236622786162 0.160528382525422 -0.0544020405100374 -0.0257822789479778 0.0774581683755668 0.0218341661233333 -0.0104692360106737];
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

Hmean = [146.3169054];
foil = ones(10,1);
Hfoil = foil*Hmean;
Spct = zeros(10,1);
for i=1:10;
    for j=1:1;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct


