;; Add recent files plugin
(require "mattwparas-helix-package/cogs/recentf.scm")

;; Enable the recentf snapshot, will watch every 2 minutes for active files,
;; and flush those down to disk
(recentf-snapshot)

;; Setup terminal plugin
(require "steel-pty/term.scm")

;; Setup steel LSP
(require "helix/configuration.scm")
(define-lsp "steel-language-server" (command "steel-language-server") (args '()))
(define-language "scheme"
                 (language-servers '("steel-language-server")))

;; Scheme keybindings
(define scm-keybindings (hash "insert" (hash "ret" ':scheme-indent "C-l" ':insert-lambda)))

