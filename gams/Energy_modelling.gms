$TITLE Simple Energy Transition CGE Model

$call GDXXRW SAM.xlsx output=SAM.gdx par=SAM rng= SAM!A1:L12 Rdim=1 Cdim=1


Set Acc / AGR, IND, TRN, FOS, REN, LAB, CAP, HH, GOV, INV, ROW/;

Alias(Acc,Ac);

parameter SAM(Acc,Acc);

$GDXIN SAM.gdx
$Load SAM
$GDXIN
Display SAM;

Set

i(Acc) sectors /AGR, IND, TRN, FOS, REN/
f(Acc) factor_of_production /LAB, CAP/
h(Acc) household /HH/
g(Acc) government /GOV/
row(Acc) restofworld /ROW/;

Alias (i,j);

* 3. BASIC PARAMETERS FROM SAM: calibration converts accounting data into behavioural parameters.
*This section reconstructs the entire economy mathematically. Finding parameter values such that the model exactly reproduces the SAM.
*Gave: observed quantities, observed flows (output,labour demand, household consumption etc..)

Parameter

X0(i) output
VA0 (I) vALUE ADDED
INT0 (i,j) intermediate demand 
FD0 (i) household demand 
G0(i)   government demand
INV0(i) investment demand 
EX0(i)  exports
IM0(i)  imports
LD0(i)  Labor demand
KD0(i)  capital demand
YH0     household income
GOVREV0 goverment revenue
SAV0  Svings
ROWBAL0 foreign savings
 ; 
X0(i) = sum(Ac,SAM(i,Ac));

INT0(i, j)= SAM(i,j);
LD0(i)= SAM("lab",i);
KD0(i)=SAM("cap", i);
VA0(I)=LD0(i)+KD0(i);
FD0(i)= SAM(i, "hh"); 
G0(i)= SAM(i,"gov"); 
INV0(i)= SAM(i,"inv");
EX0(i) = SAM(i,"row");
IM0(i)= SAM("row", i); 
YH0= sum(i,LD0(i)+KD0(i))+ SAM("hh", "row");
GOVREV0= sum (i, SAM("gov", i) +SAM("gov","hh"));
SAV0= SAM("inv","hh");
ROWBAL0= sum(i, IM0(i)) - sum(i, EX0(i));


Display X0, VA0, FD0, G0, INV0, EX0, IM0, LD0, KD0;

*4. CALIBRATION PARAMETERS:  
*But the CGE model still does NOT know: how firms behave, how households choose, substitution possibilities, input shares
*That is what calibration parameters do.

*In energy-transition CGE
*Calibration becomes even more important because you calibrate:
*energy intensities
*electricity shares
*fossil fuel dependence
*emissions coefficients
*renewable penetration

Parameter
alpha(i) household budget shares
betaL(i) labour share in value added
betaK(i) capital share in value added
aVA(i)    value-added share in output
aINT(j,i)  intermediate input coefficient
tx(i)      production tax rate;

alpha(i)= FD0(i)/sum(j,FD0(j));
betaL(i)  = LD0(i) / VA0(i);
betaK(i)  = KD0(i) / VA0(i);
aVA(i)=VA0(i)/X0(i);
aINT(i,j)= INT0(i,j)/X0(j);
tx(i)     = 0;

Display aVA;



* =====================================================
* 5. ENERGY AND EMISSIONS DATA- Climate Policy
* =====================================================
*With moneraty data
*a standard economic model into an energy-transition and climate-policy model.
*Without the ENERGY & EMISSIONS section: the model only tracks:
*production
*consumption
*trade
*income
*But it cannot analyze: carbon emissions, fossil fuel dependence, renewable transition
*electrification
*decarbonization
*climate policy
*“What happens to the economy AND energy system AND emissions?”
*Because energy is:
*an input to production
*a driver of emissions
*central to climate policy.
*Because climate policy works through emissions.


Set e energy / fos /;

Parameter

emisCoef(e)  emission coefficient. how much pollution (usually CO₂) is emitted when using one unit of fuel or energy. CO₂ emitted per unit of fuel consumed.
energyUse(e,i) fossil energy use by sector
CO20(i)        benchmark emissions;

*each fossil-energy unit emits 2.5 CO₂ units.
emisCoef("fos") = 2.5 ;

energyUse("fos", i)=INT0("fos", i);

CO20(i) = energyUse("fos", i) * emisCoef("fos");
Display energyUse, CO20;

* =====================================================
* 6.VARIABLES
* =====================================================
*This section defines the unknown economic quantities that the CGE model must solve for.
*Parameters: Known values: taken from the SAM, calibrated from data,fixed in the benchmark (household shares).

*Variables: Unknown endogenous outcomes: determined by equilibrium.
*A CGE model is a system of equations. The equations describe:
*firm behaviour
*household behaviour
*market equilibrium
*government balance
*trade balance.

