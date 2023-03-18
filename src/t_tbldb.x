include <ctotok.h>
include	<ctype.h>
include	<error.h>
include	<fset.h>
include	"fvexpr.h"

define	LEN_TBL		329		# Length of main table structure
define	LEN_TFIELD	77		# Length of table field structure
define	SZ_TLINE	79		# Length of table strings
define	SZ_TNAME	19		# Table name lengths

# Main table structure
define	THDR	Memc[P2C($1)]		# Table header file
define	TDATA	Memc[P2C($1+40)]	# Table data file
define	TFNC	Memc[P2C($1+80)]	# Table macro file
define	TUFNC	Memc[P2C($1+120)]	# Table user macro file
define	TEXTNAM	Memc[P2C($1+160)]	# Table name
define	TAUTHOR	Memc[P2C($1+200)]	# Table author
define	TREF	Memc[P2C($1+240)]	# Table reference
define	TSTR	Memc[P2C($1+280)]	# Table working string
define	TEXTVER	Memi[$1+320]		# Table version
define	TNAXIS1	Memi[$1+321]		# Number of chars per record
define	TNAXIS2	Memi[$1+322]		# Number of records
define	TNMACRO	Memi[$1+323]		# Number of macros
define	TMACRO	Memi[$1+324]		# Pointer to field structures
define	TNFIELD	Memi[$1+325]		# Number of fields
define	TFIELD	Memi[$1+326]		# Pointer to field structures
define	TSTP	Memi[$1+327]		# Symbol table of called fields
define	TREC	Memi[$1+328]		# Pointer to data record char buffer

# Table field structures
define	TNAME	Memc[P2C($1)]		# Field name
define	TFORM	Memc[P2C($1+10)]	# Table format
define	TFSPP	Memc[P2C($1+20)]	# SPP format
define	TEXPR	Memc[P2C($1+30)]	# Expression or comment
define	TEVP	Memi[$1+71]		# Expression evaluation pointer
define	TNCOL	Memi[$1+72]		# Number of columns (0 if macro)
define	TBCOL	Memi[$1+73]		# Beginning column
define	TDECP	Memi[$1+74]		# Decimal point
define	TSCAL	Memr[P2R($1+75)]	# Scale factor
define	TZERO	Memr[P2R($1+76)]	# Zero offset

define	THDRP	(P2C($1))		# Pointer to header file string
define	TDATAP	(P2C($1+40))		# Pointer to data file string
define	TTPTR	(P2C($1))		# Pointer to name string

define	NALLOC	10			# Allocation block
define	NSUBCAT	25			# Maximum number of subcatalogs
define	SZ_EXPR	1024			# Length of expression string


# T_CATALOG -- Catalog task
#
# This task accesses an ADC CD-ROM text table as a database.  It allows
# auxilary macros of fields, selection expressions on fields, and prints
# selected fields.

procedure t_catalog ()

pointer	catdir				# Catalog directory
pointer	catalog				# Catalog name
pointer	subcat[NSUBCAT]			# Subcatalog name
pointer	macro[NSUBCAT]			# Macro name
pointer	expr				# Selection expression
pointer	fields				# Fields to print
pointer	output				# Output file name

int	i, j, k, l, fd
pointer	sp, field, str, tbl, tf, te

bool	streq()
int	ctotok(), open(), fscan(), nscan(), errcode()
pointer	stopen()
errchk	open, tbl_ghdr, tbl_gmacro, tbl_gfield, tbl_read

common	/tblcom/ tbl

define	done_	10

