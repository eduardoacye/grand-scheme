(define-module (grand combinatorics)
  #:use-module (srfi srfi-1)
  #:use-module (grand syntax)
  #:use-module (grand examples)
  #:export (multicombinations
	    insertions
	    permutations
	    subsets
	    cartesian-product))

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
  (cond
   ((= n 0) '())
   ((= n 1) (map list l))
   ((> n 1)
    (match l
      (() '())
      ((first . rest)
       (append (map (lambda (next) 
		      `(,first . ,next))
		    (subsets rest (1- n)))
	       (subsets rest n)))))))

(e.g. (subsets '(a b c) 2) ===> ((a b) (a c) (b c)))

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