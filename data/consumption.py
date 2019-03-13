import numpy as np
import pandas as pd
import requests, json, tqdm, time

limit = 1000
sleeping = 5

### Collect the total number of observations
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

### Collect all links from search on Bolighed by changing the page-parameter
links = []
for offset in range(0,total+limit,limit):
    end = '100&offset={o}'.format(o = offset)
    links.append(url+end)
# len(links)

### The scraping part - OBS only run this once. It takes almost 20 minutes.
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

### Return the collected data
return data