begin
	call smark (sp)
	call salloc (catdir, SZ_FNAME, TY_CHAR)
	call salloc (catalog, SZ_FNAME, TY_CHAR)
	call salloc (subcat[1], SZ_FNAME, TY_CHAR)
	call salloc (macro[1], SZ_FNAME, TY_CHAR)
	call malloc (expr, SZ_EXPR, TY_CHAR)
	call salloc (fields, SZ_LINE, TY_CHAR)
	call salloc (output, SZ_FNAME, TY_CHAR)
	call salloc (field, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)
	call calloc (tbl, LEN_TBL, TY_STRUCT)
	   
	iferr {
	    # Set CD-ROM root directory
	    call strcpy ("adccddir$", THDR(tbl), SZ_TLINE)
	    call strcpy ("adccddir$", TDATA(tbl), SZ_TLINE)

	    # Determine catalog
	    call strcpy ("#", Memc[str], SZ_LINE)
	    repeat {
		call clgstr ("catalog", Memc[catalog], SZ_LINE)
		if (streq (Memc[catalog], Memc[str]))
		    goto done_
		call strcpy (Memc[catalog], Memc[str], SZ_LINE)

		i = 1
		fd = open ("adccdrom$catalogs.dat", READ_ONLY, TEXT_FILE)
		while (fscan (fd) != EOF) {
		    call gargwrd (Memc[expr], SZ_FNAME)
		    call gargwrd (Memc[fields], SZ_FNAME)
		    call gargwrd (Memc[subcat[i]], SZ_FNAME)
		    call gargwrd (Memc[macro[i]], SZ_FNAME)
		    if (streq (Memc[catalog], Memc[fields])) {
			i = i + 1
			if (i > NSUBCAT) {
			    call close (fd)
			    call error (1, "Too many subcatalogs")
			}
			call strcpy (Memc[expr], Memc[catdir], SZ_FNAME)
			if (nscan() == 3)
			    Memc[macro[i-1]] = EOS
			call salloc (subcat[i], SZ_FNAME, TY_CHAR)
			call salloc (macro[i], SZ_FNAME, TY_CHAR)
		    }
		}
		call close (fd)
		i = i - 1

		if (i == 0)
		    call pagefile ("adccdrom$catalogs.men",
			"ADC CD-ROM Catalogs")
	    } until (i > 0)

	    call strcat (Memc[catdir], THDR(tbl), SZ_TLINE)
	    call strcat ("/", THDR(tbl), SZ_TLINE)
	    call strcat (Memc[catalog], THDR(tbl), SZ_TLINE)
	    call strcat ("/", THDR(tbl), SZ_TLINE)
	    call strcat (Memc[catdir], TDATA(tbl), SZ_TLINE)
	    call strcat ("/", TDATA(tbl), SZ_TLINE)
	    call strcat (Memc[catalog], TDATA(tbl), SZ_TLINE)
	    call strcat ("/", TDATA(tbl), SZ_TLINE)

	    # If there is more than one entry select a subcatalog.
	    # If no subcatalog is found page the choices and try again.

	    if (i == 1) {
		j = 1
		call strcpy (Memc[subcat[j]], Memc[catalog], SZ_LINE)
	    } else {
		call strcpy (Memc[catalog], Memc[catdir], SZ_FNAME)
		call strcpy ("#", Memc[str], SZ_LINE)
		repeat {
		    call clgstr ("subcatalog", Memc[catalog], SZ_LINE)
		    if (streq (Memc[catalog], Memc[str]))
			goto done_
		    call strcpy (Memc[catalog], Memc[str], SZ_LINE)

		    do j = 1, i {
			if (streq (Memc[catalog], Memc[subcat[j]]))
			    break
		    }

		    if (j > i) {
			call printf (
			    "Choose one of the following subcatalogs in %s:\n")
			    call pargstr (Memc[catdir])
			do j = 1, i {
			    call printf ("\t%s\n")
				call pargstr (Memc[subcat[j]])
			}
		    }
		} until (j <= i)
	    }

	    call strcat (Memc[catalog], THDR(tbl), SZ_TLINE)
	    call strcat (".hdr", THDR(tbl), SZ_TLINE)
	    call strcat (Memc[catalog], TDATA(tbl), SZ_TLINE)
	    call strcat (".dat", TDATA(tbl), SZ_TLINE)

	    if (Memc[macro[j]] != EOS) {
		call strcpy ("adccdrom$", TFNC(tbl), SZ_TLINE)
		call strcat (Memc[macro[j]], TFNC(tbl), SZ_TLINE)
	    }
	    call clgstr ("macros", TUFNC(tbl), SZ_TLINE)

	    # Read header and macro files
	    call tbl_ghdr (tbl)
	    TSTP(tbl) = stopen ("tblstp", TNFIELD(tbl), TNFIELD(tbl),
		TNFIELD(tbl)*10)
	    call tbl_gmacro (tbl)

	    # Get the fields to print
	    call strcpy ("#", Memc[str], SZ_LINE)
	    repeat {
		call clgstr ("fields", Memc[fields], SZ_LINE)
		if (streq (Memc[fields], Memc[str]))
		    goto done_
		call strcpy (Memc[fields], Memc[str], SZ_LINE)

		i = 1
		j = 0
		k = 0
		repeat {
		    l = ctotok (Memc[fields], i, Memc[field], SZ_LINE)
		    if (l == TOK_IDENTIFIER) {
			j = j + 1
			if (streq (Memc[field], "all"))
			    next
			iferr (call tbl_gfield (tbl, Memc[field], YES, tf,te)) {
			    k = k + 1
			    call erract (EA_WARN)
			}
		    }
		} until (l == TOK_EOS)

		if (k > 0)
		    j = 0
		   
		if (j == 0 && k == 0)
		    call tbl_flist (tbl)

	    } until (j > 0)

	    if (j > 0) {
	        # Open the output for appending
		call clgstr ("output", Memc[output], SZ_FNAME)
		fd = open (Memc[output], APPEND, TEXT_FILE)

		call strcpy ("#", Memc[str], SZ_LINE)
		repeat {
		    # Get the expression and list fields if needed.
		    call clgstr ("expression", Memc[expr], SZ_EXPR)
		    if (streq (Memc[expr], Memc[str]))
			goto done_
		    call strcpy (Memc[expr], Memc[str], SZ_LINE)

		    if (Memc[expr] == '?') {
			call tbl_flist (tbl)
			next
		    }

		    # Now read the catalog.
		    ifnoerr (call tbl_read (tbl, expr, Memc[fields],
			Memc[field], fd))
			break

		    call erract (EA_WARN)
		    if (errcode() != 1)
			break
		}

		call close (fd)
	    }
done_	    i = 0
	} then
	    call erract (EA_WARN)
	    
	call mfree (expr, TY_CHAR)
	call tbl_free (tbl)
	call sfree (sp)
end


# T_TBLDB -- Table database task
#
# This task accesses an ADC CD-ROM text table as a database.  It allows
# auxilary macros of fields, selection expressions on fields, and prints
# selected fields.  This is a simpler interface which requires full
# file names.  It may be used on any table file which is in the same text
# format as the ADC text tables.

procedure t_tbldb ()

pointer	expr				# Selection expression
pointer	fields				# Fields to print
pointer	output				# Output file

int	i, j, k, nfields, fd
pointer	sp, field, str, tbl, tf, te

bool	streq()
int	ctotok(), open
pointer	stopen()
errchk	tbl_ghdr, tbl_gmacro, tbl_gfield, tbl_read, open

common	/tblcom/ tbl

define	done_	10

