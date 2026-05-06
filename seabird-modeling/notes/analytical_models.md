# Analytical Models for the LHSP Pair-Bond System

The agent-based simulation is the gold standard, but several pieces of it
have clean closed-form (or near-closed-form) analytical analogues. They can
be useful as

* **sanity checks** — does the simulation reproduce the predicted shift
  durations, hatch failures, energy distributions?
* **fast scans** — many of the `(min, max, μ_for, σ_for, ε)` combinations
  the simulation sweeps can be ranked instantly with formulas, so the
  simulation only has to confirm the interesting region.
* **scaling intuition** — they tell you *which parameters matter and why*
  without needing to look at heatmaps.

Below are seven models, increasing in scope. Each one is written so the LHSP
parameters slot in directly.

Symbols used throughout:

| symbol | meaning | LHSP value |
|---|---|---|
| $E_0$         | start-of-season energy            | 766 kJ |
| $m_I$         | metabolism while incubating       | 52 kJ/day |
| $m_F$         | metabolism while foraging         | 123 kJ/day |
| $\mu_F$       | mean daily intake while foraging  | 162 kJ/day |
| $\sigma_F$    | sd of daily intake                | 47 kJ/day |
| $L$           | hunger threshold (`min`)          | 200 kJ (a) |
| $H$           | satiation threshold (`max`)       | 900 kJ (a) |
| $D$           | shift envelope $H-L$              | 700 kJ |
| $h_0$         | required incubation days          | 37 |
| $\alpha$      | neglect penalty                   | 1.43 days/day |
| $\varepsilon$ | consecutive-neglect tolerance     | 7 days |
| $T_{\max}$    | season length cap                 | 60 days |

(a) The C++ defaults are 123 / 766. Throughout this note I use the
"manuscript-mid" defaults 200 / 900 the sandbox ships with, but every
formula is stated symbolically.

---

## 1. Deterministic skeleton — a piecewise ODE

If you ignore stochasticity in foraging intake, each parent's energy
follows a piecewise-linear ODE driven by its own state $s\in\{I,F\}$:

$$
\frac{dE}{dt} \;=\; \begin{cases}
-m_I & \text{if } s = I \\
\mu_F - m_F & \text{if } s = F
\end{cases}
$$

with state switches at the boundaries:

$$
s : I \to F \quad\text{when}\quad E \le L, \qquad
s : F \to I \quad\text{when}\quad E \ge H \;\text{ and } d_F > 1.
$$

The deterministic shift durations are then

$$
T_I \;=\; \frac{H - L}{m_I} \;=\; \frac{D}{m_I},
\qquad
T_F^{\text{det}} \;=\; \frac{D}{\mu_F - m_F}.
$$

For LHSP, $T_I = 700/52 \approx 13.5$ days and
$T_F^{\text{det}} = 700/39 \approx 17.9$ days, so a single
incubation–foraging cycle is roughly **31 days**, which is comparable to
the 37-day egg-development requirement. Already this tells you why the
system is *delicate* — there's barely time for one full cycle per parent
before hatch.

---

## 2. The foraging shift is an Inverse-Gaussian first-passage time

The deterministic value above is just the mean. Real foraging trips are
random: intake on day $t$ is $X_t \sim \mathcal{N}(\mu_F, \sigma_F^2)$,
truncated at zero. If we treat one trip as a Brownian motion with drift
$\nu = \mu_F - m_F$ and volatility $\sigma_F$ starting at $L$ and stopping
when energy first hits $H$, the trip duration is the **first-passage time**

$$
T_F \;\sim\; \mathrm{IG}\!\left(\frac{D}{\nu},\; \frac{D^{2}}{\sigma_F^{2}}\right),
$$

i.e. inverse Gaussian with mean $D/\nu$ and shape $D^{2}/\sigma_F^{2}$.
Its variance is $\sigma_F^{2} D / \nu^{3}$.

**For LHSP** ($D=700$, $\nu=39$, $\sigma_F=47$):

$$
\mathbb{E}[T_F] \approx 17.9\;\text{days},\quad
\mathrm{sd}(T_F) \approx 7.0\;\text{days}.
$$

Practical implications:

* The coefficient of variation $\sigma_F\sqrt{D/\nu^{3}} / (D/\nu) =
  \sigma_F / \sqrt{\nu D}$ is $\approx 0.28$. **Variance kills you faster
  than mean does** when $D$ shrinks: doubling $\sigma_F$ doubles CV; halving
  $D$ also raises CV by $\sqrt{2}$.
* The probability the partner relief is "late" is then
  $P(T_F > T_I) = 1 - F_{\mathrm{IG}}(T_I)$, which has a clean expression
  in terms of $\Phi$ (the standard normal CDF).

