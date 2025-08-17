; Artificial Finantial Market

; ==========
; globals and agent setup
; ==========

globals [
  stock-price
  fundamental-value
  price-sensitivity
  price-history
  volatility
  tick-counter
  network-edges
  periodic-shock-magnitude
  shock-count
  periodic-positive-shock-count
  rsi
  rsi-history
]

turtles-own [
  class   ; fundamentalist, technicalist, noise-raders
  wealth
  risk
  confidence
  stock-holding
  decision
  past-price
]

links-own [
  strength
]

;============
; steup procedures
;============

to setup
  clear-all
  set-default-shape turtles "person"
  setup-globals
  setup-investors
  setup-network
  reset-ticks

end

to setup-globals
  set stock-price 1000
  set fundamental-value 100
  set price-sensitivity 0.05
  set price-history (list stock-price)
  ;; set fundamental-value to half the wealth of richest turtule
  ;if any? turtles [
  ; let richest-wealth max [wealth] of turtles
  ;  set fundamental-value richest-wealth / 2
  ;]
  set volatility 0
  set tick-counter 0
  set periodic-shock-magnitude -100 ;; its initial shock :)
  set shock-count 0
  set periodic-positive-shock-count 0
  set rsi 50 ;; initial neutral RSI to start
  set rsi-history []
end

to setup-investors
  create-turtles 100 [
    setxy random-xcor random-ycor
    set wealth random-float initial-wealth
    set risk random-float 1
    set stock-holding 0
    set past-price stock-price
    set class one-of ["fundamentalist" "technicalist" "noise-traders"]
    set color ifelse-value (class = "fundamentalist") [blue]
              [ifelse-value (class = "technicalist") [orange]
                [pink]]
  ]
end

; =========
; network structure
; =========

to setup-network
  let k 2
  let p 0.1
  let n count turtles

  ask turtles [
    let my-id who
    ; loop over offsets from 1 to k
    (foreach n-values k [i -> i + 1] [ offset ->
      let right-id (my-id + offset) mod n
      let left-id (my-id - offset + n) mod n
      if not link-neighbor? turtle right-id [
        create-link-with turtle right-id
      ]
      if not link-neighbor? turtle left-id [
        create-link-with turtle left-id
      ]
    ])
  ]

  ; Rewire some links locally
  ask links [
    if random-float 1 < p [
      let source end1
      let target end2
      let candidates turtles with [
        self != source and
        not link-neighbor? source and
        distance source < 5
      ]
      if any? candidates [
        let new-target one-of candidates
        ask source [ create-link-with new-target ]
        die
      ]
    ]
  ]
end

;===============
; report some datas
;===============
to report-richest-person
  let richest max-one-of turtles [wealth + stock-holding * stock-price]
end
to report-poorest-person
 let poorest min-one-of turtles [wealth + stock-holding * stock-price]
end

; ==========
; main go procedure
; ==========

to go
  if enable-news-shocks? [
    if random-float 1 < news-shock-prob [inject-news-shock]
  ]

  ;; trigger negative shock every 150 ticks
  if (ticks mod 200 = 0) and ticks > 0 [
    inject-periodic-shock
  ]
  ;; triger positive shock every 1000 ticks
  if (ticks mod 600 = 0) and ticks > 0 [
    inject-positive-periodic-shock
  ]

  ask turtles [
    evaluate-market
    update-price
    calculate-volatility
    interact-with-neighbors
    update-wealth
    update-price-history
    update-rsi-plot
    update-price-plot
  ]
  output-print (word "Tick:" ticks  "  Last Price:" last  price-history)
  report-richest-person
  report-poorest-person
  calculate-rsi
  set rsi-history lput rsi rsi-history
  if length rsi-history > 14 [ set rsi-history but-first rsi-history]

  ;set price-history lput stock-price price-history
  ;if length price-history > 20 [ set price-history but-first price-history]

  tick
end

; ========
; decision making process
; ========

to evaluate-market
  if class = "fundamentalist" [
    if stock-price < fundamental-value [set decision "buy" set color green]
    if stock-price > fundamental-value [set decision "sell" set color red]
  if abs(stock-price - fundamental-value) < 1 [set decision "hold" set color yellow]
  ]
