* clear log and output */
dm 'clear log'; dm 'clear output';  /* clear log and output */

libname gproject "E:/Users/AXB200095/Documents/My SAS Files/9.4/Project";
title;


* Import the unformatted used vehicles dataset;
proc import datafile = "E:/Users/AXB200095/Documents/My SAS Files/9.4/vehicles/vehicles.csv"
 out = gproject.UsedCars
 dbms = CSV replace;
 guessingrows = 1000;
run;

data gproject.UsedCars;
set gproject.UsedCars;
run;

ods graphics on;
* View the dataset;
PROC CONTENTS DATA = gproject.UsedCars;
RUN;

* Drop the ID, county, VIN, description, image_url, lat, long, region_url, and url variables;
DATA gproject.UsedCars1;
	SET gproject.UsedCars(DROP=ID county VIN description image_url lat long region_url url);
RUN;

* View UsedCarsDataset1;
PROC CONTENTS DATA = gproject.UsedCars1;
RUN;

PROC PRINT DATA = gproject.UsedCars1(OBS=20);
RUN;

* Set the length, format, and label for all the char variables; 
DATA gproject.UsedCars2;
	LENGTH 
		condition $9 
		cylinders $12 
		drive $3 
		fuel $8 
		manufacturer $15 
		model $203 
		paint_color $6 
		region $26 
		size $11 
		state $2 
		title_status $10 
		transmission $12 
		type $11
	;
	FORMAT 
		condition $9. 
		cylinders $12. 
		drive $3. fuel $8. 
		manufacturer $15.
		model $203. 
		paint_color $6. 
		price DOLLAR8. 
		region $26. 
		size $11. 
		state $2. 
		title_status $10. 
		transmission $9. 
		type $11.
	;
	INFORMAT 
		condition $9. 
		cylinders $12. 
		drive $3. 
		fuel $8. 
		manufacturer $15. 
		model $203. 
		paint_color $6. 
		price DOLLAR8. 
		region $26. 
		size $11. 
		state $2. 
		title_status $10. 
		transmission $9. 
		type $11.
	;
LABEL
	condition = "The condition of the vehicle (e.g., good, excellent, like new, etc.)"
	cylinders = "The engine cylinders of the vehicle (e.g., 4, 6, 8, etc.)"
	drive = "The drivetrain of the vehicle (e.g., 4wd, rwd, awd, etc.)"
	fuel = "The fuel method of the vehicle (e.g., gas, electric, hybrid, etc.)"
	manufacturer = "The make of the vehicle"
	model = "The model of the vehicle"
	posting_date = "The listing date of the vehicle on Craigslist"
	odometer = "The mileage on the vehicle"
	paint_color = "The color of the vehicle"
	price = "The listing price of the vehicle"
	region = "The Craigslist city/region where the vehicle was listed in the U.S."
	size = "The size of the vehicle (e.g., full-size, compact, sub-compact)"
	state = "The state where the vehicle was listed in the U.S."
	title_status = "The title status of the vehicle (e.g., clean, salvage, missing, etc.)"
	transmission = "The transmission of the vehicle (e.g., automatic, manual, or other)"
	type = "The type of the vehicle (e.g., pickup, truck, hatchback, etc.)"
	year = "The year of the vehicle"
;
	SET gproject.UsedCars1;
RUN;

PROC CONTENTS DATA = gproject.UsedCars2;
RUN;

* Check the amount of missing values for all numeric variables;
PROC MEANS DATA = gproject.UsedCars2 NMISS N;
	var _NUMERIC_;
RUN;

* Check the amount of missing values for all string variables;
PROC FORMAT;
	VALUE $missfmt ' ' = 'Missing' Other = 'Not missing';

PROC FREQ DATA = gproject.UsedCars2;
	format _CHAR_ $missfmt.;
	TABLES _CHAR_ / MISSING;
RUN;

* Check the distribution of the price, odometer, and year variables;
ods graphics / imagemap=on;

PROC UNIVARIATE DATA = gproject.UsedCars2 PLOTS;
	var price odometer year;
RUN;

/* Drop the extreme observations from the price variable */
DATA gproject.UsedCars3;
	SET gproject.UsedCars2(WHERE = (price between 2000 and 120000));
	logPrice = log(price); /* Create a log price variable */
RUN;

