### Imports
import pandas as pd
import urllib.request as req
import os, requests, json, tqdm, time
idx = pd.IndexSlice

### Set working directory to work pc (use forwardslashes not backslashes)
os.chdir('C:/Users/jwz766/Documents/GitHub/energy/python')
### Set working directory to home pc
# os.chdir('C:/Users/thorn/Onedrive/Dokumenter/GitHub/electricity/python')


##############################################################################
#   SET TIME INTERVAL                                                        #
##############################################################################
start_year = 2016 # first year
end_year = 2019 # last year
stop_year = end_year+1 # year after last year
start_date = str(start_year)+'-01-01' # hour 00 missing in DK-time due to being UTC+1
end_date = str(end_year)+'-12-31' # 2018-12-31 is last date with background data
stop_date = str(end_year+1)+'-01-01' # day after for SQL

##############################################################################
#   EFFICIENT AND TRANSPARENT SCRAPING                                       #
##############################################################################
s = requests.session()
### 'User-Agent' is required for scraping soltider.dk/api
s.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:66.0) Gecko/20100101 Firefox/66.0'
s.headers['email'] = 'thor.noe@econ.ku.dk' # allowing them to contact me
s.headers['name'] = 'Thor Donsby Noe (University of Copenhagen)' # telling who I am

def parse(response):
    if response.ok:
        d = response.json() # Returns 'AttributeError' if all iterations in 'get' ran
        return d
    else:
        return print('error: no response')

def get(url, iterations=20, sleep_ok=1, sleep_err=5, check_function=lambda x: x.ok):
    """ This module ensures that your script does not crash from connection errors,
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
            For specific errors see: https://stackoverflow.com/a/16511493/9846162
            """
            print(e)  # print or log the exception message
            time.sleep(sleep_err) # sleep before trying again in case of error
    return None # code will purposely crash if you don't create a check function later


##############################################################################
#   CONSUMPTION PER GRID AREA - optimal approach using SQL request (~ 1 min) #
##############################################################################
# See https://www.energidataservice.dk/api-guides

### First, check what the variable names are ###
url = 'https://api.energidataservice.dk/datastore_search?resource_id=consumptionpergridarea&limit=' # add limit and offset
d = parse(s.get(url+'1'+'&offset=0'))
d.keys()
result = d['result']
result.keys()
result['records']
# result['_links']
# total = result['total']
# total

### Write up the SQL request link ###
""" Found by making the following SQL request in a browser:
    https://api.energidataservice.dk/datastore_search_sql?sql=SELECT "HourDK", "GridCompany", "HourlySettledConsumption" from "consumptionpergridarea" WHERE date '2018-03-31' <= "HourDK" and "HourDK" < '2018-04-01'
"""
url_base = 'https://api.energidataservice.dk/datastore_search_sql?sql=SELECT%20%22HourDK%22,%20%22GridCompany%22,%20%22ResidualConsumption%22,%20%22FlexSettledConsumption%22,%20%22HourlySettledConsumption%22%20from%20%22consumptionpergridarea%22%20WHERE%20date%20%27'
url_mid  = '%27%20<=%20"HourDK"%20and%20"HourDK"%20<%20%27'
url = url_base+start_date+url_mid+stop_date+'%27'

### Check the data structure (for a single day) ###
d = parse(get(url_base+end_date+url_mid+stop_date+'%27'))
d.keys()
result = d['result']
result
result['records'][0]
result['fields']
result['sql']
### Scrape using the script created above
d = parse(get(url))
cons = pd.DataFrame(d['result']['records'])

# Brushing up the data
cons['date'] = cons['HourDK'].str.slice(0, 10)
cons['hour'] = cons['HourDK'].str.slice(11, 13)
cons = cons.drop('HourDK',axis=1)
cons.columns = ['hourly', 'residual', 'grid', 'flex',  'date', 'hour']
cons = cons[['date', 'hour', 'grid', 'hourly', 'flex', 'residual']]
cons[['hour','grid']] = cons[['hour','grid']].astype(int)

cons.sort_values(by=['date', 'hour', 'grid']).reset_index(drop=True).to_csv('cons.csv', index=False)


##############################################################################
#   ELSPOT PRICES (~ 10 sec)                                                 #
##############################################################################
spot = []
for x in range(start_year, stop_year):
    filename = 'elspot-prices_'+str(x)+'_hourly_dkk.xls'
    url = 'https://www.nordpoolgroup.com/globalassets/marketdata-excel-files/'+filename
    req.urlretrieve(url,filename)
    data = pd.read_html(filename, thousands='.', decimal=',')
    data = pd.DataFrame(data[0])
    data = data.iloc[:, [0,1,8,9] ]
    data.columns=['date','hour', 'p_DK1', 'p_DK2']
    spot.append(data)
spot = pd.concat(spot, axis=0)

spot['hour'] = spot['hour'].str.slice(0,2)

spot.to_csv('elspot.csv', index=False)


##############################################################################
#   WIND POWER PROGNOSIS (~ 15 sec)                                          #
##############################################################################
wind_dk, wind_se = [], []

