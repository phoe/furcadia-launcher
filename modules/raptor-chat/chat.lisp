;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; RAPTOR-LAUNCHER
;;;; © Michał "phoe" Herda 2017
;;;; chat.lisp

(in-package :raptor-launcher/raptor-chat)
(in-readtable :qtools)

(define-widget chat-window (qwidget) ())

(define-subwidget (chat-window layout) (q+:make-qgridlayout)
  (setf (q+:layout chat-window) layout))

;;; Bottom row

(define-subwidget (chat-window image-left) (q+:make-qlabel)
  (q+:add-widget layout image-left 1 0)
  (setf (q+:pixmap image-left)
        (q+:make-qpixmap
         (uiop:native-namestring
          (merge-pathnames "Projects/Raptor Chat/undies.png"
                           (user-homedir-pathname))))))

(define-subwidget (chat-window splitter)
    (q+:make-qsplitter (q+:qt.horizontal))
  (q+:add-widget layout splitter 1 1))

(define-subwidget (chat-window image-right) (q+:make-qlabel)
  (q+:add-widget layout image-right 1 2)
  (setf (q+:pixmap image-right)
        (q+:make-qpixmap
         (uiop:native-namestring
          (merge-pathnames "Projects/Raptor Chat/sha.png"
                           (user-homedir-pathname))))))

;;; IC/OOC/WIDGETS

(define-subwidget (chat-window ic) (q+:make-qsplitter (q+:qt.vertical))
  (q+:add-widget splitter ic)
  (setf (q+:minimum-width ic) 100
        (q+:children-collapsible ic) nil
        (q+:stretch-factor splitter 0) 2))

(define-subwidget (chat-window ooc) (q+:make-qsplitter (q+:qt.vertical))
  (q+:add-widget splitter ooc)
  (setf (q+:minimum-width ooc) 100
        (q+:children-collapsible ooc) nil
        (q+:stretch-factor splitter 1) 1))

(define-subwidget (chat-window ic-output)
    (make-placeholder-text-edit "No IC chat yet." 1.25)
  (q+:add-widget ic ic-output)
  (setf (q+:read-only ic-output) t
        (q+:minimum-height ic-output) 100
        (q+:stretch-factor ic 0) 3)
  (setf (q+:html ic-output)
        (read-file-into-string
         "~/Projects/Raptor Chat/ic.txt")))

(define-subwidget (chat-window ic-input)
    (make-placeholder-text-edit "Type your IC here!")
  (q+:add-widget ic ic-input)
  (setf (q+:minimum-height ic-input) 100
        (q+:stretch-factor ic 1) 1
        (q+:text ic-input)
        "Hello world! This, as yyou can see, jjkhdssdfs ain't no joke."))

(define-subwidget (chat-window ooc-output)
    (make-placeholder-text-edit "[No OOC chat yet.]" 1.25)
  (q+:add-widget ooc ooc-output)
  (setf (q+:read-only ooc-output) t
        (q+:minimum-height ooc-output) 100
        (q+:stretch-factor ooc 0) 3)
  (setf (q+:html ooc-output)
        (read-file-into-string
         "~/Projects/Raptor Chat/ooc.txt")))

(define-subwidget (chat-window ooc-input)
    (make-placeholder-text-edit "[Type your OOC here!]")
  (q+:add-widget ooc ooc-input)
  (setf (q+:minimum-height ooc-input) 100
        (q+:stretch-factor ooc 1) 1))