/* Drop the extreme observations from the odometer variable */
DATA gproject.UsedCars4;
	SET gproject.UsedCars3(WHERE = (odometer between 100 and 275000));
RUN;

/* Drop the extreme observations from the price variable */
DATA gproject.UsedCars5;
	SET gproject.UsedCars4(WHERE = (year between 1990 and 2021));
RUN;

PROC CONTENTS DATA = gproject.UsedCars5;
RUN;

PROC PRINT DATA = gproject.UsedCars5(OBS=10);
RUN;

* Check distribution of the variables;
proc univariate data=gproject.UsedCars7 normal noprint;
    var price logPrice;
    histogram price logPrice  / normal kernel; /* use weibull distribution to check */
    inset n mean std / position = ne;
    probplot logPrice;
    title "Distribution Analysis - Continous Variables";
run;


/* Now, we have a total of 352523 observations in the dataset. Re-count the number of missing values from the quantitative variables. 
The results indicate there are no more missing values from the price, odometer, year, and posting_date variables. */
PROC MEANS DATA = gproject.UsedCars5 NMISS N;
	var _NUMERIC_;
RUN;

* Re-count the number of missing values from the Char variables;
PROC FREQ DATA = gproject.UsedCars5;
	format _CHAR_ $missfmt.;
	TABLES _CHAR_ / MISSING;
RUN;

*Renaming region predictor variable to city to better align the analysis;
DATA gproject.UsedCars6;
	SET gproject.UsedCars5 (RENAME = (region = city));
	RUN;

PROC CONTENTS DATA = gproject.UsedCars6;
RUN;


*Setting the region variable from states;
DATA gproject.UsedCars6;
SET gproject.UsedCars6;
IF state IN ('ct', 'me', 'ma', 'nh', 'ri', 'vt', 'nj', 'ny', 'pa') THEN region ="northeast";
ELSE IF state IN ('il', 'in', 'mi', 'oh', 'wi', 'ia', 'ks', 'mn', 'mo', 'ne', 'nd', 'sd') THEN region ="midwest";
ELSE IF state IN ('de', 'fl', 'ga', 'md', 'nc', 'sc', 'va', 'dc', 'wv', 'al', 'ky', 'ms', 'tn', 'ar', 'la', 'ok', 'tx') THEN region = "south";
ELSE IF state IN ('az', 'co', 'id', 'mt', 'nv', 'nm', 'ut', 'wy', 'ak', 'ca', 'hi', 'or', 'wa') THEN region = "west";
ELSE region = "other";
RUN;

* replace the missing values from categorical variables;
data gproject.UsedCars7;
    set gproject.UsedCars6;
    if condition = " " 
            then condition = "good";
	if cylinders = " " 
            then cylinders = "6 cylinders";
	If drive = " " 
		then drive = "4wd";

    if fuel = " " 
            then fuel = "gas";
	 If manufacturer = " " 
		then manufacturer = "ford";

    if model = " " 
            then model = "1500";
	if paint_color = " " 
            then paint_color = "white";
	if state = " " 
            then state = "ca";
	if title_status = " " 
            then title_status = "clean";
	if transmission = " " 
            then transmission = "automatic";
	if type = " " 
            then type = "sedan";
	if size = ""
			then type = "other";   
    run;


* Re-check the distribution of the price, odometer, and price variables;
PROC UNIVARIATE DATA = gproject.UsedCars7 NORMAL NOPRINT;
	VAR price logPrice odometer year;
	HISTOGRAM price logPrice odometer year / NORMAL KERNEL;
	INSET N MEAN STD / POSITION = ne;
	PROBPLOT logPrice;
	TITLE "Exploratory Distribution Analysis";
RUN;

*scatter plot for price with numerical variables;
proc sgscatter data=gproject.UsedCars7;
   compare y=logPrice x=(odometer year);
   title 'Scatter Plots of logPrice by odometer and year';
run; 

*Normalizing odometer and year;
PROC STANDARD DATA=gproject.UsedCars7 MEAN=0 STD=1;
  VAR odometer year;
RUN;

*Updating the labels for new Variables;
DATA gproject.UsedCars7;
LABEL
region = "The Craigslist regions where the vehicle was listed in the U.S.";
logPrice = "Transformed log of price variable";
odometer = "Normalizing of odometer variable";
year = "Normalizing of year variable";
SET gproject.UsedCars7;
RUN;