begin
	call smark (sp)
	call salloc (expr, SZ_EXPR, TY_CHAR)
	call malloc (fields, SZ_LINE, TY_CHAR)
	call salloc (output, SZ_FNAME, TY_CHAR)
	call salloc (field, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)
	call calloc (tbl, LEN_TBL, TY_STRUCT)
	   
	iferr {
	    # Read header and macro files
	    call clgstr ("header", THDR(tbl), SZ_TLINE)
	    call tbl_ghdr (tbl)
	    TSTP(tbl) = stopen ("tblstp", TNFIELD(tbl), TNFIELD(tbl),
		TNFIELD(tbl)*10)
	    call clgstr ("macros", TMACRO(tbl), SZ_TLINE)
	    call tbl_gmacro (tbl)
	    call clgstr ("data", TDATA(tbl), SZ_TLINE)

	    # Get the fields to print.  Print a list of fields if desired.
	    call strcpy ("#", Memc[str], SZ_LINE)
	    repeat {
		call clgstr ("fields", Memc[fields], SZ_LINE)
		if (streq (Memc[fields], Memc[str]))
		    break
		call strcpy (Memc[fields], Memc[str], SZ_LINE)

		nfields = 0
		i = 1
		j = 0
		repeat {
		    k = ctotok (Memc[fields], i, Memc[field], SZ_LINE)
		    if (k == TOK_IDENTIFIER) {
			nfields = nfields + 1
			if (streq (Memc[field], "all"))
			    next
			iferr (call tbl_gfield (tbl, Memc[field], YES,tf,te)) {
			    j = j + 1
			    call erract (EA_WARN)
			}
		    }
		} until (k == TOK_EOS)

		if (j > 0)
		    nfields = 0

		if (nfields == 0)
		    call tbl_flist (tbl)

	    } until (nfields > 0)

	    # Get the reset of the input parameters and read the catalog.
	    if (nfields > 0) {
		call clgstr ("expression", Memc[expr], SZ_EXPR)
		call clgstr ("data", TDATA(tbl), SZ_TLINE)
		call clgstr ("output", Memc[output], SZ_FNAME)
		fd = open (Memc[output], APPEND, TEXT_FILE)
		call tbl_read (tbl, expr, Memc[fields], Memc[field], fd)
		call close (fd)
	    }
done_	    i = 0
	} then
	    call erract (EA_WARN)
	    
	call mfree (expr, TY_CHAR)
	call tbl_free (tbl)
	call sfree (sp)
end


# TBL_READ -- Read the database, select fields, and print fields.

procedure tbl_read (tbl, expr, fields, field, out)

pointer	tbl				# Table structure
pointer	expr				# Selection expression
char	fields[ARB]			# Fields to print
char	field[ARB]			# Field
int	out				# Output file descriptor

int	i, j, k, fd, reclen, stat, entry, selected
pointer	tf, te, o, rec

int	open(), getline(), read(), locpr(), ctotok(), fstati()
pointer	fvexpr()
extern	tbl_gop(), tbl_fcn()
errchk	open, tbl_gval, fvexpr

begin
	# Set the selection expression which may be defined in a file.
	for (i=expr; IS_WHITE(Memc[i]); i=i+1)
	    ;
	if (Memc[i] == EOS)
	    call strcpy ("yes", Memc[expr], SZ_EXPR)
	else if (Memc[i] == '@') {
	    fd = open (Memc[i+1], READ_ONLY, TEXT_FILE)
	    Memc[expr] = EOS
	    j = 0
	    k = SZ_EXPR
	    repeat {
		i = getline (fd, field)
		if (i == EOF)
		    break
		field[i] = EOS
		i = j + i - 1
		if (i > k) {
		    k = i + SZ_EXPR
		    call realloc (expr, k, TY_CHAR)
		}
		call strcpy (field, Memc[expr+j], ARB)
		j = i
	    }
	    call close (fd)
	}

	# Set a stat flag to define whether a status output is printed.
	stat = YES
	if (out == STDOUT) {
	    stat = fstati (out, F_REDIR)
	    if (stat == NO)
		call fseti (out, F_FLUSHNL, YES)
	}

	# Read through the data
	iferr (fd = open (TDATA(tbl), READ_ONLY, TEXT_FILE)) {
	    call strupr (Memc[TDATAP(tbl)+9])
	    fd = open (TDATA(tbl), READ_ONLY, TEXT_FILE)
	    call strlwr (Memc[TDATAP(tbl)+9])
	}

	reclen = TNAXIS1(tbl) + 2
	call malloc (rec, reclen, TY_CHAR)
	TREC(tbl) = rec
	entry = 0
	selected = 0
	while (read (fd, Memc[rec], reclen) != EOF) {

	    # Evaluate the macros
	    do i = 1, TNMACRO(tbl) {
		tf = Memi[TMACRO(tbl)+i-1]
		te = TEVP(tf)
		call xfv_freeop (te)
		call mfree (te, TY_STRUCT)
		te = fvexpr (TEXPR(tf), locpr(tbl_gop), locpr(tbl_fcn))
		TEVP(tf) = te
	    }

	    # Evaluate the expression
	    o = fvexpr (Memc[expr], locpr (tbl_gop), locpr (tbl_fcn))
	    if (O_TYPE(o) != TY_BOOL)
		call error (1, "expression must be boolean")

	    # Print the selected fields
	    if (O_VALB(o)) {
		selected = selected + 1
		i = 1
		j = 0
		repeat {
		    k = ctotok (fields, i, field, SZ_LINE)
		    if (k == TOK_IDENTIFIER)
			call tbl_print (tbl, field, j, out)
		} until (k == TOK_EOS)
		call fprintf (out, "\n")
	    }

	    call xfv_freeop (o)
	    call mfree (o, TY_STRUCT)

	    # Print status info if needed.
	    entry = entry + 1
	    if (mod (entry, 1000) == 0) {
		if (stat == YES) {
		    call eprintf ("%6d/%6d/%6d ...\r")
			call pargi (selected)
			call pargi (entry)
			call pargi (TNAXIS2(tbl))
		    call flush (STDERR)
		}
	    }
	}

	if (stat == YES) {
	    call eprintf ("%20s\n")
		call pargstr ("Done")
	}
	call close (fd)
