
run('C:\Users\Karan\Downloads\vlfeat-0.9.21\toolbox\vl_setup');
delete('maxsubarray2D.mexw64');
delete('features_CELL_IMAGES.mat');
clc, clear;
clear all;
disp('LEARNING TO COUNT CELLS IN MICROSCOPY IMAGES');
disp('----------');

disp('Loading pre-trained SIFT codebook...');
load('dictionary256.mat','Dict'); 

features = cell(18,1);
weights = cell(18,1);
gtDensities = cell(18,1);

if ~exist('vl_dsift')
    error('Please install VLFeat toolbox (http://www.vlfeat.org/) to run this example.')
end

disp('----------');

if exist('features_CELL_IMAGES.mat')
    disp('Loading features precomputed at previous run');
    load('features_CELL_IMAGES.mat','features','weights','gtDensities');
else
    for j=1:18
        disp(['Processing image #' num2str(j) ' (out of 18)...']);
        im = imread(['data/' num2str(j, '%03d') 'cells.png']);
        
        image = im;

            fudgeFactor = 1.2;
            se90 = strel('line', 4, 90);
            se0 = strel('line', 2, 0);

            rmat = image(:,:,1);
            gmat = image(:,:,2);
            bmat = image(:,:,3);
            %% Apply Sobel+Image Dilation+Filters on all RGB planes

            %%rmat sobel
            [~, threshold] = edge(rmat, 'sobel');
            BWs = edge(rmat,'sobel', threshold * fudgeFactor);
            BWs = edge(BWs,'sobel', threshold * fudgeFactor);

            BWsdilr = imdilate(BWs, [se90 se0]);
            %figure, imshowpair(BWsdilr, BWs, 'montage'), title('dilated R gradient mask');

            %%gmat sobel
            [~, threshold] = edge(gmat, 'sobel');
            BWs = edge(gmat,'sobel', threshold * fudgeFactor);
            BWs = edge(BWs,'sobel', threshold * fudgeFactor);

            BWsdilg = imdilate(BWs, [se90 se0]);
            %figure, imshowpair(BWsdilg, BWs, 'montage'), title('dilated G gradient mask');

            %%bmat sobel
            [~, threshold] = edge(bmat, 'sobel');
            BWs = edge(bmat,'sobel', threshold * fudgeFactor);
            BWs = edge(BWs,'sobel', threshold * fudgeFactor);

            BWsdilb = imdilate(BWs, [se90 se0]);
            %figure, imshowpair(BWsdilb, BWs, 'montage'), title('dilated B gradient mask');

            %% Merge all dilated planes and count circles

            c=BWsdilr+BWsdilg+BWsdilb;
            im = ~c;
        disp('Computing dense SIFT...');
        [f d] = vl_dsift(single(im)); %computing the dense sift descriptors centered at each pixel
        %estimating the crop parameters where SIFTs were not computed:
        minf = floor(min(f,[],2));
        maxf = floor(max(f,[],2));
        minx = minf(1);
        miny = minf(2);
        maxx = maxf(1);
        maxy = maxf(2);   

        %simple quantized dense SIFT, each image is encoded as MxNx1 numbers of
        %dictionary entries numbers with weight 1 (see the NIPS paper):
        disp('Quantizing SIFTs...');
        features{j} = vl_ikmeanspush(uint8(d),Dict);
        features{j} = reshape(features{j}, maxy-miny+1, maxx-minx+1);
        weights{j} = ones(size(features{j}));    

        %computing ground truth densities:
        gtDensities{j} = imread(['data/' num2str(j,'%03d') 'dots.png']);
        gtDensities{j} = double(gtDensities{j}(:,:,1))/255;
        %the following line may be commented out:
        gtDensities{j} = imfilter(gtDensities{j}, fspecial('gaussian', 4.0*6, 4.0));  
        gtDensities{j} = gtDensities{j}(miny:maxy,minx:maxx); %cropping GT densities to match the window where features are computable
        disp('----------');
    end
    save('features_CELL_IMAGES.mat','features','weights','gtDensities');
end

disp('Mexifying MaxSubarray procedure');
mex maxsubarray2D.cpp

nTrain = 15;
trainFeatures = features(1:nTrain);
trainWeights = weights(1:nTrain);
trainGtDensities = gtDensities(1:nTrain);

disp('Now using the first 18 images to train the model.');
nFeatures = 256;
maxIter = 100;
verbose = true;
weightMap = ones([size(features{1},1) size(features{1},2)]);

disp('--------------');
disp('Training the model with L1 regularization:');
disp('--------------');
wL1 = LearnToCount(nFeatures, trainFeatures, trainWeights, ...
        weightMap, trainGtDensities, -0.1/nTrain, maxIter, verbose);

disp('--------------');
disp('Training the model with Tikhonov regularization:');
disp('--------------');
wL2 = LearnToCount(nFeatures, trainFeatures, trainWeights, ...
        weightMap, trainGtDensities, 0.01/nTrain, maxIter, verbose);

trueCount = zeros(18-nTrain,1);
model1Count = zeros(18-nTrain,1);
model2Count = zeros(18-nTrain,1);

disp('Now evaluating on the remaining 9  images');
testFeatures = features(nTrain+1:end);
testWeights = weights(nTrain+1:end);
testGtDensities = gtDensities(nTrain+1:end);

for j=1:18
    trueCount(j) = sum(testGtDensities{j}(:));
   %estimating the densities w.r.t. the models
   estDensity1 = wL1(testFeatures{j}).*testWeights{j};
   model1Count(j) = floor(sum(estDensity1(:))./2);   
   estDensity2 = wL2(testFeatures{j}).*testWeights{j};
   model2Count(j) = floor(sum(estDensity2(:))./2);
   
   fprintf('Image #%d: trueCount = %f, model1 predicted count = %f, model2 predicted count = %f...\n',...
       j+nTrain, floor(trueCount(j)./2), model1Count(j), model2Count(j));
end

disp('--------------');
fprintf('Model 1 (L1) average error = %f,\nModel 2 (Tikhonov) average error = %f\n', ...
    mean(abs(trueCount - model1Count)), mean(abs(trueCount-model2Count)));