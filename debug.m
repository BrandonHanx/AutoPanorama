a=[1,2;
    3,4];
b=[1,2;
    5,6;
    7,7];
gmmdata(1)=struct('cluster',a); 
gmmdata(2)=struct('cluster',b);   
c=gmmdata(1).cluster