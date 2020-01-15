# Imports
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import os

os.chdir('C:/Users/thorn/Onedrive/Dokumenter/GitHub/energy/') # one level up

# from scraping import scrape_cons
# cons = scrape_cons(limit = 10000, sleeping = 10)


##############################################################################
#   BACKGROUND DATA ON GRID COMPANIES                                        #
##############################################################################
wide = pd.read_excel('python/background.xlsx', header=[5,6], index_col=[0,1]).fillna(0).astype(int)

wide.loc[[233, '143', '144', '145', '232']]
wide.iloc[24,0]

### Mergers ###
# Nord Energi '031' took over Taars by dec-17 and Hirtshals by jan-18:
nord = pd.DataFrame(wide.loc[['031', '096', '095']].sum(axis=0)).T
# Læsø '085' took over Hornum by oct-17:
læsø = pd.DataFrame(wide.loc[['085', '014']].sum(axis=0)).T
# EnergiMidt '131' merged with HEF, AKE, Bjerringbro, ELRO, EnergiMidt Vest, Borris, and Sdr. Felding by jan-18 and Nibe by apr-18, becoming 'Eniig' and later 'N1':
n1 = pd.DataFrame(wide.loc[['131', '044', '052', '146', '149', '353', '392', '397', '015']].sum(axis=0)).T
# Dinel 233 was founded as a merge of Brabrand, Viby, GE, and Østjysk by apr-17:
dinel = pd.DataFrame(wide.loc[[233, '143', '144', '145', '232']].sum(axis=0)).T
# SE '344' took over VOS and Ærø by jan-18
se = pd.DataFrame(wide.loc[['248', '344', '443']].sum(axis=0)).T
# RAH Net '348' took over RAH Net 2 by dec-17 and MES Net by mar-18.
rah = pd.DataFrame(wide.loc[['348', '359', '246']].sum(axis=0)).T

# Applying the sum of grids included in a future merge to each prior month:
for col in range(0,len(wide.columns)):
    wide.iloc[3,col] = nord.iloc[0,col]
    wide.iloc[9,col] = læsø.iloc[0,col]
    wide.iloc[12,col] = n1.iloc[0,col]
    wide.iloc[24,col] = dinel.iloc[0,col]
    wide.iloc[33,col] = se.iloc[0,col]
    wide.iloc[35,col] = rah.iloc[0,col]
wide.loc[['031', '085', '131', 233, '344', '348']]
len(wide)
### Drop thoose with <10 total meters by dec-2018 ###
wide[wide.iloc[:,-1] == 0] # 19 dropped with 0 meters
# wide[(wide.iloc[:,-1] > 0) & (wide.iloc[:,-1] < 10)] # 2 more dropped: Vestjyske Net (2 meters) & FynsNet (7 meters)
wide = wide[wide.iloc[:,-1] >= 10]
# wide[wide.iloc[:,-1] == 0] # none left without hourly metering (wholesale meters)

### Drop the six grids with zero wholesale consumption throughout 2016-2018 ###
#   ie. Aal El-net, Hjerting Transformatorforening, Paarup Elforsyning,
#       Brenderup Netselskab, Nr. Broby-Vøjstrup Netselskab, Midtfyns Elforsyning
for i in ['370', '371', '587', '588', '590', '591']:
    wide.drop(i, level=0, inplace=True)

### Drop aggregate row and save ###
wide.drop('Hovedtotal', level=0, inplace=True) # 48 grids in total
wide.to_excel('python/grids.xlsx', index=True)

### Long format ###
meters = wide.stack(level=0).fillna(0) # set no. flex-settled to 0, not None
meters = meters.reorder_levels([2, 1, 0], axis=0).reset_index()
meters.columns = ['date', 'name', 'grid', 'n_f', 'n_r', 'n_w', 'n_t']
meters['n_hh'] = meters[['n_f', 'n_r']].sum(axis=1, skipna=True)
meters['grid'] = meters['grid'].astype(int)

### Time format ###
meters['date'] = pd.to_datetime(meters['date'])
meters['month'], meters['year'] = meters['date'].dt.month, meters['date'].dt.year
meters = meters[['grid', 'n_w', 'n_f', 'n_r', 'n_hh', 'n_t', 'month', 'year', 'name']]