end


# TBL_FREE -- Free table structures

procedure tbl_free (tbl)

pointer	tbl			# Table structure

int	i
pointer	tf

begin
	do i = 1, TNMACRO(tbl) {
	    tf = Memi[TMACRO(tbl)+i-1]
	    call xfv_freeop (TEVP(tf))
	    call mfree (TEVP(tf), TY_STRUCT)
	    call mfree (tf, TY_STRUCT)
	}
	do i = 1, TNMACRO(tbl) {
	    tf = Memi[TFIELD(tbl)+i-1]
	    call xfv_freeop (TEVP(tf))
	    call mfree (TEVP(tf), TY_STRUCT)
	    call mfree (tf, TY_STRUCT)
	}
	call mfree (TMACRO(tbl), TY_POINTER)
	call mfree (TFIELD(tbl), TY_STRUCT)
	call mfree (TREC(tbl), TY_CHAR)
	if (TSTP(tbl) != NULL)
	    call stclose (TSTP(tbl))
	call mfree (tbl, TY_STRUCT)
end


# TBL_PRINT -- Print specified fields.

procedure tbl_print (tbl, field, nfield, fd)

pointer	tbl			#I Table data structure
char	field[ARB]		#I Field to print
int	nfield			#O Number of fields
int	fd			#I Output file descriptor

int	i
pointer	tf, te
bool	streq()
errchk	tbl_gval

begin
	if (nfield > 0)
	    call fprintf (fd, " ")

	if (streq (field, "all")) {
	    do i = 1, TNMACRO(tbl) {
		tf = Memi[TMACRO(tbl)+i-1]
		call tbl_gval (tbl, TNAME(tf), tf, te)
		call fprintf (fd, TFSPP(tf))
		switch (O_TYPE(te)) {
		case TY_CHAR:
		    call pargstr (O_VALC(te))
		case TY_DOUBLE:
		    call pargd (O_VALD(te))
		}
		nfield = nfield + 1
	    }
	    do i = 1, TNFIELD(tbl) {
		if (i > 1)
		    call fprintf (fd, " ")
		tf = Memi[TFIELD(tbl)+i-1]
		call tbl_gval (tbl, TNAME(tf), tf, te)
		call fprintf (fd, TFSPP(tf))
		switch (O_TYPE(te)) {
		case TY_CHAR:
		    call pargstr (O_VALC(te))
		case TY_DOUBLE:
		    call pargd (O_VALD(te))
		}
		nfield = nfield + 1
	    }
	} else {
	    call tbl_gval (tbl, field, tf, te)
	    call fprintf (fd, TFSPP(tf))
	    switch (O_TYPE(te)) {
	    case TY_CHAR:
		call pargstr (O_VALC(te))
	    case TY_DOUBLE:
		call pargd (O_VALD(te))
	    }
	    nfield = nfield + 1
	}
end


# TBL_GMACRO -- Get macros and set macro field structures

procedure tbl_gmacro (tbl)

pointer	tbl			#O Table data structure

int	fd, nowhite(), open(), fscan(), nscan()
pointer	t, tf, te
errchk	open, tbl_gfield

