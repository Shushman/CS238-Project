#!/usr/category/env python
import numpy as np
from ss_plotting.make_plots import plot_bar_graph
from ss_plotting.plot_utils import output

SIZES = [10,15,20]
OBSFRACS = [0.1,0.2,0.3]

series_labels = ['greedy','mdp','pomcp','oracle']
series_colors = ['green','purple','orange','blue']
ylabel = 'Avg. Reward'

alg_means = [list(),list(),list(),list()]
alg_stds = [list(),list(),list(),list()]
categories = list()

for size in SIZES:
  for of in OBSFRACS:

    categ = '('+str(size)+','+str(of)+')'
    categories.append(categ)

    # Get for each algorithm
    fname = 'greedy-'+str(size)+'-'+str(of)+'.txt'
    with open(fname,'r') as f_greedy:
      info = f_greedy.readline()
      info_list = [float(v) for v in info.split(',')]
      alg_means[0].append(info_list[0])
      alg_stds[0].append(info_list[1])
      alg_means[3].append(info_list[2])
      alg_stds[3].append(0.0)

    fname = 'mdp-'+str(size)+'-'+str(of)+'.txt'
    with open(fname,'r') as f_mdp:
      info = f_mdp.readline()
      info_list = [float(v) for v in info.split(',')]
      alg_means[1].append(info_list[0])
      alg_stds[1].append(info_list[1])

    fname = 'pomcp-'+str(size)+'-'+str(of)+'.txt'
    with open(fname,'r') as f_pomcp:
      info = f_pomcp.readline()
      info_list = [float(v) for v in info.split(',')]
      alg_means[2].append(info_list[0])
      alg_stds[2].append(info_list[1])


fig,ax = plot_bar_graph(alg_means, series_colors,
               series_labels = series_labels,
               series_errs = alg_stds,
               category_labels = categories,
               category_padding = 0.4,
               plot_ylabel = ylabel,
               show_plot=False)

output(fig,'performance_nfz5.pdf',size=(6.8,3.4),latex=False)