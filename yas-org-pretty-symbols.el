;;; yas-org-pretty-symbols --- makes nested snippet expansion usable
;;
;; Author: Dodge W. Coates
;;
;;; Commentary:
;;
;;; Code:

(require 'org)

(defvar yas-org-pretty-symbols-p nil)
(defvar yas-org-pretty-symbols-nested nil)

(defun org-pretty-p ()
  "Return true iff pretty entities are on."
  (interactive)
  org-pretty-entities)

(defun yas-org-pretty-nested-p ()
  "Return true iff current yas expand is nested."
  (when (equal (length yas-org-pretty-symbols-nested) 0)
    (error "`yas-org-pretty-symbols-nested' has a zero length"))
  (> (length yas-org-pretty-symbols-nested) 1))

(defun yas-org-pretty-symbols-clear-stack ()
  "Clear nested stack used by yas-org-pretty-entities.
This is necessary because snippets unfortunately do not have a
reliable cleanup method, and are often exited uncleanly."
  (setq yas-org-pretty-symbols-nested '())
  (setq yas-org-pretty-symbols-p nil))

(defun yas-org-pretty-symbols-crash (err)
  "Crashes may happen because of yasnippet inelegance referenced by ERR.
This function kills the process after clearing the stack."
  (yas-org-pretty-symbols-clear-stack)
  (error
   (format
    "`yas-org-pretty-symbols' error, clearing stack: %s" err)))

(defun yas-org-turn-off-org-pretty-symbols ()
  "Turn off org-pretty-entities when entering a snippet expansion.
Should be added to pre-hook for yasnippet expansions"
  (push 1 yas-org-pretty-symbols-nested)
  (if (org-pretty-p)
      (progn
        ;; org-pretty-entities should never be on in a nested snippet
        (when (yas-org-pretty-nested-p)
          (yas-org-pretty-crash
           "`yas-org-pretty-symbols-p' while entering non-nested snippet"))
        (if yas-org-pretty-symbols-p
            ; should never be true in the first level
            (yas-org-pretty-crash "error")
          (org-toggle-pretty-entities)
          (setq yas-org-pretty-symbols-p t)))
    (unless (yas-org-pretty-nested-p)
      ;; org-pretty-entities must be off because user has them off by default
      (pop yas-org-pretty-symbols-nested))))

(defun yas-org-turn-on-org-pretty-symbols ()
  "Turn on org-pretty-entities when exiting a snippet expansion.
Should be added to post-hook for yasnippet expansions"
  ;; Should never happen
  (when (org-pretty-p)
    (yas-org-pretty-symbols-crash
       (format
        "`yas-org-pretty-symbols-p' %s and org-pretty-entities on while trying to exit snippet"
        (if yas-org-pretty-symbols-p "true" "false"))))
  ;; If yas-org-pretty-symbols is handling the snippet
  (when yas-org-pretty-symbols-p
    (org-toggle-pretty-entities)
    (setq yas-org-pretty-symbols-p nil)
    (pop yas-org-pretty-symbols-nested)))

(add-hook 'after-save-hook 'yas-org-pretty-symbols-clear-stack)
(add-hook 'yas-before-expand-snippet-hook 'yas-org-turn-off-org-pretty-symbols)
(add-hook 'yas-after-exit-snippet-hook 'yas-org-turn-on-org-pretty-symbols)

    ;; This code turns off pretty symbols in org-capture. It is necessary at
    ;; the moment due to a bug in org-mode that causes font-locking to crash
    ;; when pretty-entities is toggled.

(defvar yas-org-org-capture-bug-fix-p t
  "Disables pretty-symbols in `org-capture' buffers to fix a font-locking bug with `org-capture'.")

(defun org-capture-pretty-advice (funct &rest args)
  "Fixes a bug in `org-capture' that breaks fontlocking via FUNCT and ARGS.
This will turn off pretty symbols in `org-capture' buffers, and can be disabled
with `yas-org-org-capture-bug-fix-p' set to nil."
  (when yas-org-org-capture-bug-fix-p
    (setq-default org-pretty-entities nil)
    (setq-default org-pretty-entities-include-sub-superscripts nil)
    (remove-hook 'yas-before-expand-snippet-hook 'yas-turn-off-org-pretty-symbols)
    (remove-hook 'yas-after-exit-snippet-hook 'yas-turn-on-org-pretty-symbols)
    (funcall funct args)))

(defun org-capture-pretty-post-hook ()
  "Fixes a bug in `org-capture' that breaks fontlocking via FUNCT and ARGS.
This will turn off pretty symbols in `org-capture' buffers, and can be disabled
with `yas-org-org-capture-bug-fix-p' set to nil."
  (when yas-org-org-capture-bug-fix-p
    (setq-default org-pretty-entities t)
    (setq-default  org-pretty-entities-include-sub-superscripts t)
    (add-hook 'yas-before-expand-snippet-hook 'yas-turn-off-org-pretty-symbols)
    (add-hook 'yas-after-exit-snippet-hook 'yas-turn-on-org-pretty-symbols)))

  (add-hook 'org-capture-after-finalize-hook 'org-capture-pretty-post-hook)
  (advice-add 'org-capture :around 'org-capture-pretty-advice)


(provide 'yas-org-pretty-symbols)

;;; yas-org-pretty-symbols.el ends here
