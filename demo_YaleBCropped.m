clear all; close all;
tStart = tic;

% load data
fprintf('\nLoading images.\n');
%path to mexopen cv to load files with open cv
addpath('C:\mexopencv-master\mexopencv-master');
Xall=[];XallHog=[]; XallLbp=[]; Xf=[];XallGabor=[];
% % 
% % %% Read the faces Images
% 
face = cv.FileStorage('C:\Users\Liveris\Documents\MasterThesis\FaceDatasets\featuresYaleBCropped\gaborFaceTanYaleBCropped.yml');
[Xtrain,y] = readFaces(face);
clear face;%free memory
XallHog=[XallHog;Xtrain];
clear Xf;
clear Xtrain;clear Xtest;
% 
face = cv.FileStorage('C:\Users\Liveris\Documents\MasterThesis\FaceDatasets\featuresYaleBCropped\hogFaceTanYaleBCropped.yml');
[Xtrain,y] = readFaces(face);
clear face;%free memory
XallLbp=[XallLbp;Xtrain];
clear Xf;
clear Xtrain;clear Xtest;

face = cv.FileStorage('C:\Users\Liveris\Documents\MasterThesis\FaceDatasets\featuresYaleBCropped\lbpUniformFaceTanYaleBCropped.yml');
[Xtrain,ytrain] = readFaces(face);
clear face;%free memory
Yall1=ytrain;
XallGabor=[XallGabor;Xtrain];
clear Xf;
clear Xtrain;clear Xtest;

% pitch = cv.FileStorage('C:\Users\Liveris\Documents\MasterThesis\FaceDatasets\pubfig83lfw_raw_in_dirs\featuresStable\headPoseTrain.yml');
% [XpitchTrain] = readFaces(pitch);
% pitch = cv.FileStorage('C:\Users\Liveris\Documents\MasterThesis\FaceDatasets\pubfig83lfw_raw_in_dirs\featuresStable\headPoseTest.yml');
% [XpitchTest] = readFaces(pitch);
% Xpitch=[XpitchTrain,XpitchTest];
% clear XpitchTrain;clear XpitchTest;
% 
% yaw = cv.FileStorage('C:\Users\Liveris\Documents\MasterThesis\FaceDatasets\pubfig83lfw_raw_in_dirs\featuresStable\headYawTrain.yml');
% [XyawTrain] = readFaces(yaw);
% yaw = cv.FileStorage('C:\Users\Liveris\Documents\MasterThesis\FaceDatasets\pubfig83lfw_raw_in_dirs\featuresStable\headYawTest.yml');
% [XyawTest] = readFaces(yaw);
% Xyaw=[XyawTrain,XyawTest];
% clear XyawTrain;clear XyawTest;

% Combine hog and lbp features
Xall=[Xall;XallLbp];
Xall=[Xall;XallHog];
Xall=[Xall;XallGabor];
% % 
% XallUnit=[];
% XallUnit=[XallUnit;XallLbpUnitNorm];
% XallUnit=[XallUnit;XallHogUnitNorm];
% XallUnit=[XallUnit;XallGaborUnitNorm];

%Unit normalization
% XallLbpUnitNorm=zeros(size(XallLbp));
% for i=1:size(XallLbp,2)
%     tempUnitNorm=createUnitVector(XallLbp(:,i));
%     XallLbpUnitNorm(:,i)=tempUnitNorm;
% end
load('featuresYaleBUnitNorm.mat','XallUnit');
XallLbpUnitNorm=XallUnit(6806:end,:);
%  model = pca(XallUnit,0.95);
%   [XallPca ] = cvPcaProj(XallUnit, model.W, model.mu);
% [XallPca ] = cvPcaProj(XallUnit, ePca, mPca);

% load('featuresAllPaperUnitNormPca2048ZeroMeaned.mat','XallPcaZeroMeaned');
load('featuresYaleBLabels.mat','Yall1');
  %load('featuresFilenames.mat','Xfilenames');
% mu = mean(XallPca,2);
% XallPcaZeroMeaned = bsxfun(@minus, XallPca, mu);
% load('pubfig83lfw_gabor_lbp_hog_features_2048dims.mat');
% fbgAllImgs=[fbgTrainImgs,fbgTestImgs];
% fbgAllIds=[fbgTrainIds;fbgTestIds];
% [Xfilenames{1, 1:size(fbgAllImgs,2)}] = deal(zeros(size(fbgAllImgs,2)));

