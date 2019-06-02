////////////////////////////////////////////////////////////////////////////////
////////	0. Global set up 											////////
////////////////////////////////////////////////////////////////////////////////


*** Global directories, Cathrine ***
cd 				"C:\Users\Cathrine Pedersen\Documents\GitHub\energy\stata"
*global data		"??? \Google Drev\Energy Economics\Data"
global latex	"C:\Users\Cathrine Pedersen\Documents\GitHub\energy\latex\04_tables"
global results	"C:\Users\Cathrine Pedersen\Documents\GitHub\energy\results"


*** Global directories, Thor ***
cd 				"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\stata"
global data		"D:\Google Drev\KU Thor\Energy Economics\Data"
global latex	"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\latex\04_tables"
global results	"C:\Users\thorn\OneDrive\Dokumenter\GitHub\energy\results"


*** Global variable lists ***
/* 	'omit' is ignored during the 1st stage of P2SLS nor G2SLS, thus, for consistent
	 interpretation we need to control how multicollinearity is avoided */
* Wholesale:
global x_w "n_w temp* trend i.year i.week" // daytime only relevant for shoulder and off-peak
* Retail:
global x_hh "n_hh temp* daytime trend i.year i.week"
* Interaction terms for relevant hours (omitting interactions with december)
global x_11_15 "i(11 12 13 14 15).hour#i(1 2 3 4 5).day_bd i(11 12 13 14 15).hour#i(1 2 3 4 5 6 7 8 9 10 11).month" // baseline: i12.month#i(11 12 13 14 15).hour
global x_17_19 "i(17 18 19).hour#i1.non_bd i(17 18 19).hour#i(1 2 3 4 5).day_bd i(17 18 19).hour#i(1 2 3 4 5 6 7 8 9 10 11).month" // baseline: i12.month#i(17 18 19).hour


*** Load data ***
set scheme s1color

clear all

use "$data/data_stata.dta", clear

xtset grid date, clocktime delta(1 hour) // strongly balanced


////////////////////////////////////////////////////////////////////////////////
////	1. Descriptive statistics											////
////////////////////////////////////////////////////////////////////////////////
do "_descriptive" // reload data before running

/*	overall: Pooled mean, std.dev., var, min and max
	between: Cross-section std.dev. and var (not mean, min. or max!)
			 Permanent differences between grids
			 (dif. between the overtime-means for each grid)
	within:	 Time series std.dev. and var (not mean, min. or max!)
			 Differences across time within each grid
			 e.g. time-of-day & day-of-week deviations, business cycles or trend
*/

////////////////////////////////////////////////////////////////////////////////
////	2. Load and set up data for regressions								////
////////////////////////////////////////////////////////////////////////////////
drop n_f n_r holy wp_DK1 wp_DK2 _*

label variable e_w "log wholesale consumption"
label variable e_hh "log retail consumption"
label variable DK1 "Price region DK1"
label variable p "log spot price"
label variable wp "Wind power prognosis same region"
label variable wp_other "Wind power prognosis other region"
label variable wp_se "Wind power prognosis for Sweden"
label variable n_w "log wholesale meters"
label variable n_hh "log retail meters"
label variable trend "Time trend"
label variable temp "Temperature"
label variable temp_sq "Temperature squared"
label variable daytime "Daytime"
label variable temp "Temperature"
label variable daytime "Daytime"
label variable bd "Business day"
label variable non_bd "Non-business day"
label variable s_tout "Share time-of-use tariff"
label variable oct_mar "Oct-Mar (Radius only)"
label variable s_radius "Share TOUT in Radius"


////////////////////////////////////////////////////////////////////////////////
////	3. Regressions for Wholesale		 								////
////////////////////////////////////////////////////////////////////////////////

