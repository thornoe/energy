""" Color scale from d3.scale.category20c(), see:
    https://github.com/d3/d3-3.x-api-reference/blob/master/Ordinal-Scales.md#category10
"""
# Imports
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import os

# Set working folder
os.chdir('C:/Users/jwz766/Documents/GitHub/energy/') # one level up

# Load data
data = pd.read_csv('python/data.csv')
data.drop(['wp', 'wp_other', 'n_w', 'n_f', 'n_r', 'n_r', 'n_hh', 'n_t', 'name',\
           'trend', 'temp', 'temp_sq', 'daytime', 'holy', 'day_bd', 'non_bd',\
           's_tout', 'oct_mar'], axis=1, inplace=True)
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
bd = business_days[['hour', 'e_w', 'e_f', 'e_r', 'e_hh', 'e_t', 'p']].groupby('hour').mean()
nbd = weekends[['hour', 'e_w', 'e_f', 'e_r', 'e_hh', 'e_t', 'p']].groupby('hour').mean()


### Consumption only ###
fig, ax = plt.subplots(figsize=(12,7.4)) # create new figure
bd.plot(kind='line', ax=ax, y='e_w', label='Wholesale, business day', linestyle='solid', color='#3182bd')
nbd.plot(kind='line', ax=ax, y='e_w', label='Wholesale, non-business day', linestyle='dashed', color='#6baed6')
bd.plot(kind='line', ax=ax, y='e_hh', label='Retail, business day', linestyle='solid', color='#636363')
nbd.plot(kind='line', ax=ax, y='e_hh', label='Retail, non-business day', linestyle='dashed', color='#969696')
ax.set(xlabel='hour', ylabel='mean electricity consumption, MWh')
ax.set_xticks(np.arange(0, 24, 2))
ax.grid(axis='both')
plt.legend(loc='upper left', ncol=1)
fig.savefig('latex/03_figures/cons_hours.png', bbox_inches='tight')
plt.show()


### Consumption and prices ###
fig, ax1 = plt.subplots(figsize=(12,7.4)) # create new figure
color_left, color_right = '#3182bd', '#e6550d'
## Left axis:
bd.plot(kind='line', ax=ax1, y='e_t', label='Total consumption, business day (LHS)', linestyle='solid', color=color_left)
nbd.plot(kind='line', ax=ax1, y='e_t', label='Total consumption, non-business day (LHS)', linestyle='dashed', color='#6baed6')
ax1.set_ylabel('mean total electricity consumption, MWh', color=color_left)
ax1.tick_params(axis='y', labelcolor=color_left)
ax1.set_ylim([55,95])
ax1.set_xticks(np.arange(0, 24, 2))
ax1.grid(axis='both')
plt.legend(bbox_to_anchor=(.0, 1.02, .49, 1), # bbox=(x, y, width, height)
           loc='lower left', ncol=1, mode="expand", borderaxespad=0.)
# ax1.legend(loc='upper left')
## Right axis:
ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
ax2.set_ylabel('spot price, DKK/MWh', color=color_right)
bd.plot(kind='line', ax=ax2, y='p', label='Spot price, business day (RHS)', linestyle='solid', color=color_right)
nbd.plot(kind='line', ax=ax2, y='p', label='Spot price, non-business day (RHS)', linestyle='dashed', color='#fd8d3c')
ax2.tick_params(axis='y', labelcolor=color_right)
ax2.set_ylim([180,340])
plt.legend(bbox_to_anchor=(.51, 1.02, .49, 1), # bbox=(x, y, width, height)
           loc='lower left', ncol=1, mode="expand", borderaxespad=0.)
# ax2.legend(loc='upper right')
## Finish:
ax1.set_xlabel(xlabel='hour')
fig.savefig('latex/03_figures/total_hours.png', bbox_inches='tight')
plt.show()


