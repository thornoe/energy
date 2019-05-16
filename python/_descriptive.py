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

# Subset data
business_days = data[data['bd']==1] # df for business days excluding holidays
tue_thu = business_days[(business_days.day !=1) & (business_days.day !=5)]
weekends = data[data['bd']==0] # df for weekends and holidays

# Aggregate by date
# business_days_agg = business_days.groupby(['date']).sum().reset_index()


##############################################################################
#   PLOTS BY HOUR                                                            #
##############################################################################
bd = business_days[['hour', 'e_w', 'e_f', 'e_r', 'e_hh']].groupby('hour').mean()
nbd = weekends[['hour', 'e_w', 'e_f', 'e_r', 'e_hh']].groupby('hour').mean()

fig, ax = plt.subplots(figsize=(12,7.4)) # create new figure
bd.plot(kind='line', ax=ax, y='e_w', label='Wholesale, business day')
nbd.plot(kind='line', ax=ax, y='e_w', label='Wholesale, non-business day', linestyle='dashed')
bd.plot(kind='line', ax=ax, y='e_hh', label='Retail, business day', linestyle='dotted')
nbd.plot(kind='line', ax=ax, y='e_hh', label='Retail, non-business day', linestyle='dashdot')
ax.set(xlabel='hour', ylabel='mean electricity consumption, MWh')
ax.set_xticks(np.arange(0, 24, 2))
ax.grid(axis='both')
plt.legend(loc='upper right', ncol=1)
# plt.legend(loc='upper left')
fig.savefig('latex/03_figures/cons_hours.png', bbox_inches='tight')
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
weekdays = data[['day', 'e_w', 'e_f', 'e_r', 'e_hh', 'p']].groupby('day').mean()
weekdays_bd = business_days[['day', 'e_w', 'e_f', 'e_r', 'e_hh', 'p']].groupby('day').mean()
weeks = data[['week', 'e_w', 'e_f', 'e_r', 'e_hh', 'p']].groupby('week').mean()
weeks_bd = business_days[['week', 'e_w', 'e_f', 'e_r', 'e_hh', 'p']].groupby('week').mean()
months = data[['month', 'e_w', 'e_f', 'e_r', 'e_hh', 'p']].groupby('month').mean()
months_bd = business_days[['month', 'e_w', 'e_f', 'e_r', 'e_hh', 'p']].groupby('month').mean()
time_series = data[['date', 'e_w', 'e_f', 'e_r', 'e_hh', 'year', 'p']].groupby('date').mean()
time_series_bd = business_days[['date', 'e_w', 'e_f', 'e_r', 'e_hh', 'year', 'p']].groupby('date').mean()
time_series_tt = tue_thu[['date', 'e_w', 'e_f', 'e_r', 'e_hh', 'year', 'p']].groupby('date').mean()

weekdays.name, weekdays_bd.name = 'weekdays', 'weekdays, business days'
weeks.name, weeks_bd.name = 'weeks', 'weeks, business days'
months.name, months_bd.name = 'months', 'months, business days'
time_series.name, time_series_bd.name, time_series_tt.name = 'time series', 'time series, business days', 'time series, Tuesday-Thursday'

df_list = [weekdays, weekdays_bd, weeks, weeks_bd, months, months_bd, time_series, time_series_bd, time_series_tt]

### Weekday, week, month ###
for df in df_list:
    fig, ax1 = plt.subplots(figsize=(12,7.4)) # create new figure
    ax1.grid(axis='x')
    color_left, color_right = 'b', 'o'

    # Left axis
    ax1.set_ylabel('mean electricity consumption, MWh', color=color_left)
    df.plot(kind='line', ax=ax1, y='e_w', color=color_left, label='Wholesale')
    df.plot(kind='line', ax=ax1, y='e_hh', color=color_left, label='Retail', linestyle='dotted')
    ax1.tick_params(axis='y', labelcolor=color_left)
    ax1.legend(loc='upper left', ncol=2)

    # Right axis
    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
    ax2.set_ylabel('spot price, DKK/MWh', color=color_right)
    df.plot(kind='line', ax=ax2, y='p', color=color_right, label='Spot price (RHS)', linestyle='dashed')
    ax2.tick_params(axis='y', labelcolor=color_right)
    ax2.legend(loc='upper right')

    ax1.set_xlabel(xlabel=df.name)
    fig.savefig('latex/03_figures/'+df.name+'.png', bbox_inches='tight')
    print(df.name)
    plt.show()

### Time series for consumption only ###
for df in [time_series, time_series_bd, time_series_tt]:
    fig, ax = plt.subplots(figsize=(12,7.4)) # create new figure
    df.plot(kind='line', ax=ax, y='e_w', label='Wholesale')
    df.plot(kind='line', ax=ax, y='e_hh', label='Retail', linestyle='dotted')
    # df.plot(kind='line', ax=ax, y='e_r', label='Residual households', linestyle='dotted')
    # df.plot(kind='line', ax=ax, y='e_f', label='Flexibly-settled households', linestyle='dashdot')
    ax.set(xlabel=df.name, ylabel='mean electricity consumption, MWh')
    ax.grid(axis='x')
    # Place a legend above the subplots
    plt.legend(bbox_to_anchor=(0., 1.02, 1., .102), loc='lower left',
               ncol=4, mode="expand", borderaxespad=0.)
    fig.savefig('latex/03_figures/cons_'+df.name+'.png', bbox_inches='tight')
    print(df.name)
    plt.show()