********************************************************************************
**** 	Preferred specifications											****
********************************************************************************
est clear
xtivreg e_w (p = c.wp#DK1) $x_w $x_11_15 ///
	if bd==1 & inrange(hour,11,15), re vce(cluster grid) first
est store peak, title("Peak: 11-15")

qui xtivreg e_w (p = c.wp#DK1) $x_w ///
	i(0 1 2 3 4).hour#i(1 2 3 4 5).day_bd ///
	i(0 1 2 3 4).hour#i(1 2 3 4 5 6 7 8 9 10 11).month ///
	if bd==1 & inrange(hour,0,4), re vce(cluster grid)
est store off_peak, title("Off-peak: 00-04")

qui xtivreg e_w (p = c.wp#DK1) $x_w daytime ///
	i(5 6 7 8 9 10 16 17 18 19 20 21 22 23).hour#i(1 2 3 4 5).day_bd ///
	i(5 6 7 8 9 10 16 17 18 19 20 21 22 23).hour#i(1 2 3 4 5 6 7 8 9 10 11).month ///
	if bd==1 & inrange(hour,5,10)|inrange(hour,16,23), re vce(cluster grid)
est store shoulder, title("Shoulder")

qui xtivreg e_w (p = c.wp#DK1) $x_w daytime ///
	i.hour#i(1 2 3 4 5 6 7 8 9 10 11).month ///
	if non_bd==1, re vce(cluster grid)
est store non_bd, title("Non-business day")

estout _all using "ws_preferred.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R-sq within" "R-sq between" "Number of groups" "Obs. per group") )
estout _all using $latex/ws_preferred.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("\(R^2\) within" "\(R^2\) between" "Number of groups" "Obs. per group") ) ///
	prehead("\begin{tabular}{lcccc}\toprule") posthead("\midrule") ///
	prefoot("\midrule") postfoot("\bottomrule\end{tabular}")
estout _all using $results/ws_preferred.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R&sup2 within" "R&sup2 between" "Number of groups" "Obs. per group") ) ///
	prehead("**Table:** log wholesale electricity consumption (REIV)<br>*Business days (col. 1-3) and non-business days (col. 4). Baseline: year 2016 and each hour for December.*<br><html><table>") ///
	postfoot("</table>Robust standard errors are clustered at grid level and reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Log spot price is instrumented for by wind power prognosis for the same region.</html>")

	
********************************************************************************
**** 	Elasticity for each hour (business days joint)						****
********************************************************************************
est clear
qui foreach h of numlist 0/23 {
	qui xtivreg e_w (p = c.wp#DK1) $x_w daytime ///
		i(1 2 3 4 5).day_bd i(1 2 3 4 5 6 7 8 9 10 11).month ///
		if bd==1 & hour==`h', re vce(cluster grid)
	est store h_`h', title("`h'")
}
estout _all using "ws_hour.xls", replace ///
	label cells( b(fmt(4)) se(par fmt(4)) ) ///
	drop(*.* n_w temp* trend _cons)
estout _all using $results/ws_hour.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R&sup2 within" "R&sup2 between" "Number of groups" "Obs. per group") ) ///
	prehead("**Table:** log wholesale electricity consumption by hour (REIV)<br>*Business days. Baseline: December.*<br><html><table>") ///
	postfoot("</table>Robust standard errors are clustered at grid level and reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Log spot price is instrumented for by wind power prognosis for the same region.</html>")


********************************************************************************
**** 	Elasticity for each single hour-day combination						****
********************************************************************************
est clear
foreach d of numlist 1/5 {
	est clear
	qui foreach h of numlist 0/23 {
		xtivreg e_w (p = c.wp#DK1) $x_w daytime ///
			i(1 2 3 4 5 6 7 8 9 10 11).month ///
			if day_bd==`d' & hour==`h', fe vce(cluster grid)
		est store bd`d'_h`h', title("`h'")
	}
	estout _all using "ws_bd`d'_hour.xls", replace ///
		label cells( b(fmt(4)) se(par fmt(4)) ) ///
		drop(*.* n_w temp* daytime trend _cons)
}
est clear
qui foreach h of numlist 0/23 {
	xtivreg e_w (p = c.wp#i.DK1) $x_w daytime ///
		i(1 2 3 4 5 6 7 8 9 10 11).month ///
		if non_bd==1 & hour==`h', fe vce(cluster grid)
	est store nbd_h_`h', title("`h'")
}
estout _all using "ws_non-bd_hour.xls", replace ///
	label cells( b(fmt(4)) se(par fmt(4)) ) ///
	drop(*.* n_w temp* daytime trend _cons)


********************************************************************************
**** 	Robustness: For each region/year/month										****
********************************************************************************
*** For each price region and each year ***
est clear
qui xtivreg e_w (p = wp) $x_w $x_11_15 ///
	if DK1==1 & bd==1 & inrange(hour,11,15), re vce(cluster grid)
est store peak_DK1, title("Western DK")
qui xtivreg e_w (p = wp) $x_w $x_11_15 ///
	if DK1==0 & bd==1 & inrange(hour,11,15), re vce(cluster grid)
est store peak_DK2, title("Eastern DK")
qui forvalues y = 2016/2018 {
	xtivreg e_w (p = c.wp#DK1) n_w temp* trend i.week $x_11_15 ///
		if year==`y' & bd==1 & inrange(hour,11,15), re vce(cluster grid)
	est store peak_`y', title("`y'")
}
estout _all using "ws_region_year.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R-sq within" "R-sq between" "Number of groups" "Obs. per group") )
estout _all using $latex/ws_region_year.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("\(R^2\) within" "\(R^2\) between" "Number of groups" "Obs. per group") ) ///
	prehead("\begin{tabular}{lccccc}\toprule") posthead("\midrule") ///
	prefoot("\midrule") postfoot("\bottomrule\end{tabular}")	
estout _all using $results/ws_region_year.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R&sup2 within" "R&sup2 between" "Number of groups" "Obs. per group") ) ///
	prehead("**Table:** log wholesale electricity consumption by region and year (REIV)<br>*Business days, hours 11-15. Baseline: Each hour for December.*<br><html><table>") ///
	postfoot("</table>Robust standard errors are clustered at grid level and reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Log spot price is instrumented for by wind power prognosis for the same region.</html>")

*** For each month ***
est clear
qui forvalues m = 1/12 {
	qui xtivreg e_w (p = wp) $x_w ///
		i(11 12 13 14 15).hour#i(1 2 3 4).day_bd ///
		if month==`m' & bd==1 & inrange(hour,11,15), re vce(cluster grid)
	est store peak_`m', title("`m'")
}
estout _all using "ws_month.xls", replace ///
	label cells( b(fmt(4)) se(par fmt(4)) ) ///
	drop(*.* n_w temp* trend _cons)
estout _all using $results/ws_month.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R&sup2 within" "R&sup2 between" "Number of groups" "Obs. per group") ) ///
	prehead("**Table:** log wholesale electricity consumption by month (REIV)<br>*Business days, hours 11-15. Baseline: year 2016 and each hour for December.*<br><html><table>") ///
	postfoot("</table>Robust standard errors are clustered at grid level and reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Log spot price is instrumented for by wind power prognosis for the same region.</html>")


********************************************************************************
**** 	Robustness: For different grids										****
********************************************************************************
*** For the five largest grid companies - using pooled 2SLS (P2SLS) ***
est clear
qui ivregress 2sls e_w (p = wp) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
est store peak_131, title("N1 (DK1)")
qui ivregress 2sls e_w (p = wp) $x_w $x_11_15 ///
	if grid==151 & bd==1 & inrange(hour,11,15), robust
est store peak_151, title("Konstant (DK1)")
qui ivregress 2sls e_w (p = wp) $x_w $x_11_15 ///
	if grid==344 & bd==1 & inrange(hour,11,15), robust
est store peak_344, title("Evonet (DK1)")
qui ivregress 2sls e_w (p = wp) $x_w $x_11_15 ///
	if grid==740 & bd==1 & inrange(hour,11,15), robust
est store peak_740, title("Cerius (DK2)")
qui ivregress 2sls e_w (p = wp) $x_w $x_11_15 ///
	if grid==791 & bd==1 & inrange(hour,11,15), robust
est store peak_791, title("Radius (DK2)")

estout _all using "ws_grids_large.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_a N, fmt(4 %12.0gc) labels("Adj. R-sq" "Observations") )
estout _all using $latex/ws_grids_large.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(r2_a N, fmt(4 %12.0gc) labels("Adj. \(R^2\)" "Observations") ) ///
	prehead("\begin{tabular}{lccccc}\toprule") posthead("\midrule") ///
	prefoot("\midrule") postfoot("\bottomrule\end{tabular}")
estout _all using $results/ws_grids_large.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_a N, fmt(4 %12.0gc) labels("Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** log wholesale electricity consumption by grid company (P2SLS)<br>*Business days, hours 11-15. Baseline: year 2016 and each hour for December.*<br><html><table>") ///
	postfoot("</table>Robust standard errors are reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Log spot price is instrumented for by wind power prognosis for the same region.</html>")

	
*** For all 48 grid companies - using P2SLS ***
est clear
* 39 grid companies in Western DK
forvalues i = 23/592 {
	count if grid == `i'
	if r(N) == 0 {
		continue
	}
	ivregress 2sls e_w (p = wp) $x_w $x_11_15 ///
		if grid==`i' & bd==1 & inrange(hour,11,15), robust
	est store DK1_`i', title("`i'")
}
estout DK1* using "ws_grids_DK1.xls", replace ///
	label cells( b(fmt(4)) se(par fmt(4)) ) ///
	drop(*.* n_w temp* trend _cons)
* 9 grid companies in Eastern DK
qui forvalues i = 740/911 {
	count if grid == `i'
	if r(N) == 0 {
		continue
	}
	ivregress 2sls e_w (p = wp) $x_w $x_11_15 ///
		if grid==`i' & bd==1 & inrange(hour,11,15), robust
	est store DK2_`i', title("`i'")
}
estout DK2* using "ws_grids_DK2.xls", replace ///
	label cells( b(fmt(4)) se(par fmt(4)) ) ///
	drop(*.* n_w temp* trend _cons)


********************************************************************************
**** 	FE, RE, FEIV, REIV comparison										****
********************************************************************************
est clear
xtreg e_w p $x_w $x_11_15 ///
	if bd==1 & inrange(hour,11,15), fe vce(cluster grid)
est store fe, title("FE")
xtreg e_w p $x_w $x_11_15 ///
	if bd==1 & inrange(hour,11,15), re vce(cluster grid)
est store re, title("RE")
xtivreg e_w (p = c.wp#DK1) $x_w $x_11_15 ///
	if bd==1 & inrange(hour,11,15), fe vce(cluster grid) first
est store REIV, title("FEIV")
qui xtivreg e_w (p = c.wp#DK1) $x_w $x_11_15 ///
	if bd==1 & inrange(hour,11,15), re vce(cluster grid)
est store reiv, title("REIV")

estout _all using "ws_fe.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R-sq within" "R-sq between" "Number of groups" "Obs. per group") )
estout _all using $latex/ws_fe.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("\(R^2\) within" "\(R^2\) between" "Number of groups" "Obs. per group") ) ///
	prehead("\begin{tabular}{lcccc}\toprule") posthead("\midrule") ///
	prefoot("\midrule") postfoot("\bottomrule\end{tabular}")
estout _all using $results/ws_fe.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R&sup2 within" "R&sup2 between" "Number of groups" "Obs. per group") ) ///
	prehead("**Table:** log wholesale electricity consumption, business days, hours 11-15 (FE, RE, FEIV, and REIV)<br>*Business days, hours 11-15. Baseline: year 2016 and each hour for December.*<br><html><table>") ///
	postfoot("</table>Robust standard errors are clustered at grid level and reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Log spot price is instrumented for by wind power prognosis for the same region.</html>")

	
********************************************************************************
////////////////////////////////////////////////////////////////////////////////
////	4. Statistical tests (wholesale in single-grids using P2SLS)		////
////////////////////////////////////////////////////////////////////////////////
********************************************************************************
/*	
Wholesale consumption on business days, peak hours 11-15 (using pooled 2SLS)

For each of the two biggest grids (one in each price region):
- DK1: N1, grid number 131
- DK2: Radius, grid number 791
*/
********************************************************************************
**** 	Testing for homoscedasticity										****
********************************************************************************
est clear
qui foreach i in 131 791 {
	* OLS w. non-robust s.e.
	qui reg e_w p $x_w $x_11_15 if grid==`i' & bd==1 & inrange(hour,11,15)
	estat hettest, rhs mtest(bonf)
	estadd scalar hettest = r(chi2)
	estadd scalar hetdf = r(df)
	estadd scalar hetp = r(p)
	est store non_robust_`i', title("`i': s.e.")
	matrix A_`i' = r(mtest)
	/*
	The Breusch-Pagan / Cook-Weisberg test for heteroskedasticity
	H0: Constant variance, i.e. homoscedasticity
	Both:
 	- The simultaneous test clearly rejects H0 (p=0.000)
	N1 (DK1):
	- The Bonferroni-adjusted p-values for price, n_w, & temperature are 0.000
	Radius (DK2):
	- The Bonferroni-adjusted p-val for price, n_w, & temperature are ~1 however
	*/
	* OLS w. robust s.e.
	qui reg e_w p $x_w $x_11_15 if grid==`i' & bd==1 & inrange(hour,11,15), robust
	est store robust_`i', title("`i': robust s.e.")
	/*
	The differences between non-robust s.e. and robust s.e. are:
	 - Relatively large for N1 (DK1)
	 - Relatively small for Radius (DK2)
	*/
}
estout _all using "ws_homoscedasticity.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(hettest hetdf hetp r2 r2_a N, fmt(0 0 3 3 3 %12.0gc) )
estout _all using $latex/ws_homoscedasticity.tex, style(tex) replace ///
		label cells( b(star fmt(4)) se(par fmt(4)) ) ///
		starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
		indicate("Time variables=*.*") drop(trend _cons) ///
		stats(hettest hetdf hetp r2 r2_a N, fmt(1 0 3 3 3 %12.0gc) labels("\(chi^2\)" "DF" "Adj. p-val" "\(R^2\)" "Adj. \(R^2\)" "Observations") ) ///
		prehead("\begin{tabular}{lcccc}\toprule") posthead("\midrule") ///
		prefoot("\midrule") postfoot("\bottomrule\end{tabular}")
estout _all using "$results/ws_homoscedasticity.md", style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(hettest hetdf hetp r2 r2_a N, fmt(1 0 3 3 3 %12.0gc) labels("\(\chi^2\)" "DF" "Adj. p-val" "\(R^2\)" "Adj. \(R^2\)" "Observations") ) ///
	prehead("**Table:** Testing for homoscedasticity, log wholesale electricity consumption, business days, hours 11-15 (POLS)<br>*Grid 131 is N1 (DK1), grid 791 is Radius (DK2)*<br>Baseline: year 2016 and each hour for December.<br><html><table>") ///
	postfoot("</table>(robust) standard errors are reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Chi&sup2, DF, and Adj. p-val are for the simultaneous Breusch-Pagan / Cook-Weisberg test for heteroscedasticity using Bonferroni-adjusted p-values.</html>")
mat A1 = A_131[1..., 1]
mat A2 = A_131[1..., 4]
mat A3 = A_791[1..., 1]
mat A4 = A_791[1..., 4]
mat A = A1, A2, A3, A4
mat colnames A = Chi2_131 Adj_p_val_131 Chi2_791 Adj_p_val_791
mat list A
estout matrix(A, fmt(3 0 3 3)) using "$results/ws_homoscedasticity_bp.md", ///
	style(html) replace prehead("**Table:** The Breusch-Pagan / Cook-Weisberg test for heteroskedasticity w. Bonferroni-adjusted p-values<br>(log wholesale electricity consumption, business days, hours 11-15)<br>*Grid 131 is N1 (DK1), grid 791 is Radius (DK2)*<br><html><table>") ///
	postfoot("</table></html>")


********************************************************************************
**** 	Reduced form for log price (relevance of instruments)				****
********************************************************************************
est clear
* DK1:
qui reg p wp wp_other wp_se $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
test wp = wp_other = wp_se = 0
estadd scalar f3 = r(F)
estadd scalar f3_p = r(p)
test wp_other = wp_se = 0
estadd scalar f2 = r(F)
estadd scalar f2_p = r(p)
est store a_131, title("3 instruments")
qui reg p wp wp_other $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
test wp = wp_other = 0
estadd scalar f2 = r(F)
estadd scalar f2_p = r(p)
est store b_131, title("DK1 and DK2")
qui reg p wp $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
est store c_131, title("DK1")
qui reg p $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
est store d_131, title("None")
* DK2:
qui reg p wp wp_other wp_se $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
test wp = wp_other = wp_se = 0
estadd scalar f3 = r(F)
estadd scalar f3_p = r(p)
test wp_other = wp_se = 0
estadd scalar f2 = r(F)
estadd scalar f2_p = r(p)
est store a_791, title("3 instruments")
qui reg p wp wp_se $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
test wp = wp_se = 0
estadd scalar f2 = r(F)
estadd scalar f2_p = r(p)
est store b_791, title("DK2 and SE")
qui reg p wp $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
est store c_791, title("DK2")
qui reg p $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
est store d_791, title("None")

estout _all using "reduced_form_price.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Control variables=*.*") drop(n_w temp* trend _cons) ///
	stats(f3 f3_p f2 f2_p r2_a N, fmt(1 3 1 3 4 %12.0gc) labels("F statistic (df=3)" "p-val (F-test, df=3)" "F statistic (df=2)" "p-val (F-test, df=2)" "Adj. R^2" "Observations") )