*The variables are:the values the model must compute to satisfy all equations simultaneously.

Positive Variable

X(i)  output
VA(i) value added
*Q(i)  composite supply
C(i)  household consumption
LD(i) labour demand
KD(i) capital demand
P(i)  comodity price
PX(i) producer price
W     wage
R     return to capital
YH    household income
GOVREV government revenue
CO2(i) emission;

Variables

Walras;
*Example Suppose: carbon tax increases fossil-energy prices.
*Then: firms reduce production, households change consumption, wages may change,imports may change, emissions fall.
*These changes are represented by: variables.

* =====================================================
* 7. EQUATIONS
* =====================================================
Equations

production(i)
*Va_def(i)
labour_demand(i)
capital_demand(i)
price_def(i)
price_link(i)
income_def
demand_def(i)
market_clear(i)
goverev_def
co2_def(i)
*walras_def
lab_market
cap_market;

*Leontief production (because inputs are required in fixed proportions.firms cannot change these proportions.)
production(i).. X(i)=E=VA(i)/aVA(i);

*va_def(i)..    VA(i) =E= X(i) * aVA(i);

* Cobb-Douglas factor demand
*These equations define how firms demand: labour and capital in the CGE
*They are derived from: firm cost minimization / profit maximization.
*Labour demand increases when: production/value added increases, output prices increase.
*Labour demand decreases when: wages increase.
* If wages rise: firms hire less labour. Because labour becomes more expensive.

*Where do these equations come from? They come from: optimization. Specifically:firms minimize production cost subject to production technology.
*These equations determine: employment, wages, capital allocation
*Suppose: renewable energy is capital intensive, fossil sectors are labour intensive.
*Then transition changes: employment structure, capital demand, wages.

labour_demand(i).. LD(i)=E= betaL(i)*VA(i)*PX(i)/W;

capital_demand(i)..KD(i) =E= betaK(i) * PX(i) * VA(i) / R;

* Producer price including carbon tax on fossil-energy use
*This is the “zero-profit” or “unit cost” equation:  It says: the price of output must equal the cost of producing it.
*A firm produces output using: intermediate inputs, labour, capital, taxes.
*Cost=IntermediateInputs+ValueAdded+Taxes
*price: industry price fossil-energy price> ntermediate input costs (Sector i buys inputs from other sectors j.)
*Why multiply by aVA(i)? Because: value added is only part of total production cost.

price_def(i)..
    PX(i) =E=
        sum(j, aINT(j,i) * P(j))
        + aVA(i) * (betaL(i)*W + betaK(i)*R)
        + tx(i);
        
price_link(i)..
    P(i) =E= PX(i);

*Income: This defines: endogenous household income during simulations. We don't include transfert because it is exogenous
*It is one of the core equations of the CGE model because it determines: consumption, welfare, demand responses, how households react to price and income changes.

income_def.. YH =E= W * sum(i, LD(i)) + R * sum(i, KD(i));

* household demand for goods. households spend a fixed share of income on each good.
*if prices rise, they can buy fewer quantities. This Cobb-Douglas demand system is standard in simple CGE models:
*alpha(i)=household expenditure preferences. for example households spend 10% of income on fossil energy.
*If energy prices rise: households spending heavily on energy are more affected. demand_def(i)..
*It comes from: utility maximization. Households maximize utility subject to: income constraint.  
demand_def(i)..
    C(i) =E= alpha(i) * YH / P(i);

$onText

More advanced CGE demand systems

Later you may use:

LES (Linear Expenditure System)
CES utility
Stone-Geary
nested demand systems.

These allow:

minimum consumption
substitution between goods
energy transition behaviour.
C(i) =E= alpha(i) * YH / P(i);
$offText
*government revenue from production taxes. It tells the model: how much tax income the government collects.

goverev_def.. GOVREV =E= sum(i, tx(i) * X(i));
     
*Market-clearing equation. Commodity balance equation. It ensures that: total supply equals total demand.
*This is the heart of general equilibrium theory.

market_clear(i)$(not sameas(i,"AGR"))..
    X(i) + IM0(i) =E=
        C(i)
        + G0(i)
        + INV0(i)
        + EX0(i)
        + sum(j, aINT(i,j) * X(j));
        

*factor market-clearing

lab_market..
    sum(i, LD(i)) =E= sum(i, LD0(i));

cap_market..
    sum(i, KD(i)) =E= sum(i, KD0(i));
    


        
*This equation defines: how CO₂ emissions are generated in the economy.
*It is the equation that connects: economic production, energy use, climate emissions.
*This is one of the key equations transforming your CGE into: a climate / energy-transition model.

*co2_def
*It is the equation that connects: economic production energy use climate emissions.

