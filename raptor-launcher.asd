;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; RAPTOR-LAUNCHER
;;;; © Michał "phoe" Herda 2017
;;;; raptor-launcher.asd

(asdf:defsystem #:raptor-launcher
  :description "A launcher for Furcadia"
  :author "Michał \"phoe\" Herda <phoe@openmailbox.org>"
  :license "GPLv3"
  :depends-on (:alexandria
               :phoe-toolbox
               :esrap
               :parser.common-rules
               #|
               :ironclad
               :drakma
               :uiop
               :cl-json
               :bordeaux-threads
               :lparallel
               :qtools
               :qtools-evaluator
               :qtcore
               :fare-csv
               :cxml
               :split-sequence
               :static-vectors
               :qtgui
               |#
               )
  :serial t
  :components ((:file "package")
               (:file "util/util")
               (:file "util/witty-lines")
               (:file "util/date-parser")
               #|
               (:file "logger/logger")
               (:file "db/config")
               (:file "db/state")
               (:file "db/cookies")
               (:file "db/nuke")
               (:file "backend/backend-login")
               (:file "backend/backend-fured")
               (:file "backend/backend-furcadia")
               (:file "news/news")
               (:file "worker/worker-general")
               (:file "worker/worker-login")
               (:file "worker/worker-fured")
               (:file "worker/worker-furcadia")
               (:file "algorithm/algorithm")
               (:file "gui/definition")
               (:file "gui/news")
               (:file "gui/config")
               (:file "gui/editor")
               (:file "gui/debug")
               (:file "gui/help")
               (:file "gui/chars")
               (:file "gui/buttons")
               (:file "gui/image")
               (:file "gui/layout")
               (:file "build/build")
               |#
               )
  #|
  :defsystem-depends-on (:qtools)
  :build-operation "qt-program-op"
  :build-pathname "launcher"
  :entry-point "furcadia-launcher-gui:main"
  |#
  )
