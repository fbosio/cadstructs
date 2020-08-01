;;;; ActiveX permite manejar bloques din�micos y m�s de un documento a la vez

;;; Cargar extensiones de ActiveX
(VL-LOAD-COM)


;;; Almacenar objetos Application y ActiveDocument en cach�.
;; Esta es la forma de uso recomendada en la documentaci�n de AutoLISP.
;;  Ver AutoLISP Developer's Guide
;;        Using the Visual LISP Environment
;;          Working with ActiveX
;;            Accessing AutoCAD Objects
;;              Performance Considerations.
(SETQ *acad-object* nil)
(DEFUN acad-object ()
  (COND	(*acad-object*)
	(T
	 (SETQ *acad-object* (VLAX-GET-ACAD-OBJECT))
	)
  )
)
(SETQ *active-document* nil)
(DEFUN active-document ()
  (COND	(*active-document*)
	(T
	 (SETQ *active-document* (VLA-GET-ACTIVEDOCUMENT (acad-object)))
	)
  )
)
