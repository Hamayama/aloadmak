(define-module moduleB
  (export varB1 varB2 varB3 procB1 procB2 procB3))
(select-module moduleB)

(define varB1 1000)
(define varB2 2000)
(define varB3 3000)
(define (procB1) 10000)
(define (procB2 x) (+ x 20000))
(define (procB3 x y) (* x y 30000))

