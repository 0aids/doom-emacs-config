;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; ============================================================================
;; Org-roam Configuration
;; ============================================================================

;; Set org-roam directory to ~/org/roam/ - all roam files in one place
(setq org-roam-directory (expand-file-name "roam" org-directory))
(setq org-roam-db-location (expand-file-name "org-roam.db" org-directory))

;; No exclusions - all files in roam/ are roam nodes

;; Enable completion everywhere
(setq org-roam-completion-everywhere t)

;; Configure org-roam-dailies (relative to roam-directory)
(setq org-roam-dailies-directory "dailies/")
(setq org-roam-dailies-capture-templates
      '(("d" "default" entry
         "* %<%H:%M> %?"
         :target (file+head "%<%Y-%m-%d>.org"
                            "#+title: %<%Y-%m-%d %A>\n\n* Fleeting tasks\n\n* Fleeting ideas\n\n* Fleeting links\n")
         :empty-lines 1)))

;; Configure org-roam capture - new nodes go to roam/${slug}.org
(setq org-roam-capture-templates
      '(("n" "note" plain
         "* %?"
         :if-new (file+head "${slug}.org"
                            "#+title: ${title}\n#+date: %U\n")
         :unnarrowed t)))

;; ============================================================================
;; Org-agenda Configuration
;; ============================================================================

;; Scan all org files in the org directory (including roam/ and all subdirs)
(setq org-agenda-files
      (directory-files-recursively
       org-directory
       "\\.org$"
       nil
       (lambda (dir)
         (not (string-prefix-p "." (file-name-nondirectory dir))))))


;; Agenda view settings - show 14 days (2 weeks) by default
(setq org-agenda-span 14)
(setq org-agenda-start-on-weekday nil)  ; Start on current day instead of Monday
(setq org-agenda-start-day "-3d")       ; Show 3 days before today

;; Simple TODO workflow
(setq org-todo-keywords '((sequence "TODO(t)" "|" "DONE(d)")))

;; Log when tasks are done
(setq org-log-done 'time)

;; Pre-defined tags
(setq org-tag-alist '((:startgroup)
                      ("admin" . ?a)
                      ("life" . ?l)
                      ("uni" . ?u)
                      ("courseName" . ?c)
                      ("projectName" . ?p)
                      ("jobs" . ?j)
                      (:endgroup)
                      (:startgroup)
                      ("urgent" . ?U)
                      ("reading" . ?r)
                      ("coding" . ?C)
                      (:endgroup)))

;; Capture templates - insert into today's daily note
;; Lowercase = without link, Uppercase = with link to current buffer
;; Must be set after org loads to override Doom defaults
(with-eval-after-load 'org
  ;; Ensure today's daily note exists with proper structure
  (defun my/ensure-today-note-exists ()
    "Create today's daily note with proper structure if it doesn't exist."
    (let* ((today-str (format-time-string "%Y-%m-%d"))
           (filepath (expand-file-name (concat today-str ".org")
                                       (expand-file-name "dailies" org-roam-directory))))
      (unless (file-exists-p filepath)
        (with-temp-file filepath
          (insert (format "#+title: %s\n\n* Fleeting tasks\n\n* Fleeting ideas\n\n* Fleeting links\n"
                          (format-time-string "%Y-%m-%d %A")))))
      filepath))
  
  ;; Pre-create today's note so file+headline works
  (my/ensure-today-note-exists)
  
  ;; Function to get today's note path as a variable for templates
  (defvar my/today-note-path (my/ensure-today-note-exists)
    "Path to today's daily note.")
  
  ;; Update the path when date changes (simple approach)
  (defun my/update-today-note-path ()
    "Update the today note path variable."
    (setq my/today-note-path (my/ensure-today-note-exists)))
  
  ;; Run this periodically or on capture
  (add-hook 'org-capture-before-finalize-hook #'my/update-today-note-path)
  
  (setq org-capture-templates
        '(;; Tasks
          ("t" "Task (no link)" entry
           (file+headline my/today-note-path "Fleeting tasks")
           "** TODO %?\n   SCHEDULED: %t\n   %U"
           :empty-lines 1)
          ("T" "Task (with link)" entry
           (file+headline my/today-note-path "Fleeting tasks")
           "** TODO %?\n   SCHEDULED: %t\n   %U\n   Context: %a"
           :empty-lines 1)
          ;; Ideas
          ("i" "Idea (no link)" entry
           (file+headline my/today-note-path "Fleeting ideas")
           "** %?\n   %U"
           :empty-lines 1)
          ("I" "Idea (with link)" entry
           (file+headline my/today-note-path "Fleeting ideas")
           "** %?\n   %U\n   Context: %a"
           :empty-lines 1)
          ;; Links
          ("l" "Link (no context)" entry
           (file+headline my/today-note-path "Fleeting links")
           "** %? %:link\n   %U"
           :empty-lines 1)
          ("L" "Link (with context)" entry
           (file+headline my/today-note-path "Fleeting links")
           "** %? %:link\n   %U\n   Source: %:description"
           :empty-lines 1))))



;; ============================================================================
;; Custom Keybindings
;; ============================================================================

;; Quick capture binding
(map! :leader
      :desc "Quick capture"
      "X" #'org-capture)

;; Org-roam keybindings
(map! :leader
      :prefix "n"
      :desc "Toggle roam buffer"
      "r" #'org-roam-buffer-toggle
      :desc "Find node"
      "f" #'org-roam-node-find
      :desc "Insert link"
      "i" #'org-roam-node-insert
      :desc "Capture to node"
      "c" #'org-roam-capture
      :desc "Show graph"
      "g" #'org-roam-graph
      :desc "Random node"
      "R" #'org-roam-node-random)

;; Org-roam-dailies keybindings
(map! :leader
      :prefix "n"
      :desc "Today"
      "d" #'org-roam-dailies-goto-today
      :desc "Yesterday"
      "y" #'org-roam-dailies-goto-yesterday
      :desc "Tomorrow"
      "m" #'org-roam-dailies-goto-tomorrow
      :desc "Date"
      "D" #'org-roam-dailies-goto-date)


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.



(use-package! org-download
  :after org
  :config
  ;; Enable in org buffers
  (add-hook 'org-mode-hook #'org-download-enable)

  ;; Enable in dired for drag & droppp
  (add-hook 'dired-mode-hook #'org-download-enable)
  (setq-default org-download-image-dir "~/org/images"))
