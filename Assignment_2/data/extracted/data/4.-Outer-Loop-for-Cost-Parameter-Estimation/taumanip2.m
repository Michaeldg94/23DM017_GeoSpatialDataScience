clear all;
cd 'C:\Users\oporteous\Documents\Data';

data = importdata('Mkts4MatlabID.csv');
dataT = importdata('Tau4Matlab.csv');
sz = size(dataT);

tau1 = ones(233,233);
tau9 = 9999*tau1;
tau9(2:233,1) = data(1:232,1);
tau9(1,2:233) = data(1:232,1)';
%put in old data first
for i=2:233;
    for j=2:233;
        for k=1:sz(1,1);
            if dataT(k,1)==tau9(i,1);
                if dataT(k,2)==tau9(1,j);
                    tau9(i,j) = dataT(k,3);
                end;
            end;
            if dataT(k,2)==tau9(i,1);
                if dataT(k,1)==tau9(1,j);
                    tau9(i,j) = dataT(k,3);
                end;
            end;
        end;
    end;
end;

tau92 = tau9(2:233,2:233);
xlswrite('in_tau2.xlsx', tau92, 'fromMatlab','C3');  