begin
	call calloc (TMACRO(tbl), NALLOC, TY_POINTER)
	TNMACRO(tbl) = 0

	# Define standard macros if arguments are available.
	iferr {
	    call tbl_gfield (tbl, "RAH", NO, tf, te)
	    call tbl_gfield (tbl, "RAM", NO, tf, te)
	    call calloc (t, LEN_TFIELD, TY_STRUCT)
	    call strcpy ("ra", TNAME(t), SZ_TNAME)
	    iferr {
		call tbl_gfield (tbl, "RAS", NO, tf, te)
		call strcpy ("evra(RAH,RAM,RAS)", TEXPR(t), SZ_TLINE)
		call strcpy ("%12.2h", TFSPP(t), SZ_TNAME)
	    } then {
		call strcpy ("evra(RAH,RAM)", TEXPR(t), SZ_TLINE)
		call strcpy ("%9.2m", TFSPP(t), SZ_TNAME)
	    }
	    call malloc (TEVP(t), LEN_OPERAND, TY_STRUCT)
	    call xfv_initop (TEVP(t), 0, TY_DOUBLE)
	    Memi[TMACRO(tbl)+TNMACRO(tbl)] = t
	    TNMACRO(tbl) = TNMACRO(tbl) + 1
	} then
	    ;

	iferr {
	    call tbl_gfield (tbl, "DecSign", NO, tf, te)
	    call tbl_gfield (tbl, "DecD", NO, tf, te)
	    call tbl_gfield (tbl, "DecM", NO, tf, te)
	    call calloc (t, LEN_TFIELD, TY_STRUCT)
	    call strcpy ("dec", TNAME(t), SZ_TNAME)
	    iferr {
		call tbl_gfield (tbl, "DecS", NO, tf, te)
		call strcpy ("evdec(DecSign,DecD,DecM,DecS)", TEXPR(t),SZ_TLINE)
		call strcpy ("%12.2h", TFSPP(t), SZ_TNAME)
	    } then {
		call strcpy ("evdec(DecSign,DecD,DecM)", TEXPR(t), SZ_TLINE)
		call strcpy ("%9.2m", TFSPP(t), SZ_TNAME)
	    }
	    call malloc (TEVP(t), LEN_OPERAND, TY_STRUCT)
	    call xfv_initop (TEVP(t), 0, TY_DOUBLE)
	    Memi[TMACRO(tbl)+TNMACRO(tbl)] = t
	    TNMACRO(tbl) = TNMACRO(tbl) + 1
	} then
	    ;

	# Read package defined macro file
	if (nowhite (TFNC(tbl), TFNC(tbl), SZ_TLINE) != 0) {
	    fd = open (TFNC(tbl), READ_ONLY, TEXT_FILE)
	    while (fscan (fd) != EOF) {
		call calloc (t, LEN_TFIELD, TY_STRUCT)
		call gargwrd (TNAME(t), SZ_TNAME)
		call gargwrd (TFSPP(t), SZ_TNAME)
		call gargwrd (TEXPR(t), SZ_TLINE)
		if (nscan() == 3) {
		    if (!IS_ALPHA(TNAME(t))) {
			call strcpy (TNAME(t), TSTR(t), SZ_TLINE)
			call sprintf (TNAME(t), SZ_TLINE, "X%s")
			    call pargstr (TSTR(T))
		    }
		    if (mod (TNMACRO(tbl), NALLOC) == 0)
			call realloc (TMACRO(tbl), TNMACRO(tbl)+NALLOC,
			    TY_POINTER)
		    call malloc (TEVP(t), LEN_OPERAND, TY_STRUCT)
		    call xfv_initop (TEVP(t), 0, TY_DOUBLE)
		    Memi[TMACRO(tbl)+TNMACRO(tbl)] = t
		    TNMACRO(tbl) = TNMACRO(tbl) + 1
		} else
		    call mfree (t, TY_STRUCT)
	    }
	    call close (fd)
	}

	# Read user defined macro file
	if (nowhite (TUFNC(tbl), TUFNC(tbl), SZ_TLINE) != 0) {
	    fd = open (TUFNC(tbl), READ_ONLY, TEXT_FILE)
	    while (fscan (fd) != EOF) {
		call calloc (t, LEN_TFIELD, TY_STRUCT)
		call gargwrd (TNAME(t), SZ_TNAME)
		call gargwrd (TFSPP(t), SZ_TNAME)
		call gargwrd (TEXPR(t), SZ_TLINE)
		if (nscan() == 3) {
		    if (!IS_ALPHA(TNAME(t))) {
			call strcpy (TNAME(t), TSTR(t), SZ_TLINE)
			call sprintf (TNAME(t), SZ_TLINE, "X%s")
			    call pargstr (TSTR(T))
		    }
		    if (mod (TNMACRO(tbl), NALLOC) == 0)
			call realloc (TMACRO(tbl), TNMACRO(tbl)+NALLOC,
			    TY_POINTER)
		    call malloc (TEVP(t), LEN_OPERAND, TY_STRUCT)
		    call xfv_initop (TEVP(t), 0, TY_DOUBLE)
		    Memi[TMACRO(tbl)+TNMACRO(tbl)] = t
		    TNMACRO(tbl) = TNMACRO(tbl) + 1
		} else
		    call mfree (t, TY_STRUCT)
	    }
	    call close (fd)
	}
end


# TBL_GHDR -- Get table header field descriptions and set field structures

procedure tbl_ghdr(tbl)

pointer	tbl			#O Table data structure

int	fd, i, ip1, ip2
pointer	sp, card, t
int	open(), getline(), strncmp(), ctoi(), ctor(), ctowrd()
errchk	open