This is the single most useful formula in the system: **the variance of
a single shift duration follows directly from $\mu_F$, $\sigma_F$, and
$D$**, with no simulation needed.

---

## 3. Pair-state continuous-time Markov chain

Joint state $(s_F, s_M) \in \{I, F\}^2$ has 4 macro-states:
$II,\, IF,\, FI,\, FF$. The state $FF$ is the only one in which the egg is
unattended.

Approximate per-day transition rates (working in the regime where the
deterministic timescales hold):

| from \\ to | $II$ | $IF$ | $FI$ | $FF$ |
|---|---|---|---|---|
| $II$ | — | $1/T_I$ | $1/T_I$ | 0 |
| $IF$ | $1/T_F$ | — | 0 | $1/T_I$ |
| $FI$ | $1/T_F$ | 0 | — | $1/T_I$ |
| $FF$ | 0 | $1/T_F$ | $1/T_F$ | — |

(Note: $II$ is short-lived because the simulation immediately resolves
overlap by sending one parent foraging.)

The stationary distribution of an unforced chain like this gives the
**fraction of time the egg is unattended**:

$$
\pi_{FF} \;=\; \frac{T_F^{2}}{(T_I + T_F)^{2}}.
$$

For LHSP $T_I/T_F \approx 0.75$, so $\pi_{FF} \approx 0.32$. This is much
higher than what the simulation produces because the simulation actively
prevents $FF$ (when both parents try to leave, one is pushed back). In
that sense the C++ overlap-resolution rule is doing exactly the work
needed to drive $\pi_{FF}$ close to 0; the chain above is the *unforced
baseline* you'd get without it.

**Use:** the gap between the simulated unattended-day rate and
$\pi_{FF}$ measures how much "rescue" the overlap rule is providing.

---

## 4. Egg as a renewal-reward process

The egg's hatch progress is a deterministic counter that advances by 1
per attended day and by 0 per neglect day (with hatch bar pushed out by
$\alpha = 1.43$ days every neglect day). Treat each day as an
independent attendance Bernoulli trial with success probability
$p_a = 1 - \pi_{FF}$. Then the **expected calendar days to reach
$h_0$ effective incubation days** is

$$
\mathbb{E}[T_{\text{hatch}}]
\;=\; \frac{h_0}{p_a} \;+\; (1 - p_a) \cdot \frac{h_0}{p_a} \cdot \alpha
\;=\; \frac{h_0\bigl(1 + (1-p_a)\alpha\bigr)}{p_a}.
$$

The hatching success probability is then approximately

$$
P(\text{hatched}) \;\approx\; P\!\left(T_{\text{hatch}} \le T_{\max}\right)
\;\cdot\; P(\text{no run of }\varepsilon\text{ neglect days}),
$$

and the run-length condition has a closed form via the consecutive-success
runs probability for an iid Bernoulli sequence (Feller, *An Introduction to
Probability Theory*, vol. I, ch. XIII):

$$
P\bigl(\text{no run of }\varepsilon\text{ failures in }N\text{ trials}\bigr)
\approx 1 - \frac{1-x}{(\varepsilon+1) - \varepsilon x}\,x^{N+1},
$$

where $x = 1 - q^{\varepsilon}$ and $q = \pi_{FF}$.

**Use:** with $T_I, T_F$ from §1–2 and $\pi_{FF}$ from §3, this delivers
an analytical estimate of hatch success that you can plot against the
simulator over the full $(L, H)$ grid in a fraction of the time.

---

## 5. Stochastic differential equation (full system)

Putting it all together, for one parent:

$$
dE_t \;=\; \mu(s_t)\,dt \;+\; \sigma(s_t)\,dW_t,
\quad
\mu(s) = \begin{cases}-m_I & s=I\\ \nu & s=F\end{cases},\quad
\sigma(s) = \begin{cases}0 & s=I\\ \sigma_F & s=F\end{cases},
$$

with state $s_t$ updated by a hybrid switching rule at the thresholds
$\{L, H\}$. This is an *impulsive switching SDE* and lives in the
literature on hybrid stochastic systems (regime-switching diffusions,
e.g. Yin & Zhu 2010).

For two parents you have a 4-component coupled SDE on $(E_F, E_M, s_F, s_M)$
and the discrete egg counters $(h, n)$. The egg's state is purely driven
by the parents.

You won't get a closed form for the joint dynamics, but two useful
limits exist:

* **Small-noise limit ($\sigma_F \to 0$):** collapses to the deterministic
  cycle of §1.
