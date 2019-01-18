;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; RAPTOR-LAUNCHER
;;;; © Michał "phoe" Herda 2017
;;;; package.lisp

(defpackage #:raptor-launcher/base
  (:use #:cl+qt
        #:alexandria
        #:phoe-toolbox
        #:static-vectors
        #:protest
        #:raptor-launcher/util
        #:raptor-launcher/protocol)
  (:shadowing-import-from #:phoe-toolbox #:split)
  (:export
   ;; utils
   #:table-text
   #:make-text-qtoolbutton
   #:with-qimage-from-vector
   ;; main window class
   #:raptor-launcher
   ;; signal names
   #:selected #:pressed))
