# Imports
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from numpy.random import randn
from datetime import datetime, timedelta
import os

os.chdir('C:/Users/thorn/Onedrive/Dokumenter/GitHub/energy/') # one level up

# from scraping import scrape_cons
# cons = scrape_cons(limit = 10000, sleeping = 10)

##############################################################################
#   EXAMPLE: Illustration of estimates and s.e.                              #
##############################################################################
xvals = range(10)
means = [len(xvals) - i - randn() for i in xvals]
upper = [m + 1 for m in means]
lower = [m - 1 for m in means]

fig = plt.figure()
ax = fig.add_subplot(111)
ax.scatter(xvals, means, color = 'black')
for x, low, high in zip(xvals, lower, upper):
    ax.plot([x,x], [low, high], color = 'black')

##############################################################################
#   WHOLESALE CONSUMPTION BY MONTH                                           #
##############################################################################
df = pd.read_csv('stata/ws_month.xls', sep='\t', lineterminator='\r', header=[1,2], index_col=[0])

xvals = list(range(1,13))
est = np.array(list(df))[:,1].astype(float)
std = np.array(df.iloc[0,:].str.slice(1, 7)).astype(float)
upper = est-std
lower = est+std

fig, ax = plt.subplots(figsize=(12,7.4))
ax.scatter(xvals, list(est), color = '#3182bd')
for x, low, high in zip(xvals, lower, upper):
    ax.plot([x,x], [low, high], color = '#6baed6')
ax.grid(axis='y')
ax.set(xlabel='month', ylabel='estimated price elasticity of wholesale consumption')
ax.set_xticks(np.arange(0, 13, 1))
fig.savefig('latex/03_figures/ws_elasticity_month.png', bbox_inches='tight')
plt.show()

##############################################################################
#   WHOLESALE CONSUMPTION BY HOUR                                            #
##############################################################################
df = pd.read_csv('stata/ws_hour.xls', sep='\t', lineterminator='\r', header=[1,2,3], index_col=[0])
df
xvals = list(range(0,24))
est = np.array(list(df))[:,1].astype(float)
std = np.array(pd.DataFrame(list(df))[2].str.slice(1, 7)).astype(float)
upper = est-std
lower = est+std

fig, ax = plt.subplots(figsize=(12,7.4))
ax.scatter(xvals, list(est), color = '#3182bd')
for x, low, high in zip(xvals, lower, upper):
    ax.plot([x,x], [low, high], color = '#6baed6')
ax.grid(axis='y')
ax.set(xlabel='hour', ylabel='estimated price elasticity of wholesale consumption')
ax.set_xticks(np.arange(0, 24, 2))
for xc in [10.5, 15.5]:
    plt.axvline(x=xc, color='r')
for xc in [-.5, 4.5]:
    plt.axvline(x=xc, color='g')
fig.savefig('latex/03_figures/ws_elasticity_hour.png', bbox_inches='tight')
plt.show()

##############################################################################
#   RETAIL CONSUMPTION BY HOUR                                            #
##############################################################################
df = pd.read_csv('stata/r_hour_bd.xls', sep='\t', lineterminator='\r', header=[1,2,3], index_col=[0])
df
xvals = list(range(0,24))
est = np.array(list(df))[:,1].astype(float)
std = np.array(pd.DataFrame(list(df))[2].str.slice(1, 7)).astype(float)
upper = est-std
lower = est+std

fig, ax = plt.subplots(figsize=(12,7.4))
ax.scatter(xvals, list(est), color = '#636363')
for x, low, high in zip(xvals, lower, upper):
    ax.plot([x,x], [low, high], color = '#969696')
ax.grid(axis='y')
ax.set(xlabel='hour', ylabel='estimated price elasticity of retail consumption')
ax.set_xticks(np.arange(0, 24, 2))
for xc in [16.5, 19.5]:
    plt.axvline(x=xc, color='r')
fig.savefig('latex/03_figures/r_elasticity_hour.png', bbox_inches='tight')
plt.show()
