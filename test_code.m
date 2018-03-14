clc, clear;
url = 'http://192.168.43.1:8080/shot.jpg';


%% Clear environment vars
% Image Pre-processing and plane trisection
tic;
original_img = imread(url);
convolver_map = [-1, -1, -1, -1,-1;-1, -1, -1, -1,-1;-1, -1, 23.8, -1,-1;-1, -1, -1, -1,-1;-1, -1, -1, -1,-1];
image = imfilter(original_img, convolver_map, 'conv');
fudgeFactor = 4;
se90 = strel('line', 2, 90);
se0 = strel('line', 1, 0);

rmat = image(:,:,1);
gmat = image(:,:,2);
bmat = image(:,:,3);
%% Apply canny+Image Dilation+Filters on all RGB planes

%%rmat canny
[~, threshold] = edge(rmat, 'canny');
BWs = edge(rmat,'canny', threshold * fudgeFactor);
BWsdilr = imdilate(BWs, [se90 se0]);
%figure, imshowpair(BWsdilr, BWs, 'montage'), title('dilated R gradient mask');

%%gmat canny
[~, threshold] = edge(gmat, 'canny');
BWs = edge(gmat,'canny', threshold * fudgeFactor);
BWsdilg = imdilate(BWs, [se90 se0]);
%figure, imshowpair(BWsdilg, BWs, 'montage'), title('dilated G gradient mask');

%%bmat canny
[~, threshold] = edge(bmat, 'canny');
BWs = edge(bmat,'canny', threshold * fudgeFactor);
BWsdilb = imdilate(BWs, [se90 se0]);
%figure, imshowpair(BWsdilb, BWs, 'montage'), title('dilated B gradient mask');

%% Merge all dilated planes and count circles

c=BWsdilr+BWsdilg+BWsdilb;
c = ~c;

detectCircles = @(x) imfindcircles(x,[10 25],'Sensitivity',0.84, 'EdgeThreshold',0.0, 'Method','PhaseCode', 'ObjectPolarity','Bright');
[centers, radii, metric] = detectCircles(c);

%% Mark circles on the image
imshow(original_img);
viscircles(centers, radii,'LineStyle','-.', 'LineWidth',1.0);

for k = 1:length(metric)
    
    metricB1_string = sprintf('%d',k);
    text(centers(k,1),centers(k,2),metricB1_string,'color','y','HorizontalAlignment', 'center','VerticalAlignment', 'middle');
end
number=length(centers);
timeElapsed=toc; 
%Execution Time Calculation
%FileCreation
fileID = fopen('log.txt','wt')
fprintf(fileID,'Total Straws: %d \n',number);
fprintf(fileID,'\nExecution Time in Program: %d seconds',timeElapsed);
fclose(fileID);
