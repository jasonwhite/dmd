import "src/BUILD.lua"

local SYSCONFDIR = "/etc"

-- Generate verstr.h
rule {
    inputs = {"version.sh", "VERSION", ".git/HEAD"},
    task = {"sh", "-c", "./version.sh > src/verstr.h"},
    outputs = {"src/verstr.h"},
}

-- Generate SYSCONFDIR.imp
rule {
    inputs = {},
    task = {"sh", "-c", "echo '".. SYSCONFDIR .."' > src/SYSCONFDIR.imp"},
    outputs = {"src/SYSCONFDIR.imp"},
}
