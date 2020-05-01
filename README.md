# Elasticity of electricity demand
[Cathrine Falbe Pedersen](https://github.com/CathrinePedersen) and I estimate the price elasticity of electricity demand with respect to the hourly spot price, using Danish data from [Energinet](https://www.energidataservice.dk/en/dataset/consumptionpergridarea) on 48 grid companies for each hour of the years 2016-2018 split into wholesale and retail electricity consumption.

The project is a part of the 2019 seminar course in [Energy Economics](https://kurser.ku.dk/course/a%C3%98kk08318u/2018-2019) held by Frederik Roose Øvlisen at University of Copenhagen, Department of Economics.

See our

* [Seminar paper](https://github.com/thornoe/energy/blob/master/latex/main.pdf) and an overview of its main [figures](https://github.com/thornoe/energy/blob/master/figures.md).

* [Presentation](https://github.com/thornoe/energy/blob/master/presentation/main.pdf) on our (preliminary) results.

* Python code for [scraping](https://github.com/thornoe/energy/blob/master/python/_scraping.py), [cleaning](https://github.com/thornoe/energy/blob/master/python/_cleaning.py), and [descriping](https://github.com/thornoe/energy/blob/master/python/_descriptive.py) hourly data on electricity consumption and prices, wind power prognosis, temperature, sunrise and sunset. Likewise for the figures with estimation [results](https://github.com/thornoe/energy/blob/master/python/_results.py).

* Stata code for [descriptive statistics](https://github.com/thornoe/energy/blob/master/stata/_descriptive.do) and [estimation](https://github.com/thornoe/energy/blob/master/stata/_main.do) of grid-level electricity consumption using a Random Effects Instrumental Variables (REIV) model.

## Coefficients for time controls

The complete tables of estimation results including the coefficients for each of the interaction terms of the time controls:

* [Table 2:](https://github.com/thornoe/energy/blob/master/results/ws_preferred.md) log wholesale electricity consumption (REIV)

* [Table 3:](https://github.com/thornoe/energy/blob/master/results/r_region.md) log retail electricity consumption by region, hours 17-19 (REIV)

* [Table 4:](https://github.com/thornoe/energy/blob/master/results/r_radius.md) log retail electricity consumption in Radius, hours 17-19 (P2SLS)

* [Table 5:](https://github.com/thornoe/energy/blob/master/results/reduced_form_price_dk1.md) Reduced form of log spot price for DK1, business days, hours 11-15 (POLS)

* [Table 6:](https://github.com/thornoe/energy/blob/master/results/ws_fe.md) log wholesale electricity consumption, business days, hours 11-15 (FE, RE, FEIV, and REIV)

* [Table 7:](https://github.com/thornoe/energy/blob/master/results/ws_homoscedasticity.md) log wholesale electricity consumption by grid, business days, hours 11-15 (POLS)

  * [Table 7b:](https://github.com/thornoe/energy/blob/master/results/ws_homoscedasticity_bp.md) Breusch-Pagan / Cook-Weisberg test for heteroskedasticity

* [Table 8:](https://github.com/thornoe/energy/blob/master/results/reduced_form_price_dk2.md) Reduced form of log spot price for DK2, business days, hours 11-15 (POLS)

* [Table 9:](https://github.com/thornoe/energy/blob/master/results/ws_endog_overid_131.md) log wholesale electricity consumption for N1 (DK1), business days, hours 11-15

* [Table 10:](https://github.com/thornoe/energy/blob/master/results/ws_endog_overid_791.md) log wholesale electricity consumption for Radius (DK2), business days, hours 11-15

* [Table 11:](https://github.com/thornoe/energy/blob/master/results/ws_region_year.md) log wholesale electricity consumption by region/year, business days, hours 11-15 (REIV)

* [Table 12:](https://github.com/thornoe/energy/blob/master/results/ws_grids_large.md) log wholesale electricity consumption by large grid areas, business days, hours 11-15 (P2SLS)

* [Table 13:](https://github.com/thornoe/energy/blob/master/results/r_year.md) log retail electricity consumption by year, hours 17-19 (REIV)

## License

This project is released under the MIT License, that is, you can basically do anything with my code as long as you give appropriate credit and don’t hold me liable.

### MIT License

Copyright (c) 2019 Thor Donsby Noe

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
