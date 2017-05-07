;;;; image.lisp

(in-package :furcadia-launcher-gui)
(in-readtable :qtools)

(defvar *character-image-dir* "~/.furcadia-launcher/images/"
  "The directory where character images and stored.")

(defvar *character-image-empty* "No Character Image
\(click here to add)")

(define-subwidget (launcher image) (q+:make-qpushbutton *character-image-empty*)
  (setf (q+:minimum-width image) 150
        (q+:maximum-width image) 150
        (q+:flat image) t
        (q+:size-policy image) (values (q+:qsizepolicy.expanding)
                                       (q+:qsizepolicy.expanding))))

(defun image-select-file (widget)
  (q+:qfiledialog-get-open-file-name
   widget "Select image"
   "~" "PNG/JPG Image Files (*.png *.jpg)"))

(define-slot (launcher image-clicked) ()
  (declare (connected image (clicked)))
  (when-let ((sname (selected-character-sname character-list)))
    (let* ((from-path (image-select-file launcher)))
      (when (string/= from-path "")
        (let* ((from-type (pathname-type from-path))
               (filename (cat sname "." (string-downcase from-type)))
               (to-pathname (merge-pathnames filename *character-image-dir*))
               (to-path (princ-to-string to-pathname)))
          (copy-file from-path to-path :finish-output t)
          (note :info "Selected image copied to ~A." filename)
          (signal! launcher (update-image string)))))))

(define-signal (launcher update-image) ())

(define-slot (launcher update-image) ()
  (declare (connected launcher (update-image)))
  (declare (connected character-list (item-selection-changed)))
  (if-let ((path (selected-character-image-path character-list)))
    (let* ((old-icon (q+:icon image))
           (abs-path (princ-to-string (truename path)))
           (pixmap (q+:make-qpixmap abs-path))
           (new-icon (q+:make-qicon pixmap)))
      (setf (q+:text image) ""
            (q+:icon image) new-icon
            (q+:icon-size image) (q+:size (q+:rect pixmap)))
      (when old-icon
        (finalize old-icon)))
    (clear-image image)))

(defun clear-image (image)
  (setf (q+:text image) *character-image-empty*
        (q+:icon image) (q+:make-qicon)))

(defun selected-character-image-path (widget)
  (let ((sname (selected-character-sname widget)))
    (let* ((path-base (cat *character-image-dir* sname))
           (png-path (cat path-base ".png"))
           (jpg-path (cat path-base ".jpg")))
      (cond ((probe-file png-path) png-path)
            ((probe-file jpg-path) jpg-path)
            (t nil)))))
