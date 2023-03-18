#{ ADCCDROM -- Package for accessing ADC CD-ROM data

cl < "adccdrom$lib/zzsetenv.def"
package adccdrom, bin = adcbin$

task	catalog,
	spectra,
	tbldb		= "adccdrom$x_adccdrom.e"

hide	tbldb

clbye
