;;; ox-html-timeline.el --- HTML-TIMELINE Back-End for Org Export Engine -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2024 Bastien Guerry

;; Author: Bastien Guerry <bzg@gnu.org>
;; Keywords: org, ox, timeline

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'ox-html)
(require 'ob-core)
(require 'url-util)
(declare-function url-encode-url "url-util" (url))

;;; Variables and options

(defgroup org-export-html-timeline nil
  "Options specific to HTML-TIMELINE export back-end."
  :tag "Org HTML-TIMELINE"
  :group 'org-export)

(defcustom org-html-timeline-header-re "Header\\|En-tête"
  "Regex to find a header section."
  :group 'org-export-html-timeline
  :type 'string)

(defcustom org-html-timeline-footer-re "Footer\\|Bas de page"
  "Regex to find a footer section."
  :group 'org-export-html-timeline
  :type 'string)

(org-export-define-derived-backend 'html-timeline 'html
  :menu-entry
  '(?n "Export to HTML-TIMELINE"
       ((?n "As HTML-TIMELINE buffer"
	    (lambda (a s v b) (org-html-timeline-export-as-html-timeline a s v)))
	(?N "As HTML-TIMELINE file"
	    (lambda (a s v b) (org-html-timeline-export-to-html-timeline a s v)))))
  :options-alist
  '((:description "DESCRIPTION" nil nil newline)
    (:homepage    "HOMEPAGE" nil nil newline)
    (:rights      "RIGHTS" nil nil newline)
    (:keywords    "KEYWORDS" nil nil space)
    (:with-toc nil nil nil))
  :filters-alist '((:filter-final-output . org-html-timeline-final-function))
  :translate-alist '((template . org-html-timeline-template)
		     (headline . org-html-timeline-headline)
		     (section . org-html-section)
		     (paragraph . org-html-paragraph)))

;;; Utility functions

(defun org-html-timeline-flatten (l)
  (cond
   ((null l) nil)
   ((atom l) (list l))
   (t (append (org-html-timeline-flatten (car l))
	      (org-html-timeline-flatten (cdr l))))))

;;; Export functions

;;;###autoload
(defun org-html-timeline-export-as-html-timeline (&optional async subtreep visible-only)
  "Export current buffer to a HTML-TIMELINE buffer.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Export is done in a buffer named \"*Org HTML-TIMELINE Export*\", which will
be displayed when `org-export-show-temporary-export-buffer' is
non-nil."
  (interactive)
  (org-export-to-buffer 'html-timeline "*Org HTML-TIMELINE Export*"
    async subtreep visible-only nil nil (lambda () (text-mode))))

;;;###autoload
(defun org-html-timeline-export-to-html-timeline (&optional async subtreep visible-only)
  "Export current buffer to a HTML-TIMELINE file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Return output file's name."
  (interactive)
  (let ((outfile (org-export-output-file-name ".html" subtreep)))
    (org-export-to-file 'html-timeline outfile async subtreep visible-only)))

;;;###autoload
(defun org-html-timeline-publish-to-html-timeline (plist filename pub-dir)
  "Publish an org file to HTML-TIMELINE.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (org-publish-org-to 'html-timeline filename ".html" plist pub-dir))

;; Formatting templates

(defvar org-html-timeline-file-template
  "<!DOCTYPE html>
<html lang=\"%s\" class=\"no-js\">
  <head>
    <meta charset=\"utf-8\" />
    <title>%s</title>
    <meta name=\"description\" content=\"%s\">
    <meta name=\"author\" content=\"%s\">
    <link href='https://fonts.googleapis.com/css?family=Roboto+Slab|Hind+Vadodara:400,600' rel='stylesheet' type='text/css'>
    <link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css\">
    <link rel=\"stylesheet\" href=\"css/normalize.css\">
    <link rel=\"stylesheet\" href=\"css/main.css\">
    <link rel=\"icon\" type=\"image/png\" href=\"images/favicon.png\">
    <script src=\"https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js\"></script>
  </head>
  <body>
    <header class=\"page-header\">
    %s
    </header>
    <section>
    %s
    <article class=\"timeline\">
    %s
    </article>
    <footer class=\"page-footer\">
    %s
    </footer>
    </section>
    <script src=\"./js/main.js\"></script>
  </body>
</html>")

(defvar org-html-timeline-entry-template
  "<div class=\"timeline-entry\" data-category=\"%s\">
  <div class=\"timeline-icon %s\">
    <i class=\"fa %s\"></i>
  </div>
  <div class=\"timeline-description\">
    <span class=\"timestamp\">
      <time datetime=\"%s\">%s</time>
    </span>
    <h2>
      <a id=\"%s\" href=\"#%s\">
	<i class=\"fa fa-link\"></i>
      </a>%s
    </h2>
    %s
    %s
  </div>
</div>")

(defvar org-html-timeline-image-template
  "<div class=\"captioned-image image-right\">
  <a href=\"%s\">
  <img src=\"%s\" alt=\"%s\" />
  </a>
  <span class=\"caption\">%s</span>
  </div>")

(defvar org-html-timeline-filter-wrapper-template
  "<div class=\"timeline-filter-wrapper\">
  <header class=\"timeline-filter\">
    <ul>
      <li>
        <input type=\"checkbox\" name=\"filter-shortcut\" id=\"all\" checked /> <label for=\"all\">All</label>
      </li>
      %s
    </ul>
  </header>
</div>")

(defvar org-html-timeline-filter-wrapper-item-template
  "<li>
  <input type=\"checkbox\" name=\"filter\" id=\"%s\" checked /> <label for=\"%s\">%s</label>
</li>")

;;; Utility and wrapper functions

(defun org-html-timeline-linkify (s)
  (downcase (replace-regexp-in-string "\\s-" "-" s)))

(defun org-html-timeline-maybe-insert-image (image-src image-caption)
  (if (and image-src image-caption)
      (format org-html-timeline-image-template
	      image-src
	      image-src
	      image-caption
	      image-caption)
    "")) ;; Insert nothing when image-src or image-caption is missing

(defun org-html-timeline-collect-data-categories ()
  (let* ((buf (org-element-parse-buffer))
	 (filter (lambda (n)
		   (when (string= (org-element-property :key n) "data-category")
		     (org-split-string (org-element-property :value n) ","))))
	 (nodes (org-element-map buf 'node-property #'identity)))
    (mapcar #'org-trim (delete-dups
			(org-html-timeline-flatten (mapcar filter nodes))))))

(defun org-html-timeline-build-data-categories (data-categories)
  (format
   "[%s]"
   (mapconcat
    (lambda (c) (format "'%s'" (org-html-timeline-linkify c)))
    data-categories ", ")))

(defun org-html-timeline-build-filter-wrapper-item (all-categories)
  (mapconcat (lambda (c)
	       (let ((link (org-html-timeline-linkify c)))
		 (format org-html-timeline-filter-wrapper-item-template
			 link
			 link
			 c)))
	     all-categories
	     ""))

(defun org-html-timeline-build-filter-wrapper (all-categories)
  (format org-html-timeline-filter-wrapper-template
	  (org-html-timeline-build-filter-wrapper-item all-categories)))

(defun org-html-timeline-build-header (title)
  (let* ((buf (org-element-parse-buffer))
	 (section
	  (first (org-element-map buf 'section
		   (lambda (s)
		     (let* ((p (org-element-property :parent s))
			    (raw-hl (org-element-property :raw-value p)))
		       (when (and raw-hl
				  (string-match
				   org-html-timeline-header-re raw-hl))
			 s))))))
	 (reg-beg (org-element-property :contents-begin section))
	 (reg-end (org-element-property :contents-end section)))
    (concat (format "<h1>%s</h1>" title)
	    (org-export-string-as
	     (delete-and-extract-region reg-beg reg-end) 'html t))))

(defun org-html-timeline-build-footer ()
  (let* ((buf (org-element-parse-buffer))
	 (section
	  (first (org-element-map buf 'section
		   (lambda (s)
		     (let* ((p (org-element-property :parent s))
			    (raw-hl (org-element-property :raw-value p)))
		       (when (and raw-hl
				  (string-match
				   org-html-timeline-footer-re
				   raw-hl))
			 s))))))
	 (reg-beg (org-element-property :contents-begin section))
	 (reg-end (org-element-property :contents-end section)))
    (org-export-string-as
     (delete-and-extract-region reg-beg reg-end) 'html t)))

;; Transcoding functions

(defun org-html-timeline-template (contents info)
  "Return complete document string after HTML-TIMELINE conversion.
CONTENTS is the transcoded contents string.  INFO is a plist used
as a communication channel."
  (let ((title (org-export-data (plist-get info :title) info))
	(description (plist-get info :description))
	(all-categories (org-html-timeline-collect-data-categories))
	(lang (org-export-data (plist-get info :lang) info))
	(author (org-export-data (plist-get info :author) info)))
    (format org-html-timeline-file-template
	    lang
	    title
	    description
	    author
	    (org-html-timeline-build-header title)
	    (org-html-timeline-build-filter-wrapper all-categories)
	    contents
	    (org-html-timeline-build-footer))))

(defun org-html-timeline-headline (headline contents _)
  "Transcode HEADLINE element into HTML-TIMELINE format.
CONTENTS is the headline contents.  INFO is a plist used as a
communication channel."
  (if (org-element-property :DATA-CATEGORY headline)
      (let* ((raw-headline (org-element-property :raw-value headline))
	     (data-categories (org-split-string
			       (org-element-property :DATA-CATEGORY headline) ","))
	     (icon-color (org-element-property :ICON-COLOR headline))
	     (fa-icon (org-element-property :FA-ICON headline))
	     (image-src (org-element-property :IMAGE-SRC headline))
	     (image-caption (org-element-property :IMAGE-CAPTION headline))
	     (date (org-time-string-to-time (org-element-property :DATE headline)))
	     (machine-timestamp (format-time-string "%F" date))
	     (readable-timestamp (format-time-string "%F" date))
	     (id (org-html-timeline-linkify raw-headline)))
	(format org-html-timeline-entry-template
		(org-html-timeline-build-data-categories data-categories)
		icon-color
		fa-icon
		machine-timestamp
		readable-timestamp
		id
		id
     		raw-headline
		(org-html-timeline-maybe-insert-image image-src image-caption)
		contents))))

(defun org-html-timeline-section (_ contents _)
  "Transcode SECTION element into HTML-TIMELINE format.
CONTENTS is the section contents.  INFO is a plist used as
a communication channel."
  contents)

;;; Filters

(defun org-html-timeline-final-function (contents _ _)
  "Prettify the HTML-TIMELINE output."
  (with-temp-buffer
    (web-mode)
    (insert contents)
    (indent-region (point-min) (point-max))
    (buffer-substring-no-properties (point-min) (point-max))))

(provide 'ox-html-timeline)

;;; ox-html-timeline.el ends here
