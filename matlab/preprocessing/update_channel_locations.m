function data=update_channel_locations(data)

[chanformat listcolformat] = readlocs('/home/jbonaiuto/Dropbox/joint_attention/infant_gaze_eeg/GSN-HydroCel-128.sfp');

for i=1:length(chanformat)
    ch_label=chanformat(i).labels;
    for k=1:length(data.chanlocs)
        if strcmp(data.chanlocs(k).labels,ch_label)>0
            data.chanlocs(k).Y=chanformat(i).Y;
            data.chanlocs(k).X=chanformat(i).X;
            data.chanlocs(k).Z=chanformat(i).Z;
            data.chanlocs(k).sph_theta=chanformat(i).sph_theta;
            data.chanlocs(k).sph_phi=chanformat(i).sph_phi;
            data.chanlocs(k).sph_radius=chanformat(i).sph_radius;
            data.chanlocs(k).theta=chanformat(i).theta;
            data.chanlocs(k).radius=chanformat(i).radius;
        end
    end
    for k=1:length(data.urchanlocs)
        if strcmp(data.urchanlocs(k).labels,ch_label)>0
            data.urchanlocs(k).Y=chanformat(i).Y;
            data.urchanlocs(k).X=chanformat(i).X;
            data.urchanlocs(k).Z=chanformat(i).Z;
            data.urchanlocs(k).sph_theta=chanformat(i).sph_theta;
            data.urchanlocs(k).sph_phi=chanformat(i).sph_phi;
            data.urchanlocs(k).sph_radius=chanformat(i).sph_radius;
            data.urchanlocs(k).theta=chanformat(i).theta;
            data.urchanlocs(k).radius=chanformat(i).radius;
            data.urchanlocs(k).sph_theta_besa=chanformat(i).sph_theta_besa;
            data.urchanlocs(k).sph_phi_besa=chanformat(i).sph_phi_besa;
            break
        end
    end
end

