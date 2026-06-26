

## ENTRY children and min/max arities:

AUTHOR           0    1
COMMENT          0    1
E-EDITION        0    9 (children are ED and LINK)
INDEX            0   57
INDEXB           0   57
INDEXC           0    1
IPMEP            0    3
JOLLIFFE         0    2
MSLIST           1    1
NOTE             0    3 (may contain a STENCIL)
SEVERS           0   31
STENCILLIST      1    1
TITLE            1    1
WELLS            0    3


## MSLIST children and min/max arities:

MS     1    63

## STENCILLIST children and min/max arities:

MSGROUP  0  63
VARGROUP 0   1

## MSGROUP

STG   1   7

## MSGROUP/STG
EDITION   1    1
REF       0    1
STENCIL   1    1
USE       0    1

## MSGROUP/STG/STENCIL

STENCIL
   ABBR   1    1
   DATE   1    1
   WORK   1    1
     AUTHOR  0   1


## Bib XSLT needed

Note: I was inconsistent in my use of case. All the tags can be uppercase to mirror
what we do elsewhere

### Common

* Turn into`<span class="[tag]">...</span>` the following
  * `EDITION`
  * `DATE`
  * `WORK`
  * `ABBR`
  * `REF`
  * `TITLE`
  * `AUTHOR`
  * `IPMEP`
  * `JOLLIFFE`
  * `WELLS`

### Ignore
* `VARGROUP`

## Special cases
* `NOTE` and `USE` become `<span class="[tag]">Note: ...</span>` (but see more about `USE` below)
* `SEVERS` becomes `<span class="severs">Manual: ...</span>`
* `I` becomes `<span class="HI_I">...</span>` (or whatever you do in the entry stuff)
* `USE` may have embedded `STENCIL` and `NOTE` tags, so we need to apply those templates recursively here
* `E-EDITION/ED` goes to `<span class="edition">...</span>`
  * If there's a `E-EDITION/ED/LINK`, make it `<span class="edition"><a href="the_url">...</a></span>`

In all cases, the calls should be recursive.

### Bib stencil (STG) -- needs to be its own file

Based on receiving an `<STG>` snippet

```xml
    <STG>
      <STENCIL ID="HYP.1.19990513T124835">
        <DATE>c1440(?a1375)</DATE>
        <WORK><I>Abbey HG</I></WORK>
        <ABBR>Thrn</ABBR>
      </STENCIL>
      <EDITION><I>Religious Pieces in Prose and Verse,</I> ed. G. G. Perry, <I>EETS</I> 26 (1867; rev. 1914; reprint 1973).</EDITION>
      <REF>51-62.</REF>
      <USE>Dated ?a1450 in E and F of print MED.</USE>
    </STG>
```
  
becomes

```xml
  <div class="bib stencil-group">  
      <span class="stencil" id="HYP.1.19990513T124835">
        <span class="date">c1440(?a1375)</span>
        <span class="work"><i>Abbey HG</i></span>
        <span class="abbr">Thrn</span>
      </span>
      <span class="edition">
        <i>Religious Pieces in Prose and Verse,</i>
        ed. G. G. Perry,
        <i>EETS</i> 26 (1867; rev. 1914; reprint 1973).
      </span>
      <span class="ref">51-62.</span>
      <span class="use">
        <span class="note-title">Note</span>: Dated ?a1450 in E and F of print MED.
      </span>
  </div>
  
```
  
### Manuscript with embedded stencil -- needs to be its own file

Based on receiving an `<MSGROUP>` snippet

```xml
  <MSGROUP VAR="N">Thrn (Lincoln Cathedral 91)
    <STG>
      <STENCIL ID="HYP.1.19990513T124835"><DATE>c1440(?a1375)</DATE><WORK><I>Abbey HG</I></WORK><ABBR>Thrn</ABBR></STENCIL>
      <EDITION><I>Religious Pieces in Prose and Verse,</I> ed. G. G. Perry, 
        <I>EETS</I> 26 (1867; rev. 1914; reprint 1973).
      </EDITION>
      <REF>51-62.</REF>
      <USE>Dated ?a1450 in E and F of print MED.</USE>
    </STG>
  </MSGROUP>

```

becomes

```xml
<div class="bib msgroup">
  Thrn (Lincoln Cathedral 91)
  <ul class="bib stencil-list">
    <li><!-- same stg as above --></li> <!-- repeat for all stgs -->
  </ul>
</div>
```

_If you can easily do so_:
* Put the initial text (anything before the `<STG>`) into a `<span class="manuscript">`
* If the `<MSGROUP VAR="Y">` attribute is set to 'Y', add a final `<LI>` as
  * `<li class="variant-note">See also Variants below.</li>`
  
Note my use of the word _easily_!!!!

### VARGROUP -- needs to be its own file

The `<VARGROUP>` tag is _ignored_ in the general case, but I'll need to process it separately
for display of the "Variants taken from" (see [Prayer upon the cross](https://quod.lib.umich.edu/cgi/m/mec/hyp-idx?type=byte&byte=3200443))

```xml
<VARGROUP>
    <VARIANT>
      <SOURCE>
        <EDITION><I>The Minor Poems of John Lydgate,</I> ed. H. N. MacCracken, vol. 1, 
          <I>EETSES</I> 107 (1911; reprint 1961).
        </EDITION>
        <REF>fns. pp. 252-54.</REF>
      </SOURCE>
      <SHORTSTENCIL><DATE>a1500</DATE><ABBR>Clg A.2</ABBR></SHORTSTENCIL>
      <SHORTSTENCIL><DATE>a1475</DATE><ABBR>Cmb Hh.4.12:MacCracken</ABBR></SHORTSTENCIL>
      <!-- repeat SHORTSTENCIL -->
    </VARIANT>
    <!-- repeat VARIANT -->
</VARGROUP>
 ```

becomes

```xml

<div class="bib vargroup">
  <div class="variant">
    <span class="source">
      <span class="edition">blah blah blah</span>
      <span class="ref">fns. blah blah</span>
    </span>
    <ul class="stencils">
      <li> <!-- apply STENCIL transform to SHORTSTENCIL tag--></li>
    </ul>
  </div>
</div>

```

