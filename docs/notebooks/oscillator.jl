try; import KaimonSlate; catch; error("This is a Kaimon Slate notebook — running it as plain Julia needs the KaimonSlate runtime in this environment. Add it with `import Pkg; Pkg.add(\"KaimonSlate\")`, or open it in Kaimon Slate."); end; KaimonSlate.standalone!(@__MODULE__; dir=@__DIR__)

#%% md id=intro
@md raw"""
# A damped oscillator

A mass on a spring, with friction. Its displacement is

$$
x(t) = e^{-\zeta \omega t} \cos\left(\omega \sqrt{1-\zeta^2}\, t\right)
$$

where $\omega$ is the natural frequency and $\zeta$ the damping ratio. Drag the slider to change
the damping.
"""

#%% code id=controls
@bind zeta Slider(0.02:0.02:0.6; default = 0.1)

#%% code id=model
ω = 2π
ts = collect(range(0, 6; length = 400))
x(t, ζ) = exp(-ζ * ω * t) * cos(ω * sqrt(1 - ζ^2) * t)
halflife = log(2) / (zeta * ω)

#%% md id=halflife_md
@md"""
At ζ = {{ zeta }} the amplitude falls to half in {{ round(halflife; digits = 2) }} seconds.
"""

#%% code id=trace
echart(Dict(
    "tooltip" => Dict("trigger" => "axis"),
    "xAxis" => Dict("type" => "value", "name" => "t (s)"),
    "yAxis" => Dict("type" => "value", "min" => -1, "max" => 1),
    "series" => [Dict("type" => "line", "showSymbol" => false, "name" => "x(t)",
                      "data" => @replay(zeta, [[t, x(t, zeta)] for t in ts]))],
))

#%% md id=table_md
@md"""
## Peaks

Each successive peak is smaller by the same factor, so the peaks alone tell you the damping.
"""

#%% code id=peaks
T = 2π / (ω * sqrt(1 - zeta^2))
slate_table([(peak = k, time = round(k * T; digits = 3), height = round(exp(-zeta * ω * k * T); digits = 4)) for k in 0:6])

# ╔═╡ Slate.config · per-notebook settings (Settings panel)
#   docid = c64702ef-775e-42ff-bfc5-12fc2fc8a4a3
# ╚═╡