##############################################################################
#   RADIUS PLOTS                                                             #
##############################################################################
### Discontinuity around Oct 1 2018 ###
radius = data[data['grid']==791]
y18 = radius[radius['year']==2018]
w39, w40 = y18[y18['week']==39], y18[y18['week']==40]
w39, w40 = w39[['hour', 'e_f', 'e_r']].groupby('hour').mean(), w40[['hour', 'e_f', 'e_r']].groupby('hour').mean()

### Last week of September and first week of October 2018 ###
fig, ax1 = plt.subplots(figsize=(12,7.4)) # create new figure
color_left, color_right = '#3182bd', '#636363'
## Left axis
w39.plot(kind='line', ax=ax1, y='e_f', label='Flex-settled, week 39 (LHS)', linestyle='solid', color=color_left)
w40.plot(kind='line', ax=ax1, y='e_f', label='Flex-settled, week 40 (LHS)', linestyle='dashed', color='#6baed6')
ax1.set_ylabel('mean flex-settled electricity consumption, MWh', color=color_left)
ax1.tick_params(axis='y', labelcolor=color_left)
ax1.set_ylim([100,325])
ax1.set_xticks(np.arange(0, 24, 2))
ax1.grid(axis='both')
plt.legend(bbox_to_anchor=(.0, 1.02, .52, 1), # bbox=(x, y, width, height)
           loc='lower left', ncol=2, mode="expand", borderaxespad=0.)
# ax1.legend(loc='upper left')
## Right axis
ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
w39.plot(kind='line', ax=ax2, y='e_r', label='Residual, week 39 (RHS)', linestyle='solid', color=color_right)
w40.plot(kind='line', ax=ax2, y='e_r', label='Residual, week 40 (RHS)', linestyle='dashed', color='#969696')
ax2.set_ylabel('mean residual electricity consumption, MWh', color=color_right)
ax2.tick_params(axis='y', labelcolor=color_right)
ax2.set_ylim([100,325])
plt.legend(bbox_to_anchor=(.53, 1.02, .47, 1), # bbox=(x, y, width, height)
           loc='lower left', ncol=2, mode="expand", borderaxespad=0.)
# ax2.legend(loc='upper right')
ax1.set_xlabel(xlabel='hour')
for xc in [16.5, 19.5]:
    plt.axvline(x=xc, color='k')
fig.savefig('latex/03_figures/radius_w39_w40.png', bbox_inches='tight')
plt.show()


### Consumption pattern in 2018 compared to 2017 and 2016 ###
data['oct_mar'] = np.isin(data['month'], [1,2,3, 10, 11, 12])
oct_mar = data[data['oct_mar']==1]
r = oct_mar[oct_mar['grid']==791] # Radius
o = oct_mar[oct_mar['grid']!=791] # other grid companies
r16, r17, r18 = r[r['year']==2016], r[r['year']==2017], r[r['year']==2018]
o16, o17, o18 = o[o['year']==2016], o[o['year']==2017], o[o['year']==2018]
r16, r17, r18 = r16[['hour', 'e_hh']].groupby('hour').mean(), r17[['hour', 'e_hh']].groupby('hour').mean(), r18[['hour', 'e_hh']].groupby('hour').mean()
o16, o17, o18 = o16[['hour', 'e_hh']].groupby('hour').mean(), o17[['hour', 'e_hh']].groupby('hour').mean(), o18[['hour', 'e_hh']].groupby('hour').mean()

### Radius ###
fig, ax = plt.subplots(figsize=(12,7.4)) # create new figure
r16.plot(kind='line', ax=ax, y='e_hh', label='Jan-Mar & Oct-Dec, 2016', linestyle='dotted', color='#aec7e8')
r17.plot(kind='line', ax=ax, y='e_hh', label='Jan-Mar & Oct-Dec, 2017', linestyle='dashed', color='#6baed6')
r18.plot(kind='line', ax=ax, y='e_hh', label='Jan-Mar & Oct-Dec, 2018', linestyle='solid', color='#3182bd')
ax.set(xlabel='hour', ylabel='mean electricity consumption, MWh')
ax.set_xticks(np.arange(0, 24, 2))
ax.grid(axis='both')
for xc in [16.5, 19.5]:
    plt.axvline(x=xc, color='k')
