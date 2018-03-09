# TCH_testcode
Implementer: MATLAB
1. The script/program initially captures the images from a webcam or a smartphone camera and pre-processes the image, by applying median noise filters.
2. Program then 'segregates' the image in RGB to individual planes. (This heavily affects identification of yellow/light color straws because the fundamental process of rgb2gray doesn't capture those straws accurately)
3. After applying 'sobel' edge detection algorithm with parameterized 'fudge factor', the script creates 2 'structuring elements' for the 'dilation of the image'.
4. Image edges are smoothened by dilation with the structuring elements created above.
5. All the RGB planes are evaluated separately and then 'combined' to avoid any information that is lost.
6. Image isthen binarized.
7. Circles are counted using Phase Code method (Two Stage is more prone to noise) and Hough Transform.
This results in a 90-95% accuracy for a bundle of 60-70 straws, and upto 100% for 40-50 straws.

Proposed solution for best-in-class accuracy:
Implementer: Convolutional Neural Networks(CNN)
1. The script would require training of a CNN for edge detection. But, since it is not feasible to create the huge 'dataset' it requires, in such a time to train the network. Hence,it could not be prototyped to submit before 16th March.
2. The CNN trained would generate excellent edge detected output, and can be directly used to count circles.

The only problem with standalone filters is that they are 'blind'. They don't see the image, but are plain mathematical transforms. CNNs when implemented, can identify the required regions of interests(ROIs) with greater accuracy.