foreach i in 131 791 {
	estout *_`i' using $latex/reduced_form_price_`i'.tex, style(tex) replace ///
		label cells( b(star fmt(4)) se(par fmt(4)) ) ///
		starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
		indicate("Time variables=*.*") drop(trend _cons) ///
		stats(r2_a N, fmt(4 %12.0gc) labels("Adj. \(R^2\)" "Observations") ) ///
		prehead("\begin{tabular}{lcccc}\toprule") posthead("\midrule") ///
		prefoot("\midrule") postfoot("\bottomrule\end{tabular}")
}
estout _all using $results/reduced_form_price.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_a N, fmt(4 %12.0gc) labels("Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** Reduced form of log spot price (POLS)<br>*Business days, hours 11-15. Baseline: year 2016 and each hour for December.*<html><table>") ///
	postfoot("</table>Robust standard errors are reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.</html>")


********************************************************************************
**** 	Testing both endogeneity and overidentifying restrictions			****
********************************************************************************
/*  Various tests:
 1)	Testing for endogeneity of regressor:
	H0 (using estat endogenous): the regressor (price) is exogenous
	Wooldridge's robust score test: chi2(L)   | L is the number of instruments.
	Robust regression-based test: F(L, N-K-L) | K is the number of other regressors.
	Both tests: p < .05 => H0 rejected => regressor is endogenous
 2) Testing the relevance of instruments:
	H0 (using estat firststage): the set of instruments is weak
	F(L, N-K-L)
	p < .05 => H0 clearly rejected => our instruments are not weak
	estadd scalar mineig = r(mineig) // the minimum eigenvalue statistic assumes iid
 3)	Testing for overidentifying restrictions:
	H0 (using estat overid): All instruments are valid (at the 5% level)
	Wooldridge's heteroscedasticity-robust score test of 
		overidentifying restrictions: chi2(L)
	p < .05 => test statistic is significant at the 5% level => reject H0
			=> either instrument is invalid or the structural model is misspecified
*/
est clear

