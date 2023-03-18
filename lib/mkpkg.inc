# Global MKPKG definitions for the ADCCDROM package.

$set XFLAGS	= "$(XFLAGS) -p adccdrom"

# Special file lists

$ifeq (MACH, f68881) then
    $include "noao$lib/mkpkg.sf.SUN3"
$else $ifeq (MACH, ffpa) then
    $include "noao$lib/mkpkg.sf.SUN3"
$end
