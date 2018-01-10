;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; RAPTOR-LAUNCHER
;;;; © Michał "phoe" Herda 2017
;;;; loading-screen.lisp

(in-package :raptor-launcher/raptor-picker)
(in-readtable :qtools)

;;; Progress

(define-widget progress (qwidget)
  ((%label-text :accessor label-text
                :initarg :label-text
                :initform "")))

(define-subwidget (progress layout) (q+:make-qvboxlayout)
  (setf (q+:layout progress) layout
        (q+:contents-margins layout) (values 0 4 0 0)))

(define-subwidget (progress label) (q+:make-qlabel)
  (q+:add-widget layout label))

(define-subwidget (progress bar) (q+:make-qprogressbar)
  (q+:add-widget layout bar)
  (setf (q+:text-visible bar) nil
        (q+:range bar) (values 0 0)
        (q+:maximum-height bar) 10))

(defmethod update ((progress progress))
  (with-slots-bound (progress progress)
    (let ((text (format nil "~A: ~D/~D" (label-text progress)
                        (q+:value bar) (q+:maximum bar))))
      (setf (q+:text label) text))))

(defmethod reset ((progress progress))
  (with-slots-bound (progress progress)
    (q+:reset bar)
    (setf (q+:value bar) 0)
    (update progress)))

;;; Loading screen

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *progress-types*
    '(progress-logins progress-accounts progress-furres progress-portraits
      progress-specitags progress-costumes progress-images)))

(deftype progress-type ()
  '#.`(member ,@*progress-types*))

(defmacro define-loading-screen (name (qt-class &rest direct-superclasses)
                                 direct-slots progress-bars &rest options)
  `(define-widget ,name (,qt-class ,@direct-superclasses)
     (,@direct-slots
      ,@(loop for (accessor label-text) in progress-bars
              collect `(,(symbolicate "%" accessor)
                        :accessor ,accessor
                        :initform (make-instance 'progress
                                                 :label-text ,label-text))))
     ,@options))

(define-indentation define-loading-screen (4 4 &rest 2))

(define-loading-screen loading-screen (qwidget)
  ((%module :accessor module :initarg :module))
  ((progress-logins "Accounts logged in")
   (progress-accounts "Accounts downloaded")
   (progress-furres "Furres downloaded")
   (progress-portraits "Portraits downloaded")
   (progress-specitags "Specitags downloaded")
   (progress-costumes "Costumes downloaded")
   (progress-images "Images downloaded")))

(define-subwidget (loading-screen layout) (q+:make-qvboxlayout)
  (setf (q+:layout loading-screen) layout))

(define-subwidget (loading-screen label) (q+:make-qlabel)
  (q+:add-widget layout label 9001))

(define-qt-constructor (loading-screen)
  (q+:add-widget (slot-value (module loading-screen) 'layout) loading-screen)
  (let ((symbols '(progress-logins progress-accounts progress-furres
                   progress-portraits progress-specitags
                   ;; TODO make a variable with valid progress types, AND a type
                   progress-costumes progress-images)))
    (loop for symbol in symbols
          for widget = (funcall symbol loading-screen)
          do (q+:add-widget layout widget)))
  (reset loading-screen))

(defmethod reset ((loading-screen loading-screen))
  ;; TODO fix, this does not reset actually
  (with-slots-bound (loading-screen loading-screen)
    (let ((symbols '(progress-logins progress-accounts progress-furres
                     progress-portraits progress-specitags
                     progress-costumes progress-images)))
      (loop for symbol in symbols
            for widget = (funcall symbol loading-screen)
            do (reset widget)))))

(defmethod maximum ((screen loading-screen) progress-type)
  (check-type progress-type progress-type)
  (let ((progress (funcall progress-type screen)))
    (with-slots-bound (progress progress)
      (q+:maximum bar))))

(defmethod (setf maximum) (new-value (screen loading-screen) progress-type)
  (check-type progress-type progress-type)
  (let ((progress (funcall progress-type screen)))
    (with-slots-bound (progress progress)
      (prog1 (setf (q+:maximum bar) new-value)
        (update progress)))))

(defmethod minimum ((screen loading-screen) progress-type)
  (check-type progress-type progress-type)
  (let ((progress (funcall progress-type screen)))
    (with-slots-bound (progress progress)
      (q+:minimum bar))))

(defmethod (setf minimum) (new-value (screen loading-screen) progress-type)
  (check-type progress-type progress-type)
  (let ((progress (funcall progress-type screen)))
    (with-slots-bound (progress progress)
      (prog1 (setf (q+:minimum bar) new-value)
        (update progress)))))

(defmethod current ((screen loading-screen) progress-type)
  (check-type progress-type progress-type)
  (let ((progress (funcall progress-type screen)))
    (with-slots-bound (progress progress)
      (q+:value bar))))

(defmethod (setf current) (new-value (screen loading-screen) progress-type)
  (check-type progress-type progress-type)
  (let ((progress (funcall progress-type screen)))
    (with-slots-bound (progress progress)
      (prog1 (setf (q+:value bar) new-value)
        (update progress)))))
