# Keybinds

c.bindings.default = {}

# leader keys

leader = " "
tab = "t"
window = "n"
copy = "y"
paste = "p"
hint = "e"
mark = "`"
setting = "g"

# modes

config.bind("i", "mode-enter insert")
config.bind("v", "mode-enter caret")
config.bind("V", "mode-enter caret ;; selection-toggle --line")
config.bind("<Ctrl-v>", "mode-enter passthrough")

# normal

config.bind("<Escape>", "clear-keychain ;; search ;; fullscreen --leave")

config.bind("<Return>", "selection-follow")

config.bind("w", "scroll up")
config.bind("a", "scroll left")
config.bind("s", "scroll down")
config.bind("d", "scroll right")

config.bind("/", "cmd-set-text /")
config.bind("?", "cmd-set-text ?")
config.bind(":", "cmd-set-text :")

config.bind(f"o", "cmd-set-text -s :open")

config.bind(f"{leader}f", "forward")
config.bind(f"{leader}b", "back")

config.bind(f"{leader}r", "reload")
config.bind(f"{leader}R", "reload -f")

config.bind(f"q", "tab-close")
config.bind("z", "undo")
config.bind("Z", "undo -w")

config.bind(f"{leader}{copy}", "yank")
config.bind(f"{leader}<Shift-{copy}>", "yank -s")
config.bind(f"{leader}{paste}", "open -- {clipboard}")
config.bind(f"{leader}<Shift-{paste}>", "open -- {primary}")

config.bind(f"{mark}", "quickmark-save")
config.bind(f"{leader}{mark}", "cmd-set-text -s :quickmark-load")
config.bind(f"<Shift-{mark}>", "bookmark-add")
config.bind(f"{leader}<Shift-{mark}>", "cmd-set-text -s :bookmark-load")

config.bind(f"{hint}", "hint")
config.bind(f"<Shift-{hint}>", "hint --rapid")
config.bind(f"{copy}{hint}", "hint links yank")
config.bind(f"<Shift-{copy}>{hint}", "hint links yank-primary")

config.bind("f", "search-next")
config.bind("b", "search-prev")

config.bind("F", "scroll-to-perc 0")
config.bind("B", "scroll-to-perc")

config.bind("=", "zoom")
config.bind("+", "zoom-in")
config.bind("-", "zoom-out")

config.bind("[[", "navigate prev")
config.bind("]]", "navigate next")

config.bind(".", "cmd-repeat-last")
config.bind("!", "macro-record")
config.bind("@", "macro-run")

# tab

config.bind(f"{tab}{tab}", "cmd-set-text -sr :tab-focus")

config.bind("<Alt-w>", "tab-prev")
#config.bind("<Alt-a>", "tab-prev")
config.bind("<Alt-s>", "tab-next")
#config.bind("<Alt-d>", "tab-next")

config.bind("W", "tab-move -")
#config.bind("A", "tab-move -")
config.bind("S", "tab-move +")
#config.bind("D", "tab-move +")

config.bind(f"{tab}1", "tab-focus 1")
config.bind(f"{tab}2", "tab-focus 2")
config.bind(f"{tab}3", "tab-focus 3")
config.bind(f"{tab}4", "tab-focus 4")
config.bind(f"{tab}5", "tab-focus 5")
config.bind(f"{tab}6", "tab-focus 6")
config.bind(f"{tab}7", "tab-focus 7")
config.bind(f"{tab}8", "tab-focus 8")
config.bind(f"{tab}9", "tab-focus 9")
config.bind(f"{tab}0", "tab-focus -1")

config.bind(f"{tab}f", "forward -t")
config.bind(f"{tab}b", "back -t")

config.bind(f"{tab}o", "cmd-set-text -s :open -t")

config.bind(f"{tab}{copy}", "yank pretty-url")
config.bind(f"{tab}<Shift-{copy}>", "yank pretty-url -s")
config.bind(f"{tab}{paste}", "open -t -- {clipboard}")
config.bind(f"{tab}<Shift-{paste}>", "open -t -- {primary}")

config.bind(f"{tab}{mark}", "cmd-set-text -s :quickmark-load -t")
config.bind(f"{tab}<Shift-{mark}>", "cmd-set-text -s :bookmark-load -t")

config.bind(f"{tab}{hint}", "hint all tab")
config.bind(f"{tab}<Shift-{hint}>", "hint --rapid all tab")

# window

config.bind(f"{window}f", "forward -w")
config.bind(f"{window}b", "back -w")

config.bind(f"{window}o", "cmd-set-text -s :open -w")
config.bind(f"{window}O", "cmd-set-text -s :open -p")

config.bind(f"{window}{copy}", "yank title")
config.bind(f"{window}<Shift-{copy}>", "yank title -s")
config.bind(f"{window}{paste}", "open -w -- {clipboard}")
config.bind(f"{window}<Shift-{paste}>", "open -w -- {primary}")

config.bind(f"{window}{mark}", "cmd-set-text -s :quickmark-load -w")
config.bind(f"{window}<Shift-{mark}>", "cmd-set-text -s :bookmark-load -w")

