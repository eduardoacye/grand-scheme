(define-module (grand combinatorics)
  #:use-module (srfi srfi-1)
  #:use-module (grand syntax)
  #:use-module (grand list)
  #:use-module (grand examples)
  #:use-module (grand function)
  #:export (multicombinations
	    insertions
	    prefix-insertions
	    n-insertions
	    permutations
	    subsets
	    set-partitions
	    cartesian-product
	    cartesian-power
	    number-compositions
	    number-partitions
	    cycles
	    permute))

(define (multicombinations #;from-set A #;of-length n)
  #;(assert (not (contains-duplicates? A)))
  (cond ((= n 0)
	 '())
	((= n 1)
	 (map list A))
	(else
	 (append-map (lambda (combination)
		       (map (lambda (a)
			      `(,a . ,combination)) A))
		     (multicombinations #;from-set A #;of-length
						   (- n 1))))))

(e.g.
 (multicombinations #;from-set '(a b) #;of-length 3)
 ===>
 ((a a a) (b a a) (a b a) (b b a) (a a b) (b a b) (a b b) (b b b)))


(define (insertions x l)
  (match l
    (()
     `((,x)))
    ((head . tail)
     `((,x ,head . ,tail) . ,(map (lambda (y)
				    `(,head . ,y))
				  (insertions x tail))))))

(e.g.
 (insertions 'a '(x y z))
 ===> ((a x y z) (x a y z) (x y a z) (x y z a)))

(define (prefix-insertions x sequences)
  (append-map (lambda (sequence)
		(let ((prefix suffix (break (lambda (y) (eq? x y)) sequence)))
		  (map (lambda (insertion)
			 `(,@insertion ,@suffix))
		       (insertions x prefix))))
	      sequences))

(e.g.
 (prefix-insertions 'x (insertions 'x '(a b c)))
 ===> ((x x a b c) (x a x b c) (a x x b c) (x a b x c) (a x b x c)
       (a b x x c) (x a b c x) (a x b c x) (a b x c x) (a b c x x)))

(define (n-insertions n x sequences)
  (if (= n 0)
      sequences
      (n-insertions (- n 1) x (prefix-insertions x sequences))))

(e.g.
 (n-insertions 2 'x '((a b c)))
 ===> ((x x a b c) (x a x b c) (a x x b c) (x a b x c) (a x b x c)
       (a b x x c) (x a b c x) (a x b c x) (a b x c x) (a b c x x)))
 
(define (permutations l)
  (match l
    (()
     '(()))
    ((head . tail)
     (append-map (lambda (sub)
		   (insertions head sub))
		 (permutations tail)))))

(e.g.
 (permutations '(a b c))
 ===> ((a b c) (b a c) (b c a) (a c b) (c a b) (c b a)))

(define (subsets l n)
  (cond ((= n 0)
	 '(()))
	((null? l)
	 '())
	(else
	 (let (((first . rest) l))
	   `(,@(map (lambda (next)
		      `(,first . ,next))
		    (subsets rest (- n 1)))
	     ,@(subsets rest n))))))

(e.g. (subsets '(a b c) 2) ===> ((a b) (a c) (b c)))

(define (set-partition-insertions item #;into partitions)
  (append-map (lambda (partition)
		(map (lambda (n)
		       (alter n partition `(,item . ,(list-ref partition n))))
		     (iota (length partition))))
	      partitions))

(e.g.
 (set-partition-insertions 'x '(((a b) (c)) ((a) (b c))))
 ===> (((x a b) (c)) ((a b) (x c)) ((x a) (b c)) ((a) (x b c))))

(define (set-partitions l k)
  (cond ((null? l)
	 '())
	((= (length l) k)
	 `(,(map list l)))
	(else
	 (let (((h . t) l))
	   `(,@(map (lambda (subpartition)
		      `((,h) . ,subpartition))
		    (set-partitions t (- k 1)))
	     ,@(set-partition-insertions h (set-partitions t k)))))))

(e.g.
 (set-partitions '(a b c) 2)
 ===> (((a) (b c)) ((a b) (c)) ((b) (a c))))

(define (cartesian-product . lists)
  (match lists
    (() '())
    ((only) (map list only))
    ((first . rest)
     (append-map (lambda(x)
		   (map (lambda(y) (cons y x))
			first))
		 (apply cartesian-product rest)))))

(e.g.
 (cartesian-product '(a b) '(1 2 3) '(X Y))
 ===> ((a 1 X) (b 1 X) (a 2 X) (b 2 X) (a 3 X) (b 3 X) 
       (a 1 Y) (b 1 Y) (a 2 Y) (b 2 Y) (a 3 Y) (b 3 Y)))

(define (cartesian-power list n)
  (apply cartesian-product (make-list n list)))

(define (number-compositions n k)
  (cond ((or (is n < k) (is k < 0))
	 '())
	((= n k 0)
	 '(()))
	(else
	 (append-map (lambda (i)
		       (map (lambda (completions)
			      `(,(- n i) . ,completions))
			    (number-compositions i (- k 1))))
		     (iota n)))))

(define (number-partitions n k)
  (cond ((or (is n < k) (is k < 0))
	 '())
	((= n k 0)
	 '(()))
	(else
	 (append-map (lambda (i)
		       (filter-map (lambda (completions)
				     (and (isnt (- n i) < k <= i)
					  `(,(- n i) . ,completions)))
			    (number-partitions i (- k 1))))
		     (iota n)))))

(define (cycles #;from source #;to target)

  (define (counterpart #;of element)
    (define (counterpart #;of element #;from source #;in target)
      (let (((suspect . source) source)
	    ((candidate . target) target))
	(if (equal? suspect element)
	    candidate
	    (counterpart #;of element #;from source #;to target))))
    (counterpart #;of element #;from source #;to target))

  (define (cycle #;from element)
    (define (walk #;from element #;into path)
      (if (is element member #;of path)
	  (reverse path)
	  (walk #;from (counterpart #;of element)
		       #;into `(,element . ,path))))
    (walk #;from element #;into '()))

  (reverse
   (fold-left (lambda (cycles current)
		(if (any (lambda (cycle)
			   (is current member #;of cycle))
			 cycles)
		    cycles
		    `(,(cycle #;from current) . ,cycles)))
	      '()
	      source)))

(e.g.
 (cycles #;from '(1 2 3 4 5 6 7 8 9)
		#;to '(6 1 5 4 7 2 8 3 9))
 ===> ((1 6 2) (3 5 7 8) (4) (9)))

(define ((permute #;with cycles) element)
  (let* ((cycle (find (lambda (cycle)
			(is element member #;of cycle))
		      cycles))
	 ((element . next) (find-tail (lambda (item)
					(equal? item element))
				      cycle)))
    (if (null? next)
	(first cycle)
	(first next))))
