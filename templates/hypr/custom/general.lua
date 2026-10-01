-- Monitor layout is machine-specific — set your own here, e.g.
-- hl.monitor({ output = "desc:<make> <model>", mode = "highrr", position = "0x0", scale = 1 })
-- ("highrr" picks the fastest mode the link actually offers.)
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.config({
    gestures = {
        workspace_swipe_touch = true
    },
    input = {
        follow_mouse = 0
    }
})