;; to capture Framing biases, we add a risk factor in Technicalist decisions here:
;; risk-tolerant agents see rising price as a buy signal  (risk > 0.6)
;; risk-averse agents frame trend as risky (framing bias) (risk < 0.6)
  if class = "technicalist" [
    let change (stock-price - past-price)
    let sqrt-volatility volatility ^ 0.5
    if risk >= 0.6 [
      if change > sqrt-volatility [
        set decision "buy"
        set color green
      ]
      if change < sqrt-volatility [
        set decision "sell"
        set color red
      ]
      if abs(change) <= sqrt-volatility [
        set decision "hold"
        set color yellow
      ]
    ]
    if risk < 0.6 [
      if change > sqrt-volatility [
        set decision "sell"
        set color red
      ]
      if change < sqrt-volatility [
        set decision "buy"
        set color green
      ]
      if abs(change) <= sqrt-volatility [
        set decision "hold"
        set color yellow
      ]
    ]
  ]

;; to capture netwrok-based biases, we add biases in decision of noise traders based on thier confidence level which is dependent to their closest neighbors in our small world network
  if class = "noise-traders" [
    if confidence > 0.6 [
      ;; high conficence means pick buy/sell more often than holding the price
      set decision one-of (n-values 5 [ i -> ifelse-value (i < 4) ["buy"]
        [one-of ["sell" "hold"]]] )
    ]
     if confidence < 0.4 [
      ;; low confidence means more likely to hold
      set decision one-of (n-values 5 [ i -> ifelse-value (i < 3) ["hold"]
        [ifelse-value (i = 3) ["sell"] ["buy"] ] ] )
      ]
     if confidence >= 0.4 and confidence <= 0.6 [
     ;; lets moderate confidence: uniform choices
    set decision one-of ["buy" "sell" "hold"]
    ]

    if decision = "buy" [set color green]
    if decision = "sell" [set color red]
    if decision = "hold" [set color yellow]
  ]
end

; ============
; price updates and volatility
; ============

to update-price
  let buyers count turtles with [decision = "buy"]
  let sellers count turtles with [decision = "sell"]
  let delta price-sensitivity * (buyers - sellers)
  set stock-price max list 1 (stock-price + delta)
end

;;; NOTE: if you want, you can use this part of code but because we need to use GARCH process, we use of the second method.
;to calculate-volatility
;  if length price-history > 1 [
;    let recent-diffs map [p -> abs (stock-price - p)] price-history
;    set volatility mean recent-diffs
;  ]
;end

;;; NOTE: GARCH process (Volatility clustering) --> here we use GRACH(1,1) to calculate volatility:
to calculate-volatility
  let past-volatility volatility
  let squared-return (stock-price - past-price) ^ 2
  set volatility (0.1 * squared-return + 0.8 * past-volatility)
end

; =======
; neighbor interaction and framing
; =======

to interact-with-neighbors
  let my-neighbors link-neighbors
  if any? my-neighbors [
    let neighbor-confidence mean [confidence] of my-neighbors
    set confidence confidence + 0.05 * (neighbor-confidence - confidence)
  ]
end

; ========
; wealth and history update
; ========

to update-wealth
  if decision = "buy" and wealth >= stock-price [
    set stock-holding stock-holding + 1
    set wealth wealth - stock-price
  ]
  if decision = "sell" and stock-holding > 0 [
    set stock-holding stock-holding - 1
    set wealth wealth + stock-price
  ]
end

to update-price-history
  set past-price stock-price
  set price-history lput stock-price price-history
  if length price-history > 4000 [
    set price-history but-first price-history
  ]
end

; ===========
; plotting last 14 days prices
; ===========

to update-price-plot
  set-current-plot "stock prices over last 14 ticks"
  clear-plot
  set-current-plot-pen "last-14-prices"
  set-plot-pen-color orange

  if length price-history >= 1680 [
  let last-14-prices sublist price-history (length price-history - 1680) (length price-history)

  let min-price min last-14-prices
  let max-price max last-14-prices

  let range-diff max (list 1 (max-price - min-price))
  let padding range-diff * 0.05

  ;set-plot-y-range (min-price - 5) (max-price + 5)
  let rounded-min precision (min-price - padding) 1
  let rounded-max precision (max-price + padding) 1

  set-plot-y-range rounded-min rounded-max

  let x 0
  foreach last-14-prices [
  p ->
 ; plotxy x p
  plotxy x (precision p 1)
  set x x + 1
  ]
  ]
end

; ======
; news shock events
; ======

to inject-news-shock
  let shock-magnitude one-of [-75 -50 -25 100 150]
  set fundamental-value fundamental-value + shock-magnitude
  show (word "Tick" ticks ": news shock! fundamental value changed by: " shock-magnitude)
end

