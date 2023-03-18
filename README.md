		IRAF Tools for Accessing the ADC CDROM

An IRAF external package for accessing many of the 114 catalogs in Volume I
Astronomical Data Center (ADC) CD-ROM collection has been developed.  The
tasks are specific to the text file format disk.  There are two tasks, one
for selecting and printing data from tabular catalogs and one for
extracting spectra to 1D IRAF spectral images.  Below are excerpts from
the help pages.



       CATALOG - extract entries and fields from ADC CD-ROM catalogs

SUMMARY
    This  task  provides  a convenient user interface to Volume 1 of the
    Astronomical  Data  Center   CD-ROM   collection   of   astronomical 
    catalogs.   The text version of the catalogs (as opposed to the FITS
    tables version) is used and must be mounted and appear as  a  normal
    directory.      Note  that  this path may include an IRAF node name
    which then allows access  to  any  machine  available  on  the  IRAF
    network.
    
    The  catalog  to  be accessed is specified by a simple catalog name.
    One goal of this task  is  that  users  need  not  know  the  CD-ROM
    directory  structure  or  the  full file names.  A list of catalogs,
    organized by type of data, may be paged by specifying  '?'  for  the
    catalog  name.   If  '?' is given on the command line the task exits
    after paging the list and if the catalog name  is  queried  one  may
    then  enter  one of the catalog names.  The list of catalogs is also
    included below.
    
    The  purpose  of  this  task  is  to  allow selecting and printing a
    subset of the data in the  designated  catalog.   The  catalogs  are
    tables  having  a  number of entries with each entry having the same
    set of columns or fields.  Thus, one may  select  entries  based  on
    some  function  of  the  fields  and  then select which fields to be
    output.  The fields parameter selects  the  fields  to  be  printed.
    Since  one  doesn't  initially  know  what fields are contained in a
    particular catalog a list of the available fields may  be  paged  by
    entering  '?'.   If  the  parameter is specified on the command line
    then the task exits after listing the fields.  Otherwise  the  query
    is  repeated  to  allow entering the fields.  The fields are entered
    as comma separated names.
    
    To select entries a boolean selection expression is specified.   The
    expression  consists  of  various  operators  applied to the catalog
    fields.  Hence the field names must also be known  here  and  a  '?'
    value  for  the  expression parameter will provide a list of fields.
    The expression syntax is similar to that used in hedit  and  hselect
    and  is described further below.  A typical expression consists of a
    set of equality or  inequality  tests  on  various  fields  combined
    together  by logical ands and ors.  The expression may be taken from
    a file by using  specifying  @<file>  where  file  is  the  filename
    containing the expression.
    
    The output of this task is a readable text table of the field values
    for the  selected  entries.   This  table  may  be  printed  to  the
    terminal,   piped   to  another  task,  redirected  to  a  file,  or 
    explicitly directed to a file.  The output parameter is  either  the
    name  of  the  file  to  which the output is appended or the special
    file name  "STDOUT"  which  refers  to  the  standard  output.   The
    standard  output  is  the  terminal unless redirected on the command
    line to a pipe or file.
    
    Expressions  on  fields  are  not  allowed  in the fields parameter.
    However, it is possible to define special  macro  fields  which  are
    expressions  and then refer to these expressions by name in both the
    fields and expression parameters.  Two such macros, "ra" and  "dec",
    are  automatically defined if the catalog contains fields specifying
    the right ascension hours (RAH), minutes (RAM),  and  seconds  (RAS)
    and  the  declination  degrees  (DecSign  and DecD), minutes (DecM),
    seconds (DecS) separately.  The macros combine these fields  into  a
    single  numeric  field  which may be used for selection and printing
    in sexigesimal notation.
    
EXAMPLE
    1. Use the catalog task to examine the available catalogs, select  a
    catalog,  list  the  fields  of the catalog, and extract a subset of
    entries.
    
        ad> catalog
        Catalog name (? for list): ?
        <List of catalogs>
        Catalog name (? for list): fk4
        Subcatalog name (? for list): ?
        Choose one of the following subcatalogs in fk4:
                data50
                data75
                descript
                polar55
                polar60
                polar65
                polar70
                suppl
        Subcatalog name (? for list) (?): polar70
        Fields to print (? for list): ?
        <List of fields>
        Fields to print (? for list): FK4,ra,dec,Mag,Sptype
        Selection expression (? for list):\
             dec<-85:30 && Mag<7 && evsptype (SpType, "A")
        1663  10:32:53.15 -85:56:08.30  6.74 A0
        1665  13:35:43.58 -85:38:01.92  5.65 A2
         920  15:11:36.63 -88:01:29.54  6.52 A2
         921  16:49:23.73 -86:19:03.43  6.13 A0
        1669  22:31:50.54 -88:58:29.39  6.54 A5



                SPECTRA - extract spectra from ADC CD-ROM