# Denmark
for x in range(start_year, stop_year):
    filename = 'wind-power-dk-prognosis_'+str(x)+'_hourly.xls'
    url = 'https://www.nordpoolgroup.com/globalassets/marketdata-excel-files/'+str(filename)
    req.urlretrieve(url,filename)
    data = pd.read_html(filename)
    data = pd.DataFrame(data[0])
    data.columns=['date','hour', 'DK1', 'DK2']
    wind_dk.append(data)
wind_dk = pd.concat(wind_dk, axis=0)

# Sweden
for x in range(start_year, stop_year):
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

wind.to_csv('wind.csv', index=False)


##############################################################################
#   TEMPERATURE DATA (~ 8 min)                                               #
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
end = 'Københavns/'+str(stop_year)+'/Januar/1'
d   = parse(s.get(url+end))

# d[0].keys() # average temperature
# d[1]['parameter'] # average temperatur
# d[1]['parameter'] # max temperature
# d[2]['parameter'] # min temperature
# d[0]['area']
# d[0]['dataserie'][0]
# result = d[0]['dataserie'][0]
# result['dateLocalString']
# result['valueRounded2OneDecimal']

### Create links ###
dti = pd.date_range(start_date, end_date, freq='D').to_frame(index=False)
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

    print('Temperatures collected for', d[0]['area'])


temp = pd.DataFrame({'date':datehour, 'hour':datehour, 'temp_kbh':temp_kbh, 'temp_årh':temp_årh})

temp['date'] = temp['date'].str.slice(0, 10)
temp['hour'] = temp['hour'].str.slice(-5, -3)

temp.to_csv('temp.csv', index=False)


##############################################################################
#   DAYTIME (~ 8 min)                                                        #
##############################################################################
url = 'https://soltider.dk/api?' # add latitude, longitude and date
kbh = 'lat=55.675637&lng=12.5673553&date=' # Rådhuspladsen 1, København
årh = 'lat=56.1525761&lng=10.2008397&date=' # Rådhuspladsen 2, Århus

d = parse(s.get(url+årh+end_date))

# d[0].keys()
# d[0]['sunRise']
# # d[0]['sunSet']

### Create links ###
links_kbh, links_årh = [], []
dict = {'Kbh': links_kbh, 'Århus': links_årh}

dates = pd.date_range(start_date, end_date, freq='D').astype(str).to_list()

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
        if key == 'Kbh': # and jump to this part when 'break' is activated
            rise_kbh.append(d[0]['sunRise'])
            set_kbh.append(d[0]['sunSet'])
        else:
            rise_årh.append(d[0]['sunRise'])
            set_årh.append(d[0]['sunSet'])

    print('Sunrise and sunset collected for', key)


sun = pd.DataFrame({'date':dates, 'rise_kbh':rise_kbh, 'set_kbh':set_kbh, 'rise_årh':rise_årh, 'set_årh':set_årh})

sun.to_csv('sun.csv', index=False)


##############################################################################
#   ELSPOT AND ELPAS VOLUMES (~ 1 min)                                       #
##############################################################################
dict = {'elspot':[], 'elbas':[]}
volumes, shares = [], []

for y in range(2013, 2020):
    df = pd.DataFrame()
    for key, value in dict.items():
        filename = key+'-volumes_'+str(y)+'_hourly.xls'
        url = 'https://www.nordpoolgroup.com/globalassets/marketdata-excel-files/'+str(filename)
        req.urlretrieve(url,filename)
        d = pd.read_html(filename, thousands='.', decimal=',')
        d = pd.DataFrame(d[0]).fillna(0)
        if key=='elspot':
            df = d.loc[:,idx[:,:,['Unnamed: 0_level_2', 'Hours', 'DK1 Buy', 'DK2 Buy']]]
            df.columns=['date', 'hour', str(key)+'_DK1', str(key)+'_DK2']
        else:
            d = d.loc[:,idx[:,:,['Unnamed: 0_level_2', 'Unnamed: 1_level_2', 'DK1', 'DK2']]]
            d = d.loc[:,idx[:,:,:,['Unnamed: 0_level_3', 'Hours', 'Buy']]]
            d.columns=['date', 'hour', str(key)+'_DK1', str(key)+'_DK2']
            df = pd.merge(df, d, on=['date', 'hour'])
    df.iloc[:,-4:] = df.iloc[:,-4:].replace('-', 0).astype(float)
    volumes.append(df)
    s = [y, 100*(df.elbas_DK1.sum()+df.elbas_DK2.sum())/(df.elspot_DK1.sum()+df.elspot_DK2.sum()),
         100*df.elbas_DK1.sum()/df.elspot_DK1.sum(), 100*df.elbas_DK2.sum()/df.elspot_DK2.sum()]
    print(y, 'intraday shares. DK:', s[1], 'DK1:', s[2], 'DK2:', s[3], '\n')
    shares.append(s)
v = pd.concat(volumes, axis=0)
v['hour'] = v['hour'].str.slice(0, 2)
v.to_csv('volumes.csv', index=False)
s = pd.DataFrame(shares, columns=['year', 'DK pct.', 'DK1 pct.', 'DK2 pct.'])
s.to_excel('intraday_shares.xlsx', index=False)
5+
