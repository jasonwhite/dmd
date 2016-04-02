local cc = require "rules.cc"
local d = require "rules.d"

local rules = require "rules"

-- DMD has C++ in C files. Go figure.
cc.common.toolchain["gcc"] = "c++"

local warnings = {"no-deprecated", "strict-aliasing"}
local defines = {"__pascal=", "MARS=1", "TARGET_LINUX=1", "DM_TARGET_CPU_X86=1"}
local compiler_opts = {"-fno-rtti", "-m64", "-std=gnu++98"}


local idgen = d.binary {
    name = "idgen",
    srcs = {"idgen.d"},
    bindir = "bin",
}

-- Run idgen
rule {
    inputs = {idgen:path()},
    task = {path.join("..", idgen:path())},
    cwd = SCRIPT_DIR,
    outputs = {path.join(SCRIPT_DIR, "id.d"), path.join(SCRIPT_DIR, "id.h")},
}

local optabgen = cc.binary {
    name = "optabgen",
    srcs = {"backend/optabgen.c"},
    includes = {"tk"},
    warnings = warnings,
    compiler_opts = compiler_opts,
    defines = defines,
}

-- Run optabgen
rule {
    inputs = {optabgen:path()},
    task = {"bbdeps", path.join("..", optabgen:path())},
    cwd = SCRIPT_DIR,
    outputs = {
        "src/cdxxx.c", "src/debtab.c", "src/elxxx.c", "src/fltables.c",
        "src/optab.c", "src/tytab.c"
    },
}

cc.library {
    name = "glue",
    static = true,
    srcs = {
        "glue.c", "msc.c", "s2ir.c", "todt.c", "e2ir.c", "tocsym.c", "toobj.c",
        "toir.c", "iasm.c", "objc_glue_stubs.c", "id.h"
        },
    includes = {"root", "tk", "backend"},
    warnings = warnings,
    compiler_opts = compiler_opts,
    defines = defines,
}

cc.library {
    name = "root",
    static = true,
    srcs = {"root/newdelete.c"},
    includes = {"root"},
    warnings = warnings,
    compiler_opts = compiler_opts,
    defines = defines,
}

local backend_srcs = glob {
    "backend/*.c",
    "eh.c",
    "tk.c",
    "!backend/cgcv.c",
    "!backend/cgobj.c",
    "!backend/machobj.c",
    "!backend/md5.c",
    "!backend/mscoffobj.c",
    "!backend/newman.c",
    "!backend/optabgen.c",
    "!backend/platform_stub.c",
}

cc.library {
    name = "backend",
    static = true,
    srcs = backend_srcs,
    includes = {"root", "tk", "backend", ""},
    src_deps = {
        ["backend/cgcod.c"]  = {"cdxxx.c"},
        ["backend/cg.c"]     = {"fltables.c"},
        ["backend/debug.c"]  = {"debtab.c"},
        ["backend/var.c"]    = {"optab.c", "tytab.c"},
        ["backend/cgelem.c"] = {"elxxx.c"},
    },
    warnings = warnings,
    compiler_opts = compiler_opts,
    defines = table.join(defines, "DMDV2=1"),
}

local frontend_srcs = {
    "access.d", "aggregate.d", "aliasthis.d", "apply.d", "argtypes.d",
    "arrayop.d", "arraytypes.d", "attrib.d", "backend.d", "builtin.d",
    "canthrow.d", "clone.d", "complex.d", "cond.d", "constfold.d",
    "cppmangle.d", "ctfeexpr.d", "dcast.d", "dclass.d", "declaration.d",
    "delegatize.d", "denum.d", "dimport.d", "dinifile.d", "dinterpret.d",
    "dmacro.d", "dmangle.d", "dmodule.d", "doc.d", "dscope.d", "dstruct.d",
    "dsymbol.d", "dtemplate.d", "dversion.d", "entity.d", "errors.d",
    "escape.d", "expression.d", "func.d", "globals.d", "gluelayer.d",
    "hdrgen.d", "id.d", "identifier.d", "impcnvtab.d", "imphint.d", "init.d",
    "inline.d", "intrange.d", "irstate.d", "json.d", "lexer.d", "lib.d",
    "libelf.d", "link.d", "mars.d", "mtype.d", "nogc.d", "nspace.d",
    "objc_stubs.d", "opover.d", "optimize.d", "parse.d", "sapply.d",
    "scanelf.d", "sideeffect.d", "statement.d", "staticassert.d", "target.d",
    "toctype.d", "toelfdebug.d", "tokens.d", "traits.d", "typinf.d", "utf.d",
    "visitor.d",
}

d.binary {
    name = "dmd",
    deps = {"root", "glue", "backend"},
    imports = {"."},
    string_imports = {"."},
    srcs = table.join(
        frontend_srcs,
        glob "root/*.d"
        ),
    compiler_opts = "-m64",
    linker_opts = "-L-lstdc++",
}