* **Large-noise limit ($\sigma_F \gg \nu$):** foraging trips become a pure
  Brownian motion, $T_F$ is heavy-tailed, and the analytical hatch
  estimate of §4 saturates near the parent-survival cliff.

---

## 6. Population-level Fokker–Planck (PDE)

Across a colony of $N$ pairs, define the density

$$
\rho(t, e_F, e_M, h, n)\,de_F\,de_M
$$

= probability that a random pair has female energy $e_F$, male energy
$e_M$, hatch progress $h$, neglect streak $n$ at time $t$. Within each
state combination $(s_F, s_M)$, $\rho$ obeys

$$
\partial_t \rho_{s_F s_M}
\;=\;
- \mu(s_F)\,\partial_{e_F}\rho_{s_F s_M}
- \mu(s_M)\,\partial_{e_M}\rho_{s_F s_M}
+ \tfrac{1}{2}\sigma^2(s_F)\,\partial_{e_F}^2 \rho_{s_F s_M}
+ \tfrac{1}{2}\sigma^2(s_M)\,\partial_{e_M}^2 \rho_{s_F s_M}
+ \mathcal{R}_{s_F s_M},
$$

where $\mathcal{R}$ contains the threshold-switching jump terms (mass that
crosses $E=L$ or $E=H$ moves to a different state-block) and the egg
$(h, n)$ updates.

This is a 4-state, 5-D linear PDE — too big to solve by hand, but quite
solvable numerically. Once you have $\rho$ at $T_{\max}$, integrating
over $\{h \ge h_0\}$ gives the colony-wide hatch rate
**without running any agents**.

This is essentially what the **Parameter heatmap** tab does empirically;
a Fokker–Planck solver would compute the same quantity in a few seconds
and give you derivatives w.r.t. parameters as a free side-product
(useful for optimization).

---

## 7. Optimal-control / MDP formulation

The biological "why" question — *why are LHSP thresholds the values they
are?* — is naturally a constrained optimisation:

$$
\max_{(L_F, H_F, L_M, H_M)} \; P(\text{hatched})
\quad \text{s.t.} \quad
P(\text{both parents survive}) \ge \beta,
$$

at fixed $\mu_F, \sigma_F, \varepsilon$.

Two clean treatments:

* **Markov decision process.** Discretise energy, treat $(L, H)$ as the
  policy. Bellman backwards in time from $T_{\max}$. The optimal $(L^*, H^*)$
  trace a curve in the $(L, H)$ plane that is exactly the Pareto front
  the **Pareto front** tab traces empirically.

* **Lagrangian dual.** Convert the constraint into a penalty $\lambda$
  on parent mortality. Then for each $\lambda$, solve
  $\max P(\text{hatched}) - \lambda \cdot P(\text{died})$. As $\lambda$
  sweeps $0 \to \infty$, you trace the Pareto front analytically.

---

## What lives where in the sandbox

| sandbox tab | analytical analogue |
|---|---|
| Colony replay | §1 deterministic skeleton + §5 SDE |
| Parameter heatmap | §3 + §4 (closed-form hatch rate estimate) |
| Season strips | §2 IG distribution of $T_F$, plus §3 chain |
| Phase portrait | §5 SDE (each line is one realisation) |
| Sensitivity tornado | partial derivatives of §4 hatch rate estimate |
| Pareto front | §7 MDP optimum |

## Suggested follow-up build (overlay analytics on simulation)

A natural next tab:

> **Theory check.** Two side-by-side panels — one shows the simulation's
> empirical histogram of foraging-trip durations; the other shows the
> Inverse-Gaussian PDF $\mathrm{IG}(D/\nu, D^2/\sigma_F^2)$ on the same
> axes. As the user drags $D = H - L$ or $\sigma_F$, both panels update
> in lock-step, making the agreement (or its breakdown) visible.

The other useful overlay is to draw the §3 unforced unattended-fraction
$\pi_{FF}$ as a horizontal line on the heatmap colorbar, so you can see
how much rescue the simulation's overlap rule provides at each $(L, H)$.

## Minimal references

* Yin, G. and Zhu, C. (2010). *Hybrid Switching Diffusions: Properties
  and Applications.* Springer.
* Feller, W. (1968). *An Introduction to Probability Theory and its
  Applications, Vol. I.* Wiley. (consecutive-runs theorem, ch. XIII)
* Chhikara, R. and Folks, L. (1989). *The Inverse Gaussian Distribution:
  Theory, Methodology, and Applications.* Marcel Dekker.
* Mangel, M. and Clark, C. (1988). *Dynamic Modeling in Behavioral
  Ecology.* Princeton. (MDP framing of foraging schedules)
