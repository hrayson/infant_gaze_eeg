function clusters=create_cluster_structure()

clusters=[];

% v1
%clusters(1).name='O1';
%clusters(1).channels=[69, 70, 73, 74];
%clusters(2).name='O2';
%clusters(2).channels=[82, 83, 88, 89];
%clusters(3).name='C3';
%clusters(3).channels=[30, 31, 36, 37, 41, 42, 53, 54];
%clusters(4).name='C4';
%clusters(4).channels=[79, 80, 86, 87, 93, 103, 104, 105];
%clusters(5).name='P3';
%clusters(5).channels=[47, 51, 52, 60];
%clusters(6).name='P4';
%clusters(6).channels=[86, 92, 96, 97];
%clusters(7).name='F3';
%clusters(7).channels=[19, 23, 24, 27, 28];%clusters(8).name='F4';
%clusters(8).channels=[3, 4, 117, 123, 124];


% v2
%clusters(1).name='O1';
%clusters(1).channels=[70, 74, 69, 73];
%clusters(2).name='O2';
%clusters(2).channels=[83, 89, 82, 88];
%clusters(3).name='Cmedial';
%clusters(3).channels=[106, 80, 55, 31, 7];
%clusters(4).name='C3a';
%clusters(4).channels=[30, 37, 54, 36, 42, 41];
%clusters(5).name='C3b';
%clusters(5).channels=[30, 31, 36, 37, 41, 42, 54];
%clusters(6).name='C4a';
%clusters(6).channels=[79, 87, 93, 103, 104, 105];
%clusters(7).name='C4b';
%clusters(7).channels=[79, 80, 87, 93, 103, 104, 105];
%clusters(8).name='P3';
%clusters(8).channels=[47, 52, 60, 51, 59];
%clusters(9).name='P4';
%clusters(9).channels=[85, 92, 98, 97, 91];
%clusters(10).name='F3';
%clusters(10).channels=[19, 20, 23, 24, 27, 28];%clusters(11).name='F4';
%clusters(11).channels=[3, 4, 118, 117, 123, 124];


%v3
% clusters(1).name='O1';
% clusters(1).channels=[70, 74, 69];
% clusters(2).name='O2';
% clusters(2).channels=[83, 89, 82];
% clusters(3).name='Cmedial';
% clusters(3).channels=[106, 80, 55, 31, 7];
% clusters(4).name='C3a';
% clusters(4).channels=[30, 37, 53, 54, 36, 42, 41];
% clusters(5).name='C3b';
% clusters(5).channels=[30, 31, 36, 37, 41, 42, 54];
% clusters(6).name='C4a';
% clusters(6).channels=[79, 86, 87, 93, 103, 104, 105];
% clusters(7).name='C4b';
% clusters(7).channels=[79, 80, 87, 93, 103, 104, 105];
% clusters(8).name='P3';
% clusters(8).channels=[47, 52, 60, 51, 59];
% clusters(9).name='P4';
% clusters(9).channels=[85, 92, 98, 97, 91];
% clusters(10).name='F3';
% clusters(10).channels=[19, 23, 24, 27, 28];
% clusters(11).name='F4';
% clusters(11).channels=[3, 4, 117, 123, 124];


% v4
% clusters(1).name='O1';
% clusters(1).channels=[70, 74, 69, 73];
% clusters(2).name='O2';
% clusters(2).channels=[83, 89, 82, 88];
% clusters(3).name='Cmedial';
% clusters(3).channels=[106, 80, 55, 31, 7];
% clusters(4).name='C3';
% clusters(4).channels=[29, 30, 36, 37, 41, 42];
% clusters(5).name='C4';
% clusters(5).channels=[111, 87, 93, 103, 104, 105];
% clusters(6).name='P3';
% clusters(6).channels=[47, 52, 60, 51];
% clusters(7).name='P4';
% clusters(7).channels=[85, 92, 98, 97];
% clusters(8).name='F3';
% clusters(8).channels=[19, 23, 24, 27, 28];
% clusters(9).name='F4';
% clusters(9).channels=[3, 4, 117, 123, 124];

