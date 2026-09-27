# ── config.mts additions for a Vitepress site ───────────────────────────────────────────────────
# Kept here (not in the extension) so it is testable without DocumenterVitepress installed.

const VP_MARK = "/* DocumenterSlate */"

"""
    vitepress_config(config) -> String

`config` (the text of `.vitepress/config.mts`, after DocumenterVitepress has filled in its own values)
with the Slate runtime added to `head` and `slate-*` tags declared as custom elements. Each edit keys
off a stable marker; a config that lacks one is returned with that edit skipped and a warning naming
what to add by hand. Idempotent.
"""
function vitepress_config(config::String)
    occursin(VP_MARK, config) && return config
    m = match(r"\bbase:\s*['\"]([^'\"]*)['\"]", config)
    base = m === nothing ? "/" : String(m.captures[1])
    endswith(base, "/") || (base *= "/")
    script = "$(VP_MARK) ['script', { src: '$(base)slate/runtime/slate-embed.js' }],"
    if occursin(r"\bhead:\s*\[", config)
        config = replace(config, r"\bhead:\s*\[" => s -> string(s, "\n    ", script); count = 1)
    else
        @warn "SlateDocs: config.mts has no `head: [` — add $(repr(script)) to its head array"
    end
    if occursin(r"\bvue:\s*\{", config)
        @warn "SlateDocs: config.mts already has a `vue` block — add " *
              "`template: { compilerOptions: { isCustomElement: (tag) => tag.startsWith('slate-') } }` to it"
    elseif occursin(r"defineConfig\(\s*\{", config)
        config = replace(config, r"defineConfig\(\s*\{" => s -> string(s, "\n  ", VP_MARK,
            " vue: { template: { compilerOptions: { isCustomElement: (tag) => tag.startsWith('slate-') } } },");
            count = 1)
    end
    return config
end
