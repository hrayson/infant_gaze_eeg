function freq_bands=create_freq_band_structure()

freq_bands=[];

freq_bands(1).foi=[3 4];
freq_bands(1).age='';
freq_bands(1).name='theta';

freq_bands(2).foi=[5 8];
freq_bands(2).age='6m';
freq_bands(2).name='mu';

freq_bands(3).foi=[6 9];
freq_bands(3).age='9m';
freq_bands(3).name='mu';

freq_bands(4).foi=[9 20];
freq_bands(4).age='6m';
freq_bands(4).name='beta';

freq_bands(5).foi=[10 21];
freq_bands(5).age='9m';
freq_bands(5).name='beta';

freq_bands(6).foi=[9 14];
freq_bands(6).age='6m';
freq_bands(6).name='low_beta';

freq_bands(7).foi=[15 20];
freq_bands(7).age='6m';
freq_bands(7).name='high_beta';

freq_bands(8).foi=[10 15];
freq_bands(8).age='9m';
freq_bands(8).name='low_beta';

freq_bands(9).foi=[16 21];
freq_bands(9).age='9m';
freq_bands(9).name='high_beta';
