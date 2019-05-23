# Imports
import pandas as pd
import urllib.request as req
import os, requests, json, tqdm, time

# Set working directory (use forwardslashes not backslashes)
os.chdir('C:/Users/thorn/Onedrive/Dokumenter/GitHub/energy/python')


##############################################################################
#   EFFICIENT AND TRANSPARENT SCRAPING                                       #
##############################################################################
end_date = '2018-12-31' # last date with background data
s = requests.session()
# 'User-Agent' is required for scraping soltider.dk/api
s.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:66.0) Gecko/20100101 Firefox/66.0'
s.headers['email'] = 'jwz766@alumni.ku.dk' # allowing them to contact me
s.headers['name'] = 'Thor Donsby Noe (student)' # telling who I am

def parse(response):
    if response.ok:
        d = response.json() # Returns 'AttributeError' if all iterations in 'get' ran
        return d
    else:
        return print('error: no response')

def get(url, iterations=20, sleep_ok=1, sleep_err=5, check_function=lambda x: x.ok):
    """This module ensures that your script does not crash from connection errors,
        that you limit the rate of your calls,
        and that you have some reliability check.
        iterations : Define number of iterations before giving up.
    """
    for iteration in range(iterations):
        try:
            time.sleep(sleep_ok) # sleep everytime
            response = s.get(url) # the s-function defined above
            if check_function(response):
                return response # if succesful it will end the iterations here
        except requests.exceptions.RequestException as e: # find exceptions in the request library requests.exceptions
            """ Exceptions: Define which exceptions you accept, default is all.
            For specific errors see:
            stackoverflow.com/questions/16511337/correct-way-to-try-except-using-python-requests-module
            """
            print(e)  # print or log the exception message
            time.sleep(sleep_err) # sleep before trying again in case of error
    return None # code will purposely crash if you don't create a check function later


##############################################################################
#   CONSUMPTION - iterated to get complete dataset (takes <2 hours )         #
##############################################################################
# The big issue with the API address: API randomizes sample each time
# Solution: Run several iterations (7 seems to be enough to get all)
# More efficient alternative: Use SQL, see https://www.energidataservice.dk/api-guides

# Instead used as validation, i.e. that no new observations are added
url = 'https://api.energidataservice.dk/datastore_search?resource_id=consumptionpergridarea&limit=' # add limit
d = parse(s.get(url+'2'+'&offset=0'))

d.keys()
result = d['result']
result.keys()
result['records']
# result['_links']
total = result['total']
total


### Collect all links from search on Energidataservice.dk ###
links = []
limit = 10000
for offset in range(0,total,limit):
    end = '&offset={o}'.format(o = offset)
    links.append(url+str(limit)+end)
len(links)

### The scraping part ###
if os.path.exists('cons.csv'):
    cons = pd.read_csv('cons.csv') # load again
else:
    cons = pd.DataFrame()

improvement = total-len(cons)

while improvement>0:
    data = [] # Clear list to free up memory

    # Scraping
    for url in tqdm.tqdm(links):
        d = parse(get(url))
        result = d['result']
        data += result['records']
    cons2 = pd.DataFrame(data)

    # Brushing up the data to match 'cons'
    cons2['date'] = cons2['HourDK'].str.slice(0, 10)
    cons2['hour'] = cons2['HourDK'].str.slice(11, 13)
    cons2 = cons2.iloc[:, [0, 1, 4, 5, 7, 8]]
    cons2.columns = ['flex', 'grid', 'hourly', 'residual', 'date', 'hour']
    cons2 = cons2[['date', 'hour', 'grid', 'hourly', 'flex', 'residual']]
    cons2[['hour','grid']] = cons2[['hour','grid']].astype(int)

    # Append and remove duplicates
    cons_both = cons.append(cons2, ignore_index=True)
    cons_both = cons_both.drop_duplicates(['date', 'hour', 'grid', 'hourly', 'flex', 'residual'])

    # Any improvement?
    improvement = len(cons_both)-len(cons)
    print(len(cons_both)-total, 'non-unique rows of', total, '(share:', 1-len(cons_both)/total, ')')
    # Consumption can be the same at 'both instances of 2am' when switching to summertime

    # Replace old df with appended df
    cons = cons_both

