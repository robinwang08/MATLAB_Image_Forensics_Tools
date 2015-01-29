%Robin Wang

%grayImage = imread(photoName);
%imshow(grayImage);
%title('Original Grayscale Image');

I = imread('sphere_right.png');
J = rgb2gray(I);
imshow(J);
set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
hold on

%Ask the user to input number of lines to be drawn using a dialogue box
prompt = {'How many points do you want to select?'};
dlg_title = 'Number of Lines';
num_lines = 1;
def = {'2'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
numberUserPoints=str2num(answer{1,1});

%Two few lines
%Exit the program if the user doesn't choose to select at least 2 lines
if (numberUserPoints < 2)
    error('Need at least 2 lines for analysis!')
end

Xcor=zeros(numberUserPoints,1);
Ycor=zeros(numberUserPoints,1);

for i=1:(numberUserPoints),
    %Get the coordinates of each of the points selected by the user
    %Negate the Y-value as it is a positive value, but I want to treat the
    %entire image as the fourth quadrant of the coordinate system instead
    %of using the pixel coordinate system
    
    point=ginput(1);
    Xcor(i)=point(1);
    Ycor(i)=-point(2);
    drawmarker( point(1), point(2), 'o', 'y', 12 );
    
end

%Fit a circle to the contour
XY=horzcat(Xcor,Ycor);
%circle = CircleFitByTaubin(XY);
circle = circfit(Xcor,Ycor);
centerX=circle(1,1);
centerY=circle(1,2);
circlerad=circle(1,3);


%Plot the circle
th = 0:pi/50:2*pi;
xunit = circlerad * cos(th) + centerX;
yunit = circlerad * sin(th) + centerY;
plot(xunit, -yunit,'Color','b','Linewidth', 2);
drawmarker( centerX, -centerY, 'o', 'g', 5);


%Get surface normals
userVector=zeros(numberUserPoints,2);
for s=1:numberUserPoints
    userVector(s,1)=(Xcor(s)-centerX)/circlerad;
    userVector(s,2)=(Ycor(s)-centerY)/circlerad;
end




largestAngle=0;
endPts=zeros(2,2);
for i1=1:(numberUserPoints-1),
    
    for i2=1:(numberUserPoints)
        
        %angle = atan2((userVector(i1,1)*userVector(i2,2)-userVector(i1,1)*userVector(i2,1)),userVector(i1,1)*userVector(i2,1)+userVector(i1,2)*userVector(i2,2));
        angle=acosd(dot([userVector(i1,1),userVector(i1,2)],[userVector(i2,1),userVector(i2,2)])/(norm([userVector(i1,1),userVector(i1,2)])*norm([userVector(i2,1),userVector(i2,2)])));
    
        %angle=abs(angle);
        if (angle > largestAngle)
            largestAngle=angle;
            endPts(1,1)=Xcor(i1);
            endPts(1,2)=Ycor(i1);
            endPts(2,1)=Xcor(i2);
            endPts(2,2)=Ycor(i2);
            
        end
        
    end
end

drawmarker( endPts(1,1), -endPts(1,2), '*', 'g', 15 );
drawmarker( endPts(2,1), -endPts(2,2), '*', 'g', 15 );

%Get sample points using the endPts
helper1=0;
helper2=0;

if (endPts(1,1) > endPts(2,1))
    helper1=round(endPts(1,1));
    helper2=round(endPts(2,1));
else
    helper1=round(endPts(2,1));
    helper2=round(endPts(1,1));
end


sampleX=[];
sampleY=[];
largeAngleChecker=0;
checkAngle=0;

pt1 = centerX-circlerad;
pt2 = centerX+circlerad;




for a=pt1:5:pt2,
    
    posy=(sqrt((circlerad^2-(a-centerX)^2)))+centerY;
    negy=(-sqrt((circlerad^2-(a-centerX)^2)))+centerY;
    
    TorF1 = isreal(posy);
    TorF2 = isreal(negy);
    
    if TorF1 ~= 1
       continue 
    end
    
    newVectorX=(a-centerX)/circlerad;
    newVectorpY=(posy-centerY)/circlerad;
    newVectornY=(negy-centerY)/circlerad;
    

    for b=1:numberUserPoints
        %checkAngle = atan2((userVector(i1,1)*userVector(i2,2)-userVector(i1,1)*userVector(i2,1)),userVector(i1,1)*userVector(i2,1)+userVector(i1,2)*userVector(i2,2));
        checkAngle=acosd(dot([userVector(b,1),userVector(b,2)],[newVectorX,newVectorpY])/norm([userVector(b,1),userVector(b,2)])*norm([newVectorX,newVectorpY]));
        
        
        if(checkAngle > largestAngle)
            largeAngleChecker=0;
            break
        else
            largeAngleChecker=1;
        end
    end
    
    if (largeAngleChecker==1)
        
        sampleX=vertcat(sampleX,a);
        sampleY=vertcat(sampleY,posy);
    end
    
    largeAngleChecker=0;
    
    for c=1:numberUserPoints
        checkAngle=acosd(dot([userVector(c,1),userVector(c,2)],[newVectorX,newVectornY])/norm([userVector(c,1),userVector(c,2)])*norm([newVectorX,newVectornY]));
       
        
        if(checkAngle > largestAngle)
            largeAngleChecker=0;
            break
        else
            largeAngleChecker=1;
        end
    end
    
    if (largeAngleChecker==1)
        sampleX=vertcat(sampleX,a);
        sampleY=vertcat(sampleY,negy);
    end
    
end

sampleNo=size(sampleX);

for d = 1:sampleNo
drawmarker(sampleX(d), -sampleY(d), '*', 'r', 10 );
end


sampleNo=length(sampleX);
% Get M
M=ones(sampleNo,3);
for m=1:sampleNo
    M(m,1)=((sampleX(m)-centerX)/circlerad);
    M(m,2)=((sampleY(m)-centerY)/circlerad);
end

%Get the image intensities at each point
intensityValue=zeros(sampleNo,1);
for gs = 1:sampleNo
    intensityValue(gs,1) = J(round(-sampleY(gs)),round(sampleX(gs)));
end
intensityValue=double(intensityValue);

%Get v
transM = M.';
dualM=(transM*M);
invM= inv(dualM);
lastM=invM*transM;
v=lastM*intensityValue

angleInRadians=atan(v(2,1)/v(1,1));
angleInDegrees = radtodeg(angleInRadians)
