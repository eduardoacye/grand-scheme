(define-module (grand reading)
  #:use-module (ice-9 rdelim)
  #:export (read-s-expressions read-file read-lines print)
  #:re-export (read-line read-delimited))

(define* (read-lines #:optional (port (current-input-port)))
  (let loop ((lines '()))
    (let ((line (read-line port)))
      (if (eof-object? line)
	  (reverse lines)
	  (loop `(,line . ,lines))))))

(define* (read-s-expressions #:optional (port (current-input-port)))
  (let loop ((content '()))
    (let ((datum (read port)))
      (if (eof-object? datum)
	  (reverse content)
	  (loop `(,datum . ,content))))))

(define (read-file filename)
  (read-s-expressions (open-input-file filename)))

(define (print . args)
  (for-each display args)
  (newline)
  (apply values args))
