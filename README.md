# Artificial-Stock-Market-using-Agent-Based-Modeling
This agent-based market model introduces behavioral finance framing biases using a small-world network (Watts &amp; Strogatz). It features fundamentalists (blue), technicalists (orange), and noise traders (pink). Explore wealth dynamics, stock prices, volatility, RSI, and news shocks with adjustable initial wealth.

# Abstract
In this model, I introduced some framing biases from behavioral finance lectures into an agent-based model to create an artificial market using a small-world network, based on the famous paper by Watts and Strogatz. There are three types of agents: fundamentalists, technicalists, and noise traders.

Fundamentalists (blue) make decisions based on a fundamental value without any biases. Technicalists (orange) make decisions influenced by their risk preferences, with choices related to the difference between the current price and the previous price, normalized by the square root of volatility, which is calculated using GARCH(1,1). Noise traders (pink) trade randomly, but their decisions are biased by their confidence level, which depends on the behavior of their closest neighbors in the small-world network (social influence).

You can investigate their wealth over time to see the impact of biases on each group, including the poorest and wealthiest agents. The interface displays stock price, stock price over the last two weeks, log price, volatility, and RSI. There is also a button to control the impact of news shocks on the market, and you can adjust the agents’ initial wealth.

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