PROC MEANS data=gproject.UsedCars7;
var odometer year;
RUN;

*Generating heatmap for numeric variables;
PROC IML;
use gproject.UsedCars7;
read all var _NUM_ into Y[c=varNames];
title 'Heatmap of Numeric Predictors Against LogPrice';
close;
corr = corr(Y);
 
/* bin correlations into five categories */
Labl = {'1:V. Neg','2:Neg','3:Neutral','4:Pos','5:V. Pos'};        /* labels */
bins= bin(corr, {-1, -0.6, -0.2, 0.2, 0.6, 1});           /* BIN returns 1-5 */
disCorr = shape(Labl[bins], nrow(corr));               /* categorical matrix */
call HeatmapDisc(disCorr) title="Binned Correlations"
     xvalues=varNames yvalues=varNames;
RUN;

* Correlation matrix;
PROC CORR DATA=gproject.UsedCars7 plots=matrix(histogram);
VAR  logPrice odometer year posting_date;
RUN;

proc sgscatter data=gproject.UsedCars7;
   compare y=logPrice x=(odometer year);
   title 'Scatter Plots of logPrice by odometer and year';
run; 

PROC PRINT DATA = gproject.UsedCars7(OBS=20);
RUN;

*Filtering the Unique values and Missing values for Categorical predictors;
PROC FREQ DATA = gproject.UsedCars7(drop = model state city);
	TABLES _character_ / nocum nopercent missing;
	TITLE "Frequency Counts for Selected Character Variables";
RUN;

ods graphics / reset width=6.4in height=4.8in imagemap;

 * Generate Box Plots using manufacturer;
proc sgplot data=gproject.UsedCars7;
    vbox logprice / category=manufacturer
        fillattrs=(color=PAOY transparency=0.5);
run;

ods graphics on / DISCRETEMAX = 280000 /  ANTIALIASMAX=34060;
*Distribution analysis for categorical variables;
proc freq data=gproject.UsedCars7;
    tables manufacturer model type region condition fuel title_status cylinders / plots= freqplot;
   title "Frequency Analysis - Categorical Variables";
run;

proc sgplot data=gproject.UsedCars7;
 vbar year / group=manufacturer; 
xaxis values=(1990 to 2020 by 1);
 keylegend / location=inside position=topleft across=1
 titleattrs=(weight=bold size=12pt)
 valueattrs=(color=green size=12pt);
 run;

 proc sgplot data=gproject.UsedCars7;
 vline manufacturer / response=year stat=mean markers;
 *vline manufacturer / response=year stat=mean markers y2axis;
 yaxis values=(1990 to 2020 by 1);
run;

ods html style=statistical;

* manufacturer against logprice plot; 
proc sgplot data=gproject.UsedCars7;
  vbar manufacturer / response=logPrice dataskin=gloss datalabel
       categoryorder=respdesc nostatlabel;
	   xaxis label = "manufacturer";
yaxis label  = "logprice"; 
  yaxis grid discreteorder=data;
  title "Frequency of logPrice by manufacturer";
  run;

  * type against logprice plot; 
proc sgplot data=gproject.UsedCars7;
  vbar type / response=logPrice dataskin=gloss datalabel
       categoryorder=respdesc nostatlabel;
	   xaxis label = "type";
yaxis label  = "logprice"; 
  yaxis grid discreteorder=data;
  title "Frequency of logPrice by type";
  run;

  * condition against logprice plot; 
proc sgplot data=gproject.UsedCars7;
  vbar condition / response=logPrice dataskin=gloss datalabel
       categoryorder=respdesc nostatlabel;
	   xaxis label = "condition";
yaxis label  = "logprice"; 
  yaxis grid discreteorder=data;
  title "Frequency of logPrice by condition";
  run;
    * title_status against logprice plot; 
proc sgplot data=gproject.UsedCars7;
  vbar title_status / response=logPrice dataskin=gloss datalabel
       categoryorder=respdesc nostatlabel;
	   xaxis label = "title_status";
yaxis label  = "logprice"; 
  yaxis grid discreteorder=data;
  title "Frequency of logPrice by title_status";
  run;
  * cylinders against logprice plot; 
proc sgplot data=gproject.UsedCars7;
  vbar cylinders / response=logPrice dataskin=gloss datalabel
       categoryorder=respdesc nostatlabel;
	   xaxis label = "cylinders";
