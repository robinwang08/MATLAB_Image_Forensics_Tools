%Robin Wang
%Helper function derived to fit a circle to the user
%selected points
function results = fitcirc (X,Y)

%Set the radius, and center coordinates to 8. Just an initial guess
r(1,1)=8;
h(1,1)=8;
k(1,1)=8;

%Call on fminsearch to optimize error function that we set as our circle
%equation
getCircle=fminsearch(@(z) opti(z),[r,h,k]);


%Function to be optimized through fminsearch
    function least = opti(z)
        
        %Get the radius and center coordinates
        cr=z(1,1);
        ch=z(1,2);
        ck=z(1,3);
        
        %Go through each of the user selected points and use them in our
        %circle equation
        numberUserPoints=size(X);
        least=0;
        for lsm=1:numberUserPoints,
            %Circle equation as error function to be minimized
            d=((X(lsm)-ch)^2 + (Y(lsm)-ck)^2 - (cr)^2)^2;
            least=least+d;
        end
    end

%Return our results
results=getCircle;
end