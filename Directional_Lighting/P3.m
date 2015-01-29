%Robin Wang
%CS 89 Project 2

%Script that will estimate the x- and y- component of the direction to a
%point light source.

%Read in the image and grayscale it before displaying it to the user
imagereg = imread('sphere_left.png');
grayPix = rgb2gray(imagereg);
imshow(grayPix);
set(gcf, 'Position', get(0,'Screensize'));
hold on

%Ask the user to input number of points to be drawn using a dialogue box
prompt = {['How many points do you want to select? When selecting ',...
    'please select clockwise for a certain edge case!']};
dlg_title = 'Point Selection';
num_lines = 1;
def = {'3'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
numberUserPoints=str2num(answer{1,1});

%Edge case: Too few points
%Exit the program if the user doesn't choose to select at least 3 points
if (numberUserPoints < 3)
    error('Need at least 3 lines for analysis!')
end

%Create matrices to store the x and y coordinates of the selected points
Xcor=zeros(numberUserPoints,1);
Ycor=zeros(numberUserPoints,1);

for i=1:(numberUserPoints),
    %Get the coordinates of each of the points selected by the user
    %Negate the Y-value as it is a positive value, but I want to treat the
    %entire image as the fourth quadrant of the coordinate system instead
    %of using the pixel coordinate system
    [x,y]=ginput(1);
    Xcor(i)=x;
    Ycor(i)=-y;
    plot(x,y,'g.','MarkerSize',20);
end

%Fitting a circle to the contour by calling upon the fitcirc function which
%utilizes fminsearch and initial guesses for the radius and center points
circle = fitcirc(Xcor,Ycor);
centerX=circle(1,2);
centerY=circle(1,3);
circlerad=circle(1,1);

%Plot the full circle and the center
wholcirc = 0:pi/50:2*pi;
xunit = circlerad * cos(wholcirc) + centerX;
yunit = circlerad * sin(wholcirc) + centerY;
plot(xunit, -yunit,'Color','c','Linewidth', 2);
plot(centerX, -centerY, 'c.', 'Markersize', 20);

%Get the unit vector for each of the selected points to determine the user
%selected region in order to get sampled points in the step following
userVector=zeros(numberUserPoints,2);
for s=1:numberUserPoints
    userVector(s,1)=(Xcor(s)-centerX)/circlerad;
    userVector(s,2)=(Ycor(s)-centerY)/circlerad;
end

%Create a matrix to hold the two most "extreme" user points. These points
%are essentially mark the boundary of the user selected region
endPts=zeros(2,2);

%These two variables to hold the smallest and largest angle created by the
%user selected points
largestAngle=0;
leastAngle=360;

%Go through the array of user selected points to determine which has the
%largest angle and which has the smallest
for i1=1:(numberUserPoints),
        
        %Get the angle of a vector by using the atan2d function. Add 360 to
        %the result in order to create a unit circle that would go form 0 
        %to 360 degrees.
        first=(atan2d(userVector(i1,2),userVector(i1,1)))+180;
         
        %Check to see if the angle is larger or smaller than the most
        %recently determined largest and least angle and update the angles
        %if true. Set the point into the endPts matrix if the point is one
        %of the boundary points.
            if (first > largestAngle)
                endPts(2,1)=Xcor(i1);
                endPts(2,2)=Ycor(i1);
                largestAngle=first;
            end
            
            if (first < leastAngle)
                endPts(1,1)=Xcor(i1);
                endPts(1,2)=Ycor(i1);
                leastAngle=first;
            end
end

%Don't forget to check the angle of the last user selected point!!
lastcheck=(atan2d(userVector(numberUserPoints,2), ...
    userVector(numberUserPoints,1)))+180;
if (lastcheck < leastAngle)
    endPts(1,1)=Xcor(numberUserPoints);
    endPts(1,2)=Ycor(numberUserPoints);
    leastAngle=lastcheck;
end
if (lastcheck > largestAngle)
    endPts(2,1)=Xcor(numberUserPoints);
    endPts(2,2)=Ycor(numberUserPoints);
    largestAngle=lastcheck;
end

%Indicate the two points that mark the boundary of the user selected region
%with a bright green star
plot( endPts(1,1), -endPts(1,2), 'g*', 'MarkerSize', 25 );
plot( endPts(2,1), -endPts(2,2), 'g*', 'MarkerSize', 25 );

%Two vectors to hold our sampled points from within the user selected
%region
sampleX=[];
sampleY=[];

%Round the angles to make them integers and add the 180 degrees to negate
%the effect of adding prior
endA=round(leastAngle-180);
endB=round(largestAngle-180);

%Edge case when the user selects points on the right side that is below the
%x-axis of the circle and points above it. We need to get sample points
%from that angle that is below to the horizontal axis of the circle and the
%sample points from 0 to the most rightward point(which is now a new
%boundary for the user-defined region).
if ( largestAngle > (leastAngle + 180))
 
plot(Xcor(numberUserPoints),-Ycor(numberUserPoints),'b*','MarkerSize',25 );
plot(Xcor(1),-Ycor(1),'y*','MarkerSize',25 );

firstcheck=(atan2d(userVector(1,2),userVector(1,1)))+180;

    for b = (lastcheck:5:360)
        %Set angle to b so we don't change a in the for-loop
        angle=round(b-180);
        %In case the angle is in the third or fourth quadrant, we want to
        %add 360 to make the angles compatiable with the sind and cosd 
        %functions in MATLAB
        if (angle<0)
            angle=angle+360;
        end
        
        %To get the X and Y values of the points that are in between the 
        %point of our two end points, we just multiply the sind(angle) by 
        %the radius and add the center Y to get the Y coordinate. Same with 
        %the X coordinate, but we would use cosd(angle).
        newY=(circlerad*(sind(angle)))+centerY;
        newX=(circlerad*(cosd(angle)))+centerX;
        %Set this point in the new matrix of sample points
        sampleX=vertcat(sampleX,newX);
        sampleY=vertcat(sampleY,newY);
        
    end
    
    %From 0 to and onwards on the boundary
    for c = (0:5:firstcheck)
        angle=round(c-180);
        if (angle<0)
            angle=angle+360;
        end
        newY=(circlerad*(sind(angle)))+centerY;
        newX=(circlerad*(cosd(angle)))+centerX;
        sampleX=vertcat(sampleX,newX);
        sampleY=vertcat(sampleY,newY);
    end
    
%No edge case, go on as usual.
else
    %Iterate through the angles in between the angles that have been marked 
    %by the two end points. I use a step of 5.
    for a = (endA:5:endB)
        %Set angle to a so we don't change a in the for-loop
        angle=a;
        %In case the angle is in the third or fourth quadrant, we want to
        %add 360 to make the angles compatiable with the sind and cosd 
        %functions in MATLAB
        if (angle<0)
            angle=angle+360;
        end
        %To get the X and Y values of the points that are in between the 
        %point of our two end points, we just multiply the sind(angle) by 
        %the radius and add the center Y to get the Y coordinate. Same with 
        %the X coordinate, but we would use cosd(angle).
        newY=(circlerad*(sind(angle)))+centerY;
        newX=(circlerad*(cosd(angle)))+centerX;
        %Set this point in the new matrix of sample points
        sampleX=vertcat(sampleX,newX);
        sampleY=vertcat(sampleY,newY);
    end
    
end

%Get the number of sampled points
sampleNo=size(sampleX);

%Plot all of the sample points on the circle
for d = 1:sampleNo
    plot(sampleX(d),-sampleY(d),'r.','MarkerSize',20);
end

% Get M, which contains the surface normals of our sampled points
N=ones(sampleNo,3);
for m=1:sampleNo
    N(m,1)=((sampleX(m)-centerX)/circlerad);
    N(m,2)=((sampleY(m)-centerY)/circlerad);
end

%Get the image intensities at each sampled point from our grayscaled image
intensityValue=zeros(sampleNo,1);
for gs = 1:sampleNo
    intensityValue(gs,1) = grayPix(round(-sampleY(gs)),round(sampleX(gs)));
end
%Change the type to double so we can perform the later steps
intensityValue=double(intensityValue);

%Get v through least squares
transN = N.';
dualN=(transN*N);
invN= inv(dualN);
lastN=invN*transN;
v=lastN*intensityValue;

%Find the angle and direction of the light source
lightX=v(1,1);
lightY=v(2,1);
angleInRadians=atan(v(2,1)/v(1,1));
angleInDegrees = radtodeg(angleInRadians);

%Get the ambient light term
ambient=v(3,1);

%Show results in textbox
results = ['X-component of the direction to the light is ',...
    'source are: ' num2str(lightX) '. ' 'Y-component of the'...
    ' direction to the light is: ' num2str(lightY) '. '...
    'The angle of the light source is: ' num2str(angleInDegrees) '. ' ...
    'The ambient light is: ' num2str(ambient) '.'];
uiwait(msgbox(results, 'Direction of Light and Ambient Term'));