begin
	call smark (sp)
	call salloc (card, SZ_LINE, TY_CHAR)

	iferr (fd = open (THDR(tbl), READ_ONLY, TEXT_FILE)) {
	    call strupr (Memc[THDRP(tbl)+9])
	    fd = open (THDR(tbl), READ_ONLY, TEXT_FILE)
	    call strlwr (Memc[THDRP(tbl)+9])
	}

	while (getline (fd, Memc[card]) != EOF) {
	    ip1 = 6
	    ip2 = 11
	    if (Memc[card] == 'N') {
		if (strncmp (Memc[card], "NAXIS1", 6) == 0)
		    i = ctoi (Memc[card], ip2, TNAXIS1(tbl))
		else if (strncmp (Memc[card], "NAXIS2", 6) == 0)
		    i = ctoi (Memc[card], ip2, TNAXIS2(tbl))
	    } else if (Memc[card] == 'T') {
		if (strncmp (Memc[card], "TFIELDS", 6) == 0) {
		    if (ctoi (Memc[card], ip2, i) > 0) {
			call calloc (t, i, TY_STRUCT)
			do ip1 = 1, i
			    call calloc (Memi[t+ip1-1], LEN_TFIELD, TY_STRUCT)
			TNFIELD(tbl) = i
			TFIELD(tbl) = t
		    }
		    next
		}
		if (ctoi (Memc[card], ip1, i) == 0)
		    next
		if (i > TNFIELD(tbl))
		    next
		t = Memi[TFIELD(tbl)+i-1]
		if (strncmp (Memc[card], "TTYPE", 5) == 0) {
		    i = ctowrd (Memc[card], ip2, TNAME(t), SZ_TNAME)
		    i = ctowrd (Memc[card], ip2, TEXPR(t), SZ_TLINE)
		    call strcpy (Memc[card+ip2-1], TEXPR(t), SZ_TLINE)
		    call tbl_strip (TNAME(t))
		    call tbl_strip (TEXPR(t))
		    if (!IS_ALPHA(TNAME(t))) {
			call strcpy (TNAME(t), TSTR(t), SZ_TLINE)
			call sprintf (TNAME(t), SZ_TLINE, "X%s")
			    call pargstr (TSTR(T))
		    }
		} else if (strncmp (Memc[card], "TBCOL", 5) == 0)
		    i = ctoi (Memc[card], ip2, TBCOL(t))
		else if (strncmp (Memc[card], "TFORM", 5) == 0) {
		    i = ctowrd (Memc[card], ip2, TFORM(t), SZ_TNAME)
		    call tbl_strip (TFORM(t))
		    call malloc (TEVP(t), LEN_OPERAND, TY_STRUCT)

		    call strcpy (TFORM(t), TFSPP(t), SZ_TNAME)
		    TFSPP(t) = '%'
		    switch (TFORM(t)) {
		    case 'A':
			call strcat ("s", TFSPP(t), SZ_TNAME)
			call xfv_initop (TEVP(t), SZ_LINE, TY_CHAR)
			ip2 = 2
			i = ctoi (TFORM(t), ip2, TNCOL(t))
		    case 'I':
			call strcat ("d", TFSPP(t), SZ_TNAME)
			call xfv_initop (TEVP(t), 0, TY_DOUBLE)
			ip2 = 2
			i = ctoi (TFORM(t), ip2, TNCOL(t))
		    case 'D', 'E', 'F':
			call strcat ("f", TFSPP(t), SZ_TNAME)
			call xfv_initop (TEVP(t), 0, TY_DOUBLE)
			ip2 = 2
			i = ctoi (TFORM(t), ip2, TNCOL(t))
			ip2 = ip2 + 1
			if (ctoi (TFORM(t), ip2, TDECP(t)) == 0)
			    TDECP(t) = 0
			call sprintf (TFSPP(t), SZ_TNAME, "%%%d.%df")
			    call pargi (TNCOL(t)+1)
			    call pargi (TDECP(t))
		    }
		} else if (strncmp (Memc[card], "TSCAL", 5) == 0)
		    i = ctor (Memc[card], ip2, TSCAL(t))
		else if (strncmp (Memc[card], "TZERO", 5) == 0)
		    i = ctor (Memc[card], ip2, TZERO(t))
	    } else if (Memc[card] == 'E') {
		if (strncmp (Memc[card], "EXTNAME", 7) == 0) {
		    i = ctowrd (Memc[card], ip2, TEXTNAM(tbl), SZ_TLINE)
		    call tbl_strip (TEXTNAM(tbl))
		} else if (strncmp (Memc[card], "EXTVER", 6) == 0)
		    i = ctoi (Memc[card], ip2, TEXTVER(tbl))
	    } else if (strncmp (Memc[card], "AUTHOR", 6) == 0) {
		i = ctowrd (Memc[card], ip2, TAUTHOR(tbl), SZ_TLINE)
		call tbl_strip (TAUTHOR(tbl))
	    } else if (strncmp (Memc[card], "REFERENC", 8) == 0) {
		i = ctowrd (Memc[card], ip2, TREF(tbl), SZ_TLINE)
		call tbl_strip (TREF(tbl))
	    }
	}

	call close (fd)
	call sfree (sp)
end


# TBL_FLIST -- List table fields

procedure tbl_flist (tbl)

pointer	tbl			# Table structure

int	i, fd, open()
pointer	sp, fname, tf
errchk	open

begin
	call smark (sp)
	call salloc (fname, SZ_FNAME, TY_CHAR)

	call mktemp ("tmp$iraf", Memc[fname], TY_CHAR)
	fd = open (Memc[fname], NEW_FILE, TEXT_FILE)

	call fprintf (fd, "HEADER:		%s\n")
	    call pargstr (THDR(tbl))
	call fprintf (fd, "DATA:		%s\n")
	    call pargstr (TDATA(tbl))
	if (TEXTNAM(tbl) != EOS) {
	    call fprintf (fd, "TABLE:		%s\n")
		call pargstr (TEXTNAM(tbl))
	}
	if (TEXTVER(tbl) != 0) {
	    call fprintf (fd, "VERSION:	%d\n")
		call pargi (TEXTVER(tbl))
	}
	if (TAUTHOR(tbl) != EOS) {
	    call fprintf (fd, "AUTHOR:		%s\n")
		call pargstr (TAUTHOR(tbl))
	}
	if (TREF(tbl) != EOS) {
	    call fprintf (fd, "REFERENCE:	%s\n")
		call pargstr (TREF(tbl))
	}
	call fprintf (fd, "FIELDS:		%d\n")
	    call pargi (TNFIELD(tbl))
	call fprintf (fd, "RECORDS:	%d\n")
	    call pargi (TNAXIS2(tbl))
	call fprintf (fd, "\n")

	if (TNMACRO(tbl) > 0) {
	    call fprintf (fd, "MACRO DEFINITIONS ON TABLE FIELDS:	%d\n")
		call pargi (TNMACRO(tbl))
	    do i = 1, TNMACRO(tbl) {
		tf = Memi[TMACRO(tbl)+i-1]
		call fprintf (fd, "%-20.20s %-47s [%s]\n")
		    call pargstr (TNAME(tf))
		    call pargstr (TEXPR(tf))
		    call pargstr (TFSPP(tf))
	    }
	    call fprintf (fd, "\n")
	}

	call fprintf (fd, "TABLE FIELDS:		%d\n")
	    call pargi (TNFIELD(tbl))
	do i = 1, TNFIELD(tbl) {
	    tf = Memi[TFIELD(tbl)+i-1]
	    call fprintf (fd, "%-20.20s %-47s [%s]\n")
		call pargstr (TNAME(tf))
		call pargstr (TEXPR(tf))
		call pargstr (TFORM(tf))
	    if (TSCAL(tf) != 0. || TZERO(tf) != 0.) {
		if (TSCAL(tf) == 0.)
		    TSCAL(tf) = 1.
		call fprintf (fd, "%26tScale = %g, Zero = %g\n")
		    call pargr (TSCAL(tf))
		    call pargr (TZERO(tf))
	    }
	}

	call close (fd)
	call pagefile (Memc[fname], TEXTNAM(tbl))
	call delete (Memc[fname])
	call sfree (sp)