plt.legend(loc='upper left', ncol=1)
fig.savefig('latex/03_figures/oct-mar_radius.png', bbox_inches='tight')
plt.show()

### Other grid companies ###
fig, ax = plt.subplots(figsize=(12,7.4)) # create new figure
o16.plot(kind='line', ax=ax, y='e_hh', label='Jan-Mar & Oct-Dec, 2016', linestyle='dotted', color='#d9d9d9')
o17.plot(kind='line', ax=ax, y='e_hh', label='Jan-Mar & Oct-Dec, 2017', linestyle='dashed', color='#969696')
o18.plot(kind='line', ax=ax, y='e_hh', label='Jan-Mar & Oct-Dec, 2018', linestyle='solid', color='#636363')
ax.set(xlabel='hour', ylabel='mean electricity consumption, MWh')
ax.set_xticks(np.arange(0, 24, 2))
ax.grid(axis='both')
for xc in [16.5, 19.5]:
    plt.axvline(x=xc, color='k')
plt.legend(loc='upper left', ncol=1)
fig.savefig('latex/03_figures/oct-mar_other.png', bbox_inches='tight')
plt.show()


##############################################################################
#   PLOTS by WEEKDAY, WEEK, MONTH, and TIME SERIES                           #
##############################################################################
### Setting up the data ###
weekdays = data[['day', 'e_w', 'e_t', 'e_hh', 'p']].groupby('day').mean()
weekdays_bd = business_days[['day', 'e_w', 'e_t', 'e_hh', 'p']].groupby('day').mean()
weeks = data[['week', 'e_w', 'e_t', 'e_hh', 'p']].groupby('week').mean()
weeks_bd = business_days[['week', 'e_w', 'e_t', 'e_hh', 'p']].groupby('week').mean()
months = data[['month', 'e_w', 'e_t', 'e_hh', 'p']].groupby('month').mean()
months_bd = business_days[['month', 'e_w', 'e_t', 'e_hh', 'p']].groupby('month').mean()
time_series = data[['date', 'e_w', 'e_t', 'e_hh', 'year', 'p']].groupby('date').mean()
time_series_bd = business_days[['date', 'e_w', 'e_t', 'e_hh', 'year', 'p']].groupby('date').mean()
time_series_tt = tue_thu[['date', 'e_w', 'e_t', 'e_hh', 'year', 'p']].groupby('date').mean()

weekdays.name, weekdays_bd.name = 'weekdays', 'weekdays, business days'
weeks.name, weeks_bd.name = 'weeks', 'weeks, business days'
months.name, months_bd.name = 'months', 'months, business days'
time_series.name, time_series_bd.name, time_series_tt.name = 'time series', 'time series, business days', 'time series, Tuesday-Thursday'

df_list = [weekdays, weekdays_bd, weeks, weeks_bd, months, months_bd, time_series, time_series_bd, time_series_tt]

