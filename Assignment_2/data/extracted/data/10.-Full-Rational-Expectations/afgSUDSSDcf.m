clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0 0];

vars = [2890.652139 0 0; 0 494.9108411 0;0 0 0.003625];
%vars = [530.8026913 389.7811979 0; 389.7811979 1465.625944 0;0 0 0.003625];

model = recsmodel('sudssdCF.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [80 30 0.11];

smax = [250 105 0.30]; 

[interp,s] = recsinterpinit(5,smin,smax)

interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
[interp,x] = recsSolveREE(interp,model,s)

interp = rmfield(interp,{'cx','cz'})

x      = zeros(125,8);
epsilon = -0.066;
BeeC = 212.6926;
BeeI = 212.6926;
for i=1:125;
    x(i,3) = s(i,3) + 0.09105;
    x(i,4) = x(i,3) + 0.075;
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [245.1359994 101.4314565 0.133134546];
eHc = [-46.7819107852876 48.4247527641879 28.744368476335 54.5478907643609 0.424151272327549 5.91436870756007 -62.733209251124 -0.653598705506283 -95.5546029031685];
eHi = [-19.3572439839466 20.0370129903601 11.8937372249417 22.5706221189124 0.175503726263486 2.44722535188242 -25.9575125723997 -0.270443626557835 -39.5382260180673];
ePw = [-0.0150417288550624 0.0102199324731799 0.0562733850443301 0.0758182476149486 -0.0929801812002664 0.0230798823916407 0.0924340391487166 -0.0138293657983288 0.00844088284706429];
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

Hmean = [177.4682098 0;0  73.43213174];
foil = ones(10,2);
Hfoil = foil*Hmean;
Spct = zeros(10,2);
for i=1:10;
    for j=1:2;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct