(in-package :raptor-launcher/raptor-chat)
(in-readtable :qtools)

(define-widget dictionary (qwidget) ())

(define-subwidget (dictionary layout) (q+:make-qgridlayout)
  (setf (q+:layout dictionary) layout
        (q+:contents-margins layout) (values 0 0 0 0)))

(define-subwidget (dictionary browser)
    (make-instance 'browser :dictionary dictionary)
  (q+:add-widget layout browser 0 0 1 2))

(define-subwidget (dictionary input) (q+:make-qlineedit)
  (q+:add-widget layout input 1 0))

(define-subwidget (dictionary button) (make-text-qtoolbutton "Search")
  (q+:add-widget layout button 1 1)
  (setf (q+:focus input) (q+:qt.other-focus-reason)))

(define-slot (dictionary search) ()
  (declare (connected button (clicked)))
  (declare (connected input (return-pressed)))
  (let ((text (q+:text input)))
    (when (string/= "" text)
      (setf text (trim-whitespace text)
            (q+:html browser)
            (htmlize-wordnet (wordnet:wordnet-describe* text)))
      ;; (print (multiple-value-list (wordnet:wordnet-describe* text)))
      )))

(define-slot (dictionary set-focus-from-browser set-focus-from-browser)
             ((old "QWidget*") (new "QWidget*"))
  (declare (connected qt:*qapplication* (focus-changed "QWidget*" "QWidget*")))
  (%set-focus-from-browser dictionary new))

(defmethod set-focus-from-browser ((dictionary dictionary) old (new qobject))
  (%set-focus-from-browser dictionary new))

(defmethod set-focus-from-browser ((dictionary dictionary) old new))

(defun %set-focus-from-browser (dictionary new)
  (with-slots-bound (dictionary dictionary)
    (when (eq new browser)
      (setf (q+:focus input) (q+:qt.other-focus-reason)))))

(defun htmlize-wordnet (results)
  (with-output-to-string (*standard-output*)
    (dolist (result results)
      (destructuring-bind
          (word-or-phrase part-of-speech glossaries synonyms antonyms) result
        (flet ((anchorize (x) (list (substitute #\_ #\Space x) x) ))
          (format t "<h2>~A (~A)</h2>~%" word-or-phrase
                  (string-downcase (string part-of-speech)))
          (format t "<ol>~%")
          (format t "~{  <li>~A</li>~%~}" glossaries)
          (format t "</ol>~%")
          (when synonyms
            (format t "<p>Synonyms: ~{~{~%  <a href=#~A>~A</a>~}~^,~}~%</p>~%"
                    (mapcar #'anchorize synonyms)))
          (when antonyms
            (format t "<p>Antonyms: ~{~{~%  <a href=#~A>~A</a>~}~^,~}~%</p>~%"
                    (mapcar #'anchorize antonyms))))))))

(define-widget browser (qtextbrowser)
  ((clicked-anchor :accessor clicked-anchor :initform "")
   (dictionary :accessor dictionary :initarg :dictionary)))

(define-override (browser mouse-press-event) (event)
  (setf clicked-anchor
        (if (= (enum-value (q+:button event)) (q+:qt.left-button))
            (q+:anchor-at browser (q+:pos event))
            nil))
  (call-next-qmethod))

(define-override (browser mouse-release-event) (event)
  (when (and (= (enum-value (q+:button event)) (q+:qt.left-button))
             (string/= clicked-anchor "")
             (string= clicked-anchor
                      (q+:anchor-at browser (q+:pos event))))
    (let ((text (substitute #\Space #\_ (subseq clicked-anchor 1))))
      (setf (q+:text (slot-value dictionary 'input)) text
            (q+:html browser)
            (htmlize-wordnet (wordnet:wordnet-describe* text)))))
  (call-next-qmethod))
