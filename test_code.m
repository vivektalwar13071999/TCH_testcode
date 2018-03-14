
%% Clear environment vars
% Image Pre-processing and plane trisection

tic;
clear all;
close all; 

image = imread('3.jpg');
image = imsharpen(image, 'Amount',4)
number=0;
fudgeFactor = 0.9;
se90 = strel('line', 2, 90);
se0 = strel('line', 1, 0);
%Plane Trisection
rmat = image(:,:,1);
gmat = image(:,:,2);
bmat = image(:,:,3);
%% Apply sobel+Image Dilation+Filters on all RGB planes

%%rmat sobel
[~, threshold] = edge(rmat, 'sobel');
BWs = edge(rmat,'sobel', threshold * fudgeFactor);
BWsdilr = imdilate(BWs, [se90 se0]);
BWsdilr = medfilt2(BWsdilr);

%figure, imshowpair(BWsdilr, BWs, 'montage'), title('dilated R gradient mask');

%%gmat sobel
[~, threshold] = edge(gmat, 'sobel');
BWs = edge(gmat,'sobel', threshold * fudgeFactor);
BWsdilg = imdilate(BWs, [se90 se0]);
BWsdilg = medfilt2(BWsdilg);

%figure, imshowpair(BWsdilg, BWs, 'montage'), title('dilated G gradient mask');
%%bmat sobel
[~, threshold] = edge(bmat, 'sobel');
BWs = edge(bmat,'sobel', threshold * fudgeFactor);
BWsdilb = imdilate(BWs, [se90 se0]);
BWsdilb = medfilt2(BWsdilb);

%figure, imshowpair(BWsdilb, BWs, 'montage'), title('dilated B gradient mask');

%%view all
%% Merge all dilated planes and count circles 

c=BWsdilr+BWsdilg+BWsdilb;
c = im2bw(c);
c=~c;
[centers, radii] = imfindcircles(c,[40 80], 'ObjectPolarity','dark', ...
          'Sensitivity',0.92,'Method','twostage');
h = viscircles(centers,radii);
disp(size(centers));
number=number+length(centers);
timeElapsed=toc; %Execution Time Calculation
%FileCreation
fileID = fopen('strawcounter.txt','w')
fprintf(fileID,'The number of straws counted: %d \n',number);
fprintf(fileID,'\nExecution Time in Program: %d \n',timeElapsed);
fclose(fileID);

