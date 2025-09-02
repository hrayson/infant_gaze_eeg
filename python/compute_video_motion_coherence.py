import os
import seaborn as sns
import numpy as np
import pylab as py
import cv2 as cv2
from moviepy.video.io.VideoFileClip import VideoFileClip
from scipy import fftpack
from seaborn.distributions import _statsmodels_univariate_kde, _scipy_univariate_kde
from seaborn.utils import _kde_support
from skimage import img_as_ubyte
from sklearn.neighbors import KernelDensity
from statsmodels.nonparametric.kde import KDEUnivariate
from tqdm import tqdm
from scipy import stats
from radial_profile import azimuthalAverage


def draw_flow(img, flow, step=18):
    h, w = img.shape[:2]
    y, x = np.mgrid[step / 2:h:step, step / 2:w:step].reshape(2, -1).astype(int)
    fx, fy = flow[y, x].T
    lines = np.vstack([x, y, x + fx, y + fy]).T.reshape(-1, 2, 2)
    lines = np.int32(lines + 0.5)
    # vis=cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    cv2.polylines(img, lines, 0, (0, 255, 0))
    for (x1, y1), (x2, y2) in lines:
        cv2.circle(img, (x1, y1), 1, (0, 255, 0), -1)
    return img


def smooth(x, window_len=11, window='hanning'):
    if x.ndim != 1:
        raise ValueError, 'smooth only accepts 1d array'

    if x.size < window_len:
        raise ValueError, 'Input vector must be bigger than window size'

    if window_len < 3:
        return x

    if not window in ['flat', 'hanning', 'hamming', 'bartlett', 'blackman']:
        raise ValueError, 'Window unrecognized'

    s = np.r_[x[window_len - 1:0:-1], x, x[-2:-window_len - 1:-1]]
    if window == 'flat':
        w = np.ones(window_len, 'd')
    else:
        w = eval('np.' + window + '(window_len)')
    y = np.convolve(w / w.sum(), s, mode='full')
    return y



# def compute_crop(filename):
#     clip = VideoFileClip(os.path.join('../../data/stim/', filename))
#     image = img_as_ubyte(clip.reader.read_frame())
#     img_gray = np.mean(image, axis=2)
#     row_sum = np.sum(img_gray, axis=0)
#     x_min = 0
#     #x_min = np.min(np.where(row_sum < 140000.0)[0]) + 1
#     #x_max = x_min + np.max(np.where(row_sum[x_min:] > 146880)[0])
#     x_max=img_gray.shape[0]
#     col_sum = np.sum(img_gray, axis=1)
#     #y_min = np.min(np.where(col_sum < 180000)[0]) + 1
#     y_min=0
#     #y_max = y_min + np.max(np.where(col_sum[y_min:] > 146880)[0])
#     y_max = img_gray.shape[1]

    # image_cropped=image[y_min:y_max,x_min:x_max,:]
    # cv2.imshow('Frame', image[..., ::-1])
    # cv2.imshow('Frame Cropped', image_cropped[..., ::-1])
    # cv2.waitKey(1)
    # return [x_min, x_max, y_min, y_max]