% v5
% clusters(1).name='C3';
% clusters(1).channels=[30, 37, 53, 54, 36, 42, 41];
% clusters(2).name='Cmedial';
% clusters(2).channels=[106, 80, 55, 31, 7];
% clusters(3).name='C4';
% clusters(3).channels=[79, 86, 87, 93, 103, 104, 105];
% clusters(4).name='F3a';
% clusters(4).channels=[19, 23, 24, 27, 28, 20];
% clusters(5).name='F3b';
% clusters(5).channels=[19, 23, 24, 27, 28, 20, 12];
% clusters(6).name='F4a';
% clusters(6).channels=[3, 4, 117, 123, 124, 118];
% clusters(7).name='F4b';
% clusters(7).channels=[3, 4, 117, 123, 124, 118, 5];
% clusters(8).name='O1';
% clusters(8).channels=[70, 74, 69, 73, 66, 71];
% clusters(9).name='O2';
% clusters(9).channels=[83, 89, 82, 88, 76, 84];

% v6
% clusters(1).name='C3a';
% clusters(1).channels=[30, 37, 53, 54, 36, 42, 41, 31];
% clusters(2).name='C3b';
% clusters(2).channels=[30, 37, 53, 54, 36, 42, 41, 31, 7];
% clusters(3).name='C4a';
% clusters(3).channels=[79, 86, 87, 93, 103, 104, 105, 80];
% clusters(4).name='C4b';
% clusters(4).channels=[79, 86, 87, 93, 103, 104, 105, 80, 106];
% clusters(5).name='C3-P3a';
% clusters(5).channels=[30, 37, 53, 54, 36, 42, 41, 31, 47, 52, 51, 60];
% clusters(6).name='C3-P3b';
% clusters(6).channels=[30, 37, 53, 54, 36, 42, 41, 31, 47, 52, 60, 61];
% clusters(7).name='C4-P4a';
% clusters(7).channels=[79, 86, 87, 93, 103, 104, 105, 80, 98, 92, 85, 97];
% clusters(8).name='C4-P4b';
% clusters(8).channels=[79, 86, 87, 93, 103, 104, 105, 80, 98, 92, 85, 78];
% clusters(9).name='O1';
% clusters(9).channels=[70, 74, 69, 73, 65, 68];
% clusters(10).name='O2';
% clusters(10).channels=[83, 89, 82, 88, 90, 94];


% v7
clusters(1).name='C3';
clusters(1).channels=[30, 37, 53, 54, 36, 42, 41, 31];
clusters(1).hemisphere='left';
clusters(1).region='C';

clusters(2).name='C4';
clusters(2).channels=[79, 86, 87, 93, 103, 104, 105, 80];
clusters(2).hemisphere='right';
clusters(2).region='C';

clusters(3).name='P3';
clusters(3).channels=[47, 52, 60, 51, 59];
clusters(3).hemisphere='left';
clusters(3).region='P';

clusters(4).name='P4';
clusters(4).channels=[85, 92, 98, 97, 91];
clusters(4).hemisphere='right';
clusters(4).region='P';

clusters(5).name='F3';
clusters(5).channels=[19, 23, 24, 27, 28, 20, 12];
clusters(5).hemisphere='left';
clusters(5).region='F';

clusters(6).name='F4';
clusters(6).channels=[3, 4, 117, 123, 124, 118, 5];
clusters(6).hemisphere='right';
clusters(6).region='F';

clusters(7).name='O1';
clusters(7).channels=[70, 74, 69, 73];
clusters(7).hemisphere='left';
clusters(7).region='O';

clusters(8).name='O2';
clusters(8).channels=[83, 89, 82, 88];
clusters(8).hemisphere='right';
clusters(8).region='O';

clusters(9).name='Fmedial';
clusters(9).channels=[9,14,15,21,22];
clusters(9).hemisphere='medial';
clusters(9).region='F';
