---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

title: M17 Protocol Specification
layout: default
---
<div class="w-100" id="spec"></div>
<script src="https://unpkg.com/pdfobject@2.2.12/pdfobject.min.js"></script>
<script>PDFObject.embed("{{ "/pdf/M17_spec.pdf" | relative_url }}", "#spec");</script>