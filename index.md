---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

title: M17 Protocol Specification
layout: default
---
<div class="w-100 vh-100" id="spec"></div>
<script src="https://unpkg.com/pdfobject@2.2.12/pdfobject.min.js"></script>
<script>
  var options = {
    fallbackLink: "<p>Most mobile browsers do not support inline PDFs. You can either view this page on a desktop/laptop or:<br /><br /><a href='https://spec.m17project.org/pdf/M17_spec.pdf'>Download the Specification</a><br /><br />to view the PDF natively on your device.</p>"
  };
  PDFObject.embed("{{ "/pdf/M17_spec.pdf" | relative_url }}", "#spec", options);
</script>