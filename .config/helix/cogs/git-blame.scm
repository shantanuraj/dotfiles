(require "helix/editor.scm")
(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require-builtin helix/core/text)

(provide git-blame)

(define (current-path)
  (let* ([focus (editor-focus)]
         [focus-doc-id (editor->doc-id focus)])
    (editor-document->path focus-doc-id)))

(define (selection-line-start)
  (let* ([focus (editor-focus)]
         [doc-id (editor->doc-id focus)]
         [text (editor->text doc-id)]
         [sel (helix.static.current-selection-object)]
         [range (helix.static.selection->primary-range sel)])
    (+ 1 (rope-char->line text (helix.static.range->from range)))))

(define (selection-line-end)
  (let* ([focus (editor-focus)]
         [doc-id (editor->doc-id focus)]
         [text (editor->text doc-id)]
         [sel (helix.static.current-selection-object)]
         [range (helix.static.selection->primary-range sel)])
    (rope-char->line text (helix.static.range->to range))))

;;@doc
;; Show git blame for current selection.
(define (git-blame)
  (helix.run-shell-command
    (string-append
      "git blame -L"
      (number->string (selection-line-start))
      ","
      (number->string (selection-line-end))
      " "
      (current-path))))
