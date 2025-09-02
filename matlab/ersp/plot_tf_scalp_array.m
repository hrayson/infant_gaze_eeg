function plot_tf_scalp_array(chan_measure, times, freqs, chanlocs, varargin)

% Parse inputs
defaults=struct('colormap','jet','flipcolormap',false,'clim',[]);
params=struct(varargin{:});
for f = fieldnames(defaults)',
    if ~isfield(params, f{1}),
        params.(f{1}) = defaults.(f{1});
    end
end

DEFAULT_PLOT_WIDTH    = 0.95;     % 0.75, width and height of plot array on figure
DEFAULT_PLOT_HEIGHT   = 0.88;    % 0.88
DEFAULT_AXWIDTH  = 0.04; %
DEFAULT_AXHEIGHT = 0.05; %

nonemptychans = cellfun('isempty', { chanlocs.theta });
nonemptychans = find(~nonemptychans);
[tmp channames Th Rd] = readlocs(chanlocs(nonemptychans));
channames = strvcat({ chanlocs.labels });
Th = pi/180*Th;                 % convert degrees to radians
Rd = Rd;

[yvalstmp,xvalstmp] = pol2cart(Th,Rd); % translate from polar to cart. coordinates
xvals(nonemptychans) = xvalstmp;
yvals(nonemptychans) = yvalstmp;

totalchans = length(chanlocs);
emptychans = setdiff_bc(1:totalchans, nonemptychans);
totalchans = floor(sqrt(totalchans))+1;
for index = 1:length(emptychans)
    xvals(emptychans(index)) = 0.7+0.2*floor((index-1)/totalchans);
    yvals(emptychans(index)) = -0.4+mod(index-1,totalchans)/totalchans;
end;

xvals = (xvals-mean([max(xvals) min(xvals)]))/(max(xvals)-min(xvals)); % recenter

figure();
gcapos = get(gca,'Position'); axis off;
PLOT_WIDTH    = gcapos(3)*DEFAULT_PLOT_WIDTH; % width and height of gca plot array on gca
PLOT_HEIGHT   = gcapos(4)*DEFAULT_PLOT_HEIGHT;
axheight = DEFAULT_AXHEIGHT*(gcapos(4)*1.25);
axwidth =  DEFAULT_AXWIDTH*(gcapos(3)*1.3);

cond_xvals = gcapos(1)+gcapos(3)/2+PLOT_WIDTH*xvals;   % controls width of plot
cond_yvals = gcapos(2)+gcapos(4)/2+PLOT_HEIGHT*yvals;  % controls height of plot

Axes = [];
for c=1:length(chanlocs), %%%%%%%% for each data channel %%%%%%%%%%%%%%%%%%%%%%%%%%

    xcenter = cond_xvals(c); if isnan(xcenter), xcenter = 0.5; end; 
    ycenter = cond_yvals(c); if isnan(ycenter), ycenter = 0.5; end;
    ax=axes('Units','Normal','Position', ...
        [xcenter-axwidth/2 ycenter-axheight/2 axwidth axheight]);
    axis('off');
    if params.flipcolormap
        colormap(flipud(colormap(params.colormap)));
    else
        colormap(params.colormap);
    end
    tmp=chan_measure{c};
    clim=[min(tmp(:)) max(tmp(:))];
    if length(params.clim)
        if size(params.clim,1)>1
            clim=params.clim(c,:);
        else
            clim=params.clim;
        end
    end
    imagesc(times,freqs,tmp,clim);
    set(gca,'ydir','normal');
    hold on;
    plot([0 0], [freqs(1) freqs(end)], 'w--');
    ylabel(channames(c,:));
    Axes = [Axes ax];        
end