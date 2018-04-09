# Materials and Data of "Cue Detectability Predicts Instrumental Conditioning" 

This repository accompanies the research article Reber, T.P., Samimiziad, B., & Mormann F. (2018). Cue Detectability Predicts Instrumental Conditioning. Consciousness & Cognition, in press.

If you have any questions, please contact <treber@live.com>.

This repository provides:

- Matlab/Octave code and stimuli used to run the experiment under `paradigm` directory
- resulting data in the `logs` directory
- jupyter notebooks (`.ipynb` files) and Matlab functions to analyze the data in `helper_functions` directory

## Running the Experimental Paradigm
Software requirements to run the paradigm are

- linux, we used [Debian 7.2](http://www.debian.org) (Windows and MacOs should also work but may require changes to code and may not be as accurate with timing). 
- [Octave](https://www.gnu.org/software/octave/) (Matlab might also work, but again might require small changes to the code)
- [Psychtoolbox](http://psychtoolbox.org/)
- [Palamedes Toolbox](http://www.palamedestoolbox.org/download.html), we used Version 1.5.0 but newer Versions should work as well
- The scripts, stimuli and further files provided in this repository under the `paradigm` directory

Once everything is setup and all the scripts and toolboxes are added to the octave path, start octave and run the script `paradigm/octave/sc.m`, which will take you through the whole experiment as reported in the manuscript. 

Further instructions for the experimentator, as well as written Instructions for the subjects are provided under `paradigm/manual/`.  


## Analysis of Resulting Data
To document how data is aggregated, analyzed and displayed in the figures in the article, we provide [juptyer notebooks](http://www.jupyter.org). To run these notebooks yourself, you need the install 

- [Matlab](http://www.mathworks.com) We used 2016a but prior versions may also work. Maybe these things also work with [Octave](https://www.gnu.org/software/octave/) but some changes to code may become necessary. 
- [juptyer notebooks](http://www.jupyter.org)
- [a Matlab kernel for jupyter](https://github.com/calysto/matlab_kernel)
- [an R kernel for jupyter](https://github.com/IRkernel/IRkernel)

There are a few more dependencies, which are mentioned in the notebook themselves.

The are three jupyter notebook:

1. To see how we aggregated the data and store them for further processing in [R](https://www.r-project.org/) and [Matlab](https://www.mathworks.com/), use  [1_MATLAB_LoadAndAggregateData.ipynb ](http://www.github.com/rebrowski/conditioning/blob/master/1_MATLAB_LoadAndAggregateData.ipynb)
2. Analyses performed using [R](https://www.r-project.org/) are documented in [2_R_Analyses.ipynb ](http://www.github.com/rebrowski/conditioning/blob/master/2_R_Analyses.ipynb)
3. Creation of figures and additional analyses can be inspected in [3_MATLAB_FiguresAndAnalyses.ipynb](http://www.github.com/rebrowski/conditioning/blob/master/3_MATLAB_FiguresAndAnalyses.ipynb)
