;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; RAPTOR-LAUNCHER
;;;; © Michał "phoe" Herda 2017
;;;; main-window.lisp

(in-package :raptor-launcher/base)
(in-readtable :qtools)

;;; Class declaration

(define-widget main-window (QMainWindow) ()
  (:documentation "The main window widget for Raptor Launcher.
\
The main window contains a single CENTRAL-WIDGET that is split into two. On the
left we have the LEFT-WIDGET with LEFT-WIDGET-LAYOUT that holds the contents of
the currently loaded module. On the right, we have the RIGHT-WIDGET with
RIGHT-WIDGET-LAYOUT that holds the launcher buttons in BUTTONS-LAYOUT.
\
The BUTTONS-LAYOUT has three types of buttons. The bottommost button is the Quit
button that exits the launcher. The lower buttons are module-specific buttons,
defined by the module itself. The upper buttons are the module selector buttons,
each of which shows the contents of the selected module in the
LEFT-WIDGET-LAYOUT and shows the module-specific buttons."))

(define-subwidget (main-window central-widget) (q+:make-qwidget)
  (setf (q+:central-widget main-window) central-widget))

;;; Module selector

(define-subwidget (main-window module-selector) (q+:make-qwidget))

(define-subwidget (main-window module-selector-layout) (q+:make-qvboxlayout)
  (setf (q+:contents-margins module-selector-layout) (values 0 0 0 0))
  (setf (q+:layout module-selector) module-selector-layout))

;;; Button separator

(define-subwidget (main-window button-separator) (q+:make-qwidget)
  (setf (q+:size-policy button-separator) (values (q+:qsizepolicy.fixed)
                                                  (q+:qsizepolicy.expanding))))

;;; Module buttons

(define-subwidget (main-window module-buttons) (q+:make-qwidget))

(define-subwidget (main-window module-buttons-layout) (q+:make-qvboxlayout)
  (setf (q+:contents-margins module-buttons-layout) (values 0 0 0 0))
  (setf (q+:layout module-buttons) module-buttons-layout))

;;; Quit button

(define-subwidget (main-window main-quit-button) (q+:make-qpushbutton "Quit"))

(define-slot (main-window quit) ()
  (declare (connected main-quit-button (pressed)))
  (q+:close main-window))

;;; Buttons layour

(define-subwidget (main-window buttons-layout) (q+:make-qvboxlayout)
  (q+:add-widget buttons-layout module-selector)
  (q+:add-widget buttons-layout button-separator)
  (q+:add-widget buttons-layout module-buttons)
  (q+:add-widget buttons-layout main-quit-button)
  (setf (q+:contents-margins buttons-layout) (values 0 0 0 0)))

;;; Left main widget (module content)

(define-subwidget (main-window left-widget) (q+:make-qwidget)
  (setf (q+:size-policy left-widget) (values (q+:qsizepolicy.expanding)
                                             (q+:qsizepolicy.expanding))))

(define-subwidget (main-window left-widget-layout) (q+:make-qlayout)
  (setf (q+:contents-margins left-widget-layout) (values 0 0 0 0)))

;;; Right main widget (buttons)

(define-subwidget (main-window right-widget) (q+:make-qwidget)
  (setf (q+:layout right-widget) buttons-layout))

;;; Central layout

(define-subwidget (main-window central-layout) (q+:make-qhboxlayout)
  (q+:add-widget central-layout left-widget)
  (q+:add-widget central-layout right-widget))

;;; Main window constructor

(define-qt-constructor (main-window)
  (let ((title (format nil "Raptor Launcher ~A" *version*)))
    (setf (q+:window-title main-window) title
          (q+:minimum-size main-window) (values 600 600)
          (q+:layout central-widget) central-layout))
  (if (null *loaded-modules*)
      (load-dummy-data main-window)
      (load-modules main-window)))

;;; Logic

(defvar *loaded-modules* '()
  "The list of all Raptor Launcher modules loaded into the Lisp image. Each
module is designated by its respective package designator.
\
Each module is required to provide a compatible interface, in form of the
following protocol:
* Class MAIN-WIDGET that is a QWidget meant to be shown whenever the
  MODULE-SELECTOR button is pressed. This class must subclass the MODULE
  protocol class. There must exist methods specializing on this class for the
  following generic functions:
* Accessor BUTTONS holding a list of QPushButton instances meant to be shown in
  the module buttons layout.
* Accessor MODULE-SELECTOR holding a QPushButton meant to be added to the
  module selector list.")

(defgeneric buttons (object)) ;; TODO turn into protocol

(defgeneric module-selector (object)) ;; TODO turn into protocol

(defun load-module-components (package-designator)
  "Given a package designator that designates a Raptor Launcher module, returns
three values: the main widget of the module, a list of buttons to be shown in
the module buttons layout, and the module selector button."
  (let* ((package (find-package package-designator))
         (symbol (find-symbol (string :main-widget) package))
         (class (find-class symbol))
         (instance (make-instance class))
         (buttons (buttons instance))
         (module-selector (module-selector instance)))
    (values instance buttons module-selector)))

(defun load-dummy-data (main-window)
  (with-slots-bound (main-window main-window)
    (q+:add-widget module-selector-layout (q+:make-qpushbutton "module 1"))
    (q+:add-widget module-selector-layout (q+:make-qpushbutton "module 2"))
    (q+:add-widget module-selector-layout (q+:make-qpushbutton "module 3"))
    (q+:add-widget module-selector-layout (q+:make-qpushbutton "module 4"))
    (q+:add-widget module-selector-layout (q+:make-qpushbutton "module 5"))
    (q+:add-widget module-buttons-layout (q+:make-qpushbutton "button 1"))
    (q+:add-widget module-buttons-layout (q+:make-qpushbutton "button 2"))
    (q+:add-widget module-buttons-layout (q+:make-qpushbutton "button 3"))))

(defun load-modules (main-window)
  (with-slots-bound (main-window main-window)
    (loop for module in *loaded-modules*
          for (main-widget buttons selector)
            = (multiple-value-list (load-module-components module))
          do (q+:add-widget left-widget-layout main-widget)
             (q+:add-widget module-selector-layout selector)
             (dolist (button buttons)
               (q+:add-widget module-buttons-layout button))))
  (hide-all-modules main-window))

(defun show-module (main-window module)
  (hide-all-modules main-window)
  (with-slots-bound (main-window main-window)
    (let ((module (find module *loaded-modules*)))
      (multiple-value-bind (main-widget buttons selector)
          (load-module-components module)
        (declare (ignore selector))
        (q+:show main-widget)
        (dolist (button buttons)
          (q+:show button))))))

(defun hide-all-modules (main-window)
  (with-slots-bound (main-window main-window)
    (loop for module in *loaded-modules*
          for (main-widget buttons selector)
            = (multiple-value-list (load-module-components module))
          do (q+:hide main-widget)
             (dolist (button buttons)
               (q+:hide button)))))