# dummy weeks: 7, 8, 27, 28, 29, 30, 31, 42, 52, 53
weeks['e_w']
weeks['e_w'].nsmallest(15)

#### Lowest days still included in business day dummy: July ###
for y in [2016, 2017, 2018]:
    print(time_series_bd['e_w'][time_series_bd['year']==y].nsmallest(10))


##############################################################################
#   PRICE AND WIND POWER PROGNOSIS by WEEKDAY, WEEK, MONTH, and TIME SERIES  #
##############################################################################
### Aggretating on price region ###
data_DK1 = data[data['DK1']==1].groupby('date').mean().reset_index() # df for business days excluding holidays
data_DK2 = data[data['DK1']==0].groupby('date').mean().reset_index() # df for business days excluding holidays
business_days_DK1 = business_days[business_days['DK1']==1].groupby('date').mean().reset_index() # df for business days excluding holidays
business_days_DK2 = business_days[business_days['DK1']==0].groupby('date').mean().reset_index() # df for business days excluding holidays
tue_thu_DK1 = tue_thu[tue_thu['DK1']==1].groupby('date').mean().reset_index() # df for business days excluding holidays
tue_thu_DK2 = tue_thu[tue_thu['DK1']==0].groupby('date').mean().reset_index() # df for business days excluding holidays
weekends_DK1 = weekends[weekends['DK1']==1].groupby('date').mean().reset_index() # df for business days excluding holidays
weekends_DK2 = weekends[weekends['DK1']==0].groupby('date').mean().reset_index() # df for business days excluding holidays

### Merging the two price regions to a single dataset ###
data_agg = data_DK1.merge(data_DK2[['date','p']], on='date', sort=False, suffixes=('_DK1', '_DK2'))
business_days_agg = business_days_DK1.merge(business_days_DK2[['date','p']], on='date', sort=False, suffixes=('_DK1', '_DK2'))
tue_thu_agg = tue_thu_DK1.merge(tue_thu_DK2[['date','p']], on='date', sort=False, suffixes=('_DK1', '_DK2'))
weekends_agg = weekends_DK1.merge(weekends_DK2[['date','p']], on='date', sort=False, suffixes=('_DK1', '_DK2'))

### Setting up the data ###
weekdays = data_agg[['day', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se']].groupby('day').mean()
weekdays_bd = business_days_agg[['day', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se']].groupby('day').mean()
weeks = data_agg[['week', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se']].groupby('week').mean()
weeks_bd = business_days_agg[['week', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se']].groupby('week').mean()
months = data_agg[['month', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se']].groupby('month').mean()
months_bd = business_days_agg[['month', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se']].groupby('month').mean()
time_series = data_agg[['date', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se']]
time_series_bd = business_days_agg[['date', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se']]
time_series_tt = tue_thu_agg[['date', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se']]

weekdays.name, weekdays_bd.name = 'weekdays', 'weekdays, business days'
weeks.name, weeks_bd.name = 'weeks', 'weeks, business days'
months.name, months_bd.name = 'months', 'months, business days'
time_series.name, time_series_bd.name, time_series_tt.name = 'time series', 'time series, business days', 'time series, Tuesday-Thursday'

df_list = [weekdays, weekdays_bd, weeks, weeks_bd, months, months_bd, time_series, time_series_bd, time_series_tt]

### Time series for consumption only ###
for df in df_list:
    fig, ax1 = plt.subplots(figsize=(12,7.4)) # create new figure
    ax1.grid(axis='x')
    color_left, color_right = 'g', 'o'

    # Left axis
    ax1.set_ylabel('mean electricity consumption, MWh', color=color_left)
    df.plot(kind='line', ax=ax1, y='e_w', color=color_left, label='Wholesale')
    df.plot(kind='line', ax=ax1, y='e_hh', color=color_left, label='Retail', linestyle='dotted')
    ax1.tick_params(axis='y', labelcolor=color_left)
    ax1.legend(loc='upper left', ncol=2)

    # Right axis
    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
    ax2.set_ylabel('spot price, DKK/MWh', color=color_right)
    df.plot(kind='line', ax=ax2, y='p', color=color_right, label='Spot price (RHS)', linestyle='dashed')
    ax2.tick_params(axis='y', labelcolor=color_right)
    ax2.legend(loc='upper right')

    ax1.set_xlabel(xlabel=df.name)
    fig.savefig('latex/03_figures/'+df.name+'.png', bbox_inches='tight')
    print(df.name)
    plt.show()
