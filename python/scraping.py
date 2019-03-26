import numpy as np
import pandas as pd
import requests, json, tqdm, time

yr: http://sharki.oslo.dnmi.no/portal/page?_pageid=73,39035,73_39049&_dad=portal&_schema=PORTAL
dmi: https://www.dmi.dk/vejrarkiv/

### Check the page is accessible and collect the total number of observations
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
for offset in range(0,total+limit,limit):
    end = '&offset={o}'.format(o = offset)
    links.append(url+str(limit)+end)
len(links)

### The scraping part. Don't run for fun. It takes around 35 minutes.
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



# Import packages
import numpy as np
import pandas as pd
import urllib.request as re

# Hourly electricity spot prices for West Denmark (DK1) and East Denmark (DK2)
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

spot.head(1)
spot.tail(1)
