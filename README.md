# Artificial-Stock-Market-using-Agent-Based-Modeling
This agent-based market model introduces behavioral finance framing biases using a small-world network (Watts &amp; Strogatz). It features fundamentalists (blue), technicalists (orange), and noise traders (pink). Explore wealth dynamics, stock prices, volatility, RSI, and news shocks with adjustable initial wealth.

# Abstracts
In this model, I introduced some framing biases from behavioral finance lectures into an agent-based model to create an artificial market using a small-world network, based on the famous paper by Watts and Strogatz. There are three types of agents: fundamentalists, technicalists, and noise traders.

Fundamentalists (blue) make decisions based on a fundamental value without any biases. Technicalists (orange) make decisions influenced by their risk preferences, with choices related to the difference between the current price and the previous price, normalized by the square root of volatility, which is calculated using GARCH(1,1). Noise traders (pink) trade randomly, but their decisions are biased by their confidence level, which depends on the behavior of their closest neighbors in the small-world network (social influence).

You can investigate their wealth over time to see the impact of biases on each group, including the poorest and wealthiest agents. The interface displays stock price, stock price over the last two weeks, log price, volatility, and RSI. There is also a button to control the impact of news shocks on the market, and you can adjust the agents’ initial wealth.