yaxis label  = "logprice"; 
  yaxis grid discreteorder=data;
  title "Frequency of logPrice by cylinders";
  run;
    * region against logprice plot; 
proc sgplot data=gproject.UsedCars7;
  vbar region / response=logPrice dataskin=gloss datalabel
       categoryorder=respdesc nostatlabel;
	   xaxis label = "region";
yaxis label  = "logprice"; 
  yaxis grid discreteorder=data;
  title "Frequency of logPrice by region";
  run;
      * drive against logprice plot; 
proc sgplot data=gproject.UsedCars7;
  vbar drive / response=logPrice dataskin=gloss datalabel
       categoryorder=respdesc nostatlabel;
	   xaxis label = "drive";
yaxis label  = "logprice"; 
  yaxis grid discreteorder=data;
  title "Frequency of logPrice by drive";
  run;
      * transmission against logprice plot; 
proc sgplot data=gproject.UsedCars7;
  vbar transmission / response=logPrice dataskin=gloss datalabel
       categoryorder=respdesc nostatlabel;
	   xaxis label = "transmission";
yaxis label  = "logprice"; 
  yaxis grid discreteorder=data;
  title "Frequency of logPrice by transmission";
  run;
      * paint_color against logprice plot; 
proc sgplot data=gproject.UsedCars7;
  vbar paint_color / response=logPrice dataskin=gloss datalabel
       categoryorder=respdesc nostatlabel;
	   xaxis label = "paint_color";
yaxis label  = "logprice"; 
  yaxis grid discreteorder=data;
  title "Frequency of logPrice by paint_color";
  run;
* Hypothesis testing;(manufacturer)
proc glmselect data= gproject.usedcars7;
class manufacturer;
Backward_selection: model logPrice =  manufacturer / 
slstay = 0.05 hierarchy = single showpvalues;
title "backward Model Selection using Used car data";
output out=out005 r=residuals predicted=predicted_values;
run;
 * Hypothesis testing;(paint_color)
proc glmselect data= gproject.usedcars7;
class paint_color;
Backward_selection: model logPrice =  paint_color / 
slstay = 0.05 hierarchy = single showpvalues;
title "backward Model Selection using Used car data";
output out=out006 r=residuals predicted=predicted_values;
run;
 * Hypothesis testing;(transmission fuel)
proc glmselect data= gproject.usedcars7;
class transmission fuel;
Backward_selection: model logPrice =  transmission*fuel / 
slstay = 0.05 hierarchy = single showpvalues;
title "backward Model Selection using Used car data";
output out=out007 r=residuals predicted=predicted_values;
run;
 *deleting rows with missing values at this point;
DATA gproject.UsedCars8;
 set gproject.UsedCars7;
 if cmiss(of _all_) then delete;
RUN;

PROC PRINT DATA = gproject.UsedCars8(OBS=20);
RUN;

* Assumption - logPrice is normal distributed. In our case, this assumption is satisfied;
* If the dependent variable is normally distributed and you have a categorical independent variable 
that has 3 or more levels then you use ONE WAY ANOVA.;

/*	One-Way ANOVA for logPrice and region;*/
proc glm data=gproject.UsedCars8;
	class region;
	model logPrice = region /ss3;
	title "ANOVA of logPrice by region";
	run;
	quit; *region is significant;

/*	One-Way ANOVA for logPrice and condition;*/
 PROC GLM data=gproject.UsedCars8;
CLASS condition;
MODEL logPrice = condition;
MEANS condition / HOVTEST=LEVENE (TYPE=ABS);
OUTPUT OUT=diagnost p=ybar r=resid;
run;

PROC SGPLOT data=diagnost;
 SCATTER y=resid x=ybar;
 REFLINE 0;
run;

PROC UNIVARIATE noprint ;
  QQPLOT resid / normal;
run;


proc glm data=gproject.UsedCars8;
	class condition;
	model logPrice = condition /ss3;
	title "ANOVA of logPrice by condition";
	run;
	quit;

/*	One-Way ANOVA for logPrice and cylinders;*/
proc glm data=gproject.UsedCars8;
	class cylinders;
	model logPrice = cylinders /ss3;
	title "ANOVA of logPrice by cylinders";
	run;
	quit;