SUMMARY
    This task provides a convenient user interface to  the  catalogs  of
    spectra  contained  in  Volume  1  of  the  Astronomical Data Center
    CD-ROM collection.  The text version of the catalogs (as opposed  to
    the  FITS  tables version) is used and must be mounted and appear as
    a  normal  directory.
    
    The catalog to be accessed is specified by a  simple  catalog  name.
    One  goal  of  this  task  is  that  users  need not know the CD-ROM
    directory structure or the full file names.  A list of  catalogs  is
    paged  by  specifying  '?' for the catalog name.  If '?' is given on
    the command line the task exits after paging the  list  and  if  the
    catalog  name  is  queried  one  may  then  enter one of the catalog
    names.
    
    The purpose of this task is to allow  extracting  a  subset  of  the
    spectra   in  the  designated  catalog  into  one  dimensional  IRAF 
    spectral images.  Each catalog or library of spectra  consist  of  a
    number  of  similar  spectra.  To designate a spectrum or spectra to
    be extracted one specifies a list of  identification  numbers  which
    are  just the order index in the catalog.  To get a directory of the
    spectra with the identification numbers and  titles  enter  '?'  for
    the   spectra  parameter.   If  entered  on  the  command  line  the 
    directory is printed and the task exits.  If entered via a  query  a
    list  of  spectra  may be specfied after viewing the directory list.
    
    The  selected  spectra  are  output as one dimensional IRAF spectral
    images.  The image parameter specifies a root image  name  to  which
    the  spectrum  ID  number  is  appended.   The image header contains
    sufficient  information  to  allow  plotting  and  manipulating  the 
    spectra with the IRAF spectroscopy tasks.
    
    The  flux  scale  differs  among  the spectra.  Some are in absolute
    fluxes,  some  normalized,  and  some  in  magnitudes  of   absolute 
    fluxes.   The  units  are  given below but consult the documentation
    for each catalog for full details.
    
    
                  Available ADC CD-ROM Catalogs of Spectra
    
    iuelda   IUE Low-Dispersion Spectra Reference Atlas. I. Normal Stars
    iueostar IUE Atlas of O-Type Stellar Spectra from 1200 to 1900 A
    spatlasb Stellar Spectrophotometric Atlas 3160-5740 A
    spatlasr Stellar Spectrophotometric Atlas 5760-10620 A
    splib    A Library of Stellar Spectra
    spstd    Spectrophotometric Standards
    uvbs     Ultraviolet Bright Star Spectrophotometric Catalogue
    uvbssupp Supplement to the UV Bright Star Spectrophotometric Cat
    
                                 Flux Units
    
    iuelda   absolute fluxes (ergs/cm^2 s A)
    iueostar normalized fluxes
    spatlasb normalized spectral energy distributions (per unit frequency)
    spatlasr normalized spectral energy distributions (per unit frequency)
    splib    absolute fluxes
    spstd    magnitudes (Hayes-Latham system)
    uvbs     absolute fluxes (erg/cm^2 s A x 10^10)
    uvbssupp absolute fluxes (erg/cm^2 s A)
    
    
EXAMPLES
    1. Use the spectra task to examine the available catalogs, select  a
    catalog, list the contents of the catalog, and extract spectra.
    
        ad> spectra
        Spectrum catalog name (? for list): ?
	<List of catalogs>
        Spectrum catalog name (? for list): splib
        List of spectra to extract (? for list): ?
        Creating directory of adccddir$spectro/splib/splib.dat ...
          1: HD 242908 O5    V
          2: HD 215835 O5.5  V
          3: HD  12993 O6.5  V
          4: HD  35619 O7    V
          5: HD  44811 O7.5  V
        <etc>
        157: HD    108 O6    I
        158: BD+404220 O7    I
        159: HD  13256 B1    I
        160: HD  50064 B1    I
        161: BD+51 710 B5    I
        List of spectra to extract (? for list) (?): 1
        Output spectrum root name: splib
        adccddir$spectro/splib/splib.dat  1: HD 242908 O5 V --> splib.0001