to inject-periodic-shock
  set fundamental-value fundamental-value + periodic-shock-magnitude
  set periodic-shock-magnitude periodic-shock-magnitude * 1.425
  set shock-count shock-count + 1
  show (word" WOOOW. periodic shock at tick " ticks ": fundamental value decreased by " periodic-shock-magnitude)
;; after every 5 shocks, halve the shock magnitude
  if shock-count mod 5 = 0 [
  set periodic-shock-magnitude periodic-shock-magnitude / 2
  show(word" After 5 shocks, magnitude halved to: "periodic-shock-magnitude)
  ]
end

to inject-positive-periodic-shock
  let shock-magnitude 500 * 2 ^ periodic-positive-shock-count
  set fundamental-value fundamental-value + shock-magnitude
  set periodic-positive-shock-count periodic-positive-shock-count + 1
  show (word "Positive periodic shock by ADAM SMITH! Magnitude: " shock-magnitude " at tick " ticks)
  ;; after every 3 positive shocks, double the shock magnitude
  if periodic-positive-shock-count mod 3 = 0 [
    set shock-magnitude shock-magnitude * 2
    show(word" After 2 positive shocks, magnitude doubled to: "shock-magnitude)
  ]
end

; =========
; calculating relative strength index (RSI)
; =========

to calculate-rsi
  let period 14
  if length price-history >= period [
    let recent-prices sublist price-history (length price-history - (period + 1)) (length price-history)
    let gains []
    let losses []

;; loop through price differences
    (foreach but-last recent-prices but-first recent-prices [
      [prev curr] ->
    let diff curr - prev
      if diff > 0 [ set gains lput diff gains ]
      if diff < 0 [ set losses lput abs diff losses ]
      ])

    let avg-gain ifelse-value (length gains > 0) [mean gains] [0]
    let avg-loss ifelse-value (length losses > 0) [mean losses] [0]

    if avg-loss = 0 [
      set rsi 100
    ]
     if avg-loss != 0 [
      let rs avg-gain / avg-loss
      set rsi 100 - (100 / (1 + rs))
    ]
  ]
end

to update-rsi-plot
  set-current-plot "RSI indicator for last 14 days"
  clear-plot

  ;; draw rsi values
  let x 0
  foreach rsi-history [
    val ->
    plotxy x val
    set x x + 1
  ]
  draw-horizontal-line 70 red
  draw-horizontal-line 30 green
end

to draw-horizontal-line [y color-name]
  set-current-plot-pen (word "line-" y)
  set-plot-pen-color color-name

  plotxy 0 y
  plotxy 13 y ; plotting last 14 days (index 0 to 13)
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
824
625
-1
-1
18.364
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
74
236
137
281
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
145
236
202
281
NIL
ticks
17
1
11

PLOT
0
286
204
477
mean wealth over time
time
mean wealth
0.0
100.0
0.0
100.0
true
true
"clear-all-plots" ""
PENS
"all" 1.0 0 -16777216 true "" "plot mean [wealth] of turtles"
"fund" 1.0 0 -14454117 true "" "plot mean [wealth] of turtles with [class = \"fundamentalist\"]"
"tech" 1.0 0 -955883 true "" "plot mean [wealth] of turtles with [class = \"technicalist\"]"
"noise" 1.0 0 -1664597 true "" "plot mean [wealth] of turtles with [class = \"noise-traders\"]"

BUTTON
2
236
65
282
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
3
484
203
625
wealth distribution
NIL
wealth distr
0.0
10.0
0.0
1.0
true
true
"clear-all-plots" "set-plot-y-range 0 1\nset-plot-x-range 0 max [wealth] of turtles + 1"
PENS
"all" 1.0 1 -14835848 true "" "histogram [wealth] of turtles"
"fund" 1.0 0 -13791810 true "" "histogram [wealth] of turtles with [class = \"fundamentalist\"]"
"tech" 1.0 0 -955883 true "" "histogram [wealth] of turtles with [class = \"technicalist\"]"
"noise" 1.0 0 -2064490 true "" "histogram [wealth] of turtles with [class = \"noise-traders\"]"

PLOT
1230
133
1508
331
log price over time
time
log-price
0.0
10.0
0.0
10.0
true
false
"clear-all-plots" ""
PENS
"log price" 1.0 0 -8053223 true "" "if stock-price > 0 [\nplot ln stock-price\n]"

PLOT
1229
335
1508
485
Volatility
time
volatility
0.0
10.0
0.0
10.0
true
false
"clear-all-plots" ""
PENS
"volatility" 1.0 0 -14730904 true "" "plot volatility"