config.bind(f"{window}{hint}", "hint all window")
config.bind(f"{window}<Shift-{hint}>", "hint --rapid all window")

# setting

config.bind(f"{setting}sh", "config-cycle -p -t -u *://{url:host}/* content.javascript.enabled ;; reload")
config.bind(f"{setting}Sh", "config-cycle -p -u *://{url:host}/* content.javascript.enabled ;; reload")
config.bind(f"{setting}sH", "config-cycle -p -t -u *://*.{url:host}/* content.javascript.enabled ;; reload")
config.bind(f"{setting}SH", "config-cycle -p -u *://*.{url:host}/* content.javascript.enabled ;; reload")
config.bind(f"{setting}su", "config-cycle -p -t -u {url} content.javascript.enabled ;; reload")
config.bind(f"{setting}Su", "config-cycle -p -u {url} content.javascript.enabled ;; reload")

config.bind(f"{setting}ph", "config-cycle -p -t -u *://{url:host}/* content.plugins ;; reload")
config.bind(f"{setting}Ph", "config-cycle -p -u *://{url:host}/* content.plugins ;; reload")
config.bind(f"{setting}pH", "config-cycle -p -t -u *://*.{url:host}/* content.plugins ;; reload")
config.bind(f"{setting}PH", "config-cycle -p -u *://*.{url:host}/* content.plugins ;; reload")
config.bind(f"{setting}pu", "config-cycle -p -t -u {url} content.plugins ;; reload")
config.bind(f"{setting}Pu", "config-cycle -p -u {url} content.plugins ;; reload")

config.bind(f"{setting}ih", "config-cycle -p -t -u *://{url:host}/* content.images ;; reload")
config.bind(f"{setting}Ih", "config-cycle -p -u *://{url:host}/* content.images ;; reload")
config.bind(f"{setting}iH", "config-cycle -p -t -u *://*.{url:host}/* content.images ;; reload")
config.bind(f"{setting}IH", "config-cycle -p -u *://*.{url:host}/* content.images ;; reload")
config.bind(f"{setting}iu", "config-cycle -p -t -u {url} content.images ;; reload")
config.bind(f"{setting}Iu", "config-cycle -p -u {url} content.images ;; reload")

config.bind(f"{setting}ch", "config-cycle -p -t -u *://{url:host}/* content.cookies.accept all no-3rdparty never ;; reload")
config.bind(f"{setting}Ch", "config-cycle -p -u *://{url:host}/* content.cookies.accept all no-3rdparty never ;; reload")
config.bind(f"{setting}cH", "config-cycle -p -t -u *://*.{url:host}/* content.cookies.accept all no-3rdparty never ;; reload")
config.bind(f"{setting}CH", "config-cycle -p -u *://*.{url:host}/* content.cookies.accept all no-3rdparty never ;; reload")
config.bind(f"{setting}cu", "config-cycle -p -t -u {url} content.cookies.accept all no-3rdparty never ;; reload")
config.bind(f"{setting}Cu", "config-cycle -p -u {url} content.cookies.accept all no-3rdparty never ;; reload")

# caret

config.bind("<Escape>", "mode-leave", mode="caret")

config.bind("v", "selection-toggle", mode="caret")
config.bind("V", "selection-toggle --line", mode="caret")

config.bind("w", "move-to-prev-line", mode="caret")
config.bind("a", "move-to-prev-char", mode="caret")
config.bind("s", "move-to-next-line", mode="caret")
config.bind("d", "move-to-next-char", mode="caret")

config.bind("W", "move-to-start-of-document", mode="caret")
config.bind("A", "move-to-start-of-line", mode="caret")
config.bind("S", "move-to-end-of-document", mode="caret")
config.bind("D", "move-to-end-of-line", mode="caret")

config.bind("<Alt-w>", "scroll up", mode="caret")
config.bind("<Alt-a>", "scroll left", mode="caret")
config.bind("<Alt-s>", "scroll down", mode="caret")
config.bind("<Alt-d>", "scroll right", mode="caret")

config.bind("f", "move-to-next-word", mode="caret")
config.bind("b", "move-to-prev-word", mode="caret")

config.bind("[", "move-to-start-of-prev-block", mode="caret")
config.bind("]", "move-to-start-of-next-block", mode="caret")
config.bind("{", "move-to-end-of-prev-block", mode="caret")
config.bind("}", "move-to-end-of-next-block", mode="caret")

config.bind("y", "yank selection", mode="caret")
config.bind("Y", "yank selection -s", mode="caret")

# command

config.bind("<Escape>", "mode-leave", mode="command")

config.bind("<Return>", "command-accept", mode="command")
config.bind("<Ctrl-Return>", "command-accept --rapid", mode="command")

config.bind("<Tab>", "completion-item-focus next", mode="command")
config.bind("<Shift-Tab>", "completion-item-focus prev", mode="command")
config.bind("<Up>", "completion-item-focus --history prev", mode="command")
config.bind("<Down>", "completion-item-focus --history next", mode="command")

# hint