cons.sort_values(by=['date', 'hour', 'grid']).reset_index(drop=True).to_csv('cons.csv', index=False)


##############################################################################
#   ELSPOT PRICES (takes around 10 seconds to download)                      #
##############################################################################
spot = []
for x in range(2016, 2019):
    filename = 'elspot-prices_'+str(x)+'_hourly_dkk.xls'
    url = 'https://www.nordpoolgroup.com/globalassets/marketdata-excel-files/'+str(filename)
    req.urlretrieve(url,filename)
    data = pd.read_html(filename, thousands='.', decimal=',')
    data = pd.DataFrame(data[0])
    data = data.iloc[:, [0,1,8,9] ]
    data.columns=['date','hour', 'P_DK1', 'P_DK2']
    spot.append(data)
spot = pd.concat(spot, axis=0)

spot['hour'] = spot['hour'].str.slice(0,2)

spot.to_csv('elspot.csv', index=False)


##############################################################################
#   WIND POWER PROGNOSIS (takes around 20 seconds to download)              x #
##############################################################################
%timeit
wind_dk, wind_se = [], []

# Denmark
for x in range(2016, 2019):
    filename = 'wind-power-dk-prognosis_'+str(x)+'_hourly.xls'
    url = 'https://www.nordpoolgroup.com/globalassets/marketdata-excel-files/'+str(filename)
    req.urlretrieve(url,filename)
    data = pd.read_html(filename)
    data = pd.DataFrame(data[0])
    data.columns=['date','hour', 'DK1', 'DK2']
    wind_dk.append(data)
wind_dk = pd.concat(wind_dk, axis=0)

# Sweden
for x in range(2016, 2019):
    filename = 'wind-power-se-prognosis_'+str(x)+'_hourly.xls'
    url = 'https://www.nordpoolgroup.com/globalassets/marketdata-excel-files/'+str(filename)
    req.urlretrieve(url,filename)
    data = pd.read_html(filename)
    data = pd.DataFrame(data[0])
    data.columns=['date','hour', 'SE1', 'SE2', 'SE3', 'SE4', 'SE']
    wind_se.append(data)
wind_se = pd.concat(wind_se, axis=0)

# Both countries
wind = pd.concat([wind_dk, wind_se[['SE']]], axis=1)
wind['hour'] = wind['hour'].str.slice(0,2)
wind.columns = ['date', 'hour', 'wp_DK1', 'wp_DK2', 'wp_SE']

### From MWh to GWh ###
for var in ['wp_DK1', 'wp_DK2', 'wp_SE']:
    wind[var] = wind[var].apply(lambda MWh: MWh/1000) # transformed to GWh, same name

wind.to_csv('wind.csv', index=False)


##############################################################################
#   TEMPERATURE DATA (takes around 60 min to scrape)                         #
##############################################################################
"""
Scraping:
Open (or install) Firefox, right-click on a graphic to "Inspect element".
Go to "Network" banner, choose XHR, update (F5) and look for JSON files.
- Go through the JSON files that are not 3rd part (advertisement).
- In the panel in the bottom right first look under "Response" for the data
- When the desired JSON-file is found, go to "Headers" for the "Request-URL"
"""
url = 'https://www.dmi.dk/dmidk_obsWS/rest/archive/hourly/danmark/temperature/' # add 'end'
end = "Københavns/2019/Februar/1"

d = parse(s.get(url+end))

# d[0].keys() # average temperatur
# d[1]['parameter'] # average temperatur
# d[1]['parameter'] # max temperature
# d[2]['parameter'] # min temperature
# d[0]['area']
# d[0]['dataserie'][0]
# result = d[0]['dataserie'][0]
# result['dateLocalString']
# result['valueRounded2OneDecimal']


