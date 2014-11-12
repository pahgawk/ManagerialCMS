#!C:/xampp/perl/bin/perl.exe
use CGI;
use Page;
use Category;
use strict;

my %config = do 'config.pl';
my $query = CGI->new();
my $pageName = $query->param("page") || "index";
my $source = "content/" . $pageName . ".html";
my $sourceDir = "content/" . $pageName;
my $sourceCache = "cache/" . $pageName . "_cache.html";

#Show cached page if it exists
my $remake = 0;
if (-e $sourceCache) {
	open my $cached, "<", $sourceCache or die "Can't open $source: $!";
	my $input = <$cached>;
	my $created = 0;
	if ($input =~ /<\!-- ([0-9]+) -->/) {
		$created = $1;
	}
	if (time-$created <= $config{cacheLife}*60*60) {
		print $query->header("text/html");
		while (<$cached>) {
			print $_;
		}
	} else {
		$remake = 1;
	}
	close $cached or die "can't close '$cached': $!";
} else {
	$remake = 1;
}

if ($remake) {

	#make cache subdirectory if it doesn't exist
	my $dir = "";
	$dir = $1 if $pageName =~ /^(.*)\/[\w-]/;
	my $cacheDir = "cache/" . $dir;
	if (!-d $cacheDir) {
		mkdir $cacheDir or die "Unable to create $cacheDir";
	}

	my $content = "";
	my $cache = 0;

	if ($pageName eq "index") {
		print $query->header("text/html");
		$cache = 1;
		my $page = Page->new($source, $config{root});
		$content .= $config{theme}->main($page);

	} elsif (-e $source) {
		print $query->header("text/html");
		$cache = 1;
		my $page = Page->new($source, $config{root});
		$content .= $config{theme}->content($page);

		for (my $i=0; $i<scalar @{$config{plugins}}; $i++) {
			$content = $config{plugins}[$i]->content($content, $page);
		}

	} elsif (-d $sourceDir) {
		print $query->header("text/html");
		$cache = 1;
		my $category = Category->new($sourceDir, $config{root});
		
		$content .= $config{theme}->dir($category);
	} else {
		print $query->header( -status => '404 Not Found' );
		$content .= $config{theme}->error(404, $config{root});
	}

	print $content;

	$content = "<!-- " . time . " -->\n" . $content;

	if ($cache) {
		open my $cached, ">", $sourceCache or die "Can't open $sourceCache: $!";
		print $cached $content;
		close $cached or die "can't close '$cached': $!";
	}
}