*** N1 (DK1) ***
* Simple OLS for comparison (relevance of instrumenting)
qui reg e_w p $x_w $x_11_15 if grid==131 & bd==1 & inrange(hour,11,15), robust
est store POLS_131, title("POLS")
* Each instrument individually: DK1
qui ivregress 2sls e_w (p = wp) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
estat endogenous
estadd scalar endog = r(r_score) // robust score chi2
estadd scalar p_endog = r(p_r_score) // p-val
estadd scalar endog_reg = r(regF) // robust regression F
estadd scalar p_endog_reg = r(p_regF) // p-val
estat firststage // F(1, 3540) = 429, (p = 0.0000) => instruments are not weak
est store iv_wp_131, title("P2SLS, wp DK1")
* Each instrument individually: DK2
qui ivregress 2sls e_w (p = wp_other) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
estat endogenous
estadd scalar endog = r(r_score) // robust score chi2
estadd scalar p_endog = r(p_r_score) // p-val
estadd scalar endog_reg = r(regF) // robust regression F
estadd scalar p_endog_reg = r(p_regF) // p-val
estat firststage // F(1, 3540) = 397, (p = 0.0000) => instruments are not weak
est store iv_wp_other_131, title("P2SLS, wp DK2")
* Both instruments
qui ivregress 2sls e_w (p = wp wp_other) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
estat endogenous // H0: the regressor (price) is exogenous
/*	Robust score chi2(1)            =  77.1  (p = 0.0000)
	Robust regression F(1, 3539)    =  86.3  (p = 0.0000)
	p < .05 => H0 clearly rejected => regressor is endogenous
*/
estadd scalar endog = r(r_score) // robust score chi2
estadd scalar p_endog = r(p_r_score) // p-val
estadd scalar endog_reg = r(regF) // robust regression F
estadd scalar p_endog_reg = r(p_regF) // p-val
estat firststage // F(2, 3539) = 200, (p = 0.0000) => instruments are not weak
estat overid // H0: Our instruments are valid at the 5% level.
/* 	chi-sq(1) = 5.1 (p = 0.024) (df = number of overidentifying restrictions).
	p < .05 => reject H0, thus, either or all of the instruments are invalid.
	i.e. instruments are either not exogenous or the model is misspecified.
	However, regressor was found to be endogenous => Model is overspecified
*/
estadd scalar overid = r(score) // Overid-score
estadd scalar p_overid = r(p_score) // p-val (overid)
est store iv_both_131, title("P2SLS, both")

