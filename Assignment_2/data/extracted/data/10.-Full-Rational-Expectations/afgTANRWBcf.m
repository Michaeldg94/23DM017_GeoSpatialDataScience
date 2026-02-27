clear all;

cd 'C:\Users\Obie\Documents\MATLAB\AFGAINS'

addpath(genpath('C:\Users\Obie\Documents\MATLAB\COMPECON'))
addpath(genpath('C:\Users\Obie\Documents\MATLAB\RECS'))

means = [0 0 0];

vars = [467.1407072 0 0; 0 50.40847497 0;0 0 0.003625];
%vars = [530.8026913 389.7811979 0; 389.7811979 1465.625944 0;0 0 0.003625];

model = recsmodel('tanrwbCF.yaml',struct('Mu',means,'Sigma',vars,'order',4))

smin = [87 24 0.31];

smax = [150 50 0.42]; 

[interp,s] = recsinterpinit(5,smin,smax)

%interp = recsFirstGuess(interp,model,s,model.sss,model.xss,struct('fgmethod','perturbation'))
%[interp,x] = recsSolveREE(interp,model,s)

%interp = rmfield(interp,{'cx','cz'})

x      = zeros(125,8);
epsilon = -0.066;
BeeC = 98.13187;
BeeI = 31.56054;
for i=1:125;
    %x(i,3) = (s(i,1)/BeeC)^(1/epsilon);
    %x(i,4) = (s(i,2)/BeeI)^(1/epsilon);
    x(i,3) = s(i,3)+0.07245
    x(i,4) = x(i,3)-0.0776;
end;
x
interp = recsSolveREE(interp,model,s,x)

s0 = [90.20472687 26.99163819 0.154956633];
eHc = [22.06235614508 -19.1312340323112 -14.0156026751859 -9.17189636475267 30.8836523828386 -23.2458974747527 23.9137110239188 5.64456736122163 11.8965590832396];
eHi = [-5.58533222660248 -2.2066365366183 -5.35296040070723 -6.78579203690341 -5.34901534259009 1.88004832535527 7.95048699547765 11.203929991644 9.63974722006598];
ePw = [0.01345560734025 0.0132757465728333 0.0342804685005833 0.110335357935917 0.045756961593 -0.0640083390701666 0.0471634542422499 0.0486414518963334 0.0169081003916667];
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

Hmean = [119.0409423 0;0  32.38611418];
foil = ones(10,2);
Hfoil = foil*Hmean;
Spct = zeros(10,2);
for i=1:10;
    for j=1:2;
        Spct(i,j) = SPMX(i,j)/Hfoil(i,j);
    end;
end;
Spct