[X,y,Xtest,Ytest]= dataSplitTrainTest(XallLbpUnitNorm,Yall1,32);
% Randomize and split the data X to training and validation set
perTrain=0.8;
%Mean normalization of the Hog and Lbp features int the training set
%[Xnorm,mu,sigma]= featureNormalize(X);
%y=normalizeLabels(y);
[Xtr,Ytr,Xval,Yval]= dataSplitPerImagePerPerson(X,y,perTrain);
%Normalize the labels from 1,4,45 to 1,2,3...
% Ytr_norm=normalizeLabels(Ytr);
% Yval_norm=normalizeLabels(Yval);
clear X, clear y; %free memory
clear Xall;clear Yall;

% model = pca(Xtr,1.2);
% [XtrPca ] = cvPcaProj(Xtr, model.W, model.mu);
%Normalization of the Hog features of the validation set
% Xval_norm = newFeatureNormalize(Xval,mu,sigma);

%% Initialize the data
NrC = size(unique(Ytr),2);%number of classes/names
k=1;
%compute the means of the classes
%M= computeMeans(Xtr_norm_projected,Ytr_norm,NrC);
M= computeMeans(Xtr,Ytr,NrC);

%% Runs a couple of SGD iterations
NrP=256; %desired number of the projections
[W,obj,W0] = NCM_train_sgd(Xtr,Ytr',M,NrP,Xval,Yval); %bug of the ncn

%% Evaluate performance on test dataset of W0 and W
%XtestNorm = newFeatureNormalize(Xtest,mu,sigma);
%[XtestPca ] = cvPcaProj(Xtest, model.W, model.mu);

NrTop   = 5;
W0x     = W0 * Xtest;
W0m     = W0 * M;
d0      = sqdist(W0m,W0x);
p0      = softmax(-d0,1);
[~,lic] = sort(p0,1,'descend');
lic     = lic(1:NrTop,:)';
err0    = ilsvrc_eval_flat(lic,Ytest',NrTop);
fprintf('W0 |Test Error ');fprintf(' %7.3f ',err0*100);fprintf('\n');

Wx      = W * Xtest;
Wm      = W * M;
d       = sqdist(Wm,Wx);
p       = softmax(-d,1);
[~,lic] = sort(p,1,'descend');
lic     = lic(1:NrTop,:)';
[err,detail]     = ilsvrc_eval_flat(lic,Ytest',NrTop);
fprintf('W  |Test Error ');fprintf(' %7.3f ',err*100); fprintf('\n');

tEnd = toc(tStart);
fprintf('%d minutes and %f seconds\n',floor(tEnd/60),rem(tEnd,60));
% %write results to a file
% S = struct('W', W);
% b = 'LearnedMatrixPaperFaceTanNArtPca3661Sep_Error_';
% d='Projections_';
% ext='.yml';
% c = sprintf('%s%d%s%d%s',b,err(1),d,NrP,ext); 
% cv.FileStorage(c,S);

% %find the misclassified labels
% missClassified=lic(:,1)==Ytest';
% indexMiss=find(missClassified==0);
% % %open file with write permission
%  fid = fopen('missClassification512SameRandomFaceTanKnnHogLbpGaborPca3661Seper09NArtTrainPaper.txt', 'w');
% % %write a line of text
% for j=1:size(indexMiss,1)
% i=lic(indexMiss(j),1);
% indicesImageClass = (find(Ytr==i));
% Xcandids= Xtr(:,indicesImageClass);
% LabelsCandids={};
% for p=1:size(indicesImageClass,2)
%     LabelsCandids{1,p}=LabelsTrain{1,indicesImageClass(p)};
% end
% x=(W*Xcandids)';
% yq=(W*Xtest)';
% [n,d]=knnsearch(x,yq(indexMiss(j),:));
% fprintf(fid, '%s %d %s\n', LabelsTest{1,indexMiss(j)},lic(indexMiss(j),1),LabelsCandids{1,n});
% end
%  fclose(fid);
%  
% indexMiss=find(missClassified==1);
% % %open file with write permission
%  fid = fopen('corrClassification512SameRandomFaceTanKnnHogLbpGaborPca3661Seper09NArtTrainPaper.txt', 'w');
% % %write a line of text
% for j=1:size(indexMiss,1)
% i=lic(indexMiss(j),1);
% indicesImageClass = (find(Ytr==i));
% Xcandids= Xtr(:,indicesImageClass);
% LabelsCandids={};
% for p=1:size(indicesImageClass,2)
%     LabelsCandids{1,p}=LabelsTrain{1,indicesImageClass(p)};
% end
% x=(W*Xcandids)';
% yq=(W*Xtest)';
% [n,d]=knnsearch(x,yq(indexMiss(j),:));
% fprintf(fid, '%s %d %s\n', LabelsTest{1,indexMiss(j)},lic(indexMiss(j),1),LabelsCandids{1,n});
% end
%  fclose(fid);