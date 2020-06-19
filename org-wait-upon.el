;;; org-wait-upon.el --- Org Wait Upon                   -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Theo Sherry

;; Author: Theo Sherry <sherr.theo@gmail.com>
;; URL: https://github.com/theosherry/org-wait-upon
;; Package-Requires: ((emacs "25.1") (helm "3.3") (helm-org "1.0") (dash "2.12.1")  (s "1.12.0"))
;; Version: 1.0
;; Keywords: org todo blocking waiting

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package adds the ability to set which tasks WAITING tasks are waiting
;; upon.
;; Links to and from blocking and waiting tasks are added to properties drawer
;; of relevent headings, and when all blocking tasks are finished, waiting
;; tasks are activated.
;;
;; Usage:

;; `(org-wait-upon-init)`

;;; Code:
(require 'helm)
(require 'helm-org)
(require 'dash)
(require 's)

(defvar --org-wait-upon-waiting-ids-prop "ORG-WAIT-UPON-WAITING-IDS")
(defvar --org-wait-upon-waiting-links-prop "ORG-WAIT-UPON-WAITING-LINKS")
(defvar --org-wait-upon-blocking-ids-prop "ORG-WAIT-UPON-BLOCKING-IDS")
(defvar --org-wait-upon-blocking-links-prop "ORG-WAIT-UPON-BLOCKING-LINKS")

(defun --org-wait-upon-org-id-link-from-id (id)
  "Make id link to heading from id. Replaces spaces with underscores to avoid
problems with `org-entry-put-multivalued-property`, which makes use of spaces."
  (org-id-goto id)
  (let ((name  (replace-regexp-in-string "\s" "_"
                                         (nth 4 (org-heading-components)))))
    (format "[[id:%s][%s]]" id name)))

(defun --org-wait-upon-heading-from-components (components)
  "Return a basic todo heading from (org-heading-components) result."
  (let* ((level-text (make-string (nth 0 components) ?*))
         (todo (nth 2 components))
         (todo-text (if todo (format "%s " todo) ""))
         (text (nth 4 components)))
    (format "%s %s%s" level-text todo-text text)))

(defun --org-wait-upon-gather-org-headings (&optional match id)
  "Gather the org headings in the active buffer. Returns a list of cons,
(--org-wait-upon-heading-from-components . point).

Because this will set potentially multiple ids, it may be slow the first time
it's run on a set of headings.

ARGS

If `match` is provided, only select the headlines specified by the match pattern
(see org-agenda matching).

If `id` is non-nil, return the ID property (which will be set if not present)
instead of point.
"
  (org-map-entries (lambda ()
                     (let ((identifier (if id (org-id-get-create) (point))))
                       (cons (--org-wait-upon-heading-from-components (org-heading-components))
                             identifier)))
                   match nil))

(defun --org-wait-upon-set-props-on-blocking (blocking-id waiting-id waiting-link)
  "Add the necessary props on the blocking heading when waiting/blocking relationship is created."
  (let* ((pom (cdr (org-id-find blocking-id)))
         (waiting-ids (org-entry-get-multivalued-property pom --org-wait-upon-waiting-ids-prop))
         (new-waiting-ids (-union waiting-ids (list waiting-id)))
         (waiting-links (org-entry-get-multivalued-property pom --org-wait-upon-waiting-links-prop))
         (new-waiting-links (-union waiting-links (list waiting-link))))
    (apply #'org-entry-put-multivalued-property pom --org-wait-upon-waiting-ids-prop new-waiting-ids)
    (apply #'org-entry-put-multivalued-property pom --org-wait-upon-waiting-links-prop new-waiting-links)))

(defun --org-wait-upon-set-props-on-waiting (blocking-id waiting-id)
  "Add the necessary props to the waiting heading when waiting/blocking relationship is created."
  (let* ((pom (cdr (org-id-find waiting-id)))
         (blocking-ids (org-entry-get-multivalued-property pom --org-wait-upon-blocking-ids-prop))
         (new-blocking-ids (-union blocking-ids (list blocking-id)))
         (blocking-link (--org-wait-upon-org-id-link-from-id blocking-id))
         (blocking-links (org-entry-get-multivalued-property pom --org-wait-upon-blocking-links-prop))
         (new-blocking-links (-union blocking-links (list blocking-link))))
    (apply #'org-entry-put-multivalued-property pom --org-wait-upon-blocking-ids-prop new-blocking-ids)
    (apply #'org-entry-put-multivalued-property pom --org-wait-upon-blocking-links-prop new-blocking-links)))

(defun --org-wait-upon-set-heading-to-blocking-factory(waiting-id)
  "Make a function that will handle setting up blocking/waiting relationship for
any blockers + waiting-id."
  (let ((waiting-link (--org-wait-upon-org-id-link-from-id waiting-id))) ;; Create waiting link here to avoid making it multiple times for each invocation of the lambda below.
    (lambda (blocking-id)
      (--org-wait-upon-set-props-on-blocking blocking-id waiting-id waiting-link)
      (--org-wait-upon-set-props-on-waiting blocking-id waiting-id))))

(defun --org-wait-upon-resolve-props-on-waiting (blocking-id waiting-id)
  "Resolve the necessary props on waiting heading when waiting/blocking relationship is resolved."
  (let* ((pom (cdr (org-id-find waiting-id)))
         (blocking-ids (org-entry-get-multivalued-property pom --org-wait-upon-blocking-ids-prop))
         (blocking-links (org-entry-get-multivalued-property pom --org-wait-upon-blocking-links-prop))
         (new-blocking-ids (-remove-item blocking-id blocking-ids))
         (new-blocking-links (--remove-first (string-match blocking-id it) blocking-links)))
    (apply #'org-entry-put-multivalued-property pom --org-wait-upon-blocking-ids-prop new-blocking-ids)
    (apply #'org-entry-put-multivalued-property pom --org-wait-upon-blocking-links-prop new-blocking-links)

    ;; If waiting TODO is no longer being blocked, handle that
    (if (not new-blocking-ids)
        (let ((waiting-text (nth 4 (org-heading-components))))
          (goto-char pom)
          (org-todo "TODO")
          (message (format "Task \"%s\" was waiting on the task just completed and is now ready to be started."
                           (truncate-string-to-width waiting-text 20 nil nil t)))))))

(defun --org-wait-upon-resolve-props-on-blocking (blocking-id waiting-id)
  "Resolve the necessary props on blocking heading when waiting/blocking relationship is resolved."
  (let* ((pom (cdr (org-id-find blocking-id)))
         (waiting-ids (org-entry-get-multivalued-property pom --org-wait-upon-waiting-ids-prop))
         (waiting-links (org-entry-get-multivalued-property pom --org-wait-upon-waiting-links-prop))
         (new-waiting-ids (-remove-item waiting-id waiting-ids))
         (new-waiting-links (--remove-first (string-match waiting-id it) waiting-links)))
    (apply #'org-entry-put-multivalued-property pom --org-wait-upon-waiting-ids-prop new-waiting-ids)
    (apply #'org-entry-put-multivalued-property pom --org-wait-upon-waiting-links-prop new-waiting-links)))

(defun --org-wait-upon-resolve-blocking-to-done-factory(blocking-id)
  "Make a function that wlil handle resolving a blocking/waiting relationship for waiters specified
by waiting-id and blocker specified by blocking-id."
  (lambda (waiting-id)
    (--org-wait-upon-resolve-props-on-waiting blocking-id waiting-id)
    (--org-wait-upon-resolve-props-on-blocking blocking-id waiting-id)))

(defun --org-wait-upon-set-blocking-headings ()
  "Allow user to select blocking tasks, and setup blocking/waiting relationships."
  (let ((waiting-id (org-id-get-create)))
    (cl-flet ((heading-to-blocking (--org-wait-upon-set-heading-to-blocking-factory waiting-id)))
      (let* ((files (list (current-buffer)))
             (sources (helm-org-build-sources files nil nil))
             (candidates (--org-wait-upon-gather-org-headings
                          "LEVEL=1|TODO=\"TODO\"|TODO=\"RECURRING\""
                          t))
             (source-helm (helm-build-sync-source "Wait Upon Candidates"
                            :candidates candidates
                            :action (lambda (_)
                                      ;; We want to iterate over all selected candidates
                                      (let ((marked-cands (helm-marked-candidates)))
                                        (dolist (cand marked-cands)
                                          (heading-to-blocking cand)))))))
        (helm :sources source-helm
              :buffer "*helm org inbuffer*")))))

(defun --org-wait-upon-handle-blocking-heading-to-done ()
  "Check if heading marked DONE is blocking, and if so resolve its relationship with
the waiting heading(s)."
  (let* ((id (org-id-get-create))
         (pom (point))
         (waiting-ids (org-entry-get-multivalued-property pom --org-wait-upon-waiting-ids-prop))
         (waiting-links (org-entry-get-multivalued-property pom --org-wait-upon-waiting-links-prop)))
    (if waiting-ids
        (cl-flet ((blocking-to-done (--org-wait-upon-resolve-blocking-to-done-factory id)))
          (-each waiting-ids (lambda (waiting-id)
                               (blocking-to-done waiting-id)))

          ))))

(defun --org-wait-upon-on-heading-to-waiting ()
  (if (y-or-n-p "Select headings to wait upon?")
      (--org-wait-upon-set-blocking-headings)))

(defun --org-wait-upon-on-heading-to-done ()
  (--org-wait-upon-handle-blocking-heading-to-done))

(defun --org-wait-upon-on-todo-change()
  (cond ((equal org-state "WAITING") (funcall '--org-wait-upon-on-heading-to-waiting))
        ((equal org-state "DONE") (funcall '--org-wait-upon-on-heading-to-done))))

;;;###autoload
(defun org-wait-upon-init ()
  (add-hook 'org-after-todo-state-change-hook
            '--org-wait-upon-on-todo-change))

(provide 'org-wait-upon)
