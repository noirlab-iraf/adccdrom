include	<error.h>
include	<imhdr.h>

# List of catalogs understood by this task.
define	CATALOGS	"|iuelda|iueostar|spatlasb|spatlasr|splib|spstd|\
			 |uvbs|uvbssupp|"

# Enumerated value fields in catalog definition file.
define	VALTYPES		"|wavelength|flux|quality|"
define	WAVE		1	# Wavelength
define	FLUX		2	# Flux
define	QUAL		3	# Quality

define	PIXENCODE		"|value|manexp|"
define	VALUE		1	# Pixels encoded as value
define	MANEXP		2	# Pixels encoded as mantissa and exponent


# T_SPECTRA -- Extract spectra from selected ADC CD-ROM spectral catalogs.
# A catalog name, list of spectra, and output root name are specified.
# The various catalogs have different structures but the structure is
# is defined in the catalog definition file "spectra.dat".  Thus, all
# catalogs are read by the same code.

procedure t_spectra ()

pointer	catalog			# Catalog name
pointer	spec			# Spectrum list
pointer	root			# Output root image name

int	nspec			# Number of spectra
int     nrec			# Number of records per spectrum
int     nchar			# Number of characters per record
int     nheader			# Number of header lines per spectrum
int     nlskip			# Number of lines to skip
int     ncskip			# Number of initial characters to skip
int     npline			# Number of pixels per line
int	nvals			# Number of values per pixel
int	valtype[2]		# Array of value types
int     npix			# Number of pixels per spectrum
int	ncpix			# Number of characters per pixel
int     ntitle			# Number of characters in the title
int	pixencode		# Pixel encoding
real    crval			# Starting wavelength
real    cdelt			# Wavelength per pixel

bool	varrec
real	a, b
int	i, j, k, l, ip, fd, offset, cat
pointer	sp, image, str, data, im, mw, buf

pointer	immap(), impl1r(), mw_open()
bool	streq() is_in_range()
int	open(), fscan(), nscan(), read()
int	nowhite(), strdic(), stridxs(), decode_ranges(), ctorn()
errchk	open, immap, mw_open

define	done_	10