meters.tail(2)


##############################################################################
#   CONSUMPTION DATA                                                         #
##############################################################################
### Read CSV file ###
cons = pd.read_csv('python/cons.csv').fillna(0) # set flex-settled to 0, not None
cons['date'] = pd.to_datetime(cons['date'])

### Mergers ###
mergers = np.array([[31, [96, 95]], # Nord Energi '031' took over Taars by dec-17 and Hirtshals by jan-18:
                    [85, [14]], # Læsø '085' took over Hornum by oct-17:
                    [131, [44, 52, 146, 149, 353, 392, 397, 15]], # EnergiMidt '131' merged with HEF, AKE, Bjerringbro, ELRO, EnergiMidt Vest, Borris, and Sdr. Felding by jan-18 and Nibe by apr-18, becoming 'Eniig' and later 'N1':
                    [233, [143, 144, 145, 232]], # Dinel 233 was founded as a merge of Brabrand, Viby, GE, and Østjysk by apr-17:
                    [344, [248, 443]], # SE '344' took over VOS and Ærø by jan-18
                    [348, [359, 246]]]) # RAH Net '348' took over RAH Net 2 by dec-17 and MES Net by mar-18.
for row in range(len(mergers)):
    m = mergers[row][0]
    overtaken = mergers[row][1]
    df = cons[cons.grid==m]
    for i in overtaken:
        df = pd.merge(df, cons[cons.grid==i], how='outer',\ # 'outer' as 'Dinel' lacks early observations
                        on=['date','hour'], suffixes=['', '_r']).fillna(0)
        for var in ['hourly', 'flex', 'residual']:
            df[var] = df[var] + df[str(var+'_r')]
        df = df[['date', 'hour', 'grid', 'hourly', 'flex', 'residual']]
    df['grid'] = m # 'Dinel' lacking  grid number for observations prior to formation
    cons.drop(cons[cons.grid==m].index, inplace=True)
    cons = pd.concat([cons, df], sort=False, ignore_index=True)

### Create aggregates of households and total ###
cons['households'] = cons[['flex', 'residual']].sum(axis=1, skipna=True)
cons['total'] = cons[['hourly', 'households']].sum(axis=1, skipna=True)

### Rename columns ###
cons.columns = ['date', 'hour', 'grid', 'e_w', 'e_f', 'e_r', 'e_hh', 'e_t']
# cons.head(2) # starts at 1AM due to time format being UTC+1, not UTC

### From kWh to MWh ###
for var in ['e_w', 'e_f', 'e_r', 'e_hh', 'e_t']:
    cons[var] = cons[var].apply(lambda kWh: kWh/1000) # transformed to MWh, same name


##############################################################################
#   MERGE WITH SPOT PRICES, WIND POWER PROGNOSIS AND NO. METERS              #
##############################################################################
### Read CSV files ###
spot = pd.read_csv('python/elspot.csv') # SPOT PRICES
spot['date'] = pd.to_datetime(spot['date'])
wind = pd.read_csv('python/wind.csv') # WIND POWER PROGNOSIS
wind['date'] = pd.to_datetime(wind['date'])

### Merging ###
grids = pd.merge(cons, spot, how='inner', on=['date', 'hour'])
grids = pd.merge(grids, wind, how='inner', on=['date', 'hour'])

### Dummy for being in price area DK1 ###
grids['DK1'] = grids['grid'] < 700
grids['DK1'] = grids['DK1'].astype(int)

### Prices and wind power prognosis in the relevant price area ###
grids['p'] = (grids['P_DK1']*grids['DK1']+grids['P_DK2']*(1-grids['DK1']))
grids['wp'] = (grids['wp_DK1']*grids['DK1']+grids['wp_DK2']*(1-grids['DK1']))
grids['wp_other'] = (grids['wp_DK1']*(1-grids['DK1'])+grids['wp_DK2']*grids['DK1'])
grids['wp_se'] = grids['wp_SE']

### Create month and year variables for merging ###
grids['month'], grids['year'] = grids['date'].dt.month, grids['date'].dt.year

