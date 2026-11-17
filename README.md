# Infant gaze following and joint attention

Analysis code for a study combining infant EEG and preferential looking to investigate early sensitivity to having one’s gaze followed.

## Paper

Rayson, H., Bonaiuto, J. J., Ferrari, P. F., Chakrabarti, B., & Murray, L. (2019). [Building blocks of joint attention: Early sensitivity to having one’s own gaze followed](https://doi.org/10.1016/j.dcn.2019.100631). *Developmental Cognitive Neuroscience*, 37, 100631.

## Code

- [`matlab/`](matlab/) contains EEG preprocessing and time–frequency analysis.
- [`R/coded_eeg/`](R/coded_eeg/) covers gaze coding and gaze-shift analyses, [`R/preferential_gaze/`](R/preferential_gaze/) covers preferential looking, and [`R/erd/`](R/erd/) covers event-related desynchronisation.
- [`python/`](python/) contains supporting utilities.

The analyses expect the study’s local EEG and behavioural files. See [LICENSE](LICENSE) for the code licence.
