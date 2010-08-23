#!/usr/bin/perl
# Archdocumentalist
# Copyright (C) 2010  Francois Boulogne <fboulogne at april dot org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


# Available languages on http://wiki.archlinux
#  עברית #
# ФОС

#Country codes come from http://en.wikipedia.org/wiki/ISO_3166-1
my %lang_hash=(
'Български',	 'BG',
'正體中文',		 'CN',
'简体中文',		 'CN',
'繁體中文', 	 'CN',
'Česky',         'CZ', 
'Dansk',         'DK', 
'Deutsch',       'DE', 
'English',       'EN', 
'Español',       'ES', 
'Suomi',         'FI', 
'Français',      'FR', 
'Ελληνικά',      'GR', 
'Srpski',		 'HR',
'Magyar',        'HU', 
'Indonesia',     'ID', 
'Italiano',      'IT', 
'日本語',        'JP', 
'Lietuviškai',   'LT', 
'Nederlands',    'NL', 
'Polski',        'PL', 
'Português',     'PT', 
'Română',        'RO', 
'Српски',        'RS', 
'Russian',       'RU', 
'Русский',		 'RU',
'Svenska',       'SE', 
'Slovenský',     'SK', 
'ไทย',           'TH',     
'Türkçe',        'TR', 
'Українська',    'UA' 
				);

use warnings;
use strict;

my $VERSION="0.2";

sub usage
{
	print "Usage: archdocumentalist.pl LANGUAGE PATH\nwhere\n\tLANGUAGE is a valid language code (EN, FR, DE...).\n" ;
	print "\tSee http://en.wikipedia.org/wiki/ISO_3166-1\n";
	print "\tPATH is the output path\n";
}

if ($#ARGV!=1) # 1 = 2 args
{
	usage();
	exit(0);
}

my $LANGUAGE=uc($ARGV[0]); #Declare before use LWP::Simple to avoid errors

#Check and find the language
my @langs;
while (my ($key,$value) = each(%lang_hash) ) 
{
	if ( $LANGUAGE eq $value )
	{
		push(@langs, $key);
	}
}
if ($#langs==-1)
{
	print "Wrong language.\n";
	print "Use one of the following standard code\n";
	for (keys %lang_hash) { print "$_ => $lang_hash{$_}\n"; }
	print "If you find a mistake or a missing item. Please, open a bug report at http://github.com/sciunto/archdocumentalist\n";
	usage();
	exit(0);
}

#Path
my $PATH=$ARGV[1]; #Declare before use LWP::Simple to avoid errors
unless ($PATH=~m/.*\/$/) {$PATH.='/';} #Complete the path with a / if needed

use Encode;
use JSON::XS;
use LWP::Simple;


my $DATADIR=$PATH."arch-wiki-".$LANGUAGE."/"; #Directory for data
mkdir $DATADIR; 
my $indexfile=$DATADIR."index.html"; #index file

#Start the index page
open (INDEX,">:utf8",$indexfile) or die "cannot open index.html";
print INDEX "<HTML><HEAD> Archlinux wiki ".$LANGUAGE." </HEAD><BODY>\n";
close(INDEX);

my $from = "";
my $count = 0;
use constant TITLE => $from;


print "Download pages... it might take a while.\n";

#loop on different pages. Stop when $count==1.
while()
{
	$count=0;
	my $text= get("http://wiki.archlinux.org/api.php?action=query&list=allpages&aplimit=500&format=json&apfilterredir=nonredirects&apfrom=$from");
	my $ret = JSON::XS->new->utf8->decode($text);
	my $elements = $ret->{query}->{allpages};

	#loop on all elements of the current page($from)
	foreach (@$elements)
	{
		my $title=encode("utf8","$_->{title}");
		$from=$title; #Do not modify this variable. No perl module for constant in extra/community...
		#Detect the language of the current page
		my $page_lang=$title;
		my $index_entry = $title;
		if ($page_lang=~ m/.*\((.*)\)/)
		{
			$page_lang=~ s/.*\((.*)\)/$1/;
			$index_entry =~ s/(.*)\($page_lang\)/$1/;
		}
		else 
		{
			$page_lang="English"; #Default language
		}
		
		#loop on @langs: positive strings in titles
		for my $lang (@langs)
		{
			#Save the page if language is OK.		
			if($lang eq $page_lang)
			{
				#Download the wiki page
				my $link="http://wiki.archlinux.org/index.php?title=".$title ."&printable=yes";
				my $doc = get($link); #Download the page
				
				if (defined $doc)
				{
					#Save the page
					my $fname=$DATADIR.$_->{pageid}.'.html';
					open (FILE,">:utf8",$fname) or die "cannot open file $fname";
					print FILE $doc;
					close(FILE);

					open (INDEX,">>:utf8",$indexfile) or die "cannot open index.html";
					print INDEX "<P><A HREF=\'".$_->{pageid}.".html\'>".$index_entry."</A>\n"; 
					close(INDEX);
				}
			}
		}
		$count++;
	}
	last if($count == 1) #end of while loop
}

#Finish the index page
open (INDEX,">>:utf8",$indexfile) or die "cannot open index.html";
print INDEX "</BODY></HTML>";
close(INDEX);
print "Done.\nDocumentation generated in ".$DATADIR."\n";
exit(0);