SLIDER
2
10
204
43
initial-wealth
initial-wealth
0
1000
455.0
1
1
NIL
HORIZONTAL

SWITCH
2
46
204
79
enable-news-shocks?
enable-news-shocks?
0
1
-1000

OUTPUT
1202
10
1511
126
14

MONITOR
827
10
981
67
The poorest wealth
[wealth + stock-holding * stock-price] of min-one-of turtles [wealth + stock-holding * stock-price]
20
1
14

MONITOR
827
71
981
128
Elon musk
[wealth + stock-holding * stock-price] of max-one-of turtles [wealth + stock-holding * stock-price]
20
1
14

MONITOR
985
71
1075
128
Elon ID
[who] of max-one-of turtles [wealth + stock-holding * stock-price]
20
1
14

MONITOR
985
10
1075
67
poorest ID
[who] of min-one-of turtles [wealth + stock-holding * stock-price]
20
1
14

TEXTBOX
8
133
200
219
NOTE: \"If you want to see the changes more clearly, use the bar above and move its slider to the bottom of the 'r' in the word 'slower'.\"
14
15.0
1

PLOT
827
132
1226
331
stock-price over time
time
price
0.0
10.0
0.0
10.0
true
false
"clear-all-plots" ""
PENS
"default" 1.0 0 -4079321 true "" "plot stock-price"

MONITOR
1079
10
1195
67
poorest Class ID
[class] of min-one-of turtles [wealth + stock-holding * stock-price]
20
1
14

MONITOR
1079
71
1196
128
Elon Class ID
[class] of max-one-of turtles [wealth + stock-holding * stock-price]
20
1
14

PLOT
828
489
1508
623
RSI indicator for last 14 days
ticks
rsi
0.0
10.0
-10.0
110.0
false
true
"clear-all-plots" ""
PENS
"RSI" 1.0 0 -7858858 true "" "plot rsi\n"
"line-70" 1.0 0 -5298144 true "" "plotxy ticks 70"
"line-30" 1.0 0 -15040220 true "" "plotxy ticks 30"

PLOT
827
335
1226
486
stock prices over last 14 ticks
time
price
0.0
1400.0
0.0
10.0
true
false
"clear-all-plots" ""
PENS
"last-14-prices" 1.0 0 -955883 true "" ""

SLIDER
1
83
204
116
news-shock-prob
news-shock-prob
0
1
0.4
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model simulates an artificial financial market populated by heterogeneous agents, each following different decision-making strategies: fundamentalists, technicalists, and noise traders. The goal is to study how individual behaviors, interactions, and external news events affect market dynamics, such as price movements, volatility, wealth distribution, and trading patterns.

This agent-based model aims to explore key behavioral finance phenomena like herding behaviors, framing biases, Generalized Autoregressive Conditional Heteroskedasticity (GARCH) processes like volatility clustering, and reaction to news shocks. By analyzing price trends, relative strength index (RSI), and market shocks.

Users can gain insights into how real-world markets may behave under different conditions and information structures.

## HOW IT WORKS

There are three types of agents: fundamentalists, technicalists, and noise traders—interact based on individual decision-making rules and social influences in an small world network. 
Here's how the system functions work:

1. Agent Decision-Making: Each agent is initialized with: A wealth level, risk tolerance, confidence level, and a stock-holding value. A class that determines its trading strategy: Fundamentalists compare the current stock price to a “fundamental value” and buy/sell based on whether the stock is undervalued or overvalued. Technicalists look at "recent price changes" and adjust their decisions based on "volatility" and their "risk tolerance". "Risk-averse" technicalists tend to avoid buying into rising prices, while "risk-tolerant" ones interpret rising prices as positive signals (framing bias). Noise traders make decisions influenced by their "confidence" level, which is updated through interactions with neighboring agents in the network (to simulate herd behavior and social bias).

2. Market Price Update: In each tick, agents make buy/sell/hold decisions. The stock price is updated based on the net demand: If there are more buyers than sellers, the price increases. and If there are more sellers, it decreases. and there is a price-sensitivity factor which controls how strongly demand impacts price.

3. Volatility and RSI: Volatility is calculated using a GARCH(1,1)-like process, simulating volatility clustering. The Relative Strength Index (RSI) is calculated over the last 14 days to monitor momentum in the stock price. It helps observe overbought (RSI > 70) or oversold (RSI < 30) market conditions.

