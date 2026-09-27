# ── Rendering: KaimonSlate runs the notebooks ──────────────────────────────────────────────────

function __init__()
    RENDERER[] = function (jobs; backend, light, dark)
        KaimonSlate.render_doc_bundles(jobs; backend, light, dark)
        return nothing
    end
end
