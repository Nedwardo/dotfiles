-- DMS Window Rules — managed by Dux Modular Shell
-- Do not edit manually; changes may be overwritten

-- DMS-RULE: id=dms-floating-windows, name=DMS Floating Windows
hl.window_rule({ match = { class = "^(dev\\.duxlabs\\.shell|com\\.danklinux\\.dms)$" }, float = true })

-- DMS-RULE: id=wr_1794312067191933090, name=firefox downloads
hl.window_rule({ match = { class = "^firefox$", title = "^Library$" }, float = true })

-- DMS-RULE: id=wr_1794312125406326507, name=com.system76.CosmicFiles
hl.window_rule({ match = { class = "^com.system76.CosmicFiles$" }, float = true })

-- DMS-RULE: id=dms-window-opaque, name=DMS Window Opaque
hl.window_rule({ match = { class = "^(dev\\.duxlabs\\.shell|com\\.danklinux\\.dms)$" }, opaque = true })
