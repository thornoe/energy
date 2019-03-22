# Imports
import numpy as np
import pandas as pd
import urllib.request as re
from bs4 import BeautifulSoup  # for parsing
import requests, json, tqdm, time, os, datetime

os.chdir('C:/Users/thorn/Onedrive/Dokumenter/GitHub/energy/python') # forwardslashes not backslashes

from scraping import scrape_cons
cons = scrape_cons(limit = 10000, sleeping = 10)



### SPOT PRICES ###
spot = pd.read_csv('elspot.csv')

# spot_copy = spot.copy()
spot.head(1)
spot.tail(1)

# Date format in spot prices
spot['date'] = pd.to_datetime(spot['date'])
spot['time'] = spot['time'].str.slice(0,2)

# Weekday, week and month
spot['day'] = spot['date'].dt.dayofweek # with Monday=0, Sunday=6
spot['week'] = spot['date'].dt.week
spot['month'] = spot['date'].dt.month
spot['year'] = spot['date'].dt.year
spot['trend'] = spot.index

# Holiday dummies
holy = pd.read_excel('Ovrigt.xlsx', 'Helligdage')
holy.columns = ['date', 'holy']
spot = pd.merge(spot, holy, how='left', on=['date'])
spot['holy'] = spot['holy'] == 1
# spot['holy'].value_counts(normalize=True, dropna=False) # No missing observations

# School holidays
for i in [7, 8, 27, 28, 29, 30, 31, 32, 42]:
    spot['w'+str(i)] = spot['week'] == i
    spot[['w'+str(i)]] = spot[['w'+str(i)]].astype(int)
    # print(spot['w'+str(i)].value_counts(normalize=True, dropna=False)) # No missing obs.

# On 2016-03-27, 2017-03-26, and 2018-03-25 spot prices are missing from 02-03
spot[spot['DK1'].isnull()]



df[['COL2', 'COL4']] = (df[['COL2', 'COL4']] == 'TRUE').astype(int)

cons.tail(1)
cons.head(1)







### CONSUMPTION DATA ###
cons = pd.read_csv('cons.csv')

cons.head(1)
cons.tail(1)

# Date format in consumption data
cons['date'] = cons['HourDK'].str.slice(0, 10)
cons['date'] = pd.to_datetime(cons['date'])
cons['time'] = cons['HourDK'].str.slice(11, 13)

# Drop company 920-993, sort and reset index
cons = cons[cons.GridCompany < 920]
cons.sort_values(by=['date', 'time', 'GridCompany'], inplace=True)
cons = cons.reset_index(drop=True)

# Drop and rename variables
cons = cons.iloc[:, [0, 1, 4, 5, 7, 8]]
cons.columns = ['flex', 'grid', 'hourly', 'residual', 'date', 'time']

grids = cons['grid'].value_counts(dropna=False).reset_index()
grids.columns = ['grid', 'obs']

zeroes = []
for i in grids['grid']:
    temp = cons[cons.grid == i]
    temp = temp['hourly']
    (cons == 0).astype(int).sum(axis=1)


    if temp == 0:
        print('Grid company:', i,' Zeroes:', temp.count())



grids
temp
.count()






### MERGING ###

pd.merge(cons, spot, how='left', on=['date', 'time'])


# Dummies & time to integers
spot[['holy', 'time']] = spot[['holy', 'time']].astype(int)

spot.describe()





##############################################################################
#   Scraping                                                                 #
##############################################################################

### CONSUMPTION ###
limit = 10000
sleeping = 10

url = 'https://api.energidataservice.dk/datastore_search?resource_id=consumptionpergridarea&limit=' # add limit
response = requests.get(url+'1')
if response.ok:
    d = response.json()
else:
    print('error: no response')

# d.keys()
# result.keys()
result = d['result']
total = result['total']
total
result['records']
result['_links']

### Collect all links from search on Energidataservice.dk
links = []
for offset in range(0,total,limit):
    end = '&offset={o}'.format(o = offset)
    links.append(url+str(limit)+end)
len(links)

### The scraping part. Don't run for fun. It takes 35-40 minutes.
data = []

for url in tqdm.tqdm(links):

    response = requests.get(url)

    if response.ok:
        d = response.json()
    else:
        print('error: no response')

    result = d['result']
    data += result['records']
    time.sleep(sleeping)

cons = pd.DataFrame(data)

cons.to_csv('cons.csv', index=False)


### ELSPOT ¤¤¤
spot = []
for x in range(2016, 2020):
    filename = 'elspot-prices_'+str(x)+'_hourly_dkk.xls'
    url = 'https://www.nordpoolgroup.com/globalassets/marketdata-excel-files/'+str(filename)
    re.urlretrieve(url,filename)
    data = pd.read_html(filename)
    data = pd.DataFrame(data[0])
    data = data.iloc[:, [0,1,8,9] ]
    data.columns=['date','time', 'DK1', 'DK2']
    spot.append(data)

spot = pd.concat(spot, axis=0)

spot.to_csv('elspot.csv', index=False)


### WIND POWER PROGNOSIS ###
wind = []
for x in range(2016, 2020):
    filename = 'wind-power-dk-prognosis_'+str(x)+'_hourly.xls'
    url = 'https://www.nordpoolgroup.com/globalassets/marketdata-excel-files/'+str(filename)
    re.urlretrieve(url,filename)
    data = pd.read_html(filename)
    data = pd.DataFrame(data[0])
    data.columns=['date','time', 'DK1', 'DK2']
    wind.append(data)

wind = pd.concat(wind, axis=0)

wind.to_csv('wind.csv', index=False)