##
# Compare videos in terms of brightness, contrast, spatial frequency, and movement
##
def analyze_videos(videos, crop = True):

    frame_buffer = 10

    threshold=300
    block_width=18

    video_angles=[]
    video_motion=[]
    # video_coherence=[]

    for video in videos:

        # Figure out how to crop video to remove back border
        # roi = compute_crop(video)

        # Open video clip
        clip = VideoFileClip(os.path.join('../../data/stim/', video))

        # Figure out the approximate number of frames in the video
        n_frames_approx = int(np.ceil(clip.duration * clip.fps) + frame_buffer)
        n_frames=n_frames_approx

        clip.reader.initialize()

        # Have to store last frame because of stupid bug where sometimes frames are duplicated
        last_image = None
        last_img_gray = None

        # Iterate through frames in video (only first third has head turn)
        for index in tqdm(range(n_frames_approx)):

            # Get next frame and crop
            image = img_as_ubyte(clip.reader.read_frame())

            # if crop:
            #     # Image is NxMx3 (last dimension is RGB channels)
            #     image = image[roi[2]:roi[3], roi[0]:roi[1], :]

            # Deal with stupid repeated frame bug
            if index == int(n_frames_approx - frame_buffer * 2):
                last_image = image
            elif index > int(n_frames_approx - frame_buffer * 2):
                if (image == last_image).all():
                    n_frames = index
                    break

        angles=np.zeros((n_frames,image.shape[0],image.shape[1]))
        motions=np.zeros((n_frames,image.shape[0],image.shape[1]))
        # coherences=[]
        # frame_angles=[]

        clip.reader.initialize()

        # Iterate through frames in video (only first third has head turn)
        for index in tqdm(range(n_frames_approx)):

            # Get next frame and crop
            image = img_as_ubyte(clip.reader.read_frame())
            xblock = image.shape[0] / block_width
            yblock = image.shape[1] / block_width

            # if crop:
            #     # Image is NxMx3 (last dimension is RGB channels)
            #     image = image[roi[2]:roi[3], roi[0]:roi[1], :]

            # Deal with stupid repeated frame bug
            if index == int(n_frames_approx - frame_buffer * 2):
                last_image = image
            elif index > int(n_frames_approx - frame_buffer * 2):
                if (image == last_image).all():
                    n_frames = index
                    break

            # Convert to grayscale by averaging over last dimension (RGB channels)
            img_gray = np.mean(image, axis=2)

            # Initialize motion to 0
            if index > 0:
                flow=np.zeros((img_gray.shape[0],img_gray.shape[1],2))
                # block_angles=np.zeros((xblock,yblock))
                for xb in xrange(xblock):
                    for yb in range(yblock):
                        box = (xb * block_width, yb * block_width, (xb + 1) * block_width, (yb + 1) * block_width)
                        weighted_angle = np.nan

                        if box[2]<img_gray.shape[0] and box[3]<img_gray.shape[1]:
                            # Compute optical flow to get global motion
                            box_flow = cv2.calcOpticalFlowFarneback(last_img_gray[box[0]:box[2], box[1]:box[3]],
                                                                    img_gray[box[0]:box[2], box[1]:box[3]],
                                                                    flow[box[0]:box[2], box[1]:box[3], :], 0.5, 3, 15, 3, 5, 1.2, 0)
                            # None, 0.5, 3, 10, 3, 5, 1.1, 0)
                            # None, 0.5, 3, 15, 3, 5, 1.2, 0)
                            flow[box[0]:box[2], box[1]:box[3],:]=box_flow

                            # Compute direction in box as weighted sum of angles
                        #     box_motion = (np.sqrt(np.sum(np.power(box_flow, 2), axis=2)) * clip.fps).flatten()
                        #     box_angle = (np.arctan2(box_flow[:, :, 0], box_flow[:, :, 1]) * 180 / np.pi).flatten()
                        #     if np.max(box_motion)>block_threshold:
                        #         weighted_angle=np.sum((box_motion/np.sum(box_motion))*box_angle)
                        #     #    weighted_angle=box_angle[np.where(box_motion==np.max(box_motion))[0]]
                        # block_angles[xb,yb]=weighted_angle

                # frame_coherence=
                #block_angles=block_angles[8:-8,0:-3].flatten()
                # block_angles=block_angles[~np.isnan(block_angles)]
                # block_angles=block_angles.flatten()
                # [counts, x] = np.histogram(block_angles[~np.isnan(block_angles)], bins=range(-160,180,20))
                # frame_coherence=np.max(counts)/float(block_angles.shape[0])*100.0
                # coherences.append(frame_coherence)

                cv2.imshow('Optical flow', draw_flow(img_gray, flow))
                cv2.imshow('Frame', image[..., ::-1])
                cv2.waitKey(1)
                # Convert flow to pixels/s
                #motion = np.mean(np.sqrt(np.sum(np.power(flow, 2), axis=2))) * clip.fps
                motion = np.sqrt(np.sum(np.power(flow, 2), axis=2)) * clip.fps
                angle = np.arctan2(flow[:, :, 0], flow[:, :, 1]) * 180 / np.pi
                angles[index,:,:]=angle
                motions[index,:,:]=motion

                # data = angle[nz].flatten()
                # data = np.asarray(data)
                # data = data.astype(np.float64)
                # if len(data) > 1:
                #     x, y = _scipy_univariate_kde(data, 'scott', 100, 3, (-np.inf, np.inf))
                #     frame_angles.append(list(y))
                # else:
                #     frame_angles.append(list(np.zeros((100))))

                # angle.flatten()
                # [counts, x] = np.histogram(angle.flatten(), bins=range(-170, 180, 10))
                # frame_coherence = np.max(counts) / float(len(nz[0])) * 100.0
                # coherences.append(frame_coherence)

            last_img_gray=img_gray

        # py.figure(3)
        # py.imshow(np.asarray(frame_angles).transpose(), extent=[0,n_frames_approx,x[1],x[-1]])
        # py.show()

        video_angles.append(angles)
        video_motion.append(motions)
        # video_coherence.append(coherences)

    # Plot
    py.figure(1)
    py.clf()
    video_peak_dir=[]
    for idx,video in enumerate(videos):
        path,fname=os.path.split(video)
        fname,ext=os.path.splitext(fname)
        angles=video_angles[idx]
        angles=angles.flatten()
        motions=video_motion[idx]
        motions=motions.flatten()
        kde = KDEUnivariate(angles[motions>=threshold])
        kde.fit(bw=10)
        x=np.linspace(-180, 180, 100)
        y = kde.evaluate(x)
        video_peak_dir.append(x[np.where(y==np.max(y))])
        # sns.distplot(angles[motions>=threshold], hist=False, kde=True, kde_kws={'linewidth': 3}, label=fname)
        py.plot(x,y, label=fname)
    yl=py.ylim()
    py.legend(prop={'size':16},title='Video')
    py.xlim([-180,180])
    py.ylim(yl)
    py.xlabel('Direction (deg)')
    py.ylabel('Density')


    py.figure(2)
    w = np.hanning(11)
    video_coherence=[]
    for idx,video in enumerate(videos):
        path, fname = os.path.split(video)
        fname, ext = os.path.splitext(fname)

        py.subplot(len(videos),1,idx+1)
        angles = video_angles[idx]
        motions = video_motion[idx]
        frame_angles = np.zeros((angles.shape[0], 100))

        for frame_idx in range(angles.shape[0]):
            data = angles[frame_idx, :, :].flatten()
            motion = motions[frame_idx, :, :].flatten()
            data = np.asarray(data[motion >= threshold])
            data = data.astype(np.float64)
            if len(data) > 1 and np.min(data) < np.max(data):
                # x, y = _scipy_univariate_kde(data, 'scott', 100, 3, (-180, 180))
                kde = KDEUnivariate(angles[motions >= threshold])
                kde.fit(bw=10)
                x = np.linspace(-180, 180, 100)
                y = kde.evaluate(x)
                frame_angles[frame_idx, :] = y

        X, Y = np.meshgrid(range(angles.shape[0]), x)

        for deg_idx in range(frame_angles.shape[1]):
            y = np.convolve(w / w.sum(), frame_angles[:,deg_idx], mode='same')
            frame_angles[:,deg_idx]=y

        frame_coherence=[]
        for frame_idx in range(angles.shape[0]):
            f_angles=frame_angles[frame_idx,:]
            dir_idx=np.intersect1d(np.where(x>video_peak_dir[idx]-15), np.where(x<video_peak_dir[idx]+15))
            coherence=0.0
            if len(np.where(f_angles>0.002)[0])>0:
                coherence=np.sum(f_angles[dir_idx])/np.sum(f_angles[np.where(f_angles>0.002)[0]])*100.0
            frame_coherence.append(coherence)
        video_coherence.append(frame_coherence)
        py.pcolormesh(X, Y, frame_angles.transpose())
        py.colorbar()
        py.xticks(range(0, angles.shape[0], 20))
        py.yticks(range(-180, 180, 60))
        py.ylabel('%s Dir' % fname)
    py.xlabel('Frame')

    py.figure(3)
    py.clf()
    for idx, video in enumerate(videos):
        path, fname = os.path.split(video)
        fname, ext = os.path.splitext(fname)
        py.plot(smooth(np.array(video_coherence[idx])), label=fname)
    py.legend(prop={'size': 16}, title='Video')
    py.xlabel('Frame')
    py.ylabel('Motion Coherence (%)')

    py.show()
    print('Done')


if __name__ == '__main__':
    videos = ['/home/bonaiuto/Dropbox/joint_attention/infant_gaze_eeg/videos/CG-left.mpg',
              '/home/bonaiuto/Dropbox/joint_attention/infant_gaze_eeg/videos/CG-left.shuffled.mpg',
              '/home/bonaiuto/Dropbox/joint_attention/infant_gaze_eeg/videos/FO-left.mpg',
              '/home/bonaiuto/Dropbox/joint_attention/infant_gaze_eeg/videos/FO-left.shuffled.mpg',
              '/home/bonaiuto/Dropbox/joint_attention/infant_gaze_eeg/videos/CG-right.mpg',
              '/home/bonaiuto/Dropbox/joint_attention/infant_gaze_eeg/videos/CG-right.shuffled.mpg',
              '/home/bonaiuto/Dropbox/joint_attention/infant_gaze_eeg/videos/FO-right.mpg',
              '/home/bonaiuto/Dropbox/joint_attention/infant_gaze_eeg/videos/FO-right.shuffled.mpg']
    analyze_videos(videos, crop=False)
