;;;; worker-login.lisp

(in-package :furcadia-launcher)

(defun make-login-cons (email password)
  "Provided an account, returns a cons, in which CAR is the email and CDR is a
worker thread which executes the login for the provided account."
  ;; TODO handle errors in threads
  (cons email (make-thread (curry #'do-login email password)
                           :name (cat "Login worker for " email))))

(defun make-fured-cons (cons)
  "Provided a cons, whose CAR is email and CDR is a cookie jar, returns a cons,
whose CAR is the email and CDR is a worker thread which fetches the FurEd
page for the provided cookie jar."
  ;; TODO handle errors in threads
  (destructuring-bind (email . cookie-jar) cons
    (cons email (make-thread (curry #'http-get-fured-page cookie-jar)
                             :name (cat "FurEd worker for " email)))))

(defun make-load-character-cons (cons)
  "Provided a cohs, whose CAR is a shortname and CDR is a cookie jar, returns a
cons, whose CAR is the shortname and CDR is a worker thread which loads the
character JSON for the provided shortname and cookie jar."
  (destructuring-bind (sname . cookie-jar) cons
    (cons sname (make-thread (compose #'decode-character
                                      (curry #'http-load-character sname cookie-jar))
                             :name (cat "Load-char worker for " sname)))))

(defun finalize-thread-alist (alist)
  "Provided an alist, in which CDRs are threads, blocks and waits for each
thread to finish before destructively replacing each CDR with the resulting
value of the thread's function."
  ;; We assume that JOIN-THREAD returns the value of the function the thread
  ;; was called with. In the event of BORDEAUX-THREADS being fixed in order
  ;; to provide a documented function that returns the return value of the
  ;; thread by *definition*, not by *accident*, please fix this code to use
  ;; the new function. In the event an implementation does not conform to
  ;; this behaviour, please fix your impleme^W^W^Wcreate a bug on this
  ;; project.
  (flet ((finalize-cdr (cons)
           (setf (cdr cons) (join-thread (cdr cons)))))
    (mapc #'finalize-cdr alist)))

(defun login-all (&optional (config *config*))
  ;; TODO add key unlogged-only
  "Logs in all accounts in the given config in parallel and returns an alist, in
which the keys are the logins and values are the respective cookie jars.
This list is suitable for a call to (SETF STATE-COOKIES) of of any given state
of the launcher."
  (let* ((accounts (getf config :accounts))
         (alist (sleepcar (curry #'apply #'make-login-cons) accounts))
         (values (finalize-thread-alist alist)))
    values))

(defmacro login-allf (&optional (config '*config*) (state '*state*)
                        (state-lock '*state-lock*))
  "Modify macro for LOGIN-ALL that automatically calls SETF STATE-COOKIES on the
provided STATE."
  `(setf (state-cookies ,state ,state-lock) (login-all ,config)))

(defun fetch-all-accounts (&optional (state *state*) (state-lock *state-lock*))
  "Provided a state and a state lock, returns a list of decoded account JSONs."
  (let* ((cookie-alist (state-cookies state state-lock))
         (fured-alist (sleepcar #'make-fured-cons cookie-alist))
         (fured-pages (mapcar #'cdr (finalize-thread-alist fured-alist)))
         (accounts (mapcar #'extract-fured-account-json fured-pages)))
    (dolist (account accounts)
      (assert (assoc :email account)))
    accounts))

(defmacro fetch-all-accountsf (&optional (state '*state*)
                                 (state-lock '*state-lock*))
  "Modify macro for FETCH-ALL-ACCOUNTS that automatically sets SETF
STATE-ACCOUNTS on the provided STATE."
  `(setf (state-accounts ,state ,state-lock)
         (fetch-all-accounts ,state ,state-lock)))

(defun make-email-shortname-alist (account)
  "Provided an account, returns an alist whose CARs are the email bound to that
account and CDRs are successive characters on that "
  (let ((characters (list-characters account))
        (email (cdr (assoc :email account))))
    (mapcar (lambda (x) (cons email x)) characters)))

(defun shortnames-cookies (email-shortname-alist email-cookie-alist)
  "Provided an alist of emails and shortnames and an alist of emails and
cookie jars, returns an alist of shortnames and cookie jars."
  (flet ((construct (x)
           (cons (cdr x)
                 (assoc-value email-cookie-alist (car x) :test #'string=))))
    (mapcar #'construct email-shortname-alist)))

(defun fetch-all-characters (&optional (state *state*)
                               (state-lock *state-lock*))
  "Provided a list of decoded account JSONs, a state and a state-lock, accesses
the accounts stored in the state, fetches all characters on the provided
accounts in parallel and returns an alist, in which CARs are the character
shortnames and CDRs are the decoded character JSONs."
  (let* ((accounts (state-accounts state state-lock))
         (email-shortnames (mapcan #'make-email-shortname-alist accounts))
         (email-cookies (state-cookies state state-lock))
         (shortname-cookies (shortnames-cookies email-shortnames email-cookies))
         (alist (sleepcar #'make-load-character-cons shortname-cookies))
         (character-list (finalize-thread-alist alist)))
    character-list))

(defmacro fetch-all-charactersf (&optional (config '*config*) (state '*state*)
                                   (state-lock '*state-lock*))
  "Modify macro for FETCH-ALL-CHARACTERS which automatically calls
SETF (GETF CONFIG :CHARACTERS) on the provided config."
  ;; TODO write SETF CONFIG-CHARACTERS
  `(setf (getf ,config :characters)
         (fetch-all-characters ,state ,state-lock)))

(defun character-login-link (sname config state state-lock)
  "Provided a shortname, a config, a state and a state lock, returns a furc://
login link for the character with the respective shortname."
  (let* ((character (cdr (assoc sname (getf config :characters)
                                :test #'string=)))
         (accounts (with-lock-held (state-lock) (gethash :accounts state)))
         (email-shortnames (mapcan #'make-email-shortname-alist accounts))
         (email (rassoc-value email-shortnames sname :test #'string=))
         (account (find email accounts :test #'string=
                                       :key (rcurry #'assoc-value :email)))
         (fured-secret (assoc-value account :session))
         (cookie-jar (state-cookie state state-lock email))
         (result (http-save-character character cookie-jar fured-secret)))
    (extract-login-link result)))

(defun furcadia (sname &optional
                         (config *config*) (state *state*)
                         (state-lock *state-lock*))
  "Launches Furcadia for the character with the given shortname."
  (let ((login-link (character-login-link sname config state state-lock))
        (furcadia-path (getf *config* :furcadia-path)))
    (launch-furcadia furcadia-path login-link)))

(defun initialize ()
  "A high-level function for initializing the launcher."
  (note :info "Loading configuration file.")
  (setf *config* (load-config-file))
  (cond ((null (getf *config* :accounts))
         (note :error "Account credentials are not set in config."))
        ((null (getf *config* :furcadia-path))
         (note :error "Furcadia path is not set in config."))
        (t
         (note :info "All clear - beginning initialization.")
         (login-allf)
         (note :info "All ~D accounts logged in successfully."
               (length (state-cookies *state* *state-lock*)))
         (fetch-all-accountsf)
         (note :info "Data for all ~D accounts fetched successfully."
               (length (state-cookies *state* *state-lock*)))
         (fetch-all-charactersf)
         (note :info "All ~D characters fetched successfully."
               (length (getf *config* :characters)))
         (save-config-file)
         (note :info "Config file saved.")
         (note :info "Initialization complete.
Type (furcadia \"shortname\") in the REPL to launch Furcadia.")
         t)))