### Create links ###
dti = pd.date_range('2016-01-01', end_date, freq='D').to_frame(index=False)
dti.columns = ['date']
dti['y'], dti['m'], dti['d'] = dti['date'].dt.year, dti['date'].dt.month, dti['date'].dt.day

def month(m):
    if m == 1: m = 'Januar'
    elif m == 2: m = 'Februar'
    elif m == 3: m = 'Marts'
    elif m == 4: m = 'April'
    elif m == 5: m = 'Maj'
    elif m == 6: m = 'Juni'
    elif m == 7: m = 'Juli'
    elif m == 8: m = 'August'
    elif m == 9: m = 'September'
    elif m == 10: m = 'Oktober'
    elif m == 11: m = 'November'
    elif m == 12: m = 'December'
    return m
dti['m'] = dti.m.apply(month)

for i in dti.index:
    y, m, d = dti.loc[i, 'y'], dti.loc[i, 'm'], dti.loc[i, 'd']
    dti.loc[i, 'kbh'] = (url+'Københavns/'+str(y)+'/'+str(m)+'/'+str(d))
    dti.loc[i, 'årh'] = (url+'Århus/'+str(y)+'/'+str(m)+'/'+str(d))

links_kbh = dti.kbh.tolist()
links_årh = dti.årh.tolist()


### The scraping part ###
datehour, temp_kbh, temp_årh = [], [], []

for links in [links_kbh, links_årh]:

    for url in tqdm.tqdm(links):

        d = parse(get(url)) # self-defined function to avoid crashes

        for hour in range(0, 24):
            result = d[0]['dataserie'][hour]
            if d[0]['area'] == 'Københavns':
                datehour.append(result['dateLocalString'])
                temp_kbh.append(result['valueRounded2OneDecimal'])
            else:
                temp_årh.append(result['valueRounded2OneDecimal'])


temp = pd.DataFrame({'date':datehour, 'hour':datehour, 'temp_kbh':temp_kbh, 'temp_årh':temp_årh})

temp['date'] = temp['date'].str.slice(0, 10)
temp['hour'] = temp['hour'].str.slice(-5, -3)

temp.to_csv('temp.csv', index=False)


##############################################################################
#   DAYTIME (takes around 60 min to scrape)                                  #
##############################################################################
url = 'https://soltider.dk/api?' # add latitude, longitude and date
kbh = 'lat=55.675637&lng=12.5673553&date=' # Rådhuspladsen 1, København
årh = 'lat=56.1525761&lng=10.2008397&date=' # Rådhuspladsen 2, Århus

d = parse(s.get(url+årh+end_date))

# d[0].keys() # average temperatur
# d[0]['sunRise']
# # d[0]['sunSet']

### Create links ###
links_kbh, links_årh = [], []
dict = {0: links_kbh, 1: links_årh}

dates = pd.date_range('2016-01-01', end_date, freq='D').astype(str).to_list()

for date in dates:
    links_kbh.append(url+kbh+date)
    links_årh.append(url+årh+date)


### The scraping part ###
rise_kbh, set_kbh, rise_årh, set_årh = [], [], [], []

for key, links in dict.items():
    for url in tqdm.tqdm(links):
        for iteration in range(20):
            try:
                d = parse(get(url))
                break # if succesfully parsed it will end the iterations here
            except json.decoder.JSONDecodeError as e:
                print(e)
                time.sleep(5)
        if key == 0: # and jump to this part when 'break' is activated
            rise_kbh.append(d[0]['sunRise'])
            set_kbh.append(d[0]['sunSet'])
        else:
            rise_årh.append(d[0]['sunRise'])
            set_årh.append(d[0]['sunSet'])

sun = pd.DataFrame({'date':dates, 'rise_kbh':rise_kbh, 'set_kbh':set_kbh, 'rise_årh':rise_årh, 'set_årh':set_årh})

sun.to_csv('sun.csv', index=False)