4. Network Interactions: Agents are connected in a small-world network, allowing them to influence each other’s confidence and decisions. Confidence levels of only "noise traders" are dynamically updated based on neighboring agents.

5. News and Shocks: When the enable-news-shocks? switch is on, random news events occasionally affect the fundamental value of the asset. Also Periodic negative and positive shocks simulate larger external economic events:
Negative shocks occur every 200 ticks and increase in magnitude over time (then get halved after every 5 shocks).
Positive shocks occur every 600 ticks and exponentially grow (then double every 3 times).

6. Wealth Updates: Agents buy or sell stocks depending on their decisions and current wealth. Their total wealth (cash + stock value) updates after each transaction.

## HOW TO USE IT

1. Sliders and Switches:
initial-wealth Slider: Sets how much wealth each agent starts with. This determines their initial trading capacity and affects how wealth accumulates or depletes over time. when you set it to a number, each agent would have a random number as their wealth to start with.
"enable-news-shocks?" Switch: Turns the simulation of random market news shocks on or off. These shocks can cause sudden changes in price and volatility, affecting agent decisions.
news-shock-probability Slider: Sets how likely a news shock is to occur at each tick. Higher values make external shocks more frequent, simulating a more unstable or news-sensitive market environment.

2. Buttons:
setup: Initializes the environment, creates agents, and resets all variables and plots. Should be clicked before each new run.
go: Starts or pauses the simulation. When active, agents trade, prices evolve, and all metrics update over time.

3. Monitors:
ticks: Shows the number of simulation steps (or ticks) that have passed since the model started. Helps track simulation length and agent behavior over time.
last-ticks & last-prices: Display the most recent tick values and corresponding prices. Useful for tracking short-term trends and verifying the most current market state.
Wealth Extremes Monitors: those 6 monitors display The ID, class (e.g., noise trader, technicalist, fundamentalist), and wealth of the richest (Elon Musk) and poorest agents in the market. This gives direct insight into inequality, class performance, and market dynamics at the individual level.

4. Plots:
Mean Wealth Over Time: Tracks the average wealth of all agents. Indicates general market prosperity or loss over time.
Wealth Distribution: Shows how wealth is spread across agents. Can reveal growing inequality.
Stock Price Over Time: Displays the full historical trajectory of the stock price. Helps identify long-term trends, booms, and crashes.
Stock Price over Last 14 Ticks: Zooms in on recent price behavior. Useful for observing short-term fluctuations and momentum.
RSI over last 2 Weeks: Plots the Relative Strength Index calculated over the last 14 ticks. RSI is a technical indicator reflecting whether the asset is overbought or oversold.
Log Price Over Time: Shows the logarithmic transformation of price. Highlights relative changes more clearly than raw price, useful for volatility and return analysis.
Volatility: Tracks how much the price is fluctuating. Calculated over a rolling window to visualize calm vs. turbulent periods in the market. you can check market fluctuations using this plot. if volatiltiy peaks, there would be a carsh or a jump in stock price or in log-price.

5. Environment View: 
Network: The environment visualizes the agents in the market and show their interactions and positions. it provides an intuitive view of the simulation's state.

You can investigate each agent properties to compare the effect of social influnce for noise traders and volatility and risk tolerance for technicalists.

## THINGS TO NOTICE

In the network, all agent classes are assigned unique colors: fundamentalists are blue, technicalists are orange, and noise traders are pink. However, when you run the model, their colors change based on their states at each tick. If an agent wants to buy a share, their color turns green; if they want to sell their shares, it changes to red; and if they hold their shares, they turn yellow.

To see the changes more clearly, use the bar above the screen and move its slider to the bottom of the "r" in the word "slower" to slow down the speed.

You can also track the news when it occurs by using the "command center".

## THINGS TO TRY

1. Vary the Initial Wealth: Use the initial-wealth slider to test how starting wealth influences market behavior.
to see: "Do richer agents dominate the market long-term?"

2. Toggle News Shocks: Use the enable-news-shocks? switch and news-shock-probability slider. during running, you can change the impact of news by using its switch key to see what will happen to price plot.

3. Observe Volatility Patterns: Use the Volatility plot to find turbulent vs. stable periods. for example See how Shocks increase volatility.


## EXTENDING THE MODEL
these are some suggestions to extend the model:

1. Agent Behavior Enhancements: Adaptive Learning: Allow agents to switch strategies (e.g., from technicalist to fundamentalist) based on past success.
Sentiment or Memory: Add a memory mechanism so agents remember previous shocks or trends and adjust behavior accordingly.