### Merge with background grids on no. meters ###
grids = pd.merge(grids, meters, how='inner', on=['month', 'year', 'grid'])

### Drop columns ###
grids.drop(['P_DK1','P_DK2','wp_SE','month','year'], axis=1, inplace=True)

grids.head(2)


##############################################################################
#   WEATHER VARIABLES, GROWTH TREND, AND DAYTIME                             #
##############################################################################
# Read csv file
sun = pd.read_csv('python/sun.csv') # sunrise and sunset
sun['date'] = pd.to_datetime(sun['date'])

### Technology/growth time-trend variable (counting no. days since 2016-01-01) ###
sun['trend'] = sun.index

# Sunrise and sunset in hour/minute format
sun['r_kbh'] = 1-sun['rise_kbh'].str.slice(-2).astype(int)/60 # sun share of hour
sun['rise_kbh'] = sun['rise_kbh'].str.slice(0,1).astype(int) # sunrise hour
sun['s_kbh'] = sun['set_kbh'].str.slice(-2).astype(int)/60 # sun share of hour
sun['set_kbh'] = sun['set_kbh'].str.slice(0,2).astype(int) # sunset hour
sun['r_årh'] = 1-sun['rise_årh'].str.slice(-2).astype(int)/60 # sun share of hour
sun['rise_årh'] = sun['rise_årh'].str.slice(0,1).astype(int) # sunrise hour
sun['s_årh'] = sun['set_årh'].str.slice(-2).astype(int)/60 # sun share of hour
sun['set_årh'] = sun['set_årh'].str.slice(0,2).astype(int) # sunset hour

### READ TEMPERATURE FILE AND MERGE ###
temp = pd.read_csv('python/temp.csv') # sunrise and sunset
temp['date'] = pd.to_datetime(temp['date'])
W = pd.merge(sun, temp, how='inner', on=['date'])

### Daytime, i.e. share of hour between sunrise and sunset, between [0,1] ###
W['dt_kbh'] = 0
W['dt_årh'] = 0

for city in ['kbh', 'årh']:
    conditions = [W['hour'] == W['rise_'+city],
                  (W['rise_'+city] < W['hour']) & (W['hour'] < W['set_'+city]),
                  W['hour'] == W['set_'+city]]
    choices = [W['r_'+city], 1, W['s_'+city]]
    W['dt_'+city] = np.select(conditions, choices)

### Drop irrelevant sunrise and sunset columns ###
W = W.iloc[:,[0,5,-5,-4,-3,-2,-1]]

W.head(2)


##############################################################################
#   CREATING THE JOINT DATASET                                               #
##############################################################################
### Merging ###
data = pd.merge(grids, W, how='left', on=['date', 'hour'])

### Temperature and temperature squared in the relevant price area ###
data['temp'] = (data['temp_årh']*data['DK1']+data['temp_kbh']*(1-data['DK1']))
data['temp_sq'] = data['temp']**2 # Temperature squared

### Daytime in the relevant price area ###
data['daytime'] = (data['dt_årh']*data['DK1']+data['dt_kbh']*(1-data['DK1']))

### Drop columns ###
data.drop(['temp_kbh', 'temp_årh', 'dt_kbh', 'dt_årh'], axis=1, inplace=True)


##############################################################################
#   CALENDAR VARIABLES                                                       #
##############################################################################
### Weekday, week and month ###
data['day'] = data['date'].dt.dayofweek # standard is Monday=0, Sunday=6
data['day'] = data['day']+1             # instead changed to Monday=1, Sunday=7
data['week'] = data['date'].dt.week
data['month'] = data['date'].dt.month
data['year'] = data['date'].dt.year

### Holiday dummies: For holidays not already placed in weekends ###
holy = pd.read_excel('python/holy.xlsx', 'Helligdage')
holy.columns = ['date', 'holy']
data = pd.merge(data, holy, how='left', on=['date']).fillna(0)

### Business day dummy: not weekend or holiday ###
data['bd'] = np.select([(data['day']<6) & (data['holy']==0)], [1])

### Categorical variable for business days: Mon, Tue, Wed, Thu, and Fri ###
conditions = [(data['bd']==1) & (data['day']==1),
              (data['bd']==1) & (data['day']==2),
              (data['bd']==1) & (data['day']==3),
              (data['bd']==1) & (data['day']==4),
              (data['bd']==1) & (data['day']==5)]