*** Radius (DK2) ***
* Simple OLS for comparison (relevance of instrumenting)
qui reg e_w p $x_w $x_11_15 if grid==791 & bd==1 & inrange(hour,11,15), robust
est store POLS_791, title("POLS")
* Each instrument individually: DK2
qui ivregress 2sls e_w (p = wp) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
estat endogenous
estadd scalar endog = r(r_score) // robust score chi2
estadd scalar p_endog = r(p_r_score) // p-val
estadd scalar endog_reg = r(regF) // robust regression F
estadd scalar p_endog_reg = r(p_regF) // p-val
estat firststage // F(1, 3540) = 429, (p = 0.0000) => instruments are not weak
est store iv_wp_791, title("P2SLS, wp DK2")
* Each instrument individually: SE
qui ivregress 2sls e_w (p = wp_se) $x_w $x_11_15 ///
	if grid==131 & bd==1 & inrange(hour,11,15), robust
estat endogenous
estadd scalar endog = r(r_score) // robust score chi2
estadd scalar p_endog = r(p_r_score) // p-val
estadd scalar endog_reg = r(regF) // robust regression F
estadd scalar p_endog_reg = r(p_regF) // p-val
estat firststage // F(1, 3540) = 317, (p = 0.0000) => instruments are not weak
est store iv_wp_se_791, title("P2SLS, wp SE")
* Both instruments
qui ivregress 2sls e_w (p = wp wp_se) $x_w $x_11_15 ///
	if grid==791 & bd==1 & inrange(hour,11,15), robust
