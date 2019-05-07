# Imports
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os

# Set working folder
os.chdir('C:/Users/thorn/Onedrive/Dokumenter/GitHub/energy/') # one level up

# Load data
data = pd.read_csv('python/data.csv')

data.columns.values

##############################################################################
#   PLOTS BY HOUR                                                            #
##############################################################################
business_days = data[data['bd']==1] # df for business days excluding holidays
weekends = data[data['bd']==0] # df for weekends and holidays

bd = business_days[['hour', 'e_w', 'e_f', 'e_r', 'e_hh']].groupby('hour').mean()
nbd = weekends[['hour', 'e_w', 'e_f', 'e_r', 'e_hh']].groupby('hour').mean()

fig, ax = plt.subplots(figsize=(12,7.4)) # create new figure
bd.plot(kind='line', ax=ax, y='e_w', label='Wholesale, business day')
nbd.plot(kind='line', ax=ax, y='e_w', label='Wholesale, non-business day', linestyle='dashed')
bd.plot(kind='line', ax=ax, y='e_hh', label='Retail, business day', linestyle='dotted')
nbd.plot(kind='line', ax=ax, y='e_hh', label='Retail non-business day', linestyle='dashdot')
ax.set(xlabel='hour', ylabel='mean electricity consumption, kWh')
ax.set_xticks(np.arange(0, 24, 2))
ax.grid(axis='both')
plt.legend(loc='upper right', ncol=1)
# plt.legend(loc='upper left')
fig.savefig('latex/03_figures/hours.png')
plt.show()
### Wholesale intervals ###
# peak: mon-fri 8-13
# shoulder: mon-fri 6-7, 14-17
# off-peak: mon-fri 18-4
# weekends-peak: sat-sun 10-13
# weekend-shoulder: sat-sun 7-9, 14-16
# weekend-off-peak: sat-sun 17-6

### Household intervals ###
# peak: mon-sun 17-19
# shoulder: mon-fri 8-16, 20-21
# off-peak: mon-fri 22-6
# weekend-shoulder: sat-sun 9-16, 20-21
# weekend-off-peak: sat-sun 22-8


##############################################################################
#   PLOTS by WEEKDAY, WEEK, MONTH, and TIME SERIES                           #
##############################################################################
### Setting up the data ###
weekdays = data[['day', 'e_w', 'e_f', 'e_r', 'e_hh']].groupby('day').mean()
weekdays_bd = business_days[['day', 'e_w', 'e_f', 'e_r', 'e_hh']].groupby('day').mean()
weeks = data[['week', 'e_w', 'e_f', 'e_r', 'e_hh']].groupby('week').mean()
weeks_bd = business_days[['week', 'e_w', 'e_f', 'e_r', 'e_hh']].groupby('week').mean()
months = data[['month', 'e_w', 'e_f', 'e_r', 'e_hh']].groupby('month').mean()
months_bd = business_days[['month', 'e_w', 'e_f', 'e_r', 'e_hh']].groupby('month').mean()
time_series = business_days[['date', 'e_w', 'e_f', 'e_r', 'e_hh', 'year']].groupby('date').mean()

weekdays.name, weekdays_bd.name, weeks.name, weeks_bd.name = 'weekdays', 'weekdays_bd', 'weeks', 'weeks_bd'
months.name, months_bd.name, time_series.name = 'months', 'months_bd' 'time_series'

list_other = [weekdays, weeks, months, time_series]

### Weekday, week, month and time-series ###
for df in list_other:
    fig, ax = plt.subplots(figsize=(12,7.4)) # create new figure
    df.plot(kind='line', ax=ax, y='e_w', label='Wholesale')
    # df.plot(kind='line', ax=ax, y='e_r', label='Residual households', linestyle='dashed')
    # df.plot(kind='line', ax=ax, y='e_f', label='Flexibly-settled households', linestyle='dotted')
    # df.plot(kind='line', ax=ax, y='e_hh', label='Total households', linestyle='dashdot')
    ax.set(xlabel=df.name, ylabel='mean electricity consumption, kWh')
    ax.grid(axis='x')
    # Place a legend above the subplots
    plt.legend(bbox_to_anchor=(0., 1.02, 1., .102), loc='lower left',
               ncol=4, mode="expand", borderaxespad=0.)
    fig.savefig('latex/03_figures/'+df.name+'.png')
    print(df.name)
    plt.show()

# dummy weeks: 7, 8, 27, 28, 29, 30, 31, 42, 52, 53

weeks['e_w'].nsmallest(15)

#### Lowest days still included in business day dummy ###
for y in [2016, 2017, 2018]:
    print(time_series['e_w'][time_series['year']==y].nsmallest(5))