/*	One-Way ANOVA for logPrice and fuel;*/
PROC GLM data=gproject.UsedCars8;
CLASS fuel;
MODEL logPrice = fuel;
title "ANOVA of logPrice by fuel";
MEANS fuel / HOVTEST=LEVENE (TYPE=ABS);
OUTPUT OUT=diagnost p=ybar r=resid;
run;

PROC SGPLOT data=diagnost;
 SCATTER y=resid x=ybar;
 REFLINE 0;
run;

PROC UNIVARIATE noprint ;
  QQPLOT resid / normal;
run;


/*	One-Way ANOVA for logPrice and title_status;*/
proc glm data=gproject.UsedCars8;
	class title_status;
	model logPrice = title_status /ss3;
	title "ANOVA of logPrice by title_status";
	run;
	quit;

/*	One-Way ANOVA for logPrice and transmission;*/
proc glm data=gproject.UsedCars8;
	class transmission;
	model logPrice = transmission /ss3;
	title "ANOVA of logPrice by transmission";
	run;
	quit;

/*	One-Way ANOVA for logPrice and drive;*/
proc glm data=gproject.UsedCars8;
	class drive;
	model logPrice = drive /ss3;
	title "ANOVA of logPrice by drive";
	run;
	quit;

/*	One-Way ANOVA for logPrice and type;*/
proc glm data=gproject.UsedCars8;
	class type;
	model logPrice = type /ss3;
	title "ANOVA of logPrice by type";
	run;
	quit;

/*	One-Way ANOVA for logPrice and paint_color;*/
proc glm data=gproject.UsedCars8;
	class paint_color;
	model logPrice = paint_color /ss3;
	title "ANOVA of logPrice by paint_color";
	run;
	quit;

/*	One-Way ANOVA for logPrice and model;*/
proc glm data=gproject.UsedCars8;
	class model;
	model logPrice = model /ss3;
	title "ANOVA of logPrice by model";
	run;
	quit;

/*	One-Way ANOVA for logPrice and manufacturer;*/
proc glm data=gproject.UsedCars8;
	class manufacturer;
	model logPrice = manufacturer /ss3;
	title "ANOVA of logPrice by manufacturer";
	run;
	quit;

/*	One-Way ANOVA for logPrice and size;*/
proc glm data=gproject.UsedCars8;
	class size;
	model logPrice = size /ss3;
	title "ANOVA of logPrice by size";
	run;
	quit;



* Model Builing:: Regression Models;
ods graphics on;

*Model1 : multi-Linear regression with all the independent variables excluding model;
proc glm data=gproject.UsedCars8 order=freq plots=all plots(MAXPOINTS=352523);
  title "GLM model with all Variables excluding model";
  class manufacturer type region condition fuel title_status cylinders transmission drive paint_color size;
  glmModelAll: model logPrice = year odometer manufacturer type region condition fuel title_status cylinders transmission drive paint_color size /solution ss3 tolerance; 
output out=out r=residuals cookd=cookd student=student rstudent=rstudent predicted=predicted h=leverage dffits=dffits;
run;
quit;

ods graphics on / TIPMAX=97500;
* Check validity of assumptions;
proc univariate data=out;
	var residuals;
	histogram residuals / normal kernel;
	qqplot residuals / normal(mu=est sigma=est);
	run;


 ods graphics on;
*Model2 : multi-Linear regression with all the independent variables excluding model title_staus transmission paint_color;
proc glm data=gproject.UsedCars8 order=freq plots=all plots(MAXPOINTS=352523);
title "GLM model excluding title_staus transmission paint_color Variables";
  class manufacturer type region condition fuel cylinders drive size;
  glmModelAll3: model logPrice = year odometer manufacturer type region condition fuel cylinders drive size /solution ss3 tolerance; 
output out=out r=residuals cookd=cookd student=student rstudent=rstudent predicted=predicted h=leverage dffits=dffits;
run;
quit;

ods graphics on / TIPMAX=97500;
* Check validity of assumptions;
proc univariate data=out;
	var residuals;
	histogram residuals / normal kernel;
	qqplot residuals / normal(mu=est sigma=est);
	run;


*Model3: Using proc glmselect - Lasso;
proc glmselect data=gproject.UsedCars8  plots=all;
   title "GLMSELECT model with all Variables excluding model";
  class manufacturer type region condition fuel title_status cylinders drive paint_color size;
 modelLasso : model logPrice= year odometer manufacturer type region condition fuel title_status cylinders drive paint_color size / selection=lasso 
	details=steps select=SL slentry=0.05 slstay=0.05 showpvalues; 
  output out=out1 r=residuals predicted=predicted_values;
