%Robin Wang
 
%Displays the image
I = imread('8.jpg');
imshow(I);
%set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
hold on
 
%Create matrices to store the x & y coordinates of the user-selected points
Xcor=zeros(4,1);
Ycor=zeros(4,1);
 
for a=1:4,
    %Get the coordinates of each of the points selected by the user
    [x,y]=ginput(1);
    Xcor(a)=x;
    Ycor(a)=y;
    plot(x,y,'g.','MarkerSize',20);
end
 
%World coordinates forming a unit square
wa=[0;0;1];
wb=[1;0;1];
wc=[1;1;1];
wd=[0;1;1];
Ww=[wa,wb,wc,wd];
faridworld=Ww;
Ww=Ww';
Wx=Ww(:,1);
Wy=Ww(:,2);

faridpts=[Xcor';Ycor';1,1,1,1];
faridH2=homography(faridworld, faridpts);
faridH3 = faridH2 / faridH2(9);
faridH3=inv(faridH3);
 
%Zero-mean the image and world coordinates
NX = (Wx-mean(Wx(:)));
NY = (Wy-mean(Wy(:)));
NormalizedArrayX = (Xcor-mean(Xcor(:)));
NormalizedArrayY = (Ycor-mean(Ycor(:)));
 
%Calculate the magntude of the points
sum=0;
sumw=0;
for c= 1:4
    sum=sum + norm([NormalizedArrayX(c);NormalizedArrayY(c)]);
    sumw=sumw + norm([NX(c);NY(c)]);
end
 
%Normalized image and world coordinates
newX=zeros(4,1);
newY=zeros(4,1);
WwX=zeros(4,1);
WwY=zeros(4,1);
 
%Scale to multiply by
scale=((2^.5)/(sum/4));
scalew=((2^.5)/(sumw/4));
 
%Scale the coordinates that have been "zero-meaned"
for d=1:4
    newX(d)= (scale)*NormalizedArrayX(d);
    newY(d)=(scale)*NormalizedArrayY(d);
    WwX(d)= (scalew)*NX(d);
    WwY(d)= (scalew)*NY(d);
end
 
%Calculate the A matrix
A=[];
for b=1:4,
    x1=newX(b);
    y1=newY(b);
    X2=WwX(b);
    Y2=WwY(b);
    
    a1=[0,0,0,-X2,-Y2,-1,(y1*X2),(y1*Y2),(y1)];
    a2=[X2,Y2,1,0,0,0,(-x1*X2),(-x1*Y2),(-x1)];
    A=vertcat(A,a1,a2);
end
 
%Find the minimal eigenvalue eigenvector of A
%A'*A to turn A into a square matrix
E=(A'*A);
[Ve,Va] = eig(E);
 
%The minimal eigenvalue eigenvector is the first column displayed in MATLAB
K(:,1)=Ve(:,1);
 
%Reshape the vector into a 3x3 matrix
H1=[K(1,1), K(2,1), K(3,1);K(4,1), K(5,1), K(6,1); K(7,1), K(8,1), K(9,1)];
 
%Transformation matrix to scale back by
Ti=[scale, 0, -scale*mean(Xcor(:)); 0, scale, -scale*mean(Ycor(:)); 0,0,1];
Tw=[scalew, 0, -scalew*mean(Wx(:)); 0, scalew, -scalew*mean(Wy(:)); 0,0,1];

%Denormalize our homography
H2 = (inv(Ti)*H1*Tw);
H3 = H2 / H2(9);

%Inverse homography
H=inv(H3);
   

%Function to create transformation structure that will transform our image
%according to our homography
 T = maketform('projective',H');
 
 HF = maketform('projective', faridH3');
   udata = [0 1];  vdata = [0 1];
   [B,xdata,ydata] = imtransform(I,T,'udata',udata,...
       'vdata',vdata,...
       'size',size(I),...
       'fill',128);

%B = imtransform( I, T );


 
%Display image
hold off;
imshow(B);
 
%Adjust aspect ratio - ask for user input
prompt = {'What aspect ratio would you like (width:height)?'};
dlg_title = 'Aspect Ratio';
num_lines = 1;
def = {'1'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
ratio=str2num(answer{1,1});
if (ratio == 0)
    error('Should not use an aspect ratio of 0!')
end
 
%Change the ratio in the image and display
[height width color] = size(B);
nWidth = (height * ratio);
B = imresize(B, [height nWidth]);
imshow(B);
set(gcf, 'Position', get(0,'Screensize'));




%%%
function[H] = homography(x1,x2)

[x1, T1] = normalise(x1); % world
[x2, T2] = normalise(x2); % image

N = length(x1);
A = zeros(3*N,9);
O = [0 0 0];
for n = 1 : N
    X = x1(:,n)';
    x = x2(1,n);
    y = x2(2,n);
    s = x2(3,n);
    A(3*n-2,:) = [  O  -s*X  y*X];
    A(3*n-1,:) = [ s*X   O  -x*X];
    A(3*n  ,:) = [-y*X  x*X   O ];
end
[U,D,V] = svd(A,0); % Total least squares
H = reshape(V(:,9),3,3)';
H = inv(T2)*H*T1;