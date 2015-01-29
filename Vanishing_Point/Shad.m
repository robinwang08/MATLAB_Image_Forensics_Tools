%Robin Wang
%CS 89 Photo Forensics Project 1

%Function that runs the forensic analysis tool that computes the vanishing
%point from user selected lines
function Shad(photoName)

%Display the image
imshow(photoName,'Border','tight')
hold on

%Ask the user to input number of lines to be drawn using a dialogue box
prompt = {'How many lines do you want to select?'};
dlg_title = 'Number of Lines';
num_lines = 1;
def = {'2'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
numberUserLines=str2num(answer{1,1});

%Two few lines
%Exit the program if the user doesn't choose to select at least 2 lines
if (numberUserLines < 2)
    error('Need at least 2 lines for analysis!')
end

%Double the number of lines the user wants to input and create an array to
%hold the coordinates of the soon-to-be inputted lines
twiceLines=2*numberUserLines;
Xcor=zeros(twiceLines,1);
Ycor=zeros(twiceLines,1);

%Helper variable to help collect the coordinate data
coorNumb=0;
for i=1:(numberUserLines),
    %Get the coordinates of each of the points selected by the user
    %Negate the Y-value as it is a positive value, but I want to treat the
    %entire image as the fourth quadrant of the coordinate system instead
    %of using the pixel coordinate system
    coorNumb=coorNumb+1;
    [a,b]=ginput(2);
    Xcor(coorNumb)=a(1);
    Ycor(coorNumb)=-b(1);
    coorNumb=coorNumb+1;
    Xcor(coorNumb)=a(2);
    Ycor(coorNumb)=-b(2);
    
    %Plot each of the lines the user selects
    plot(a,b,'Color','b','Linewidth', 2);
end

%Edge cases - Points
%Helper variable to help check coordinate data
coorNumb=0;
%If the user selected line is a point, exit.
for poi=(1:numberUserLines),
    coorNumb=coorNumb+1;
    if ((Xcor(coorNumb)==Xcor(coorNumb+1))&& ...
            (Ycor(coorNumb)==Ycor(coorNumb+1)))
        error('Detected a point instead of an user selected line.')
    end
    coorNumb=coorNumb+1;
end

%Edge cases - Vertical Lines
%Helper variable to help check coordinate data
coorNumb=0;
%If the line is vertical, change the value in the first column to 1 and 
%record the value of that x in the second column
VertLine=zeros(numberUserLines,2);
for vert=(1:numberUserLines),
    coorNumb=coorNumb+1;
    if (Xcor(coorNumb)==Xcor(coorNumb+1))
        VertLine(vert,1)=1;
        VertLine(vert,2)=Xcor(coorNumb);
    end
    coorNumb=coorNumb+1;
end

%Matrix to hold the slopes of each line
M=zeros(numberUserLines, 2);
%Counter to help get the slopes and intersections
LineCounter=0;
for j=1:(numberUserLines),
    %Get the slopes of each line and insert into nx2 matrix
    LineCounter = LineCounter+1;
    M(j,2)=1;
    M(j,1)= -1*((Ycor(LineCounter+1)-Ycor(LineCounter))/...
        (Xcor(LineCounter+1)-Xcor(LineCounter)));
    LineCounter=LineCounter+1;
end

%Edge Cases - Parallel Lines
%Counter to keep track of the number of parallel lines
parallelLines=1;
for par2=2:numberUserLines,
    if (M(1,1)== M(par2,1))
        parallelLines=parallelLines+1;
    end
end
%All of the user selected lines are parallel to each other; there is error
if (parallelLines==numberUserLines)
    error(['All user selected lines are parallel to each other.',...
        'The vanishing point is infinitely far away, or there is none.'])
end

%Matrix to hold the intersections
B=zeros(numberUserLines,1);
for k=1:numberUserLines,
    % Get the intersections for each line
    B(k,1)=Ycor(2*k)+(M(k,1)*Xcor(2*k));
end

%Adjust for the vertical lines by changing the -mn value to 1, the 1
%coefficient in the second column of the slope matrix to 0, and the 
%intercept to the value of the vertical line, which has the form X=xn, 
%with xn being the X-coordinate of any point on the vertical line
for adjust=1:numberUserLines,
    if (VertLine(adjust,1)==1)
        M(adjust,1)=1;
        M(adjust,2)=0;
        B(adjust,1)=VertLine(adjust,2);
    end
end

%Reset the image to plot all of the user selected lines as well as the
%lines determined by the least-squares method
hold off
imshow(photoName,'Border','tight')
hold on;

%Plot the user selected non-vertical lines
for l=1:numberUserLines,
    if(VertLine(l,1)~=1)
        userline=refline(M(l,1),-B(l,1));
        set(userline, 'Color', 'b', 'Linewidth', 2)
    end
end
%Plot the vertical user lines
for n=1:(numberUserLines),
    if(VertLine(n,1)==1)
        yL = get(gca,'YLim');
        line([B(n,1) B(n,1)],yL,'Color','b', 'Linewidth', 2);
    end
end

%When you have more than two lines, call upon the least-squares method to
%optimize the slope and intercept values to determine the optimal vanishing
%point as well "wiggle" the user lines to fit that point
if(numberUserLines>2)
    
    %Optimizing the objective function
    %Pass in the matrix containing the slopes as well as the matrix
    %containing the intersections of the user selected lines
    %Return the new slopes and intersections that is determined by the
    %least squares method
    wiggledLines=fminsearch(@(z) opti(z),[M,B]);
    
    %Plot the "wiggled" vertical lines
    for n=1:numberUserLines,
        if(VertLine(n,1)==1)
            yL = get(gca,'YLim');
            line([wiggledLines(n,3) wiggledLines(n,3)],yL,'Color','r',...
                'Linewidth', 2);
        end
    end
    %Plot the "wiggled" non-vertical lines determined after optimization
    for m=1:numberUserLines,
        if(VertLine(m,1)~=1)
            userline=refline(wiggledLines(m,1),-wiggledLines(m,3));
            set(userline, 'Color', 'r', 'Linewidth', 2)
        end
    end
end

%Helper function that contains the objective function that is optimized by
%minimizing the deviation of all pairs of line intersections from their
%center of mass and the minimazation of the deviation of the user selected
%points from initial values
%Function that the fminsearch will attempt to optimize
    function least = opti(z)
        
        %Get the matrix and intercepts from the single matrix that is
        %passed through by the fminsearch function
        mSlope(:,1)=z(:,1);
        mSlope(:,2)=z(:,2);
        Bint(:,1)=z(:,3);
        
        %Find the intersection/vanishing point of all lines
        transM = mSlope.';
        dualM=(transM*mSlope);
        invM= inv(dualM);
        lastM=invM*transM;
        thePoint=lastM*Bint;
        
        %Least squares method: calculate the distance between the lines and
        %the point
        least=0;
        for lsm=1:numberUserLines,
            %If any of the lines are vertical, calculate the horizontal
            %difference in distance instead of the vertical difference
            if(VertLine(lsm,1)==1)
                least=least+((Bint(lsm,1)-thePoint(1,1))^2);
            else
                least=least+((((-mSlope(lsm,1)*thePoint(1,1))+...
                    Bint(lsm,1))-thePoint(2,1))^2);
            end
        end
    end

%Finish entire function
end