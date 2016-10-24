Analysis code for Ca Imaging

Combines all data into one structure

Run CaAnalysis.m
Choose folder with .csv files from ImageJ and .mat files from speedTracker for one experiment
(Use 'Results' folder to test)
Enter in number of orientations (8 for the example)

Last row of data(n).fluoDat.dFF is the concatenated dF/F signal over all 8 trials
data(n).fluoDat.totTrig gives you the location of stimulus start

Copied here October 13, 2016 11:39PM by WWY

-----------------------------------------------------------------------------------------------

Update: October 17, 2016 3:24AM by WWY

now also plots dF/F0 and polar plots in interactive user interfaces
Run program as before
