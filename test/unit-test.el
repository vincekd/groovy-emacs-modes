(require 'ert)
(require 'shut-up)
(require 'faces)
(require 'groovy-mode)

(ert-deftest groovy-smoke-test ()
  "Ensure that we can activate the Groovy major mode."
  (with-temp-buffer
    (groovy-mode)))


(defmacro should-indent-to (source result)
  "Assert that SOURCE is indented to produce RESULT."
  `(with-temp-buffer
     (insert ,source)
     (groovy-mode)
     (setq indent-tabs-mode nil)
     (shut-up
       (indent-region (point-min) (point-max)))
     (should (equal (buffer-string) ,result))))

(defmacro should-preserve-indent (source)
  "Assert that SOURCE does not change when indented."
  (let ((src-sym (make-symbol "src")))
    `(let ((,src-sym ,source))
       (should-indent-to ,src-sym ,src-sym))))

(ert-deftest groovy-indent-function ()
  "We should indent according to the number of parens."
  (should-indent-to
   "def foo() {
bar()
}"
   "def foo() {
    bar()
}"))

(ert-deftest groovy-indent-infix-operator ()
  "We should increase indent after infix operators."
  (should-preserve-indent
   "def a = b +
    1")
  (should-preserve-indent
   "def a = b+
    1")
  ;; Don't get confused by commented-out lines.
  (should-preserve-indent
   "// def a = b+
1"))

(ert-deftest groovy-indent-infix-closure ()
  "We should only indent by one level inside closures."
  (should-preserve-indent
   "def foo() {
    def f = { ->
        \"foo\"
    }
}"))

(ert-deftest groovy-indent-method-call ()
  "We should increase indent for method calls"
  (should-preserve-indent
   "foo
    .bar()"))

(ert-deftest groovy-indent-switch ()
  "We should indent case statements less than their bodies."
  ;; Simple switch statement
  (should-preserve-indent
   "switch (foo) {
    case Class1:
        bar()
        break
    default:
        baz()
}")
  ;; Braces within switch statements.
  (should-preserve-indent
   "switch (foo) {
    case Class1:
        if (bar) {
            bar()
        }
        break
    default:
        baz()
}")
  ;; Ensure we handle colons correctly.
  (should-preserve-indent
   "switch (foo) {
    case Class1 :
        bar()
}")
  (should-preserve-indent
   "switch (foo) {
    case Class1:
        x? y: z
}")
  )

(defmacro with-highlighted-groovy (src &rest body)
  "Insert SRC in a temporary groovy-mode buffer, apply syntax highlighting,
then run BODY."
  (declare (indent 1) (debug t))
  `(with-temp-buffer
     (insert ,src)
     (goto-char (point-min))
     ;; Activate groovy-mode, but don't run any hooks. This doesn't
     ;; matter on Travis, but is defensive when running tests in the
     ;; current Emacs instance.
     (delay-mode-hooks (groovy-mode))
     ;; Ensure we've syntax-highlighted the whole buffer.
     (font-lock-ensure (point-min) (point-max))
     ,@body))

(ert-deftest groovy-highlight-triple-double-quote ()
  "Ensure we handle single \" correctly inside a triple-double-quoted string."
  (with-highlighted-groovy "x = \"\"\"foo \" bar \"\"\""
    (search-forward "bar")
    (should (eq (face-at-point) 'font-lock-string-face))))

(ert-deftest groovy-highlight-triple-single-quote ()
  "Ensure we handle single \" correctly inside a triple-double-quoted string."
  (with-highlighted-groovy "x = '''foo ' bar '''"
    (search-forward "bar")
    (should (eq (face-at-point) 'font-lock-string-face))))

(defun faces-at-point ()
  (let* ((props (text-properties-at (point)))
         (faces (plist-get props 'face)))
    (if (listp faces) faces (list faces))))

(ert-deftest groovy-highlight-interpolation ()
  "Ensure we highlight interpolation in double-quoted strings."
  (with-highlighted-groovy "x = \"$foo\""
    (search-forward "$")
    (should (memq 'font-lock-variable-name-face (faces-at-point))))
  (with-highlighted-groovy "x = \"\"\"$foo\"\"a\""
    (search-forward "$")
    (should (memq 'font-lock-variable-name-face (faces-at-point)))))

(ert-deftest groovy-highlight-interpolation-single-quotes ()
  "Ensure we do not highlight interpolation in single-quoted strings."
  (with-highlighted-groovy "x = '$foo'"
    (search-forward "$")
    ;; This should be highlighted as a string, nothing else.
    (should (equal '(font-lock-string-face) (faces-at-point))))
  (with-highlighted-groovy "x = '''$foo'''"
    (search-forward "$")
    (should (equal '(font-lock-string-face) (faces-at-point)))))

(ert-deftest groovy-highlight-comments ()
  "Ensure we do not confuse comments with slashy strings."
  (with-highlighted-groovy "// foo"
    (search-forward " ")
    (should (memq 'font-lock-comment-face (faces-at-point))))
  ;; // on a single line is a comment, not an empty slashy-string.
  (with-highlighted-groovy "// foo\n//\n"
    (search-forward "\n")
    (should (memq 'font-lock-comment-face (faces-at-point)))))

(ert-deftest groovy-highlight-slashy-string ()
  "Highlight /foo/ as a string."
  (with-highlighted-groovy "x = /foo/"
    (search-forward "foo")
    (should (memq 'font-lock-string-face (faces-at-point)))))
