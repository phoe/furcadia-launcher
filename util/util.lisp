;;;; util.lisp

(in-package :furcadia-launcher)

(defun cat (&rest strings)
  "Concatenates all strings passed as arguments."
  (apply #'concatenate 'string strings))

(defun trim-whitespace (string)
  "Trims whitespace characters from both sides of a string."
  (let ((whitespace '(#\Space #\Newline #\Backspace #\Tab
                      #\Linefeed #\Page #\Return #\Rubout)))
    (string-trim whitespace string)))

(defun hexadecimal-string-p (string)
  "Returns true if the string contains only digits 0-9 and lowercase characters
a-f, false otherwise."
  (let ((chars '(#\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7
                 #\8 #\9 #\a #\b #\c #\d #\e #\f)))
    (loop for char across string
          unless (member char chars) return nil
            finally (return t))))

(defun sleepcar (function list &optional (n 5) (sleep-interval 1))
  "Collects the element of funcalling FUNCTION on successive elements of LIST,
sleeping for SLEEP-INTERVAL seconds every N elements."
  (loop for elt in list
        for i from 0
        collect (funcall function elt)
        when (zerop (mod (1+ i) n))
          do (sleep sleep-interval)))

(defun fformat (stream format-string &rest format-args)
  "Acts like FORMAT, except it calls FORCE-OUTPUT on STREAM afterwards."
  (apply #'format stream format-string format-args)
  (force-output stream))

(defun replace-all (string part replacement &key (test #'char=))
  "Returns a new string in which all the occurences of the part
is replaced with replacement."
  (with-output-to-string (out)
    (loop with part-length = (length part)
          for old-pos = 0 then (+ pos part-length)
          for pos = (search part string
                            :start2 old-pos
                            :test test)
          do (write-string string out
                           :start old-pos
                           :end (or pos (length string)))
          when pos do (write-string replacement out)
            while pos)))

(defun get-unix-time ()
  "Returns the current Unix timestamp."
  (- (get-universal-time) 2208988800))
