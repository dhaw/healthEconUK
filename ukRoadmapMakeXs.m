function f=ukRoadmapMakeXs(Xin)
%Input grid

%X - Daedalus input for roadmap periods
%x - monthly values (from data)
Xout=Xin;
lx=size(Xin,1);%Number of sectors

A=zeros(6,11);
A(1,1)=28;
A(2,2:4)=[7,21,3];
A(3,5:6)=[11,19];
A(4,7:8)=[16,15];
A(5,9)=30;
A(6,10:11)=[18,13];
a=[28,31,30,31,30,31]';
[a1,a2]=size(A);
A=A./repmat(a(1:a1),1,a2);

B=zeros(6,11);
B(1,1:2)=[28,7];
B(2,3)=21;
B(3,4:5)=[3,11];
B(4,6:7)=[19,16];
B(5,8:10)=[15,30,18];
B(6,11)=13;
b=[35,21,14,35,63,13]';
[b1,b2]=size(B);
B=B./repmat(b(1:b1),1,b2);
%C=B*pinv(A);

fun=@(z)toOptimise(z,B);
%fun2=@(z)toConstrain(z,B,xpre);

nperiods=size(A,2);
lb=zeros(1,nperiods)';
ub=ones(1,nperiods)';

z0=(.4:.05:.9)';
%nullA=null(A);
%undoA=A'\(A'*A);
rng default;%for reproducibility
options=optimoptions(@fmincon,'UseParallel',true,'MaxFunctionEvaluations',1e4,'MaxIterations',1e4);%,'algorithm','interior-point');
%options=optimoptions(@fmincon,'MaxFunctionEvaluations',1e4,'MaxIterations',1e4);%,'GradObj','off','GradConstr','off');

for i=1:lx
    xpre=Xin(i,12);
    xmax=max(1,xpre);
    fun2=@(z)toConstrain(z,B,xpre,xmax);%y constrained by Jan x
    %{
    if xpre==xmax
        z0=xpre*ones(nperiods,1);
    else
        z0=(xpre:(1-xpre)/(nperiods-1):xmax)';
    end
    %}
    xi=Xin(i,13:18)';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Solver:
    %xout=fmincon(fun,'x0',z0,'Aeq',A,'beq',xi,'lb',lb,'ub',ub,'nonlcon',fun2);%,'options',options);
    zout=fmincon(fun,z0,A,xi,[],[],lb,ub,fun2,options);
    %
    %{
    rng default;%for reproducibility
    
    problem=createOptimProblem('fmincon','x0',z0,'objective',fun,'Aeq',A,'beq',xi,'lb',lb,'ub',ub,'nonlcon',fun2,'options',options);
    gs=GlobalSearch;
    zout=run(gs,problem);
    %}
    Xout(i,13:18)=B*zout;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Simpler method:
    %Feb to July or equiv periods
    %{
    x0=undoA*xi;
    %xi=C*xi;
    Xout(i,13:18)=B*x0';
    %}
end
f=Xout;
end

function f=toOptimise(z,B)
%f=-sum(z);
%f=max(diff(diff(B*z)));%As close to linear as possible
dy=diff(B*z);
f=-sum(dy(dy<0));%Minimise re-closing
end

function [c,ceq]=toConstrain(z,B,xpre,xmax)
y=B*z;
%mindiffy=min(diff([xpre;y]));%>0
miny=min(y);%>0 - covered using xpre
maxy=max(y);%<1
%c=max([-mindiffy,-miny,maxy-1]);
c=max([-miny+xpre,maxy-xmax]);
ceq=[];
end

%{
A=[28,0,0,0,0,0;
    2,26,3,0,0,0;
    0,0,11,19,0,0;
    0,0,0,16,15,0;
    0,0,0,0,30,0;
    0,0,0,0,18,13];
%A=A(1:4,1:5);
a=[28,31,30,31,30,31]';
[a1,a2]=size(A);
A=A./repmat(a(1:a1),1,a2);
B=[28,2,0,0,0,0;
    0,26,0,0,0,0;
    0,3,11,0,0,0;
    0,0,0,19,16,0;
    0,0,0,15,30,18;
    0,0,0,0,0,13];
b=[30,26,14,35,63,13]';
[b1,b2]=size(A);
B=B./repmat(b(1:b1),1,b2);
%}
