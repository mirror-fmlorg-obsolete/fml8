<!-- $FML: fml.dsl,v 1.4 2002/04/01 23:41:08 fukachan Exp $ -->

<!DOCTYPE style-sheet PUBLIC "-//James Clark//DTD DSSSL Style Sheet//EN" [
   <!ENTITY docbook.dsl PUBLIC "-//Norman Walsh//DOCUMENT DocBook HTML Stylesheet//EN" CDATA DSSSL>

<!ENTITY % output.html          "INCLUDE">
<!ENTITY % output.html.images   "INCLUDE">
<!ENTITY % output.print         "IGNORE">
<!ENTITY % output.print.pdf     "IGNORE">

<![ %output.html; [
<!ENTITY docbook.dsl PUBLIC "-//Norman Walsh//DOCUMENT DocBook HTML Stylesheet//EN"
CDATA DSSSL>
]]>
<![ %output.print; [
<!ENTITY docbook.dsl PUBLIC "-//Norman Walsh//DOCUMENT DocBook Print Stylesheet//EN"
 CDATA DSSSL>

]]>

]>

<style-sheet>
  <style-specification use="docbook">
    <style-specification-body>

      <![ %output.html; [

        (define %root-filename%
          ;; Name for the root HTML document
          "index")

        (define %html-ext%
          ;; Default extension for HTML output files
          ".html")

      (define %use-id-as-filename%
          ;; Use ID attributes as name for component HTML files?
          #t)

        (define ($html-body-end$)
          (if (equal? $email-footer$ (normalize ""))
            (empty-sosofo)
            (make sequence
              (if nochunks
                  (make empty-element gi: "hr")
                  (empty-sosofo))
              ($email-footer$))))

	(define ($email-footer$)
          (make sequence
	    (make element gi: "p"
                  attributes: (list (list "align" "center"))
              (make element gi: "small"
                (literal "fml-devel (fml 8.0), fml next generation prototype, homepage is ")
	        (make element gi: "a"
                      attributes:
                      (list (list "href" "http://www.fml.org/software/fml-devel/")
                            (list "target" "_top"))
                  (literal "www.fml.org/software/fml-devel/"))
                (literal "."))

                (make empty-element gi: "br")

              (make element gi: "small"
                (literal "fml 4.0 homepage is ")
	        (make element gi: "a"
                      attributes:
                     (list (list "href" "http://www.fml.org/fml/menu.html")
                            (list "target" "_top"))
                  (literal "www.fml.org/fml/menu.html"))
                (literal "."))

                (make empty-element gi: "br")

              (make element gi: "small"
                (literal "For questions about FML, e-mail <")
                (make element gi: "a"
                      attributes: (list (list "href" "mailto:fml-bugs@fml.org"))
                  (literal "fml-bugs@fml.org"))
	        (literal ">.")))))
      ]]>

    </style-specification-body>
  </style-specification>

  <external-specification id="docbook" document="docbook.dsl">
</style-sheet>