end
		
		
# TBL_STRIP -- Strip leading whitespace and trailing non-alpha characters.

procedure tbl_strip (str)

char	str[ARB]

int	i, strlen()

begin
	for (i=strlen(str); i>0 && !IS_ALNUM(str[i]); i=i-1)
	    ;
	str[i+1] = EOS
	for (i=1; str[i]==' '; i=i+1)
	    ;
	if (i > 1)
	    call strcpy (str[i], str, ARB)
end


# TBL_GFIELD -- Get field structure with given name
# Use a symbol table of previously called fields for efficiency.
# Allow abbreviations.

procedure tbl_gfield (tbl, name, abbr, tf, te)

pointer	tbl			#I Table data structure
char	name[ARB]		#I Field name
int	abbr			#I Allow abbreviations?
pointer	tf			#O Field structure
pointer	te			#O Field expression pointer

int	i, ip1, ip2, nmatch
pointer	stp, sym, err, stfind(), stenter()

begin
	# Check symbol table
	stp = TSTP(tbl)
	sym = stfind (stp, name)
	if (sym != NULL) {
	    tf = Memi[sym]
	    te = TEVP(tf)
	    return
	}

	# Check the fields
	nmatch = 0
	do i = 1, TNMACRO(tbl) {
	    ip2 = TTPTR(Memi[TMACRO(tbl)+i-1])
	    for (ip1=1; name[ip1]!=EOS; ip1=ip1+1) {
		if (Memc[ip2]==EOS || name[ip1] != Memc[ip2])
		    break
		ip2 = ip2 + 1
	    }
	    if (name[ip1] == EOS) {
		if (Memc[ip2] == EOS) {
		    nmatch = 1
		    tf = Memi[TMACRO(tbl)+i-1]
		    te = TEVP(tf)
		    sym = stenter (stp, name, 1)
		    Memi[sym] = tf
		    return
		} else if (abbr == YES) {
		    tf = Memi[TMACRO(tbl)+i-1]
		    nmatch = nmatch + 1
		}
	    }
	}
	do i = 1, TNFIELD(tbl) {
	    ip2 = TTPTR(Memi[TFIELD(tbl)+i-1])
	    for (ip1=1; name[ip1]!=EOS; ip1=ip1+1) {
		if (Memc[ip2]==EOS || name[ip1] != Memc[ip2])
		    break
		ip2 = ip2 + 1
	    }
	    if (name[ip1] == EOS) {
		if (Memc[ip2] == EOS) {
		    nmatch = 1
		    tf = Memi[TFIELD(tbl)+i-1]
		    te = TEVP(tf)
		    sym = stenter (stp, name, 1)
		    Memi[sym] = tf
		    return
		} else if (abbr == YES) {
		    tf = Memi[TFIELD(tbl)+i-1]
		    nmatch = nmatch + 1
		}
	    }
	}
	if (nmatch == 1) {
	    sym = stenter (stp, name, 1)
	    Memi[sym] = tf
	    return
	}

	call salloc (err, SZ_LINE, TY_CHAR)
	call sprintf (Memc[err], SZ_LINE, "%s `%s'")
	if (nmatch == 0)
	    call pargstr ("No such field")
	else
	    call pargstr ("Ambiguous field name")
	    call pargstr (name)
	call error (1, Memc[err])
end


# TBL_GVAL -- Get value of table field from the data record
# Macro fields are assumed to be previously defined

procedure tbl_gval (tbl, name, tf, te)

pointer	tbl			# Table structure
char	name[ARB]		# Name
pointer	tf			# Field structure
pointer	te			# Field expression pointer

int	ip, ctod(), stridxs()
errchk	tbl_gfield

begin
	call tbl_gfield (tbl, name, YES, tf, te)
	if (TNCOL(tf) > 0) {
	    switch (O_TYPE(te)) {
	    case TY_CHAR:
		call strcpy (Memc[TREC(tbl)+TBCOL(tf)-1], TSTR(tbl),
		    min (TNCOL(tf), SZ_TLINE))
		call strcpy (TSTR(tbl), O_VALC(te), SZ_LINE)
	    case TY_DOUBLE:
		call strcpy (Memc[TREC(tbl)+TBCOL(tf)-1], TSTR(tbl),
		    min (TNCOL(tf), SZ_TLINE))
		ip = 1
		if (ctod (TSTR(tbl), ip, O_VALD(te)) == 0)
		    ;
		if (TDECP(tf) > 0) {
		    ip = stridxs (".", TSTR(tbl))
		    if (ip == 0)
		    #if (ip != TNCOL(tf) - TDECP(tf))
			O_VALD(te) = O_VALD(te) * 10. ** (-TDECP(tf))
		}
		if (TSCAL(tf) != 0.)
		    O_VALD(te) = O_VALD(te) * TSCAL(tf)
		O_VALD(te) = O_VALD(te) + TZERO(tf)
	    }
	}
end


# TBL_GOP -- Get expression operand for expression parser.

procedure tbl_gop (operand, o)

char	operand[ARB]
pointer	o

pointer	tf, te

pointer	tbl
common	/tblcom/ tbl
errchk	tbl_gval

