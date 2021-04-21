#!/usr/local/bin/perl
use 5.010;
if($#ARGV== -1 || $#ARGV>1) {
	print "please give input and output files as arguments.\n";
	exit;
}
my $in_file = $ARGV[0];
my $out_file = $ARGV[1];
my $in_is_out = 0;
open(IFH, '<', $in_file) or die $!;

if( ($in_file eq $out_file) || $#ARGV == 0) {
	$in_is_out = 1;
	$tmp_out = 'tmp.txt';
        open(OFH, '>', $tmp_out) or die $!;

} else {
	open(OFH, '>', $out_file) or die $!;
}       

my $suffix = 10;
while(<IFH>){
	$_ =~ s/(\s*)(.*?)(?=\=)=\s*\$\(\s*(?![\"'])(.*?)(?=[\s+\)])/\n\1\3$suffix = "#"+\3;\n\1\2 = jQuery(\3$suffix/;
	#$_ =~ s/(\s*)\$\((.*?)(?=\))\)\.onsubmit\(\s*\)/\1\2$suffix = "#"+\2;\n\1jQuery(\2$suffix).submit\(\)/;
	$_ =~ s/([^\$])\$\(\s*(?=[\"'])([\"'])(.*?)(?=[\"'])([\"'])/\1jQuery('#\3'\5/g;
	$_ =~ s/\.onsubmit/.submit/;
	#$_ =~ s/(\w+)\.onsubmit\(\s*\)/Rails\.fire\(\1, 'submit')/g;
	$_ =~ s/\.clientHeight/.height()/g;
	$_ =~ s/\.clientWidth/.width()/g;
	$_ =~ s/\(\s*(.*?)(?=\.)\.value\s*==\s*(.*?)(?=[\)])/(\1.val() == \2\5/g;
	$_ =~ s/(.*?)(?=[\.])\.value\s*\=(?=[^\=])(.*?)(?=[;\n])/\1.val(\2)\5/g;
        $_ =~ s/\.value/.val\(\)/g;
        $_ =~ s/\.getValue\(\s*\)/.val\(\)/g; 
	$_ =~ s/(.*?)(?=\.)\.onresize\s*\=(.*?)(?=[;])/\1.on('resize', \2)\5/g;
	$_ =~ s/\.offsetLeft/.offset().left/g;
        $_ =~ s/\.offsetTop/.offset().top/g;
	$_ =~ s/\.offsetWidth/.outerWidth()/g;
	$_ =~ s/\.innerWidth/.innerWidth()/g;
	$_ =~ s/(.*?)(?=\.)\.onscroll\s*\=(.*?)(?=[;])/\1.scroll(\2)\5/g;
	$_ =~ s/\.visible\(\s*\)/.is(':visible')/g;
	$_ =~ s/\$\$/jQuery/g;
	$_ =~ s/\.up\(/.closest(/g;
	$_ =~ s/\.setStyle\(\s*\'(.*?)(?=:):(.*?)'\s*\+/.attr('\1',\5/g;
	$_ =~ s/\.setStyle\(/.attr(/g;
	$_ =~ s/\.setAttribute\(/.attr(/g;
	$_ =~ s/(?<![\w_-])window(?![\w_-])/jQuery(window)/g;
	$_ =~ s/jQuery\(window\)\.open/window.open/g;
	$_ =~ s/Event\.observe\(\s*(.*?)(?=,),/\1.on(\5/g;
	$_ =~ s/\.getAttribute\(/.attr(/g;
	$_ =~ s/\.writeAttribute\(/.attr(/g;
	$_ =~ s/\.scrollWidth/[0].scrollWidth/g;
	$_ =~ s/(?<![\w_-])new\s*Element\(\s*(['"])(.*?)(?=\1)\1\s*,\s*(?=\{)(\{.*?(?=\})\})\)/\$\(\"<\2><\/\2>\"\).attr\(\3\)/g;
	$_ =~ s/\.innerHTML\s*\=\s*(.*?)(?=;)/\.html\(\1\)/g;
	$_ =~ s/\.prototype\./.fn./g;
	$_ =~ s/\.insert\(\s*\{'bottom'\s*:\s*(.*?)(?=\})\s*\}\s*\)/\.append\(\1\)/g;
        $_ =~ s/\.insert\(\s*\{'after'\s*:\s*(.*?)(?=\})\s*\}\s*\)/\.after\(\1\)/g;
	$_ =~ s/\.style\.(.*?)(?=[\s\=])\s*\=\s*([\"'])(.*?)(?=\2)\2/\.css\('\1','\3'\)/g;
        $_ =~ s/\.style\.(.*?)(?=[\s\=])\s*\=\s*(.*?)(?=[\n;])/\.css\('\1', \2\)/g;	
	$_ =~ s/\.down\(([\"'])\.*(.*?)(?=\1)\1\)/.find\('\2:first'\)/g;
	$_ =~ s/\.cloneNode\(\.*(.*?)(?=\))\)/.clone\(\1\)/g;
	$_ =~ s/\.id\s*\=\s*(.*?)(?=;)/.attr\('id',\1\)/g;
        $_ =~ s/\.name\s*\=\s*(.*?)(?=;)/.attr\('name',\1\)/g;
	$_ =~ s/\.selected\s*\=\s*(.*?)(?=;)/.prop\('selected',\1\)/g;
	# $_ =~ s/(?<!\))\.each\(/\.forEach\(/g;
	$_ =~ s/\.insert\(\s*\{'bottom'\s*:\s*(.*?)(?=\})\s*\}\s*\)/\n1\1 \n2\2 \n3\3 \n4\4 \n5\5 \n6\6 /g;
	$_ =~ s/\$\(/jQuery\(/g;
	$_ =~ s/\.select\(/\.find\(/g;
	print OFH $_;
	$suffix++;
}

close(IFH);
close(OFH);

if($in_is_out){
	open(OFH, '>', $in_file) or die $!;
	open(IFH, '<', $tmp_out) or die $!;
	while(<IFH>){
		print OFH $_;
	}
	close(IFH);
	close(OFH);
}

