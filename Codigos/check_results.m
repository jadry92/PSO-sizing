close all;
clc;
clear all;

load('cm_good.mat');
CM_good = CM;
load('cm_new.mat');

min(CM_good-CM)
max(CM_good-CM)

figure;
imagesc(CM_good-CM);