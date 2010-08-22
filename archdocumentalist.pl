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
# ไทย
# Česky
# Dansk
# Deutsch
# English
# Español
# Français
# Indonesia
# Italiano
# Italiano in corso
# Italitan
# Lietuviškai
# Magyar
# Nederlands
# Polski
# Português
# Pусский
# Română
# Russian
# Slovenský
# Srpski
# Suomi
# Svenska
# Türkçe
#  עברית #
# Ελληνικά
# Български
# русский
# Русский
# Српски
# Українська
# ФОС
# 日本語
# 正體中文
# 简体中文
# 繁體中文

use warnings;
use strict;

my $VERSION="0.1";

sub usage
{
	print "Usage: archdocumentalist.pl LANGUAGE PATH\nwhere LANGUAGE is a valid Language.\n" ;
	print "Read the source file for a list of available languages.\n";
	print "PATH is the output path\n";
}

if ($#ARGV!=1) # 1 = 2 args
{
	usage();
	exit(0);
}

my $LANGUAGE=$ARGV[0]; #Declare before use LWP::Simple to avoid errors
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
		my $lang=$title;
		my $index_entry = $title;
		if ($lang=~ m/.*\((.*)\)/)
		{
			$lang=~ s/.*\((.*)\)/$1/;
			$index_entry =~ s/(.*)\($lang\)/$1/;
		}
		else 
		{
			$lang="English"; #Default language
		}

		#Save the page if language is OK.		
		if($lang eq $LANGUAGE)
		{
			#Download the wiki page
			my $link="http://wiki.archlinux.org/index.php?title=".$title ."&printable=yes";
			my $doc = get($link); #Download the page
			
			#Save the page
			my $fname=$DATADIR.$_->{pageid}.'.html';
			open (FILE,">:utf8",$fname) or die "cannot open file $fname";
			print FILE $doc;
			close(FILE);

			open (INDEX,">>:utf8",$indexfile) or die "cannot open index.html";
			print INDEX "<P><A HREF=\'".$_->{pageid}.".html\'>".$index_entry."</A>\n"; 
			close(INDEX);
		}
		$count++;
	}
	last if($count == 1) #end of while loop
}

#Finish the index page
open (INDEX,">>:utf8",$indexfile) or die "cannot open index.html";
print INDEX "</BODY></HTML>";
close(INDEX);
print "Done.\nDocumentation generated in ".$DATADIR."\n"
exit(0);
