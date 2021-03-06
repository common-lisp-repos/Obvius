(in-package :obvius)

;; Routines translated from Numerical Recipes in C.
;; Each should be functionally identical to the C version.


(defun gammln (xx)
  (if (< xx 1.0)
    (let ((z (- 1.0 xx)))
      (- (log (/ (* pi z) (sin (* pi z))))
         (gammln (+ 1.0 z))))
    (let* ((z   (- xx 1.0))
           (tmp (+ z 5.0 0.5)))
      (+ (* (log tmp) (+ z 0.5))
         (- tmp)
         (log (sqrt (* 2 pi)))
         (log (+ 1.0
                 (/  76.18009173d0   (+ z 1.0d0))
                 (/ -86.50532033d0   (+ z 2.0d0))
                 (/  24.01409822d0   (+ z 3.0d0))
                 (/  -1.231739516d0  (+ z 4.0d0))
                 (/   0.120858003d-2 (+ z 5.0d0))
                 (/  -0.536382d-5    (+ z 6.0d0))))))))

(defun bico (n k)
  (floor (+ 0.5 (exp (- (factln n) (factln k) (factln (- n k)))))))

(defun factln (n)
  (cond ((minusp n) (error "Factorial argument must be nonnegative"))
        ((<= n 1.0) 0.0)
        (t (gammln (+ n 1.0)))))

(defun gammp (a x)
  (cond ((or (< x 0.0) (<= a 0.0)) (error "Invalid arguments"))
	((< x (+ a 1.0)) (gser a x))
	(t (- 1.0 (gcf a x)))))

(defun gammq (a x)
  (cond ((or (< x 0.0) (<= a 0.0)) (error "Invalid arguments"))
	((< x (+ a 1.0)) (- 1.0 (gser a x)))
	(t (gcf a x))))

(defun gcf (a x)
  (let ((gold 0.0)
	(fac 1.0)
	(b1 1.0)
	(b0 0.0)
	(a0 1.0)
	(eps 3.0e-7)
	gln gammcf anf ana an a1 g)
    (declare (float gln anf ana an a1 g gold fac b1 b0 a0 eps))
    (setq gln (gammln a)
	  a1 x)
    (loop for n from 1 below 100
	  until gammcf do
	  (setq an (float n)
                ana (- an a)
                a0 (* (+ a1 (* a0 ana)) fac)
                b0 (* (+ b1 (* b0 ana)) fac)
                anf (* an fac)
                a1 (+ (* x a0) (* anf a1))
                b1 (+ (* x b0) (* anf b1)))
	  (unless (zerop a1)
	    (setq fac (/ a1)
		  g (* b1 fac))
	    (when (< (abs (/ (- g gold) g)) eps)
	      (setq gammcf (* g (exp (+ (- x) (* a (log x)) (- gln))))))
	    (setq gold g)))
    (or gammcf (error "a too large, or too many iterations"))))
 		
(defun gser (a x)
  (let ((eps 3.0e-7)
	sum del ap gamser gln)
    (declare (float eps sum del ap gln))
    (setq gln (gammln a))
    (cond ((minusp x) (error "Negative x not allowed"))
	  ((zerop x) 0.0)
	  (t (setq ap a sum (/ a) del sum)
	     (loop for n from 0 below 100
		   until gamser do
		   (incf ap)
		   (setq del (* del (/ x ap)))
		   (incf sum del)
		   (when (< (abs del) (* (abs sum) eps))
		     (setq gamser (* sum (exp (+ (- x) (* a (log x)) (- gln)))))))
             (or gamser (error "a too large, or too many iterations"))))))

(defun betacf (a b x)
  (declare (float a b x))
  (let* ((eps 3.0e-7)
	 (qab (+ a b))
	 (qap (+ a 1.0))
	 (qam (- a 1.0))
	 (bz  (- 1.0 (/ (* qab x) qap)))
	 (bm  1.0)
	 (az  1.0)
	 (am  1.0))
    (declare (float eps qab qap qam bz bm az am))
    (do ((m 1 (1+ m)))
	((>= m 100)
	 (error "too many iterations"))
      (declare (fixnum m))

      (let* ((em  (float m))
	     (tem (* 2.0 em))
	     (d   (/ (* em (- b em) x)
		     (* (+ qam tem) (+ a tem))))
	     (ap  (+ az (* d am)))	; even step of recurrance
	     (bp  (+ bz (* d bm)))
	     (d   (- (/ (* (+ a em) (+ qab em) x)
			(* (+ qap tem) (+ a tem)))))
	     (app (+ ap (* d az)))	; odd step of recurrance
	     (bpp (+ bp (* d bz))))
	(declare (float em tem d ap bp app bpp))

	(let ((aold az))		; save old answer
	  (declare (float aold))
	  ;; renormalize
	  (setq am (/ ap  bpp))
	  (setq bm (/ bp  bpp))
	  (setq az (/ app bpp))
	  (setq bz 1.0)
	  (if (< (abs (- az aold)) (* EPS (abs az)))
	      (return az))
	  )))
    ))

(defun betai (a b x)
  (declare (float a b x))
  (if (or (< x 0.0) (> x 1.0))
      (error "Bad argument, x=~f" x)
      (let ((bt (if (or (= x 0.0) (= x 1.0))
		    0.0
		    (exp (+ (- (gammln (+ a b))
			       (gammln a)
			       (gammln b))
			    (* a (log x))
			    (* b (log (- 1.0 x))))))))
	(declare (float bt))
	(if (< x (/ (+ a 1.0) (+ a b 2.0)))
	    (* bt (/ (betacf a b x) a))
	    (- 1.0 (/ (* bt (betacf b a (- 1.0 x))) b))))))