2. More Realistic News Dynamics: Varying News Intensity: Not all news shocks are equal. Create a range of mild to extreme news events with different effects.

3. Additional Market Features: Transaction Costs: Simulate brokerage fees or taxes to see how they influence trading frequency and agent performance.
Liquidity Constraints: Limit how much stock agents can buy/sell at once to model real-world market frictions.
Order Book Mechanics: Instead of global price setting, implement an order-matching system (more complex but realistic).

4. Visualization and Analysis: Sharpe Ratio or Drawdown Metrics: Measure and compare risk-adjusted returns per agent type.
Heatmaps or Histograms: Visualize agent distribution, stock holdings, or price changes across space or time.

5. Multi-Asset or Sector Modeling: Add more than one stock (e.g., tech vs. energy) to explore portfolio diversification, sector-specific shocks, or arbitrage behavior.

## NETLOGO FEATURES

In NetLogo, I used the "map" primitive many times, which takes a reporter and a list and applies the reporter to all elements of that list. 

Another interesting thing about NetLogo is that you can configure your plot settings during coding your project without changing anything manually in the plot itself.

## RELATED MODELS

IMPORTANT: This agent-based model was created by ""Ali Khabazian"" as a final project for the Agent-Based Modeling course at Santa Fe (2025). It was implemented in NetLogo 6.4.0, using original code and design logic. All rights reserved.
If you’re interested in using this model as a base model, citing it, offering help, or for any other collaborations, you can contact me at: alirezakhabaz01@gmail.com.

Here are some related models and simulations you can explore to learn more about markets:

1. LeBaron’s Artificial Stock Market (1999): Introduced fundamentalists and chartists (technical traders) whose interaction produces realistic price dynamics.
2. Lux-Marchesi Model (1999): Models fundamentalists and noise traders with switching between strategies driven by market sentiment.


## CREDITS AND REFERENCES

1. An artificial stock market:
cite: Palmer, Richard G., W. Brian Arthur, John H. Holland, and Blake LeBaron. "An artificial stock market." Artificial Life and Robotics 3, no. 1 (1999): 27-31.
link: https://link.springer.com/article/10.1007/bf02481484 -  R.G. Palmer - W. Brian Arthur - John H. Holland - Blake LeBaron - An artificial stock market

2. Time series properties of an artificial stock market
cite: LeBaron, Blake, W. Brian Arthur, and Richard Palmer. "Time series properties of an artificial stock market." Journal of Economic Dynamics and control 23, no. 9-10 (1999): 1487-1516.
link: https://www.sciencedirect.com/science/article/abs/pii/S0165188998000815 - Time series properties of an artificial stock market - Blake LeBaron - W. Brian Arthur - Richard Palmer

3. Prospect Theory: An Analysis of Decision under Risk
cite: Kahneman, Daniel. "Econ ometrica i ci." Econometrica 47, no. 2 (1979): 263-291.
link: https://web.mit.edu/curhan/www/docs/Articles/15341_Readings/Behavioral_Decision_Theory/Kahneman_Tversky_1979_Prospect_theory.pdf

4. HERD BEHAVIOR AND AGGREGATE FLUCTUATIONS IN FINANCIAL MARKETS
cite: Cont, Rama, and Jean-Philipe Bouchaud. "Herd behavior and aggregate fluctuations in financial markets." Macroeconomic dynamics 4, no. 2 (2000): 170-196.
link: https://www.cambridge.org/core/journals/macroeconomic-dynamics/article/abs/herd-behavior-and-aggregate-fluctuations-in-financial-markets/51990E3780C6EBDA07A1753FC08E8453

5. Autoregressive Conditional Heteroscedasticity with Estimates of the Variance of United Kingdom Inflation
cite: Engle, Robert F. "Autoregressive conditional heteroscedasticity with estimates of the variance of United Kingdom inflation." Econometrica: Journal of the econometric society (1982): 987-1007.
link: https://www.jstor.org/stable/1912773

6. Scaling and criticality in a stochastic multi-agent model of a financial market
cite: Lux, Thomas, and Michele Marchesi. "Scaling and criticality in a stochastic multi-agent model of a financial market." Nature 397, no. 6719 (1999): 498-500.
link: https://www.nature.com/articles/17290

7. Collective dynamics of 'small-world' networks
cite: DJ, WATTS. "Collective dynamics of'small-world'networks." Nature 393, no. 6684 (1998): 409-410.
link: https://cir.nii.ac.jp/crid/1571417125648012800

@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
