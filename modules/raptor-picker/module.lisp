;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; RAPTOR-LAUNCHER
;;;; © Michał "phoe" Herda 2017
;;;; module.lisp

(in-package :raptor-launcher/raptor-picker)
(in-readtable :qtools)

(defvar *character-image-empty* "No Character Image
150x400+
\(click here to add)")

(define-subwidget (raptor-picker image)
    (q+:make-qpushbutton *character-image-empty*)
  (q+:add-widget layout image)
  (setf (q+:minimum-width image) 150
        (q+:maximum-width image) 150
        (q+:flat image) t
        (q+:size-policy image) (values (q+:qsizepolicy.expanding)
                                       (q+:qsizepolicy.expanding))))

(define-subwidget (raptor-picker furre-list) (q+:make-qtablewidget 0 3)
  (q+:add-widget layout furre-list)
  (setf (q+:horizontal-header-labels furre-list)
        '("" "Furre Name" "Last Login")
        (q+:column-width furre-list 0) 24
        (q+:column-width furre-list 1) 180
        (q+:vertical-scroll-mode furre-list)
        (q+:qabstractitemview.scroll-per-pixel)
        (q+:horizontal-scroll-mode furre-list)
        (q+:qabstractitemview.scroll-per-pixel)
        (q+:selection-behavior furre-list)
        (q+:qabstractitemview.select-rows))
  (let ((h-header (q+:horizontal-header furre-list))
        (v-header (q+:vertical-header furre-list)))
    (setf (q+:stretch-last-section h-header) t
          (q+:resize-mode v-header) (q+:qheaderview.fixed)
          (q+:default-section-size v-header) 24
          (q+:sort-indicator h-header 0) (q+:qt.ascending-order))
    (q+:hide v-header))
  (insert-row furre-list "1" "Foobar" "2017-08-01 10:00")
  (insert-row furre-list "2" "Bumblebutt" "2017-07-01 10:00")
  (insert-row furre-list "1" "Oskar Fjötenssën" "2017-09-01 10:00")
  (insert-row furre-list "1" "Hehehehehehe" "2017-08-01 10:00")
  (setf (q+:sorting-enabled furre-list) t))

(defun insert-row (widget s1 s2 s3)
  (let ((count (q+:row-count widget)))
    (q+:insert-row widget count)
    (put-table-text widget s1 count 0)
    (put-table-text widget s2 count 1)
    (put-table-text widget s3 count 2)))

;; TODO turn into SETF TABLE-TEXT
(defun put-table-text (widget text row column)
  (when (null-qobject-p (q+:item widget row column))
    (setf (q+:item widget row column) (q+:make-qtablewidgetitem)))
  (let ((item (q+:item widget row column)))
    (setf (q+:text item) text
          (q+:flags item) (+ (q+:qt.item-is-selectable)
                             (q+:qt.item-is-enabled)))))

(define-subwidget (raptor-picker loading-screen) (q+:make-qwidget)
  (q+:add-widget layout loading-screen)
  (q+:hide loading-screen))
