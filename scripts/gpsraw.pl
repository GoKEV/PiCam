#!/usr/bin/perl

open(GPSRAW, "gpscat /dev/ttyACM0|");
# This was giving me message types: $GPRMC $GPVTG $GPGGA $GPGSA $GPGSV $GPGLL $GPTXT 
# but I'm ignoring the rest.  Full list of message types and explanations of fields
# can be found here: http://aprs.gids.nl/nmea/

while (<GPSRAW>) {
	($msgtype,undef) = split(/\,/,$_);
	push @mtypes,$msgtype;
	chomp($message = $_);

	($time,$lat,$latx,$lon,$lonx,$fixqa,$satct) = &parse_gpgga($message) if ($msgtype eq "\$GPGGA"); # $GPGGA - Global Positioning System Fix Data
	($lat,$latx,$lon,$lonx) = &parse_gpgll($message) if ($msgtype eq "\$GPGLL"); # $GPGLL - Geographic Position, Latitude / Longitude and time.
	($satct,$azi) = &parse_gpgsv($message) if ($msgtype eq "\$GPGSV"); # $GPGSV - GPS Satellites in view
	($time,$date,$knots,$mph,$kph,$lat,$latns,$lon,$lonew) = &parse_gprmc($message) if ($msgtype eq "\$GPRMC"); # $GPRMC - Recommended minimum specific GPS/Transit data
	($mph,$kmph) = &parse_gpvtg($message) if ($msgtype eq "\$GPVTG"); # $GPVTG - Track Made Good and Ground Speed.

	# Print all undefined message types
	print "$message\n" if (($msgtype ne "\$GPGGA") and ($msgtype ne "\$GPGLL") and ($msgtype ne "\$GPGSA") and ($msgtype ne "\$GPGSV") and ($msgtype ne "\$GPRMC") and ($msgtype ne "\$GPVTG") );

	$google_url = &google_url($lat,$latx,$lon,$lonx);

#	next if (! $_);		# skip blank lines


print<<ALLDONE;
TIME	$time
DATE	$date
LAT	$lat $latx
LON	$lon $lonx
FIXQA	$fixqa
SATS	$satct
KNOTS	$knots
MPH	$mph
KMPH	$kmph
GOOGLE	$google_url

ALLDONE
}

close(GPSRAW);


###############################################################################
###       Everything below here is a subroutine referenced above.           ###
###############################################################################


sub parse_gpgga{
	my ($msg) = shift(@_);
	my ($format,$time,$lat,$latns,$lon,$lonew,$fixqa,$satct,$hdop,$altm,$tslgpsdu,$dgpssid,$sum) = split(/\,/,$msg);
	return ($time,$lat,$latns,$lon,$lonew,$fixqa,$satct);

}

sub parse_gpgsv{
	my ($msg) = shift(@_);
	my ($msgtot,$msgnum,$satct,$svprn,$elevdeg,$azi,$snr,undef) = split(/\,/,$msg);
	return ($satct,,$azi);
}


sub parse_gpgll{
	# $GPGLL - Geographic position, latitude / longitude
	my ($msg) = shift(@_);
	my ($format,$lat,$latns,$lon,$lonew,$kts,$sum) = split(/\,/,$msg);
	return ($lat,$latns,$lon,$lonew);
}

sub parse_gprmc{
	my ($msg) = shift(@_);
	my ($format,$time,$warn,$lat,$latns,$lon,$lonew,$knots,$true,$date,$var,$ew,$sum) = split(/\,/,$msg);
        my ($mph,$kph) = &convert_knots_speed($knots);
	return ($time,$date,$knots,$mph,$kph,$lat,$latns,$lon,$lonew);
}

sub convert_knots_speed{
	my $knots = shift(@_);
	my $mph = ($knots * 1.15078);
	my $kph = ($mph * 1.60934);
	$mph =~ s/\..*$//g;	# we round down instead of using int().  Because of
	$kph =~ s/\..*$//g;	# this, a value of 54.9 MPH is still reported as 54.
	return ($mph,$kph);
}

sub parse_gpvtg{
	my ($msg) = shift(@_);
	my ($format,$tmg,$tmgtn,undef,undef,$knots,undef,$kmph,undef,$sum) = split(/\,/,$msg);
	my ($mph,$kph) = &convert_knots_speed($knots);
	return ($mph,$kph);
}

sub google_url{
	my ($lat,$latx,$lon,$lonx) = (@_);
	my $googleurl = 'https://www.google.com/maps/@';
	$googleurl .= "-" if ($latx eq "S");
	$googleurl .= $lat . ',';
	$googleurl .= "-" if ($latx eq "W");
	$googleurl .= $lon;
	return $googleurl;
}

sub unique_array{
	my %seen;
	return grep { !$seen{$_}++ } @_;
}