(define-subwidget (chat-window dictionary) (make-instance 'dictionary)
  (q+:add-widget splitter dictionary)
  (setf (q+:stretch-factor splitter 1) 1)
  (q+:hide dictionary))

(define-subwidget (chat-window description-left)
    (make-instance 'placeholder-text-edit)
  (q+:add-widget splitter description-left)
  (setf (q+:stretch-factor splitter 2) 1)
  (q+:hide description-left)
  (setf (q+:html description-left)
        (format nil "<h1>Undies</h1>~%~A"
                (read-file-into-string "~/Projects/Raptor Chat/undies.txt"))))

(define-subwidget (chat-window description-right)
    (make-instance 'placeholder-text-edit)
  (q+:add-widget splitter description-right)
  (setf (q+:stretch-factor splitter 3) 1
        (q+:stretch-factor splitter 4) 1)
  (q+:hide description-right)
  (setf (q+:html description-right)
        (format nil "<h1>Sashasa</h1>~%~A"
                (read-file-into-string "~/Projects/Raptor Chat/sha.txt"))))

;;; PLACEHOLDER-TEXT-EDIT

(define-widget placeholder-text-edit (qtextedit)
  ((placeholder :accessor placeholder :initarg :placeholder)
   (font :accessor font :initarg :font))
  (:default-initargs :placeholder "" :font (q+:make-qfont)))

(defmethod initialize-instance :after
    ((object placeholder-text-edit) &key font-size)
  (let* ((palette (q+:palette object))
         (color (q+:color palette (q+:background-role object))))
    (when (and (< (q+:red color) 80)
               (< (q+:blue color) 80)
               (< (q+:green color) 80))
      (setf (q+:default-style-sheet (q+:document object))
            "a { color: #8888ff; }")))
  (with-accessors ((font font)) object
    (setf (q+:italic font) t)
    (when font-size
      (setf (q+:point-size-f font)
            (* font-size (q+:point-size-f font))))))

(define-override (placeholder-text-edit paint-event) (ev)
  (when (string= "" (q+:to-plain-text placeholder-text-edit))
    (let ((viewport (q+:viewport placeholder-text-edit)))
      (with-finalizing ((painter (q+:make-qpainter viewport)))
        (let* ((color (q+:color (q+:brush (q+:pen painter))))
               (old-font (q+:font painter)))
          (setf (q+:alpha color) 80
                (q+:font painter) font)
          (q+:draw-text painter (q+:rect placeholder-text-edit)
                        (logior (q+:qt.text-word-wrap)
                                (q+:qt.align-center))
                        (placeholder placeholder-text-edit))
          (setf (q+:alpha color) 255
                (q+:font painter) old-font)))))
  (call-next-qmethod))

(define-widget placechecked-text-edit
      (qtextedit placeholder-text-edit spellchecked-text-edit) ())

(defun make-placeholder-text-edit (placeholder &optional font-size)
  (make-instance 'placechecked-text-edit :placeholder placeholder
                                         :font-size font-size))

;;; BUTTONS

;;; Upper row

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun forms-subwidgets (forms)
    (loop for tail in (mapcar #'cddr forms)
          for subwidget = (getf tail :subwidget)
          when subwidget collect it))
  (defun make-button (widget name string
                      &key checkable (layout 'buttons-layout) default init-forms
                      &allow-other-keys)
    `(define-subwidget (,widget ,name) (make-chat-button ,string)
       ,@(when layout `((q+:add-widget ,layout ,name)))
       ,@(when checkable `((setf (q+:checkable ,name) t)))
       ,@(when default `((setf (q+:checked ,name) t)))
       ,@init-forms))
  (defun make-slot (widget name string &key subwidget &allow-other-keys)
    (declare (ignore string))
    (let ((slot-name (symbolicate name "-CLICKED"))
          (state (gensym)) (symbol (gensym)))
      `(define-slot (,widget ,slot-name) ()
         (declare (connected ,name (clicked)))
         (let ((,state (q+:save-state splitter)))
           (dolist (,symbol *right-chat-widgets*)
             (q+:hide (slot-value ,widget ,symbol)))
           (q+:show ,subwidget)
           (q+:insert-widget splitter 1 ,subwidget)
           (dolist (,symbol *right-chat-buttons*)
             (setf (q+:checked (slot-value ,widget ,symbol)) nil))
           (setf (q+:checked ,name) t)
           (q+:restore-state splitter ,state))))))

(define-subwidget (chat-window buttons-layout) (q+:make-qhboxlayout)
  (q+:add-layout layout buttons-layout 0 1))

(defun make-chat-button (string)
  (let ((button (make-text-qtoolbutton string))
        (font (q+:make-qfont)))
    (setf (q+:point-size font) 8
          (q+:font button) font)
    button))

#|
(define-subwidget (chat-window description-button-left)
    (make-chat-button "Description")
  (q+:add-widget layout description-button-left 0 0))

(define-subwidget (chat-window description-button-right)
    (make-chat-button "Description")
  (q+:add-widget layout description-button-right 0 2))
|#

(defmacro define-chat-buttons
    (widget (far-left-button) left-buttons right-buttons (far-right-button))
  `(progn
     ,@(mapcar (curry #'apply #'make-button widget) left-buttons)
     (define-subwidget (,widget buttons-stretch)
         (q+:add-stretch buttons-layout 9001))
     ,@(mapcar (curry #'apply #'make-button widget) right-buttons)
     (defparameter *right-chat-buttons*
       ',(list* (car far-left-button)
                (car far-right-button)
                (mapcar #'car right-buttons)))
     (defparameter *right-chat-widgets*
       ',(list* 'description-left
                'description-right
                (forms-subwidgets right-buttons)))
     ,@(mapcar (curry #'apply #'make-slot widget) right-buttons)
     ,(apply #'make-button widget far-left-button)
     ,(apply #'make-slot widget far-left-button)
     ,(apply #'make-button widget far-right-button)
     ,(apply #'make-slot widget far-right-button)))

(trivial-indent:define-indentation define-chat-buttons (4 2 2))

(define-chat-buttons chat-window
  ((description-button-left
    "Description"
    :layout nil :checkable t
    :subwidget description-left
    :init-forms
    ((q+:add-widget layout description-button-left 0 0))))
  ((timestamps-button "Timestamps" :checkable t)
   (names-button "Names" :checkable t)
   (mark-read-button "Mark Read")
   (logs-button "Logs")
   (justify-button "Justify" :checkable t)
   (spellchecker-button "Spelling"))
  ((ooc-button "OOC" :checkable t :subwidget ooc :default t)
   (dictionary-button "Dictionary" :checkable t :subwidget dictionary))
  ((description-button-right
    "Description"
    :layout nil :checkable t
    :subwidget description-right
    :init-forms
    ((q+:add-widget layout description-button-right 0 2 (q+:qt.align-right))))))

(define-slot (chat-window dictionary-text-selection) ()
  (declare (connected ic-input (selection-changed)))
  (with-finalizing ((cursor (q+:text-cursor ic-input)))
    (when (q+:is-visible dictionary)
      (let ((selection (q+:selected-text cursor)))
        (when (string/= selection "")
          (setf (q+:text (slot-value dictionary 'input)) selection))))))

;; TODO hyperlink style
;; TODO descriptions

(defun chat ()
  (with-main-window (chat-window 'chat-window)))