### Wholesale, retail and spot price by Weekday, week, month ###
for df in df_list:
    fig, ax1 = plt.subplots(figsize=(12,7.4)) # create new figure
    color_left, color_right = '#3182bd', '#e6550d'
    ## Left axis
    ax1.set_ylabel('mean electricity consumption, MWh', color=color_left)
    df.plot(kind='line', ax=ax1, y='e_w', label='Wholesale (LHS)', linestyle='solid', color=color_left, )
    df.plot(kind='line', ax=ax1, y='e_hh', label='Retail (LHS)', linestyle='dashed', color='#6baed6')
    ax1.tick_params(axis='y', labelcolor=color_left)
    plt.legend(bbox_to_anchor=(.0, 1.02, .40, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=2, mode="expand", borderaxespad=0.)
    ## Right axis
    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
    ax2.set_ylabel('spot price, DKK/MWh', color=color_right)
    df.plot(kind='line', ax=ax2, y='p', label='Spot price (RHS)', linestyle='dotted', color=color_right)
    ax2.tick_params(axis='y', labelcolor=color_right)
    ax2.legend(loc='upper right')
    plt.legend(bbox_to_anchor=(.80, 1.02, .20, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=2, mode="expand", borderaxespad=0.)

    ax1.set_xlabel(xlabel=df.name)
    fig.savefig('latex/03_figures/'+df.name+'.png', bbox_inches='tight')
    print(df.name)
    plt.show()


### Time series for consumption and spot price ###
for df in [time_series, time_series_bd, time_series_tt]:
    fig, ax1 = plt.subplots(figsize=(12,7.4)) # create new figure
    color_left, color_right = '#3182bd', '#e6550d'
    ## Left axis
    ax1.set_ylabel('mean electricity consumption, MWh', color=color_left)
    df.plot(kind='line', ax=ax1, y='e_t', label='Total consumption (LHS)', linestyle='solid', color=color_left, )
    ax1.tick_params(axis='y', labelcolor=color_left)
    plt.legend(bbox_to_anchor=(.0, 1.02, .49, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=2, mode="expand", borderaxespad=0.)
    ## Right axis
    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
    ax2.set_ylabel('spot price, DKK/MWh', color=color_right)
    df.plot(kind='line', ax=ax2, y='p', label='Spot price (RHS)', linestyle='dotted', color=color_right)
    ax2.tick_params(axis='y', labelcolor=color_right)
    ax2.legend(loc='upper right')
    plt.legend(bbox_to_anchor=(.51, 1.02, .49, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=2, mode="expand", borderaxespad=0.)

    ax1.set_xlabel(xlabel=df.name)
    fig.savefig('latex/03_figures/total_'+df.name+'.png', bbox_inches='tight')
    print(df.name)
    plt.show()


### Time series for consumption only ###
for df in [time_series, time_series_bd, time_series_tt]:
    fig, ax = plt.subplots(figsize=(12,7.4)) # create new figure
    df.plot(kind='line', ax=ax, y='e_w', label='Wholesale', linestyle='solid', color='#3182bd')
    df.plot(kind='line', ax=ax, y='e_hh', label='Retail', linestyle='solid', color='#636363')
    # df.plot(kind='line', ax=ax, y='e_r', label='Residual households', linestyle='dotted')
    # df.plot(kind='line', ax=ax, y='e_f', label='Flexibly-settled households', linestyle='dashdot')
    ax.set(xlabel=df.name, ylabel='mean electricity consumption, MWh')
    # Place a legend above the subplots
    plt.legend(loc='upper left', ncol=1)
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
data_DK1 = data[data['DK1']==1].groupby(['date', 'hour']).mean().reset_index() # df for business days excluding holidays
data_DK2 = data[data['DK1']==0].groupby(['date', 'hour']).mean().reset_index() # df for business days excluding holidays
business_days_DK1 = business_days[business_days['DK1']==1].groupby(['date', 'hour']).mean().reset_index() # df for business days excluding holidays
business_days_DK2 = business_days[business_days['DK1']==0].groupby(['date', 'hour']).mean().reset_index() # df for business days excluding holidays
tue_thu_DK1 = tue_thu[tue_thu['DK1']==1].groupby(['date', 'hour']).mean().reset_index() # df for business days excluding holidays
tue_thu_DK2 = tue_thu[tue_thu['DK1']==0].groupby(['date', 'hour']).mean().reset_index() # df for business days excluding holidays
weekends_DK1 = weekends[weekends['DK1']==1].groupby(['date', 'hour']).mean().reset_index() # df for business days excluding holidays
weekends_DK2 = weekends[weekends['DK1']==0].groupby(['date', 'hour']).mean().reset_index() # df for business days excluding holidays

### Merging the two price regions to a single dataset ###
data_agg = data_DK1.merge(data_DK2[['date','hour','e_t','p']], on=['date','hour',], sort=False, suffixes=('_DK1', '_DK2'))
business_days_agg = business_days_DK1.merge(business_days_DK2[['date','hour','e_t','p']], on=['date','hour',], sort=False, suffixes=('_DK1', '_DK2'))
tue_thu_agg = tue_thu_DK1.merge(tue_thu_DK2[['date','hour','e_t','p']], on=['date','hour',], sort=False, suffixes=('_DK1', '_DK2'))
weekends_agg = weekends_DK1.merge(weekends_DK2[['date','hour','e_t','p']], on=['date','hour',], sort=False, suffixes=('_DK1', '_DK2'))

### Setting up the data ###
hours = data_agg[['hour', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se', 'e_t_DK2']].groupby('hour').mean()
hours_bd = business_days_agg[['hour', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se', 'e_t_DK2']].groupby('hour').mean()
hours_tt = tue_thu_agg[['hour', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se', 'e_t_DK2']].groupby('hour').mean()
weekdays = data_agg[['day', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se', 'e_t_DK2']].groupby('day').mean()
weekdays_bd = business_days_agg[['day', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se', 'e_t_DK2']].groupby('day').mean()
weeks = data_agg[['week', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se', 'e_t_DK2']].groupby('week').mean()
weeks_bd = business_days_agg[['week', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se', 'e_t_DK2']].groupby('week').mean()
months = data_agg[['month', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se', 'e_t_DK2']].groupby('month').mean()
months_bd = business_days_agg[['month', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se', 'e_t_DK2']].groupby('month').mean()
time_series = data_agg[['date', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se', 'e_t_DK2']].groupby('date').mean().reset_index()
time_series_bd = business_days_agg[['date', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se', 'e_t_DK2']].groupby('date').mean().reset_index()
time_series_tt = tue_thu_agg[['date', 'p_DK1', 'p_DK2', 'wp_DK1', 'wp_DK2', 'wp_se', 'e_t_DK2']].groupby('date').mean().reset_index()

hours.name, hours_bd.name, hours_tt.name = 'hours', 'hours, business days', 'hours, Tuesday-Thursday'
weekdays.name, weekdays_bd.name = 'weekdays', 'weekdays, business days'
weeks.name, weeks_bd.name = 'weeks', 'weeks, business days'
months.name, months_bd.name = 'months', 'months, business days'
time_series.name, time_series_bd.name, time_series_tt.name = 'time series', 'time series, business days', 'time series, Tuesday-Thursday'

df_list = [hours, hours_bd, weekdays, weekdays_bd, weeks, weeks_bd, months, months_bd]

### Price and wind power prognosis by hour, day, week, and month ###
## All:
for df in df_list:
    fig, ax1 = plt.subplots(figsize=(12,7.4)) # create new figure
    color_left, color_right = '#31a354', '#e6550d'
    ## Left axis
    ax1.set_ylabel('wind power prognosis, MWh', color=color_left)
    df.plot(kind='line', ax=ax1, y='wp_DK1', label='Wind power prognosis, DK1 (LHS)', linestyle='solid', color=color_left)
    df.plot(kind='line', ax=ax1, y='wp_DK2', label='Wind power prognosis, DK2 (LHS)', linestyle='dashed', color='#74c476')
    # df.plot(kind='line', ax=ax1, y='wp_se', label='Wind power prognosis, Sweden (LHS)', linestyle='dotted', color='#a1d99b')
    if df.name == 'weekdays':
        ax1.set_ylim([0,1400])
        ax1.grid(axis='both')
    ax1.tick_params(axis='y', labelcolor=color_left)
    plt.legend(bbox_to_anchor=(.0, 1.02, .49, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=1, mode="expand", borderaxespad=0.)
    ## Right axis
    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
    ax2.set_ylabel('spot price, DKK/MWh', color=color_right)
    df.plot(kind='line', ax=ax2, y='p_DK1', label='Spot price, DK1 (RHS)', linestyle='solid', color=color_right)
    df.plot(kind='line', ax=ax2, y='p_DK2', label='Spot price, DK2 (RHS)', linestyle='dashed', color='#fd8d3c')
    if df.name == 'weekdays':
        ax2.set_ylim([0,350])
    ax2.tick_params(axis='y', labelcolor=color_right)
    plt.legend(bbox_to_anchor=(.51, 1.02, .49, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=1, mode="expand", borderaxespad=0.)
    ## Finish
    ax1.set_xlabel(xlabel=df.name)
    fig.savefig('latex/03_figures/wp_'+df.name+'.png', bbox_inches='tight')
    print(df.name)
    plt.show()

## DK1:
for df in df_list:
    fig, ax1 = plt.subplots(figsize=(12,7.4)) # create new figure
    color_left, color_right = '#31a354', '#e6550d'
    ## Left axis
    ax1.set_ylabel('wind power prognosis, MWh', color=color_left)
    df.plot(kind='line', ax=ax1, y='wp_DK1', label='Wind power prognosis, DK1 (LHS)', linestyle='solid', color=color_left)
    ax1.tick_params(axis='y', labelcolor=color_left)
    ax1.grid(axis='x')
    plt.legend(bbox_to_anchor=(.0, 1.02, .49, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=1, mode="expand", borderaxespad=0.)
    ## Right axis
    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
    ax2.set_ylabel('spot price, DKK/MWh', color=color_right)
    df.plot(kind='line', ax=ax2, y='p_DK1', label='Spot price, DK1 (RHS)', linestyle='solid', color=color_right)
    ax2.tick_params(axis='y', labelcolor=color_right)
    plt.legend(bbox_to_anchor=(.51, 1.02, .49, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=1, mode="expand", borderaxespad=0.)
    ## Finish
    ax1.set_xlabel(xlabel=df.name)
    fig.savefig('latex/03_figures/wp_DK1_'+df.name+'.png', bbox_inches='tight')
    print(df.name)
    plt.show()

## DK2:
for df in df_list:
    fig, ax1 = plt.subplots(figsize=(12,7.4)) # create new figure
    color_left, color_right = '#31a354', '#e6550d'
    ## Left axis
    ax1.set_ylabel('wind power prognosis, MWh', color=color_left)
    df.plot(kind='line', ax=ax1, y='wp_DK2', label='Wind power prognosis, DK2 (LHS)', linestyle='dashed', color=color_left)
    ax1.tick_params(axis='y', labelcolor=color_left)
    ax1.grid(axis='x')
    plt.legend(bbox_to_anchor=(.0, 1.02, .49, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=1, mode="expand", borderaxespad=0.)
    ## Right axis
    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
    ax2.set_ylabel('spot price, DKK/MWh', color=color_right)
    df.plot(kind='line', ax=ax2, y='p_DK2', label='Spot price, DK2 (RHS)', linestyle='dashed', color=color_right)
    ax2.tick_params(axis='y', labelcolor=color_right)
    plt.legend(bbox_to_anchor=(.51, 1.02, .49, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=1, mode="expand", borderaxespad=0.)
    ## Finish
    ax1.set_xlabel(xlabel=df.name)
    fig.savefig('latex/03_figures/wp_DK2_'+df.name+'.png', bbox_inches='tight')
    print(df.name)
    plt.show()


### Consumption, price, and wind power prognosis by hour, day, week, and month ###
## DK2:
for df in df_list:
    fig, ax1 = plt.subplots(figsize=(12,7.4)) # create new figure
    color_left, color_right = '#3182bd', 'k'
    ## Left axis
    ax1.set_ylabel('mean electricity consumption, MWh', color=color_left)
    df.plot(kind='line', ax=ax1, y='e_t_DK2', label='Total consumption, DK2 (LHS)', linestyle='solid', color=color_left)
    ax1.tick_params(axis='y', labelcolor=color_left)
    ax1.grid(axis='x')
    plt.legend(bbox_to_anchor=(.0, 1.02, .31, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=1, mode="expand", borderaxespad=0.)
    ## Right axis
    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
    ax2.set_ylabel('wind power prognosis, MWh     /     spot price, DKK/MWh', color=color_right)
    df.plot(kind='line', ax=ax2, y='wp_DK2', label='Wind power prognosis, DK2 (RHS)', linestyle='dashed', color='#31a354')
    df.plot(kind='line', ax=ax2, y='p_DK2', label='Spot price, DK2 (RHS)', linestyle='dotted', color='#e6550d')
    ax2.tick_params(axis='y', labelcolor=color_right)
    plt.legend(bbox_to_anchor=(.44, 1.02, .56, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=2, mode="expand", borderaxespad=0.)
    ## Finish
    ax1.set_xlabel(xlabel=df.name)
    fig.savefig('latex/03_figures/trio_DK2_'+df.name+'.png', bbox_inches='tight')
    print(df.name)
    plt.show()


### Time series for price and wind power prognosis ###
### DK1:
for df in [time_series, time_series_bd, time_series_tt]:
    fig, ax1 = plt.subplots(figsize=(12,7.4)) # create new figure
    color_left, color_right = '#31a354', '#e6550d'
    # Left axis
    ax1.set_ylabel('wind power prognosis, MWh', color=color_left)
    df.plot(kind='line', ax=ax1, x='date', y='wp_DK1', label='Wind power prognosis, DK1 (LHS)', linestyle='solid', color=color_left)
    ax1.tick_params(axis='y', labelcolor=color_left)
    plt.legend(bbox_to_anchor=(.0, 1.02, .49, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=1, mode="expand", borderaxespad=0.)
    # Right axis
    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
    ax2.set_ylabel('spot price, DKK/MWh', color=color_right)
    df.plot(kind='line', ax=ax2, x='date', y='p_DK1', label='Spot price, DK1 (RHS)', linestyle='solid', color=color_right)
    ax2.tick_params(axis='y', labelcolor=color_right)
    plt.legend(bbox_to_anchor=(.51, 1.02, .49, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=1, mode="expand", borderaxespad=0.)
    ax1.set_xlabel(xlabel=df.name)
    ax1.format_xdata = mdates.DateFormatter('%Y-%m-%d')
    fig.savefig('latex/03_figures/wp_dk1_'+df.name+'.png', bbox_inches='tight')
    print(df.name)
    plt.show()

### DK2:
for df in [time_series, time_series_bd, time_series_tt]:
    fig, ax1 = plt.subplots(figsize=(12,7.4)) # create new figure
    color_left, color_right = '#31a354', '#e6550d'
    # Left axis
    ax1.set_ylabel('wind power prognosis, MWh', color=color_left)
    df.plot(kind='line', ax=ax1, x='date', y='wp_DK2', label='Wind power prognosis, DK2 (LHS)', linestyle='solid', color=color_left)
    ax1.set_ylim(0)
    ax1.tick_params(axis='y', labelcolor=color_left)
    plt.legend(bbox_to_anchor=(.0, 1.02, .49, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=1, mode="expand", borderaxespad=0.)
    # Right axis
    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
    ax2.set_ylabel('spot price, DKK/MWh', color=color_right)
    df.plot(kind='line', ax=ax2, x='date', y='p_DK2', label='Spot price, DK2 (RHS)', linestyle='solid', color=color_right)
    ax2.tick_params(axis='y', labelcolor=color_right)
    plt.legend(bbox_to_anchor=(.51, 1.02, .49, 1), # bbox=(x, y, width, height)
               loc='lower left', ncol=1, mode="expand", borderaxespad=0.)
    ax1.set_xlabel(xlabel=df.name)
    ax1.format_xdata = mdates.DateFormatter('%Y-%m-%d')
    fig.savefig('latex/03_figures/wp_dk2_'+df.name+'.png', bbox_inches='tight')
    print(df.name)
    plt.show()
