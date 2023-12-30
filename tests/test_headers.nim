var 
  adoc1 = """= Document Title

This document provides..."""
  ahtml1 = """<div id="header">
<h1>Document Title</h1>
</div>
<div id="content">
<div class="paragraph">
<p>This document provides&#8230;&#8203;</p>
</div>
</div>"""

  adoc2 = """= Document Title
Author Name <author@email.org>; Author Name <author@email.org>

This document provides..."""
  ahtml2 = """<div id="header">
<h1>Document Title</h1>
<div class="details">
<span id="author" class="author">Author Name</span><br>
<span id="email" class="email"><a href="mailto:author@email.org">author@email.org</a></span><br>
<span id="author2" class="author">Author Name</span><br>
<span id="email2" class="email"><a href="mailto:author@email.org">author@email.org</a></span><br>
</div>
</div>
<div id="content">
<div class="paragraph">
<p>This document provides&#8230;&#8203;</p>
</div>
</div>"""