run;
quit;


* model using the degree of polynomial;
ods graphics on;
proc glmselect data=gproject.UsedCars8 plots=all;
	class fuel;
	effect p_odo = polynomial(odometer / degree = 2);
	Backward_selection: model logPrice = p_odo year fuel / selection = none
			slstay = 0.05 hierarchy = single showpvalues;
	title "Polynomial Model using odometer and year against logPrice";
	output out=out004 r=residuals predicted=predicted_values;
	run;

ods graphics / TIPMAX=97500 ;
 proc univariate data=out004;
var residuals;
histogram residuals / normal kernel;
qqplot residuals / normal(mu=est sigma=est);
run;

proc sgplot data=out004;
	scatter x=predicted_values y= residuals;
	title "Scatter Plot using Used car data";
	run;


*---------------------------------------------------------------------------------------------------------------------------;
*Transforming categorical data with dummy values;

data gproject.UsedCars9;
    set gproject.UsedCars8;

	*paint_color variable transformation;
	if paint_color = "black" then paint_color = 201;
	if paint_color = "blue" then paint_color = 202;
	if paint_color = "brown" then paint_color = 203;
	if paint_color = "custom" then paint_color = 204;
	if paint_color = "green" then paint_color = 205;
	if paint_color = "grey" then paint_color = 206;
	if paint_color = "orange" then paint_color = 207;
	if paint_color = "purple" then paint_color = 208;
	if paint_color = "red" then paint_color = 209;
	if paint_color = "silver" then paint_color = 210;
	if paint_color = "white" then paint_color = 211;
	if paint_color = "yellow" then paint_color = 212;
	
	*manufacturer variable transformation;
    if manufacturer = "acura" then manufacturer = 1;
	if manufacturer = "alfa-romeo" then manufacturer = 2;
	if manufacturer = "aston-martin" then manufacturer = 3;
	if manufacturer = "audi" then manufacturer = 4;
	if manufacturer = "bmw" then manufacturer = 5;
	if manufacturer = "buick" then manufacturer = 6;
	if manufacturer = "cadillac" then manufacturer = 7;
	if manufacturer = "chevrolet" then manufacturer = 8;
	if manufacturer = "chrysler" then manufacturer = 9;
	if manufacturer = "dodge" then manufacturer = 10;
	if manufacturer = "ferrari" then manufacturer = 11;
	if manufacturer = "fiat" then manufacturer = 12;
	if manufacturer = "ford" then manufacturer = 13;
	if manufacturer = "gmc" then manufacturer = 14;
	if manufacturer = "harley-davids" then manufacturer = 15;
	if manufacturer = "honda" then manufacturer = 16;
	if manufacturer = "hyundai" then manufacturer = 17;
	if manufacturer = "infiniti" then manufacturer = 18;
	if manufacturer = "jaguar" then manufacturer = 19;
	if manufacturer = "jeep" then manufacturer = 20;
	if manufacturer = "kia" then manufacturer = 21;
	if manufacturer = "land rover" then manufacturer = 22;
	if manufacturer = "lexus" then manufacturer = 23;
	if manufacturer = "lincoln" then manufacturer = 24;
	if manufacturer = "mazda" then manufacturer = 25;
	if manufacturer = "mercedes-benz" then manufacturer = 26;
	if manufacturer = "mercury" then manufacturer = 27;
	if manufacturer = "mini" then manufacturer = 28;
	if manufacturer = "mitsubishi" then manufacturer = 29;
	if manufacturer = "nissan" then manufacturer = 30;
	if manufacturer = "pontiac" then manufacturer = 31;
	if manufacturer = "porsche" then manufacturer = 32;
	if manufacturer = "ram" then manufacturer = 33;
	if manufacturer = "rover" then manufacturer = 34;
	if manufacturer = "saturn" then manufacturer = 35;
	if manufacturer = "subaru" then manufacturer = 36;
	if manufacturer = "tesla" then manufacturer = 37;
	if manufacturer = "toyota" then manufacturer = 38;
	if manufacturer = "volkswagen" then manufacturer = 39;
	if manufacturer = "volvo" then manufacturer = 40;

	*type variable transformation;
	if type = "SUV" then type = 101;
	if type = "bus" then type = 102;
	if type = "convertible" then type = 103;
	if type = "coupe" then type = 104;
	if type = "full-size" then type = 105;
	if type = "hatchback" then type = 106;
	if type = "mini-van" then type = 107;
	if type = "offroad" then type = 108;
	if type = "other" then type = 109;
	if type = "pickup" then type = 110;
	if type = "sedan" then type = 111;
	if type = "truck" then type = 112;
	if type = "van" then type = 113;
	if type = "wagon" then type = 114;

	*transmission variable transformation;
	
	if transmission = "automatic" then transmission = 901;
	else if transmission = "manual" then transmission = 902 ;
	else transmission = 3;

	*region variable transformation;
	if region = "midwest" then region = 401;
	if region = "northeast" then region = 402;
	if region = "south" then region = 403;
	if region = "west" then region = 404;

	*drive variable transformation;
	if drive = "4wd" then drive = 501;
	if drive = "fwd" then drive = 502;
	if drive = "rwd" then drive = 503;

	*size variable transformation;
	if size = "compact" then size = 601;
	if size = "full-size" then size = 602;
	if size = "mid-size" then size = 603;
	if size = "sub-compact" then size = 604;
	else size = 605;

	*condition variable transformation;
	IF condition = "good" then condition = 41;
	IF condition = "excellent" then condition = 42;
	if condition = "like new" then condition = 43;
	if condition = "fair" then condition = 44;
	if condition = "new" then condition = 45;
	if condition = "salvage" then condition = 46;

	*fuel variable transformation;
	If fuel = "gas" then fuel = 51;
	if fuel = "other" then fuel = 52;
	if fuel = "diesel" then fuel = 53;
	if fuel = "hybrid" then fuel = 54;
	if fuel = "electr" then fuel = 55;

	*title_status variable transformation;
	If title_status = "clean" then title_status = 61;
	if title_status = "rebuilt" then title_status = 62;
	if title_status = "salvage" then title_status = 63;
	if title_status = "lien" then title_status = 64;
	if title_status = "missing" then title_status = 65;
	if title_status = "parts o" then title_status = 66;

	*cylinders variable transformation;
	If cylinders = "6 cylinders" then cylinders = 71;
	if cylinders = "4 cylinders" then cylinders = 72;
	if cylinders = "8 cylinders" then cylinders = 73;
	if cylinders = "5 cylinders" then cylinders = 74;
	if cylinders = "10 cylinders" then cylinders = 75;
	if cylinders = "other" then cylinders = 76;
	if cylinders = "3 cylinders" then cylinders = 77;
	if cylinders = "12 cylinders" then cylinders = 78;
	Run;


