#!/usr/bin/perl

while(1){
	chomp($nowtime = `date +"%Y-%m-%d_%H-%M-%S_%N"`);
	($date,$time,$micro) = split(/_/,$nowtime);
	$microo++;
	print $date . "_" . $time . "." . $microo . "\n";
}