begin
	call smark (sp)
	call salloc (catalog, SZ_FNAME, TY_CHAR)
	call salloc (spec, 300, TY_INT)
	call salloc (root, SZ_FNAME, TY_CHAR)
	call salloc (image, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	iferr {
	    # Select the catalog and page list if unknown.
	    call strcpy ("#", Memc[str], SZ_LINE)
	    repeat {
		call clgstr ("catalog", Memc[catalog], SZ_FNAME)
		i  = nowhite (Memc[catalog], Memc[catalog], SZ_FNAME)
		if (streq (Memc[catalog], Memc[str]))
		    goto done_
		call strcpy (Memc[catalog], Memc[str], SZ_LINE)

		cat = strdic (Memc[catalog], Memc[catalog], SZ_FNAME, CATALOGS)
		if (cat > 0)
		    break

		call pagefile ("adccdrom$spectra.men", "ADC CD-ROM Spectra")
	    }

	    # Read the catalog data description file.
	    fd = open ("adccdrom$spectra.dat", READ_ONLY, TEXT_FILE)
	    while (fscan (fd) != EOF) {
		call gargwrd (Memc[str], SZ_LINE)
		if (streq (Memc[catalog], Memc[str]))
		    break
	    }
	    if (fscan (fd) == EOF) {
		call close (fd)
		call error (1, "Catalog data description not found")
	    }

	    call gargwrd (Memc[str], SZ_LINE)
	    call sprintf (Memc[catalog], SZ_FNAME, "%s$%s")
		call pargstr ("adccddir")
		call pargstr (Memc[str])
	    i = fscan (fd); call gargi (nspec)
	    i = fscan (fd); call gargi (nrec)
	    i = fscan (fd); call gargi (nchar)
	    i = fscan (fd); call gargi (nheader)
	    i = fscan (fd); call gargi (nlskip)
	    i = fscan (fd); call gargi (ncskip)
	    i = fscan (fd); call gargi (npline)
	    i = fscan (fd)
		do i = 1, 2 {
		    call gargwrd (Memc[str], SZ_LINE)
		    if (Memc[str] == '#' || nscan() != i)
			break
		    valtype[i] = strdic (Memc[str], Memc[str], SZ_LINE,VALTYPES)
		    nvals = i
		}
	    i = fscan (fd); call gargi (npix)
	    i = fscan (fd); call gargi (ncpix)
	    i = fscan (fd); call gargi (ntitle)
	    i = fscan (fd); call gargwrd (Memc[str], SZ_LINE)
		pixencode = strdic (Memc[str], Memc[str], SZ_LINE, PIXENCODE)
	    i = fscan (fd); call gargr (crval)
	    i = fscan (fd); call gargr (cdelt)
	    call close (fd)

	    varrec = IS_INDEFI(nrec)
	    call salloc (data, nchar, TY_CHAR)

	    # Open the catalog
	    iferr (fd = open (Memc[catalog], READ_ONLY, TEXT_FILE)) {
		call strupr (Memc[catalog+9])
	        fd = open (Memc[catalog], READ_ONLY, TEXT_FILE)
		call strlwr (Memc[catalog+9])
	    }

	    # Get list of spectra and print directory if requested
	    call clgstr ("spectra", Memc[str], SZ_LINE)
	    if (stridxs ("?", Memc[str]) > 0) {
		call eprintf ("Creating directory of %s ...\n")
		    call pargstr (Memc[catalog])
		call flush (STDOUT)
		call mktemp ("tmp", Memc[root], SZ_FNAME)
		j = open (Memc[root], TEMP_FILE, TEXT_FILE)
		offset = 0
		do i = 1, nspec {
		    call ghead (cat, fd, offset, Memc[data], nrec, nchar,
			nheader, nlskip, ncskip, npline, npix, crval, cdelt,
			Memc[str], ntitle)
		    offset = offset + nrec * nchar
		    call fprintf (j, "%3d: %s\n")
			call pargi (i)
			call pargstr (Memc[str])
		}
		call close (j)
		call pagefile (Memc[root], Memc[catalog])

		call clgstr ("spectra", Memc[str], SZ_LINE)
		if (stridxs ("?", Memc[str]) > 0) {
		    call close (fd)
		    goto done_
		}

		call seek (fd, BOF)
	    }

	    # Decode spectrum list
	    if (decode_ranges (Memc[str], Memi[spec], 100, i) == ERR)
		call error (1, "Error in spectrum list")

	    # Get root name
	    call clgstr ("image", Memc[root], SZ_FNAME)

	    # Extract requested spectra
	    offset = 0
	    do i = 1, nspec {

		# For variable record structures we must read each spectrum
		# header and accumulate the offsets.  For fixed length
		# structures we can more efficiently compute the offset
		# from the spectrum index.

		if (varrec) {
		    call ghead (cat, fd, offset, Memc[data], nrec, nchar,
			nheader, nlskip, ncskip, npline, npix, crval, cdelt,
			Memc[str], ntitle)
		    offset = offset + nrec * nchar
		    if (!is_in_range (Memi[spec], i))
			next
		} else {
		    if (!is_in_range (Memi[spec], i))
			next
		    offset = (i - 1) * nrec * nchar
		    call ghead (cat, fd, offset, Memc[data], nrec, nchar,
			nheader, nlskip, ncskip, npline, npix, crval, cdelt,
			Memc[str], ntitle)
		}

		# Open the image, setup the header, and get a data buffer.
		call sprintf (Memc[image], SZ_FNAME, "%s.%04d")
		    call pargstr (Memc[root])
		    call pargi (i)

		im = immap (Memc[image], NEW_IMAGE, 0)

		call strcpy (Memc[str], IM_TITLE(im), SZ_IMTITLE)

		call imaddr (im, "EXPTIME", 1)
		call imaddi (im, "APNUM", i)
		call imaddi (im, "DC-FLAG", 0)

		IM_PIXTYPE(im) = TY_REAL
		IM_NDIM(im) = 1
		IM_LEN(im,1) = npix

		mw = mw_open (NULL, 1)
		call mw_newsystem (mw, "world", 1)
		call mw_swtype (mw, 1, 1, "linear",
		    "label=Wavelength units=Angstroms")
		call mw_swtermr (mw, 1., crval, cdelt, 1)
		call mw_saveim (mw, im)
		call mw_close (mw)

		buf = impl1r (im)

		# Skip any initial data
		do k = 1, nlskip
		    j = read (fd, Memc[data], nchar)
		j = read (fd, Memc[data], nchar)
		ip = 1 + ncskip

		# Get the pixel values which may be encoded in various way.
		switch (pixencode) {
		case VALUE:
		    do j = 0, npix-1 {
			do k = 1, nvals {
			    if (ctorn (Memc[data], ip, ncpix, a) == 0) {
				l = read (fd, Memc[data], nchar)
				ip = 1
				l = ctorn (Memc[data], ip, ncpix, a)
			    }
			    if (valtype[k] == FLUX)
				Memr[buf+j] = a
			}
		    }
		case MANEXP:
		    do j = 0, npix-1 {
			do k = 1, nvals {
			    if (ctorn (Memc[data], ip, ncpix, a) == 0) {
				l = read (fd, Memc[data], nchar)
				ip = 1
				l = ctorn (Memc[data], ip, ncpix, a)
			    }
			    if (ctorn (Memc[data], ip, ncpix, b) == 0) {
				l = read (fd, Memc[data], nchar)
				ip = 1
				l = ctorn (Memc[data], ip, ncpix, b)
			    }
			    if (valtype[k] == FLUX)
				Memr[buf+j] = a * 10. ** b
			}
		    }
		}

		call imunmap (im)

		# Print operation
		call printf ("%s %3d: %s --> %s\n")
		    call pargstr (Memc[catalog])
		    call pargi (i)
		    call pargstr (Memc[str])
		    call pargstr (Memc[image])
		call flush (STDOUT)

	    }
	    call close (fd)

done_       i = 0

	} then
	    call erract (EA_WARN)

	call sfree (sp)
end


# GHEAD -- This procedure reads the header block and returns a spectrum
# title.  The file offset to the beginning of the header is input.  This
# procedure handles most of the difference in the catalogs as defined in the
# header.  Catalogs with variable lengths or variable wavelength ranges have
# fields defining the parameters of the following spectrum in the header
# block.  These values are extracted and update the last values.

procedure ghead (cat, dat, offset, data, nrec, nchar, nheader,
	nlskip, ncskip, npline, npix, crval, cdelt, title, ntitle)

int	cat			#I Catalog ID
int	dat			#I Data file descriptor
int	offset			#I Offset to header
char	data[ARB]		#I Data buffer
int     nrec			#U Number of records per spectrum
int     nchar			#I Number of characters per record
int     nheader			#I Number of header lines per spectrum
int     nlskip			#I Number of lines to skip
int     ncskip			#I Number of initial characters to skip
int     npline			#I Number of pixels per line
int     npix			#U Number of pixels per spectrum
real    crval			#U Starting wavelength
real    cdelt			#U Wavelength per pixel
char	title[ARB]		#O Title string
int     ntitle			#I Number of characters in the title

int	i, j, read(), ctowrd(), ctoi(), ctor(), ctorn()

begin
	call seek (dat, offset)

	switch (cat) {
	case 1, 2, 3, 4, 5:
	    i = read (dat, data, nchar)
	    call strcpy (data, title, ntitle)
	    do j = 2, nheader
		i = read (dat, data, nchar)
	case 6:
	    i = read (dat, data, nchar)
	    j = 1
	    i = ctowrd (data, j, title, SZ_LINE)
	    i = ctoi (data, j, npix)
	    i = ctor (data, j, crval)
	    i = ctor (data, j, cdelt)
	    nrec = nheader + (npix + npline - 1) / npline
	    do j = 2, nheader
		i = read (dat, data, nchar)
	case 8:
	    i = read (dat, data, nchar)
	    call strcpy ("HD ", title, SZ_LINE)
	    call strcat (data[5], title, 9)
	    call seek (dat, offset)
	case 9:
	    i = read (dat, data, nchar)
	    call strcpy ("HD ", title, SZ_LINE)
	    call strcat (data, title, 9)
	    j = 24
	    i = ctorn (data, j, 4, crval)
	    call seek (dat, offset)
	}
end


# CTORN -- A version of CTOR to convert N characters when the strings are not
# blank or new-line delimited.

int procedure ctorn (str, ip, n, rval)

char	str[ARB]		#I Input string
int	ip			#I Index pointer
int	n			#I Maximum number of character to convert
real	rval			#O Integer value
int	stat			#O Returned status

int	jp, ctor()
char	c

begin
	jp = ip + n
	c = str[jp]
	str[jp] = EOS
	stat = ctor (str, ip, rval)
	str[jp] = c
	return (stat)
end
