# Associated-Press-Reposts
Uses the GDELT DOC API to detect when other news outlets ran and reprinted stories from The Associated Press. 
Pulls story titles from .txt files, all of which were downloaded from the LexisNexis database.

Includes 5 example text files from early November for ease of reproduction. 

I've attached examples of the kinds of visualization that can be made with data from the GDELT API (and ggplot2).


**EDIT December 2017:

Added (some) network visualizations, more to come. 

ninety_five.pdf, eighty_five.pdf, seventy_five.pdf are all visualizations of an adjacency matrix I constructed from the news outlets. The filename corresponds to the threshold correlation coefficient for the adjacency matrices. 

g_full.pdf is a visualization of the entire news agency network created with Cytoscape. The map visualizes the resulting communities of news outlets after I applied clustering to the network.