*This equation defines: how CO₂ emissions are generated in the economy.
*This emissions-production linkage is central in climate-economy models:
*X(i) / X0(i): how much production changed compared to the base-year economy.

$onText
But after a policy shock?

Suppose:

carbon tax
renewable subsidy
productivity shock

changes production.

Now Industry may produce:

240
or 150
or 100.

The model must therefore adjust energy use accordingly.
$offText

co2_def(i)..
    CO2(i) =E= energyUse("fos", i) * X(i) / X0(i) * emisCoef("fos");
    
*This equation says: emissions are proportional to: fossil-energy use production level carbon intensity.

*Walras: This equation checks whether: all markets clear simultaneously.
*It measures: total excess demand or total excess supply in value terms.

*Walras’ Law says:if all markets except one are in equilibrium, then the last market must also be in equilibrium.

*walras_def..WALRAS =E= sum(i, P(i) * (X(i) + IM0(i)- C(i) - G0(i) - INV0(i) - EX0(i)- sum(j, aINT(i,j) * X(j))));
              


* =====================================================
* 8. MODEL: “These are the equations that together define my economic system.”“All these equations interact simultaneously.”
*It tells GAMS: solve all equations simultaneously.
*=====================================================
$onText
| Mechanism        | Depends on              |
| ---------------- | ----------------------- |
| Production       | prices, labour, capital |
| Household demand | income, prices          |
| Income           | wages, capital returns  |
| Emissions        | production, energy use  |
| Prices           | taxes, wages, inputs    |
$offText


Model energyCGE /
    production
*va_def
    labour_demand
    capital_demand
    price_def
    price_link
    income_def
    demand_def
    market_clear
     goverev_def
    co2_def
*walras_def
    lab_market
    cap_market
/;
* =====================================================
* 9. INITIAL VALUES: starting values for the endogenous variables before the model is solved.
*CGE models are nonlinear systems nonlinear solvers need an initial guess.
*=====================================================
$onText
When GAMS solves the model, it does NOT automatically know:

prices
production
wages
consumption
emissions.

It must search for equilibrium values.

The initial values help the solver:

$offText

X.l(i)     = X0(i);
VA.l(i)    = VA0(i);
C.l(i)     = FD0(i);
LD.l(i)    = LD0(i);
KD.l(i)    = KD0(i);

P.l(i)     = 1;
PX.l(i)    = 1;
W.l        = 1;
R.l        = 1;
YH.l       = YH0;
GOVREV.l   = GOVREV0;
CO2.l(i)   = CO20(i);

* Numeraire (normalise price, simplify calibration)
P.fx("agr") = 1;
* =====================================================
* 10. BASELINE SOLUTION; “Now solve the model and reproduce the benchmark equilibrium.”
*the benchmark equilibrium economy. Usually: before any policy shock. he model reproduces the SAM equilibrium exactly.
* =====================================================
$onText
It is one of the most important stages in CGE modelling because it verifies:

your equations are consistent
your calibration is correct
your SAM equilibrium is reproduced.
$offText


*Solve; how the equilibrium problem is mathematically formulated and solved. CNS(Constrained Nonlinear System): solve the model as a system of nonlinear equations.
*cns: Used when: number of equations = number of variables
*MCP: solve the model as a complementarity equilibrium problem. equations are written as equalities.


Solve energyCGE using CNS;

Parameter
    X_base(i)
    C_base(i)
    CO2_base(i)
;

X_base(i)   = X.l(i);
C_base(i)   = C.l(i);
CO2_base(i) = CO2.l(i);

Display X_base, C_base, CO2_base;

* =====================================================
* 11. CARBON TAX SCENARIO
* =====================================================

* Carbon tax applied to sectors using fossil energy. sectors pay a tax proportional to their fossil-energy intensity.So sectors that use more fossil energy per unit of output pay a higher tax.
tx(i) = 0.05 * energyUse("fos",i) / X0(i);

Solve energyCGE using CNS;

Parameter
    X_scen(i)
    C_scen(i)
    CO2_scen(i)
    pct_change_output(i)
    pct_change_consumption(i)
    pct_change_CO2(i)
;

*Then after carbon tax:
X_scen(i)   = X.l(i);
C_scen(i)   = C.l(i);
CO2_scen(i) = CO2.l(i);

pct_change_output(i) =
    100 * (X_scen(i) - X_base(i)) / X_base(i);

pct_change_consumption(i) =
    100 * (C_scen(i) - C_base(i)) / C_base(i);

pct_change_CO2(i) =
    100 * (CO2_scen(i) - CO2_base(i)) / CO2_base(i);

Display
    X_scen
    C_scen
    CO2_scen
    pct_change_output
    pct_change_consumption
    pct_change_CO2
    GOVREV.l
*WALRAS.l;
    