begin
	call tbl_gval (tbl, operand, tf, te)
	switch (O_TYPE(te)) {
	case TY_CHAR:
	    call xfv_initop (o, SZ_LINE, TY_CHAR)
	    call strcpy (O_VALC(te), O_VALC(o), SZ_LINE)
	case TY_DOUBLE:
	    call xfv_initop (o, 0, TY_DOUBLE)
	    O_VALD(o) = O_VALD(te)
	}
end


# Special functions
define	KEYWORDS	"|ctoi|ctor|evra|evdec|evsptype|"
define	F_CTOI		1		# function codes
define	F_CTOR		2
define	F_EVRA		3
define	F_EVDEC		4
define	F_EVSPTYPE	5

# TBL_FCN -- Special functions called by expression parser.

procedure tbl_fcn (fcn, args, nargs, out)

char	fcn[ARB]		# function to be called
pointer	args[ARB]		# pointer to arglist descriptor
int	nargs			# number of arguments
pointer	out			# output operand (function value)

double	rresult
int	iresult, optype, oplen
int	opcode, v_nargs, i, j, ip
pointer	sp, buf, rval

bool	strne()
int	stridx(), strdic(), ctod()
errchk	zcall4, xfv_error1, xfv_error2, malloc
define	badtype_ 91
define	free_ 92

begin
	call smark (sp)
	call salloc (buf, SZ_FNAME, TY_CHAR)
	call salloc (rval, nargs, TY_DOUBLE)

	oplen = 0

	# Lookup the function name in the dictionary.  An exact match is
	# required (strdic permits abbreviations).

	opcode = strdic (fcn, Memc[buf], SZ_FNAME, KEYWORDS)
	if (opcode > 0 && strne(fcn,Memc[buf]))
	    opcode = 0

	# Abort if the function is not known.

	if (opcode <= 0)
	    call xfv_error1 ("unknown function `%s' called", fcn)

	# Verify correct number of arguments.
	switch (opcode) {
	case F_EVRA:
	    v_nargs = -1
	case F_EVDEC:
	    v_nargs = -2
	case F_EVSPTYPE:
	    v_nargs = -2
	default:
	    v_nargs = 1
	}

	if (v_nargs > 0 && nargs != v_nargs)
	    call xfv_error2 ("function `%s' requires %d arguments",
		fcn, v_nargs)
	else if (v_nargs < 0 && nargs < abs(v_nargs))
	    call xfv_error2 ("function `%s' requires at least %d arguments",
		fcn, abs(v_nargs))

	# Convert datatypes to real.
	do i = 1, nargs {
	    switch (O_TYPE(args[i])) {
	    case TY_CHAR:
		ip = 1
		if (ctod (O_VALC(args[i]), ip, Memd[rval+i-1]) == 0)
		    Memd[rval+i-1] = 0.
	    case TY_INT:
		Memd[rval+i-1] = O_VALI(args[i])
	    case TY_DOUBLE:
		Memd[rval+i-1] = O_VALD(args[i])
	    }
	}

	# Evaluate the function.

	optype = TY_DOUBLE
	switch (opcode) {
	case F_CTOI:
	    optype = TY_INT
	    iresult = nint (Memd[rval])
	case F_CTOR:
	    rresult = Memd[rval]
	case F_EVRA:
	    rresult = Memd[rval]
	    if (nargs > 1)
		rresult = rresult + Memd[rval+1] / 60.
	    if (nargs > 2)
		rresult = rresult + Memd[rval+2] / 3600.
	case F_EVDEC:
	    rresult = Memd[rval+1]
	    if (nargs > 2)
		rresult = rresult + Memd[rval+2] / 60.
	    if (nargs > 3)
		rresult = rresult + Memd[rval+3] / 3600.
	    if (O_VALC(args[1]) == '-')
		rresult = -rresult
	case F_EVSPTYPE:
	    optype = TY_BOOL
	    iresult = 1
	    do i = 1, nargs {
		call strcpy (O_VALC(args[i]), Memc[buf], SZ_FNAME)
		call strupr (Memc[buf])
		ip = stridx (Memc[buf], "OBAFGKM")
		if (ip == 0)
		    iresult = 0
		else if (Memc[buf+1] == ' ' || Memc[buf+1] == EOS)
		    j = 0
		else {
		    j = stridx (Memc[buf+1], "0123456789")
		    if (j == 0)
			iresult = 0
		}
		Memd[rval+i-1] = ip * 100 + j
	    }
	    ip = nint (Memd[rval])
	    if (nargs == 2) {
		i = nint (Memd[rval+1])
		j = i
	    } else {
		i = min (nint (Memd[rval+1]), nint (Memd[rval+2]))
		j = max (nint (Memd[rval+1]), nint (Memd[rval+2]))
	    }
	    if (mod (ip, 100) == 0) {
		ip = ip / 100
		i = i / 100
		j = j / 100
	    } else if (mod (j, 100) == 0)
		j = j + 10
	    if (ip < i || ip > j)
		    iresult = 0

	default:
	    call xfv_error ("bad switch in userfcn")
	}

	# Write the result to the output operand.  Bool results are stored in
	# iresult as an integer value, string results are stored in iresult as
	# a pointer to the output string, and integer and real results are
	# stored in iresult and rresult without any tricks.

	call xfv_initop (out, oplen, optype)

	switch (optype) {
	case TY_BOOL:
	    O_VALB(out) = (iresult != 0)
	case TY_CHAR:
	    O_VALP(out) = iresult
	case TY_INT:
	    O_VALI(out) = iresult
	case TY_DOUBLE:
	    O_VALD(out) = rresult
	}

free_
	# Free any storage used by the argument list operands.
	do i = 1, nargs
	    call xfv_freeop (args[i])

	call sfree (sp)
	return

badtype_
	call xfv_error1 ("bad argument to function `%s'", fcn)
	call sfree (sp)
	return
end
