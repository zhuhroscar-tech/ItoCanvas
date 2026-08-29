# ItoCanvas Model Notes

## Black–Scholes–Merton

ItoCanvas prices European calls and puts under the Black–Scholes–Merton assumptions:

- the underlying follows a lognormal diffusion;
- volatility, risk-free rate, and continuous dividend yield are constant over the option life;
- markets are frictionless and continuously hedgeable;
- no early exercise is allowed.

For time to expiry $T>0$ and volatility $\sigma>0$:

$$d_1 = \frac{\ln(S/K) + (r-q+\tfrac{1}{2}\sigma^2)T}{\sigma\sqrt{T}}, \qquad d_2=d_1-\sigma\sqrt{T}$$

$$C = Se^{-qT}N(d_1)-Ke^{-rT}N(d_2)$$

$$P = Ke^{-rT}N(-d_2)-Se^{-qT}N(-d_1)$$

The implementation handles expiry and zero-volatility cases explicitly rather than dividing by zero.

## Greeks

The core returns delta, gamma, vega, theta, and rho in mathematical units. The interface presents:

- delta: price change per one currency-unit move in spot;
- gamma: delta change per one currency-unit move in spot;
- vega: price change per one volatility percentage point;
- theta: approximate price change per calendar day;
- rho: price change per one interest-rate percentage point.

## Implied volatility

The solver first checks discounted no-arbitrage bounds. It then brackets volatility and uses a hybrid Newton/bisection iteration. Newton steps are accepted only when vega is sufficiently large and the proposed value remains inside the bracket; otherwise the algorithm falls back to bisection.

## Scenario grid

Scenario cells reprice the same contract after applying a relative spot change and an absolute volatility-point change. Invalid scenarios—such as a non-positive spot or negative volatility—are rejected.

## Important limitations

- European options only
- no discrete dividend schedule
- no volatility smile, skew, term structure, jumps, or stochastic rates
- expiration strategy charts use entered premiums and do not model pre-expiry mark-to-market P&L
- outputs are analytical estimates, not executable market quotes

ItoCanvas is educational and analytical software, not investment advice.
