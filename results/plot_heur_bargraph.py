#!/usr/category/env python
import numpy as np
from ss_plotting.make_plots import plot_bar_graph
from ss_plotting.plot_utils import output

series_labels=['none','mov','sense','both']
series_colors = ['green','purple','orange','blue']
ylabel = 'Avg. Reward'

series_vals = [ [-807],[-1235], [-1090], [168] ]
series_errs = [ [3], [63], [4], [49] ]
categories = ['(20,0.2)']

fig,ax = plot_bar_graph(series_vals, series_colors,
               series_labels = series_labels,
               series_errs = series_errs,
               category_labels = categories,
               category_padding = 0.25,
               barwidth = 0.10,
               plot_ylabel = ylabel,
               show_plot=False)

output(fig,'heuristics.pdf',size=(2.5,4.5),latex=False)