config.bind("<Escape>", "mode-leave", mode="hint")

config.bind("<Return>", "hint-follow", mode="hint")

# insert

config.bind("<Escape>", "mode-leave", mode="insert")
config.bind("<Shift-Escape>", "fake-key <Escape>", mode="insert")

# passthrough

config.bind("<Shift-Escape>", "mode-leave", mode="passthrough")

# prompt

config.bind("<Escape>", "mode-leave", mode="prompt")

config.bind("<Return>", "prompt-accept", mode="prompt")

# register

config.bind("<Escape>", "mode-leave", mode="register")

# yesno

config.bind("<Escape>", "mode-leave", mode="yesno")

config.bind("<Return>", "prompt-accept", mode="yesno")
config.bind("y", "prompt-accept yes", mode="yesno")
config.bind("n", "prompt-accept no", mode="yesno")
config.bind("Y", "prompt-accept --save yes", mode="yesno")
config.bind("N", "prompt-accept --save no", mode="yesno")

# Behaviour

homepage = "about:blank"

# preferences

config.load_autoconfig(False)

c.confirm_quit = [ "never" ]

c.url.default_page = homepage
c.url.start_pages = [ homepage ]

c.completion.show = "always"
c.completion.min_chars = 1
c.completion.delay = 0

c.completion.quick = True
c.completion.open_categories = [ "quickmarks", "bookmarks", "searchengines", "history", ]
c.completion.web_history.max_items = -1

c.content.mute = False
c.content.autoplay = False

c.content.notifications.presenter = "auto"
c.content.notifications.show_origin = True

c.tabs.background = True
c.tabs.close_mouse_button = "middle"
c.tabs.close_mouse_button_on_bar = "new-tab"
c.tabs.last_close = "default-page"

c.tabs.focus_stack_size = 9
c.tabs.mode_on_change = "normal"
c.tabs.mousewheel_switching = True

c.tabs.new_position.related = "next"
c.tabs.new_position.stacking = False
c.tabs.new_position.unrelated = "last"

c.tabs.select_on_remove = "next"

c.tabs.wrap = True

c.downloads.open_dispatcher = None
c.downloads.prevent_mixed_content = True
c.downloads.remove_finished = 300_000
c.downloads.location.directory = "~/Downloads"
c.downloads.location.prompt = False
c.downloads.location.remember = False
c.downloads.location.suggestion = "path"

# search engine

c.url.searchengines = {
    "DEFAULT": "https://www.startpage.com/sp/search?query={}",
    "yt": "https://youtube.com/search?q={}",
    "gh": "https://github.com/search?q={}",
    "cpp": "https://en.cppreference.com/mwiki/index.php?search={}",
}

# saving

c.completion.cmd_history_max_items = 0

c.tabs.undo_stack_size = 100

c.auto_save.interval = 20_000
c.auto_save.session = False

c.content.private_browsing = False
c.content.cookies.store = True
c.content.persistent_storage = "ask"

# permissions

c.content.proxy = "system"
c.content.proxy_dns_requests = True

c.content.javascript.enabled = True
c.content.javascript.prompt = True
c.content.javascript.alert = True
c.content.javascript.can_close_tabs = False
c.content.javascript.can_open_tabs_automatically = False
c.content.javascript.clipboard = "ask"
c.content.javascript.legacy_touch_events = "never"
c.content.javascript.modal_dialog = False

c.content.local_storage = True
c.content.local_content_can_access_file_urls = True
c.content.local_content_can_access_remote_urls = False

c.content.media.audio_capture = "ask"
c.content.media.video_capture = "ask"
c.content.media.audio_video_capture = "ask"

c.content.mouse_lock = "ask"

c.content.register_protocol_handler = "ask"

c.content.site_specific_quirks.enabled = True

c.content.xss_auditing = False

c.content.notifications.enabled = False

c.content.cookies.accept = "no-3rdparty"

c.content.blocking.enabled = True
c.content.blocking.adblock.lists = [
    'https://easylist.to/easylist/easylist.txt',
    'https://easylist.to/easylist/easyprivacy.txt',
]
c.content.blocking.method = "both"

c.content.headers.accept_language = "en-UK,en;q=0.9"
c.content.headers.referer = "same-domain"
c.content.headers.do_not_track = True

c.content.geolocation = False
c.content.notifications.enabled = False
c.content.desktop_capture = False

c.content.webrtc_ip_handling_policy = "default-public-interface-only"

# performance

c.backend = "webengine"

c.content.webgl = True

c.content.cache.appcache = True
c.content.cache.maximum_pages = 0
c.content.cache.size = None
c.content.canvas_reading = True

c.content.default_encoding = "iso-8859-1"

c.content.dns_prefetch = True

# external

c.qt.args = [
    "widevine-path=/usr/lib/widevine/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so"
]

c.editor.command = [ "nvim", "{file}" ]
c.editor.encoding = "utf-8"
c.editor.remove_file = True

c.content.pdfjs = True

# Theme

with open("@THEME_SWITCHER_ROOT@/active/qutebrowser-theme.py") as f:
    exec(f.read())
