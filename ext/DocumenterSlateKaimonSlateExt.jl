# With KaimonSlate loaded in make.jl, `SlateDocs(render = …)` can render bundles during the build.
module DocumenterSlateKaimonSlateExt

import DocumenterSlate
import KaimonSlate

function __init__()
    DocumenterSlate.RENDERER[] = function (notebook, dir; backend, light, dark)
        KaimonSlate.render_doc_bundle(notebook, dir; backend, light, dark)
        return nothing
    end
end

end
