(define-module (grand function)
  #:use-module (grand examples)
  #:use-module (grand syntax)
  #:use-module (srfi srfi-1)
  #:export (impose-arity
	    arity
	    clip
	    pass
	    compose/values
	    iterations
	    partial
	    maybe
	    either
	    neither
	    both
	    is
	    isnt)
  #:export-syntax (with-procedure-properties))

(define-syntax (with-procedure-properties ((property value) ...) procedure)
  (let ((target procedure))
    (set-procedure-property! target 'property value)
    ...
    target))

(define (impose-arity n procedure)
  (let ((new-procedure (lambda args (apply procedure args))))
    (set-procedure-property! new-procedure 'name
			     (or (procedure-name procedure)
				 'fixed-arity))
    (set-procedure-property! new-procedure 'imposed-arity
			     (if (list? n) n `(,n 0 #f)))
    new-procedure))

(define (arity procedure)
  ;;(assert (procedure? procedure))
  (or (procedure-property procedure 'imposed-arity)
      (procedure-property procedure 'arity)))

(define (clip args #;to arity)
  (match arity
    ((min _ #f)
     (take args min))
    ((? number?)
     (take args arity))
    (_
     args)))

(define (compose/values . fns)
  (define (make-chain fn chains)
    (impose-arity
     (arity fn)
     (lambda args
       (call-with-values 
	   (lambda () (apply fn args))
	 (lambda vals (apply chains (clip vals (arity chains))))))))
  (let ((composer (reduce make-chain values fns)))
    composer))

(define (iterations n f)
  (apply compose/values (make-list n f)))

(e.g.
 ((iterations 3 1+) 0)
 ===> 3)

(define (pass object #;to . functions)
  ((apply compose/values (reverse functions)) object))

(e.g. (pass 5 #;to 1- #;to sqrt) ===> 2)

(define ((partial function . args) . remaining-args)
  (apply function `(,@args ,@remaining-args)))

#;(assert (lambda (f x)
(if (defined? (f x))
    (equal? (f x) ((partial f) x)))))

(define ((maybe pred) x)
  (or (not x)
      (pred x)))

(e.g.
 (and ((maybe number?) 5)
      ((maybe number?) #f)))

(define ((either . preds) x)
  (any (lambda (pred)
	 (pred x))
       preds))

(define ((neither . preds) x)
  (not ((apply either preds) x)))

(e.g.
 (and ((either number? symbol?) 5)
      ((either number? symbol?) 'x)
      ((neither number? symbol?) "abc")))

(define ((both . preds) x)
  (every (lambda (pred)
	   (pred x))
	 preds))

(e.g.
 (and ((both positive? integer?) 5)
      (not ((both positive? integer?) 4.5))))


(define-syntax infix/postfix ()
  
  ((infix/postfix x somewhat?)
   (somewhat? x))

  ((infix/postfix left related-to? right)
   (related-to? left right))

  ((infix/postfix left related-to? right . likewise)
   (let ((right* right))
     (and (infix/postfix left related-to? right*)
	  (infix/postfix right* . likewise)))))

(define-syntax extract-placeholders (_)
  ((extract-placeholders final () () body)
   (final (infix/postfix . body)))

  ((extract-placeholders final () args body)
   (lambda args (final (infix/postfix . body))))

  ((extract-placeholders final (_ op . rest) (args ...) (body ...))
   (extract-placeholders final rest (args ... arg) (body ... arg op)))

  ((extract-placeholders final (arg op . rest) args (body ...))
   (extract-placeholders final rest args (body ... arg op)))

  ((extract-placeholders final (_) (args ...) (body ...))
   (extract-placeholders final () (args ... arg) (body ... arg)))

  ((extract-placeholders final (arg) args (body ...))
   (extract-placeholders final () args (body ... arg))))

(define-syntax (identity-syntax form)
  form)

(define-syntax (is . something)
  (extract-placeholders identity-syntax something () ()))

(define-syntax (isnt . something)
  (extract-placeholders not something () ()))

(e.g.
 (filter (is 5 < _ <= 10) '(1 3 5 7 9 11))
 ===> (7 9))