estat endogenous // H0: the regressor (price) is exogenous
/*	Robust score chi2(1)            =  5.0	(p = 0.0249)
	Robust regression F(1,3539)     =  4.8	(p = 0.0285)
	p < .05 => H0 rejected => regressor is endogenous
*/
estadd scalar endog = r(r_score) // robust score chi2
estadd scalar p_endog = r(p_r_score) // p-val
estadd scalar endog_reg = r(regF) // robust regression F
estadd scalar p_endog_reg = r(p_regF) // p-val
estat firststage // F(2, 3539) = 249, (p = 0.0000) => instruments are not weak
estadd scalar mineig = r(mineig) // doesn't work somehow
estat overid // H0: Our instruments are valid at the 5% level.
/* 	chi-sq(1) = 15.5 (p = 0.0001) (df = number of overidentifying restrictions).
	p < .05 => reject H0, thus, either or all of the instruments are invalid.
	i.e. instruments are either not exogenous or the model is misspecified.
	However, regressor was found to be endogenous => Model is overspecified
*/
estadd scalar overid = r(score) // Overid-score
estadd scalar p_overid = r(p_score) // p-val (overid)
est store iv_both_791, title("P2SLS, both")

estout _all using "ws_endog_overid.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(endog p_endog endog_reg p_endog_reg overid p_overid r2_a N, fmt(1 4 1 4 1 4 4 %12.0gc) )
foreach i in 131 791 {
	estout *_`i' using $latex/ws_endog_overid_`i'.tex, style(tex) replace ///
		label cells( b(star fmt(4)) se(par fmt(4)) ) ///
		starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
		indicate("Time variables=*.*") drop(trend _cons) ///
		stats(endog p_endog endog_reg p_endog_reg overid p_overid r2_a N, fmt(1 4 1 4 1 4 4 %12.0gc) labels("Score test of exogeneity" "p-val, exogeneity" "Regression-based F-statistic" "p-val, regression-based" "Test of overidentifying restrictions" "p-val, overidentifying restrictions" "Adj. \(R^2\)" "Observations") ) ///
		prehead("\begin{tabular}{lcccc}\toprule") posthead("\midrule") ///
		prefoot("\midrule") postfoot("\bottomrule\end{tabular}")
}
estout *_131 using $results/ws_endog_overid_131.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(endog p_endog endog_reg p_endog_reg overid p_overid r2_a N, fmt(1 4 1 4 1 4 4 %12.0gc) labels("Score test of exogeneity" "p-val, exogeneity" "Regression-based F-statistic" "p-val, regression-based" "Test of overidentifying restrictions" "p-val, overidentifying restrictions" "n*R&sup2" "p-val" "Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** Testing endogeneity and overidentifying restrictions (wholesale, business days, hours 11-15)<br>*For grid company N1 (DK1)*<br><html><table>") ///
	postfoot("</table>Robust standard errors are reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Baseline: year 2016 and each hour for December.</html>")
estout *_791 using $results/ws_endog_overid_791.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(endog p_endog endog_reg p_endog_reg overid p_overid r2_a N, fmt(1 4 1 4 1 4 4 %12.0gc) labels("Score test of exogeneity" "p-val, exogeneity" "Regression-based F-statistic" "p-val, regression-based" "Test of overidentifying restrictions" "p-val, overidentifying restrictions" "N*R&sup2" "p-val" "Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** Testing endogeneity and overidentifying restrictions (wholesale, business days, hours 11-15)<br>*For grid company Radius (DK2)*<br><html><table>") ///
	postfoot("</table>Robust standard errors are reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Baseline: year 2016 and each hour for December.</html>")


********************************************************************************
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////	5. Regressions for households and small companies		 			////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
********************************************************************************
**** 	Pooled 2SLS for Radius, 17-19 only									****
********************************************************************************
est clear
qui ivregress 2sls e_hh s_tout (p = wp) $x_hh $x_17_19 ///
	if grid==791 & inrange(hour,17,19), robust
est store all, title("All days")
qui ivregress 2sls e_hh s_tout (p = wp) $x_hh ///
	i(17 18 19).hour#i(1 2 3 4 5).day_bd ///
	i(17 18 19).hour#i(1 2 3 4 5 6 7 8 9 10 11).month ///
	if bd==1 & grid==791 & inrange(hour,17,19), robust
est store bd, title("Business days")
qui ivregress 2sls e_hh s_tout (p = wp) $x_hh ///
	i(17 18 19).hour#i(1 2 3 4 5 6 7 8 9 10 11).month ///
	if non_bd==1 & grid==791 & inrange(hour,17,19), robust
est store nbd, title("Non-business days")

estout _all using "r_radius.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_a N, fmt(4 %12.0gc) labels("Adj. R-sq" "Observations") )
estout _all using $latex/r_radius.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(r2_a N, fmt(4 %12.0gc) labels("Adj. \(R^2\)" "Observations") ) ///
	prehead("\begin{tabular}{lccc}\toprule") posthead("\midrule") ///
	prefoot("\midrule") postfoot("\bottomrule\end{tabular}")
estout _all using $results/r_radius.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_a N, fmt(4 %12.0gc) labels("Adj. R&sup2" "Observations") ) ///
	prehead("**Table:** log retail electricity consumption in Radius (P2SLS)<br>*Hours 17-19. Baseline: year 2016 and each hour for December.*<br><html><table>") ///
	postfoot("</table>Robust standard errors are reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Log spot price is instrumented for by wind power prognosis for DK2.</html>")


********************************************************************************
**** 	Robusness-check: Applying share-TOUT in Radius to other grids		****
********************************************************************************
est clear
qui forvalues i = 23/592 {
	count if grid == `i'
	if r(N) == 0 {
		continue
	}
	ivregress 2sls e_hh s_radius (p = wp wp_other) $x_hh $x_17_19 ///
		if grid==`i' & inrange(hour,17,19), vce(robust)
	est store DK1_`i', title("`i'")
}
estout DK1* using "r_grids_DK1.xls", replace ///
	label cells( b(fmt(4)) se(par fmt(4)) ) ///
	drop(*.* n_hh temp* daytime trend _cons)

qui forvalues i = 740/911 {
	count if grid == `i'
	if r(N) == 0 {
		continue
	}
	ivregress 2sls e_hh s_radius (p = wp wp_other) $x_hh $x_17_19 ///
		if grid==`i' & inrange(hour,17,19), vce(robust)
	est store DK2_`i', title("`i'")
}
estout DK2* using "r_grids_DK2.xls", replace ///
	label cells( b(fmt(4)) se(par fmt(4)) ) ///
	drop(*.* n_hh temp* daytime trend _cons)


********************************************************************************
**** 	Retail electricity consumption by region and year					****
********************************************************************************
*** by region ***
est clear
qui xtivreg e_hh (p = c.wp#DK1) s_tout oct_mar $x_hh $x_17_19 ///
	if inrange(hour,17,19), re vce(cluster grid)
est store all, title("All")
qui xtivreg e_hh (p = c.wp#DK1) s_tout oct_mar $x_hh $x_17_19 ///
	if bd==1 & inrange(hour,17,19), re vce(cluster grid)
est store bd, title("Business day")
qui xtivreg e_hh (p = c.wp#DK1) s_tout oct_mar $x_hh $x_17_19 ///
	if bd==0 & inrange(hour,17,19), re vce(cluster grid)
est store nbd, title("Non-business day")
qui xtivreg e_hh (p = wp) $x_hh $x_17_19 ///
	if DK1==1 & inrange(hour,17,19), re vce(cluster grid)
est store DK1, title("DK1")
qui xtivreg e_hh (p = wp) s_tout oct_mar $x_hh $x_17_19 ///
	if DK1==0 & inrange(hour,17,19), re vce(cluster grid)
est store DK2, title("DK2")

estout _all using "r_region.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R-sq within" "R-sq between" "Number of groups" "Obs. per group") )
estout _all using $latex/r_region.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("\(R^2\) within" "\(R^2\) between" "Number of groups" "Obs. per group") ) ///
	prehead("\begin{tabular}{lccccc}\toprule") posthead("\midrule") ///
	prefoot("\midrule") postfoot("\bottomrule\end{tabular}")	
estout _all using $results/r_region.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R&sup2 within" "R&sup2 between" "Number of groups" "Obs. per group") ) ///
	prehead("**Table:** log retail electricity consumption by region (REIV)<br>*Hours 17-19. Baseline: year 2016 and each hour for December.*<br><html><table>") ///
	postfoot("</table>Robust standard errors are clustered at grid level and reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Log spot price is instrumented for by wind power prognosis for the same region.</html>")


*** by year ***
est clear
qui forvalues y = 2016/2017 {
	xtivreg e_hh (p = c.wp#DK1) n_hh temp* daytime trend i.week $x_17_19 ///
		if year==`y' & inrange(hour,17,19), re vce(cluster grid)
	est store y`y', title("Year `y'")
}
xtivreg e_hh (p = c.wp#DK1) s_tout n_hh temp* daytime trend i.week $x_17_19 ///
		if year==2018 & inrange(hour,17,19), re vce(cluster grid)
	est store y2018, title("Year `y'")

estout _all using "r_year.xls", replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R-sq within" "R-sq between" "Number of groups" "Obs. per group") )
estout _all using $latex/r_year.tex, style(tex) replace ///
	label cells( b(star fmt(4)) se(par fmt(4)) ) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	indicate("Time variables=*.*") drop(trend _cons) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("\(R^2\) within" "\(R^2\) between" "Number of groups" "Obs. per group") ) ///
	prehead("\begin{tabular}{lccc}\toprule") posthead("\midrule") ///
	prefoot("\midrule") postfoot("\bottomrule\end{tabular}")	
estout _all using $results/r_year.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R&sup2 within" "R&sup2 between" "Number of groups" "Obs. per group") ) ///
	prehead("**Table:** log retail electricity consumption by year (REIV)<br>*Hours 17-19. Baseline: Each hour for December.*<br><html><table>") ///
	postfoot("</table>Robust standard errors are clustered at grid level and reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Log spot price is instrumented for by wind power prognosis for the same region.</html>")


*** by hour ***
est clear
qui foreach d in 0 1 {
	foreach h of numlist 0/23 {
		qui xtivreg e_hh (p = c.wp#DK1) s_tout oct_mar $x_hh $x_17_19 ///
			if bd==`d' & hour==`h', re vce(cluster grid)
		est store bd`d'_h`h', title("`h'")
	}
}
estout bd1* using "r_hour_bd.xls", replace ///
	label cells( b(fmt(4)) se(par fmt(4)) ) ///
	drop(*.* s_tout oct_mar n_hh temp* daytime trend _cons)
estout bd0* using "r_hour_nbd.xls", replace ///
	label cells( b(fmt(4)) se(par fmt(4)) ) ///
	drop(*.* s_tout oct_mar n_hh temp* daytime trend _cons)
estout bd1* using $results/r_hour_bd.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R&sup2 within" "R&sup2 between" "Number of groups" "Obs. per group") ) ///
	prehead("**Table:** log retail electricity consumption by hour (REIV)<br>*Business days. Baseline: December.*<br><html><table>") ///
	postfoot("</table>Robust standard errors are clustered at grid level and reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Log spot price is instrumented for by wind power prognosis for the same region.</html>")
estout bd1* using $results/r_hour_nbd.md, style(html) replace ///
	label cells( b(star fmt(4)) & se(par fmt(4)) ) incelldelimiter(<br>) ///
	starlevels(* .10 ** .05 *** .01) mlabels(,titles numbers) ///
	stats(r2_w r2_b N_g g_avg, fmt(4 4 0 %12.0gc) labels("R&sup2 within" "R&sup2 between" "Number of groups" "Obs. per group") ) ///
	prehead("**Table:** log retail electricity consumption by hour (REIV)<br>*Business days. Baseline: December.*<br><html><table>") ///
	postfoot("</table>Robust standard errors are clustered at grid level and reported in parentheses below each estimate. * p<0.10, ** p<0.05, *** p<0.01.<br>Log spot price is instrumented for by wind power prognosis for the same region.</html>")
