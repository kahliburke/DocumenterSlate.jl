try; import KaimonSlate; catch; error("This is a Kaimon Slate notebook — running it as plain Julia needs the KaimonSlate runtime in this environment. Add it with `import Pkg; Pkg.add(\"KaimonSlate\")`, or open it in Kaimon Slate."); end; KaimonSlate.standalone!(@__MODULE__; dir=@__DIR__)

#%% md id=intro
@md raw"""
# Resonance

Push the [damped oscillator](oscillator.jl) with a periodic force of frequency $\Omega$, measured in
units of its natural frequency, and once the start-up transient has died away it oscillates at the
driving frequency. How far it swings depends on how close $\Omega$ is to 1, and on the damping ratio
$\zeta$: the same $\zeta$ that sets how quickly [its free oscillation decays](oscillator.jl#peaks).

$$
A(\Omega) = \frac{1}{\sqrt{(1-\Omega^2)^2 + (2\zeta\Omega)^2}}
$$
"""

#%% code id=controls
@bind zeta Slider(0.05:0.05:1.0; default = 0.1)

#%% code id=model
A(Ω, ζ) = 1 / sqrt((1 - Ω^2)^2 + (2ζ * Ω)^2)
Ωs = collect(range(0, 3; length = 300))
Ωpeak = zeta < 1 / sqrt(2) ? sqrt(1 - 2zeta^2) : 0.0
nothing

#%% md id=peak_md
@md"""
At ζ = {{ zeta }} the response peaks at Ω = {{ round(Ωpeak; digits = 3) }}, where the oscillator swings
{{ round(A(Ωpeak, zeta); digits = 2) }} times as far as the same force would push it if applied steadily.
"""

#%% code id=response
echart(:line, Ωs, @replay(zeta, [A(Ω, zeta) for Ω in Ωs]);
       name = "A(Ω)", showSymbol = false,
       xAxis = (type = :value, name = "Ω"), yAxis = (type = :log, name = "amplitude"))

#%% md id=q_md
@md raw"""
## Quality factor

Light damping gives a tall, narrow peak. Its sharpness is the quality factor $Q = 1/(2\zeta)$, which
for light damping is also roughly the number of cycles the [free oscillation](oscillator.jl) takes to
lose most of its energy.
"""

#%% code id=qtable
slate_table([(ζ = z, Q = round(1 / (2z); digits = 2), peak = round(A(sqrt(max(1 - 2z^2, 0.0)), z); digits = 2))
             for z in (0.02, 0.05, 0.1, 0.2, 0.5)])

# ╔═╡ Slate.config · per-notebook settings (Settings panel)
#   docid = 600a8b0b-d395-4d53-b814-4c144e46b77c
# ╚═╡
