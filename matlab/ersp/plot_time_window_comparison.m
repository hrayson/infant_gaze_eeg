function plot_time_window_comparison()
   %0-500 500-1000 1000-1500 1500-2000 2000-2500 2500-3000
C3=[ NaN     -1.6      -7.41     -10.09     -11.80   -9.02; %0-500
    NaN     NaN       -5.81      -8.49     -10.20   -7.42; %500-1000
    NaN     NaN        NaN        -2.68     -4.39    -1.61; %1000-1500
    NaN     NaN       NaN        NaN     -1.72     1.07; %1500-2000
    NaN     NaN       NaN        NaN       NaN       2.78; %2000-2500
    NaN     NaN       NaN        NaN       NaN      NaN];   %2500-3000
fig=figure();
[nr,nc]=size(C3);
pcolor([C3 nan(nr,1); nan(1,nc+1)]);
set(gca,'color',[0.8 0.8 0.8]);
cl=get(gca,'CLim');
%set(gca,'CLim',[-max(abs(cl)) max(abs(cl))]);
set(gca,'CLim',[-20 20]);
set(gca,'ydir','reverse');
set(gca,'ytick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'yticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
set(gca,'xtick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'xticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
colorbar();
saveas(fig, '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/with_p/mu/all_times_500ms/c3_woi_comparisons.eps','epsc');

   %0-500 500-1000 1000-1500 1500-2000 2000-2500 2500-3000
C4=[ NaN     0.44      -6.75     -6.44  -13.29    -8.41; %0-500
     NaN   NaN        -7.20     -6.88   -13.73    -8.86; %500-1000
     NaN   NaN       NaN        0.32   -6.53     -1.66; %1000-1500
     NaN   NaN       NaN      NaN     -6.85     -1.98; %1500-2000
     NaN   NaN       NaN      NaN       NaN        4.87; %2000-2500
     NaN   NaN       NaN      NaN      NaN       NaN ];
fig=figure();
[nr,nc]=size(C4);
pcolor([C4 nan(nr,1); nan(1,nc+1)]);
set(gca,'color',[0.8 0.8 0.8]);
cl=get(gca,'CLim');
%set(gca,'CLim',[-max(abs(cl)) max(abs(cl))]);
set(gca,'CLim',[-20 20]);
set(gca,'ydir','reverse');
set(gca,'ytick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'yticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
set(gca,'xtick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'xticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
colorbar();
saveas(fig, '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/with_p/mu/all_times_500ms/c4_woi_comparisons.eps','epsc');

   %0-500 500-1000 1000-1500 1500-2000 2000-2500 2500-3000
F3=[NaN    5.33     -3.85      -6.87    -15.33     -14.62; %0-500
    NaN    NaN      -9.17     -12.20    -20.65     -19.94; %500-1000
    NaN    NaN       NaN       -3.02    -11.48     -10.77; %1000-1500
    NaN    NaN       NaN        NaN     -8.46      -7.74;  %1500-2000
    NaN    NaN       NaN        NaN      NaN        0.71;  %2000-2500
    NaN    NaN       NaN        NaN      NaN          NaN];   %2500-3000
fig=figure();
[nr,nc]=size(F3);
pcolor([F3 nan(nr,1); nan(1,nc+1)]);
set(gca,'color',[0.8 0.8 0.8]);
cl=get(gca,'CLim');
%set(gca,'CLim',[-max(abs(cl)) max(abs(cl))]);
set(gca,'CLim',[-20 20]);
set(gca,'ydir','reverse');
set(gca,'ytick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'yticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
set(gca,'xtick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'xticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
colorbar();
saveas(fig, '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/with_p/mu/all_times_500ms/f3_woi_comparisons.eps','epsc');

   %0-500 500-1000 1000-1500 1500-2000 2000-2500 2500-3000
F4=[NaN    6.73     -4.13     -5.86    -8.46      -9.45; %0-500
    NaN    NaN      -10.86    -12.59  -15.20     -16.18; %500-1000
    NaN    NaN        NaN      -1.73   -4.33      -5.32; %1000-1500
    NaN    NaN        NaN       NaN    -2.60      -3.59; %1500-2000
    NaN    NaN        NaN       NaN     NaN       -0.99; %2000-2500
    NaN    NaN        NaN       NaN     NaN        NaN];  %2500-3000
fig=figure();
[nr,nc]=size(F4);
pcolor([F4 nan(nr,1); nan(1,nc+1)]);
set(gca,'color',[0.8 0.8 0.8]);
cl=get(gca,'CLim');
%set(gca,'CLim',[-max(abs(cl)) max(abs(cl))]);
set(gca,'CLim',[-20 20]);
set(gca,'ydir','reverse');
set(gca,'ytick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'yticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
set(gca,'xtick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'xticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
colorbar();  
saveas(fig, '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/with_p/mu/all_times_500ms/f4_woi_comparisons.eps','epsc');

   %0-500 500-1000 1000-1500 1500-2000 2000-2500 2500-3000
O1=[NaN    -0.76     -6.93     2.07      -5.20    -10.48;  %0-500
    NaN     NaN      -6.16     2.84      -4.44     -9.72;  %500-1000
    NaN     NaN       NaN      9.00       1.72     -3.55;  %1000-1500
    NaN     NaN       NaN      NaN       -7.28    -12.55;  %1500-2000
    NaN     NaN       NaN      NaN        NaN      -5.28;  %2000-2500
    NaN     NaN       NaN      NaN        NaN       NaN];   %2500-3000
fig=figure();
[nr,nc]=size(O1);
pcolor([O1 nan(nr,1); nan(1,nc+1)]);
set(gca,'color',[0.8 0.8 0.8]);
cl=get(gca,'CLim');
%set(gca,'CLim',[-max(abs(cl)) max(abs(cl))]);
set(gca,'CLim',[-20 20]);
set(gca,'ydir','reverse');
set(gca,'ytick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'yticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
set(gca,'xtick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'xticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
colorbar();
saveas(fig, '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/with_p/mu/all_times_500ms/o1_woi_comparisons.eps','epsc');

   %0-500 500-1000 1000-1500 1500-2000 2000-2500 2500-3000
O2=[ NaN    -0.83    -8.66     -2.17     -6.20     -11.50;  %0-500
     NaN     NaN     -7.83     -1.34     -5.37     -10.68;  %500-1000
     NaN     NaN      NaN       6.49      2.46      -2.84;  %1000-1500
     NaN     NaN      NaN       NaN      -4.03      -9.34;  %1500-2000
     NaN     NaN      NaN       NaN       NaN       -5.31;  %2000-2500
     NaN     NaN      NaN       NaN       NaN        NaN];   %2500-3000
fig=figure();
[nr,nc]=size(O2);
pcolor([O2 nan(nr,1); nan(1,nc+1)]);
set(gca,'color',[0.8 0.8 0.8]);
cl=get(gca,'CLim');
%set(gca,'CLim',[-max(abs(cl)) max(abs(cl))]);
set(gca,'CLim',[-20 20]);
set(gca,'ydir','reverse');
set(gca,'ytick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'yticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
set(gca,'xtick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'xticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
colorbar();
saveas(fig, '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/with_p/mu/all_times_500ms/o2_woi_comparisons.eps','epsc');

   %0-500 500-1000 1000-1500 1500-2000 2000-2500 2500-3000
P3=[ NaN   -0.82    -11.88     -5.87     -4.59     -9.91;  %0-500
     NaN    NaN     -11.06     -5.05     -3.78     -9.09;  %500-1000
     NaN    NaN       NaN       6.01      7.28      1.97;  %1000-1500
     NaN    NaN       NaN       NaN       1.27     -4.04;  %1500-2000
     NaN    NaN       NaN       NaN       NaN      -5.32;  %2000-2500
     NaN    NaN       NaN       NaN       NaN      NaN];  %2500-3000
fig=figure();
[nr,nc]=size(P3);
pcolor([P3 nan(nr,1); nan(1,nc+1)]);
set(gca,'color',[0.8 0.8 0.8]);
cl=get(gca,'CLim');
%set(gca,'CLim',[-max(abs(cl)) max(abs(cl))]);
set(gca,'CLim',[-20 20]);
set(gca,'ydir','reverse');
set(gca,'ytick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'yticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
set(gca,'xtick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'xticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
colorbar();
saveas(fig, '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/with_p/mu/all_times_500ms/p3_woi_comparisons.eps','epsc');

   %0-500 500-1000 1000-1500 1500-2000 2000-2500 2500-3000
P4=[ NaN    -2.58    -15.31    -10.34    -12.31    -10.29;  %0-500
     NaN     NaN     -12.73     -7.75     -9.73     -7.70;  %500-1000
     NaN     NaN       NaN       4.98      3.01      5.03;  %1000-1500
     NaN     NaN       NaN       NaN      -1.97      0.05;  %1500-2000
     NaN     NaN       NaN       NaN       NaN       2.02;  %2000-2500
     NaN     NaN       NaN       NaN       NaN        NaN];   %2500-3000
fig=figure();
[nr,nc]=size(P4);
pcolor([P4 nan(nr,1); nan(1,nc+1)]);
set(gca,'color',[0.8 0.8 0.8]);
cl=get(gca,'CLim');
%set(gca,'CLim',[-max(abs(cl)) max(abs(cl))]);
set(gca,'CLim',[-20 20]);
set(gca,'ydir','reverse');
set(gca,'ytick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'yticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
set(gca,'xtick',[1.5 2.5 3.5 4.5 5.5 6.5]);
set(gca,'xticklabel',{'0-500ms','500-1000ms','1000-1500ms','1500-2000ms','2000-2500ms','2500-3000ms'});
colorbar();
saveas(fig, '/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/erd/erd_results/obs/with_p/mu/all_times_500ms/p4_woi_comparisons.eps','epsc');