*Convert Char variable types to numeric post data transformation;
data gproject.UsedCars10(drop = city state model transmission) ;
   set gproject.UsedCars9 ;

   array _char manufacturer type region condition fuel title_status cylinders drive paint_color size ;

   array _num 8 manufacturerN typeN regionN conditionN fuelN title_statusN cylindersN driveN paint_colorN sizeN ;

   do i=1 to dim(_char);
      _num(i) = input(_char(i), BEST32.);
	  end;
run;

data gproject.UsedCars12(drop = i) ;
   set gproject.UsedCars98 ;
   run;


proc contents data = gproject.UsedCars12;
run;

PROC PRINT DATA = gproject.UsedCars12(OBS=20);
RUN;

PROC MEANS DATA = gproject.UsedCars12 NMISS N;
	var _NUMERIC_;
RUN;

PROC IML;
use gproject.UsedCars12;
read all var _NUM_ into Y[c=varNames];
title 'Heatmap of Transformed Numeric Predictors Against LogPrice';
close;
corr = corr(Y);
 
/* bin correlations into five categories */
Labl = {'1:Very Neg','2:Neg','3:Neutral','4:Pos','5:Very Pos'};        /* labels */
bins= bin(corr, {-1, -0.6, -0.2, 0.2, 0.6, 1});           /* BIN returns 1-5 */
disCorr = shape(Labl[bins], nrow(corr));               /* categorical matrix */
call HeatmapDisc(disCorr) title="Binned Correlations"
     xvalues=varNames yvalues=varNames;
	 outest = corr;
RUN;

