function out = outmdm(x)

 
%Median Deviation of the Medians outliers detection. Rousseeuw and Croux (1993)
%For each data point xi, we find the distance to all other data points and 
%find the resulting median.  We do this for all data points and we get n medians.  
%Now we find the median of this new data set:
% 
%MDM = c median( median( abs(xi ?xj) ) )
% 
%If we set c=1.1926, then MDM is a robust estimate of the standard deviation 
%of the data set, without assuming that the true underlying data come from a Gaussian distribution.  
%a.tomassini@ucl.ac.uk

 
[rows,cols]=size(x);
c=1.1926;
check = @(xi,mdm) (abs(xi-nanmedian(xi))./mdm)>3;%outliers defined as abs(xi-median)>3mdm i.e. alpha = 0.003 
for ic = 1:cols

   
    a = [-1.*ones(rows,1) x(:,ic)];b=[x(:,ic) ones(rows,1)];%(nxm) * (mxn)

    
     mdm = c.*nanmedian(nanmedian(abs(a*b'),2));%simple linear algebra to avoid loops for xi-xj
     out(:,ic) = check(x(:,ic),mdm);
end