data['day_bd'] = np.select(conditions, [1, 2, 3, 4, 5]) # OBS: 0 if non-bd

### For non-business days (weekends, holidays) ###
data['non_bd'] = np.select([data['bd']==0], [1])

### Share of consumers in net company 'Radius' exposed to time-of-use tariff ###
data['s_tout'] = np.select(\
    [(data['grid']==791) & (np.isin(data['hour'], [17,18,19])) & (data['month']>9),
     (data['grid']==791) & (np.isin(data['hour'], [17,18,19])) & (data['month']<4)],
    [data['n_f']/data['n_hh'], data['n_f']/data['n_hh']])

### Oct-Mar and net company 'Radius' as a control for the above ###
data['oct_mar'] = np.select(\
    [(data['grid']==791) & (np.isin(data['hour'], [17,18,19])) & (data['month']>9),
     (data['grid']==791) & (np.isin(data['hour'], [17,18,19])) & (data['month']<4)],
    [1, 1])

data.iloc[:,list(range(-14,0))].describe()


##############################################################################
#   REMOVE DUPLICATES, CHECK RANK, SORT AND RESET INDEX                      #
##############################################################################
''' Issues due to switching between summertime and wintertime:
    Switching to wintertime --> two observations for hour 02
    i.e. on 2016-10-30, 2017-10-29, 2018-10-28 due to wintertime
    Switching to summer time --> data is missing for hour 02
    i.e. On 2016-03-27, 2017-03-26, 2018-03-25, and 2019-03-31
'''

### Remove duplicates due to switching to wintertime; sort; reset index ###
data = data.drop_duplicates(['date', 'hour', 'grid'])\
    .sort_values(by=['date', 'hour', 'grid']).reset_index(drop=True)

### Rows with missing data is removed due to 'inner'-merge ###
# data['date'].value_counts().nsmallest(5)
# data['date'].value_counts().describe()

### Checking the dataset has full rank (i.e. no observations are missing) ###
''' 1st hour missing due to datasource starting at 0am UTC, but our data at UTC+1
    3 hours missing due to switching to summertime each year '''
full_rank = 24*len(pd.date_range('2016-01-01', '2018-12-31', freq='D'))-1-3

print('Full rank:',
      full_rank, 'obs. per grid',
      '\nMissing observations:',
      full_rank - data['grid'].value_counts(dropna=False).mean())


##############################################################################
#   DATA SET FOR STATA                                                       #
##############################################################################
### Copy of df ###
ds = data.drop(['e_f', 'e_r', 'e_t', 'n_t', 'name'], axis=1)

### The natural logarithm of consumption and price ###
def log_apply(s):
    if s < 1: return 0
    else: return np.log(s)
for var in ['e_w', 'e_hh', 'n_w', 'n_hh', 'n_f', 'n_r', 'p']:
    ds['_'+var] = ds[var] # non-log values
    ds[var] = ds[var].apply(log_apply) # transformed to log values, same name

### Wind power prognosis from MWh to GWh ###
for var in ['wp_DK1', 'wp_DK2', 'wp', 'wp_other', 'wp_se']:
    ds[var] = ds[var].apply(lambda MWh: MWh/1000) # transformed to GWh, same names

### Datetime format including hours ###
ds['date'] = pd.to_datetime(ds['date'].astype(str)+' '+ds['hour'].astype(str)+':00:00')

ds.describe().T

### Applying share TOUT in Radius to all grid companies for robustness check ###
ds2 = ds[ds.loc[:,'grid'] == 791]
ds2 = ds2[['date', 's_tout']]
ds2.columns = ['date', 's_radius']
ds = pd.merge(ds, ds2, how='inner', on='date')


##############################################################################
#   EXPORT READY DATASETS                                                    #
##############################################################################
### To DTA for STATA ###
ds.to_stata('D:/Google Drev/KU Thor/Energy Economics/Data/data_stata.dta', write_index=False) # too big for GitHub
ds.columns.values


### To CSV for plots ###
data.to_csv('python/data.csv', index=False)
