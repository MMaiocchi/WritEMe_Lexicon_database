#!/usr/local/bin/perl

# This code was written by Massimo Maiocchi as part of the project "Writing in Early Mesopotamia (WritEMe)",
# which has received funding from the European Union’s Horizon 2020 research and innovation
# programme under the Marie Skłodowska-Curie grant agreement n. 882257.
# For further information please visit https://writeme.hypotheses.org

use strict;
use warnings;
use utf8;
use utf8::all;
use Sort::Naturally;
use Text::CSV;
use HTML::TreeBuilder;
use HTML::Entities;
my $csv = Text::CSV->new({ sep_char => ',' });

#the following paths areto be adjusted according to locale
my $project_directory = 'C:\Users\Documents\project';
my $cdli_catalogue = 'C:\Users\Documents\project\input\cdli_catalogue.csv'; #https://cdli.ucla.edu/bulk_data/
my $cdli_transliterations = 'C:\Users\Documents\input\cdliatf.atf'; #https://cdli.ucla.edu/bulk_data/
my $datafile = 'C:\Users\Documents\project\input\_ePSD2_data.tab';
my $datafile2 = 'C:\Users\Documents\input\project_extra_data.tab';


my %hash_catalogue = ();
my %hash_words_matches = ();
my %hash_words_texts = ();

open( CATALOGUE, "<$cdli_catalogue" ) || die "Error opening the catalogue file!:$!\n\n";
my @catalogue = <CATALOGUE>;

open( LEMMAS, "<_my_lemmas.tab" ) || die "Error opening the input file!:$!\n\n";
my @lemmas = <LEMMAS>;


open( DATA1, "<$datafile" ) || die "Error opening the data file!:$!\n\n";
my @input = <DATA1>;
open( DATA2, "<$datafile2" ) || die "Error opening the data file!:$!\n\n";
my @input2 = <DATA2>;
push( @input, @input2 );

open( UNWANTED, "<_unwanted_spellings.tab" )
  || die "Error opening the unwanted spellings file!:$!\n\n";
my @unwanted        = <UNWANTED>;
my %unwanted_lemmas = ();
foreach my $line (@unwanted) {
    next if ( $line =~ m/^#/ );
    chomp $line;
    my @parts = split /\t/, $line;
    next if ( !$parts[0] );
    my $id = $parts[0];
    $id =~ s/^\s+|\s+$//;
    my $unwanted               = "";
    my $all_unwanted_spellings = "";
    $all_unwanted_spellings = $parts[1] if ( $parts[1] );
    @unwanted               = split /,|;/, $all_unwanted_spellings;

    foreach my $unw (@unwanted) {
        $unw =~ s/^\s+|\s+$//;
        next if ( !$unw );
        $unwanted_lemmas{$id}{$unw}++;
    }
}

foreach my $line (@catalogue) {
  process_catalogue_data ($line);
}


#output in just 1 big file
open( HTML_TEMPLATE, "<html_template.txt" ) || die "Error opening HTML template!:$!\n\n";
my @html_template = <HTML_TEMPLATE>;
close HTML_TEMPLATE;

#left panel
open( MENU_TEMPLATE, "<menu_template.txt" ) || die "Error opening HTML1 template!:$!\n\n";
my @menu_template = <MENU_TEMPLATE>;
close MENU_TEMPLATE;

#right panel
my $file = 'page_template.txt';
my $page_template = do {
    local $/ = undef;
    open my $fh, "<", $file
      or die "could not open $file: $!";
    <$fh>;
};

#main page
open ( INDEX_TEMPLATE, "<index_template.txt") || die "Error opening the index template!:$!\n\n";
my @index_template = <INDEX_TEMPLATE>;
close INDEX_TEMPLATE;

#middle panel
open ( LEX_TEMPLATE, "<lex_template.txt") || die "Error opening the lexicon template!:$!\n\n";
my @lex_template = <LEX_TEMPLATE>;
close LEX_TEMPLATE;

#Statistics
open (STAT_TEMPLATE, "<stat_template.txt") || die "Error opening the statistics template file!:$!\n\n";
my @stat_template = <STAT_TEMPLATE>;


chdir $project_directory || die "Can't navigate to project folder: $1\n";

open( OUT_HTML, ">_miner_output.html" ) || die "Error creating the output HTML file!:$!\n\n";
print OUT_HTML @html_template;

open( OUT_MENU, ">menu.html" ) || die "Error creating the output menu HTML file!:$!\n\n";
print OUT_MENU @menu_template;

#used for debugging
open( DUMP, ">_dump.txt" ) || print "Error creating the dump file!:$!\n\n";


my %selected_lemmas = ();
foreach my $line (@lemmas) {
    chomp $line;
    my @parts   = split /\t/, $line;
    my $ranking = "";
    $ranking = $parts[1] if ( $parts[1] );
    $ranking =~ s/\s//g;
    next if ( !$ranking );
    next if ( $ranking =~ m /^x$/ );
    my $id = $parts[0];
    $id =~ s/^\s+|\s+$//;
    $selected_lemmas{$id} = $ranking;
}

my %sum_hash   = ();
my %seen       = ();
my $line_count = 0;
foreach my $line (@input) {
    next if ( $line =~ m/^#/ );
    chomp $line;
    my @parts = split /\t/, $line;
    my $ID    = $parts[0];
    $ID =~ s/^\s+|\s+$//;
    next if !$ID;
    next if ( !exists $selected_lemmas{$ID} );
    if ( exists $seen{$ID} ) {
        print "ERROR: the following ID is already in use: -->$ID<-- line $line\n";
        print "compare: $seen{$ID}\nCurrently working on line $line_count of the merged input files\n";
        print "check the following files for inconsistencies:\n\t$datafile\n\t$datafile2\n";

    }
    $seen{$ID} = $line;
    $line_count++;

    #citation to ePSD2 to be implemented
    if ($parts[9]) {
      my $lemma_citation_url = $parts[9];
      $lemma_citation_url =~ s/^\s+||s+$//g;
      #etc.
    }

    my $all_sum_spellings    = $parts[2];
    my $extra_sum_spellings1 = $all_sum_spellings;
    my $extra_sum_spellings2 = $all_sum_spellings;
    $all_sum_spellings =~ s/<sup>/{/g;
    $all_sum_spellings =~ s/<\/sup>/}/g;

    $extra_sum_spellings1 =~ s/<sup>ŋeš<\/sup>/<sup>giš<\/sup>/g;
    $extra_sum_spellings1 =~ s/ŋ/g/g;
    $extra_sum_spellings1 =~ s/Ŋ/G/g;
    $extra_sum_spellings1 =~ s/<sup>/{/g;
    $extra_sum_spellings1 =~ s/<\/sup>/}/g;

    $extra_sum_spellings2 =~ s/<sup>ŋeš<\/sup>/<sup>geš<\/sup>/g;
    $extra_sum_spellings2 =~ s/ŋ/g/g;
    $extra_sum_spellings2 =~ s/Ŋ/G/g;
    $extra_sum_spellings2 =~ s/<sup>/{/g;
    $extra_sum_spellings2 =~ s/<\/sup>/}/g;

    my $forms        = "";
    my $extra_forms1 = "";
    my $extra_forms2 = "";

    $forms        = $parts[12] if ( $parts[12] );
    $extra_forms1 = $forms;
    $extra_forms2 = $forms;

    $extra_forms1 =~ s/\{ŋeš\}/{geš}/g;
    $extra_forms1 =~ s/ŋ/g/g;
    $extra_forms1 =~ s/Ŋ/G/g;

    $extra_forms2 =~ s/\{ŋiš\}/{giš}/g;
    $extra_forms2 =~ s/ŋ/g/g;
    $extra_forms2 =~ s/Ŋ/G/g;

    my $augmented_sum_spellings =
        $all_sum_spellings . ','
      . $extra_sum_spellings1 . ','
      . $extra_sum_spellings2 . ','
      . $forms . ','
      . $extra_forms1 . ','
      . $extra_forms2;

    $all_sum_spellings =~ s/š/sz/g;
    $all_sum_spellings =~ s/ḫ/h/g;
    my @sum_spellings = split /,/, $augmented_sum_spellings;
    @sum_spellings = uniq(@sum_spellings);

    #HASH: e2-dub-ba => eduba [STOREHOUSE] || edubbaʾa [SCRIBAL SCHOOL]
  CREATE_SUM_HASH:
    foreach my $sp (@sum_spellings) {
        $sp =~ s/^\s+|\s+$//;

        #avoid unwanted lemmas
        foreach my $unwanted_item ( keys %{ $unwanted_lemmas{$ID} } ) {
            if ( $sp eq $unwanted_item ) {
                next CREATE_SUM_HASH;
            }
        }
        if ( !exists $sum_hash{$sp} ) {
            $sum_hash{$sp} = $ID;
        }
        else {
            my $existing_ID = $sum_hash{$sp};
            $sum_hash{$sp} = $ID . '||' . $existing_ID;
        }
    }

    my $all_akk_equivalents = "";
    $all_akk_equivalents = $parts[4] if ( $parts[4] );
    my @akk_equivalents = split /;/, $all_akk_equivalents;

    #akkadian to be implemented
}

#FIXING HASH VALUES
foreach my $sp ( sort keys %sum_hash ) {
    my $IDS        = $sum_hash{$sp};
    my @ID_parts   = split /\|\|/, $IDS;
    my %hash_parts = ();
    foreach my $part (@ID_parts) {
        $hash_parts{$part}++;
    }
    my $final_IDS = join '||', sort keys %hash_parts;
    $sum_hash{$sp} = $final_IDS;
    print DUMP "$sp -> $sum_hash{$sp}\n";
}

my $document = do {
    local $/ = undef;
    open my $fh, "<", $cdli_transliterations
      or die "could not open $cdli_transliterations: $!";
    <$fh>;
};

$document =~ tr/₀₁₂₃₄₅₆₇₈₉ₓ/0123456789x/;

#$document = decode_entities($document);
print "\nGathering data, please wait...\n";
my @paragraphs = split /\R&/, $document;
print "\nProcessing...\n";

my %hash_results      = ();
my %hash_menu         = ();
my $total_texts_count = 0;
my $total_found_texts = 0;
my $total_matches = 0;

foreach my $paragraph (@paragraphs) {
    my @lines      = split /\n/, $paragraph;
    my $P_num      = "";
    my $score      = 0;
    my $saved_text = "";
    my $lang       = "";
    foreach my $line (@lines) {
        $line =~ tr/<>/˂˃/;  #deal with special characters conflicting with HTML
        $line =~ s/^\s+|\s+$//;
        next if ( !$line );

        if ( $line =~ m/(^P\d+)/ ) {
            $P_num = $1;
            print "... $P_num\n";
            $saved_text =
                $saved_text
              . '<span class = Pnum>'
              . "<a href = \"https://cdli.ucla.edu/$P_num\" target=\"_blank\">"
              . $line
              . '</a></span>'
              . "<br>\n";
            $total_texts_count++;
            next;
        }
        if ( $line =~ m/^#/ ) {
            $saved_text =
                $saved_text
              . '<span class = catMeta>'
              . $line
              . '</span>'
              . "<br>\n";
            if ( $line =~ m/#atf: lang akk/ ) {
                $lang = 'akk';
            }
            next;
        }
        if ( $line =~ m/^>>/ ) {
            $saved_text =
                $saved_text
              . '<span class = transMeta>'
              . $line
              . '</span>'
              . "<br>\n";
            next;
        }
        if ( $line =~ m/^@|\$/ ) {
            $saved_text =
                $saved_text
              . '<span class = transMeta>'
              . $line
              . '</span>'
              . "<br>\n";
            next;
        }

        #change format to numbers and partial textual brakes
        my @tokens = split /\s+/, $line;
        foreach ( my $i = 0 ; $i <= $#tokens ; $i++ ) {
            if ( $tokens[$i] !~ m/^\[?_?Q?P?\d/ ) {
                $tokens[$i] =~ tr/0123456789/₀₁₂₃₄₅₆₇₈₉/;
            }

            my @token_parts = split /(\.|\-)/, $tokens[$i];
            foreach my $tp (@token_parts) {

                if ( $tp =~ m /\#/ ) {
                    $tp =~ s/\#//g;
                    $tp = '˹' . $tp . '˺';
                }
            }
            $tokens[$i] = join '', @token_parts;
        }

        my $line_formatted = join ' ', @tokens;
        $line_formatted =~ s/sz/š/g;
        $line_formatted =~ s/SZ/Š/g;
        $line_formatted =~ s/S,/Ṣ/g;
        $line_formatted =~ s/s,/ṣ/g;
        $line_formatted =~ s/T,/Ṭ/g;
        $line_formatted =~ s/t,/ṭ/g;
        $line_formatted =~ s/J/Ĝ/g;
        $line_formatted =~ s/j/ĝ/g;
        $line_formatted =~ s/\{(.+?)\}/<sup>$1<\/sup>/g;
        my @words_backup = split /\s+/, $line_formatted;




        #clean up transliterations
        $line =~ s/#//g;
        $line =~ s/\?//g;
        $line =~ s/\[|\]//g;

        #mask unwanted patterns
        if ( $line =~ m/(\d+\(.+?\)\s+ la2 \d+\(>+?\))/ ) { #2(u@c) la2 3(asz@c)
            $line =~ s/$1/############/;
        }
        if ( $line =~ m/(\d+ la2 \d+)/ ) {                  #2 la2 3
            $line =~ s/$1/############/;
        }
        if ( $line =~ m/(la2 \d+)/ ) {                      #3 ku3 la2 2
            $line =~ s/$1/############/;
        }

        my @words = split /\s+/, $line;
        foreach ( my $i = 0 ; $i <= $#words ; $i++ ) {
            my $word = $words[$i];
            next if ( !$word );
            if ( $lang eq 'akk' ) {
                if ( $word !~ /^_/ ) {
                    $saved_text = $saved_text . ' ' . $words_backup[$i];
                    next;
                }
                else {
                    $word =~ s/_//g;
                }
            }
            if ( exists $sum_hash{$word} ) {
                $words_backup[$i] =
                    '<mark><div class="tooltip">'
                  . $words_backup[$i]
                  . '<span class="tooltiptext">'
                  . $sum_hash{$word}
                  . '</span></div></mark>';
                $score++;
                $total_matches++;
                $hash_words_matches{$sum_hash{$word}}++;
                $hash_words_texts{$sum_hash{$word}}{$P_num}++;

            }
            $saved_text = $saved_text . ' ' . $words_backup[$i];
        }
        $saved_text = $saved_text . '<br>' . "\n";

    }
    if ( $score > 0 ) {
        $hash_results{$score}{$saved_text}++;
        $total_found_texts++;
        makeHTMLpage ($P_num, $saved_text);

        if (exists $hash_catalogue{$P_num}) {
          makeHTMLcataloguePage($P_num);
          print "FOUND catalogue information about $P_num\n"
        };
        $hash_menu{$P_num}{$score}++;
    }
}

print OUT_HTML "<h1>Results: $total_found_texts matching texts out of $total_texts_count transliterated texts</h1><br>";
foreach my $s ( sort { $b <=> $a } keys %hash_results ) {
    print OUT_HTML
      "<p> <div class = \"scoreBox\">--- SCORE: $s ---</div><br>\n";
    foreach my $text ( sort keys %{ $hash_results{$s} } ) {
        print OUT_HTML $text . "<br>\n<br>\n";
    }
    print OUT_HTML '</p><br>' . "\n\n";
}

print OUT_HTML "\n<\/body>\n<\/html>";
print OUT_MENU '<table id="my-table" class="display" cellspacing="0" style="width:100%">
        <thead>
            <tr>
                <th>ID</th>
                <th>Rank</th>
                <th>Prov</th>
                <th>Chron</th>
                <th>Gen</th>
            </tr>
        </thead>
        <tfoot>
            <tr>
                <th>ID</th>
                <th>Rank</th>
                <th>Prov</th>
                <th>Chron</th>
                <th>Genre</th>
            </tr>
        </tfoot>
        <tbody>
        ';

foreach my $p (nsort keys %hash_menu) {
  print OUT_MENU '            <tr>'."\n";
  foreach my $score (nsort keys %{$hash_menu{$p}}) {
    my $p_for_printing = $p;
    $p_for_printing =~ s/^P0*//;
    print OUT_MENU "                <td><span class = \"text_ID\"><a href = \"$p.html\" target=\"mainContent\">$p_for_printing<\/a><\/span><\/td>\n";
    print OUT_MENU "                <td><span class = \"score\">$score<\/span><\/td>\n";
    print OUT_MENU "                <td><span class = \"cat_info\">";
    if (exists $hash_catalogue{$p}{'provenience'}) {
      print OUT_MENU "$hash_catalogue{$p}{'provenience'}";
    }
    print OUT_MENU "<\/span><\/td>\n";
    print OUT_MENU "                <td><span class = \"cat_info\">";
    if (exists $hash_catalogue{$p}{'period'}) {
      print OUT_MENU "$hash_catalogue{$p}{'period'}";
    }
    print OUT_MENU "<\/span><\/td>\n";
    print OUT_MENU "                <td><span class = \"cat_info\">";
    if (exists $hash_catalogue{$p}{'genre'}) {
      print OUT_MENU "$hash_catalogue{$p}{'genre'}";
    }

    print OUT_MENU "<\/span><\/td>\n";
    print OUT_MENU '            </tr>'."\n";
  }
}
print OUT_MENU "        <\/tbody>\n<\/table>\n";
print OUT_MENU "\n<\/body>\n<\/html>";



open( OUT_INDEX, ">index.html" ) || die "Error creating the output index HTML file!:$!\n\n";
print OUT_INDEX @index_template;

open( OUT_LEX, ">lexicon.html" ) || die "Error creating the output index HTML file!:$!\n\n";
print OUT_LEX @lex_template;

foreach my $word (sort {$hash_words_matches{$b} <=> $hash_words_matches{$a}} keys %hash_words_matches) {
            print OUT_LEX '            <tr>'."\n";

            my @elements = split /\|\|/, $word;
            my $spelling = "";
            my $meanings = "";
            my %hash_spell = ();
            my %hash_mean = ();
            foreach my $el (@elements) {
              $el =~ s/^\s+|\s+$//g;
              my @el_parts = split /\[/, $el;
              $el_parts[0] =~ s/^\s+|\s+$//g;
              $el_parts[1] =~ s/^\s+|\s+$//g;
              $hash_spell{$el_parts[0]}++;
              $hash_mean{$el_parts[1]}++;
            }

            $spelling = join '||', sort keys %hash_spell;
            $meanings = join '||', sort keys %hash_mean;
            $meanings =~ s/\]//g;
            print OUT_LEX "              <td>$spelling<\/td>\n";
            print OUT_LEX "              <td>$meanings<\/td>\n";
            print OUT_LEX "              <td>$hash_words_matches{$word}<\/td>\n";
            print OUT_LEX "              <td>";



            my @Pnums = sort keys %{$hash_words_texts{$word}};
            for (my $i=0; $i<=$#Pnums;$i++) {
              my $p_for_printing = $Pnums[$i];
              $p_for_printing =~ s/^P0*//;
              print OUT_LEX "<a href = \"$Pnums[$i].html\" target=\"mainContent\">$p_for_printing<\/a>";
              print OUT_LEX ", " if ($i <$#Pnums);
            }
            print OUT_LEX "<\/td>\n";

            #print OUT_STAT join ', ', @Pnums;
            print OUT_LEX '            </tr>'."\n";
  }

print OUT_LEX "        <\/tbody>\n<\/table>\n";
print OUT_LEX "        <\/body>\n<\/html>\n";


open( OUT_STAT, ">statistics.html" ) || die "Error creating the output index HTML file!:$!\n\n";
print OUT_STAT @stat_template;
print OUT_STAT "<h2>Statistics:<\/h2><br>
<ul>
  <li>Total texts: $total_texts_count<\/li>
  <li>Texts with ranking 1 or more: $total_found_texts<\/li>
  <li>Total matches: $total_matches<\/li>
<\/ul>";

print OUT_STAT '<div id="container" style="width: 75%;">
    <canvas id="myChart"></canvas>
  </div>

  <script>
  var ctx = document.getElementById(\'myChart\').getContext(\'2d\');
  var gradientStroke = ctx.createLinearGradient(500, 0, 100, 0);
  gradientStroke.addColorStop(0, \'#80b6f4\');
  gradientStroke.addColorStop(1, \'#f49080\');

  var myChart = new Chart(ctx, {
      type: \'bar\',
      data: {
          labels: [';
my @scores = sort { $b <=> $a } keys %hash_results;

 for (my $s= 0; $s<=$#scores;$s++) {
   print OUT_STAT "'$scores[$s]'";
   print OUT_STAT ", " if ($s<$#scores);
 }
   print OUT_STAT '],'."\n";
   print OUT_STAT "          datasets: [{
                 label: '',
                 backgroundColor: gradientStroke,
                 borderColor: gradientStroke,
                 pointBorderColor: gradientStroke,
                 pointBackgroundColor: gradientStroke,
                 pointHoverBackgroundColor: gradientStroke,
                 pointHoverBorderColor: gradientStroke,
                 pointBorderWidth: 10,
                 pointHoverRadius: 10,
                 pointHoverBorderWidth: 1,
                 pointRadius: 3,
                 fill: false,
                 borderWidth: 14,
                 data: [";
  for (my $s= 0; $s<=$#scores;$s++) {
    my @texts_in_score = keys %{$hash_results{$scores[$s]}};
    my $num_of_texts_in_score = scalar @texts_in_score;
    #print "\tscore_A: $scores[$s] -> ".$#texts_in_score."\n";
    #print "\tscore_B: $scores[$s] -> $num_of_texts_in_score\n";
    #for (my $i=0;$i<=$#texts_in_score; $i++) {
    #    print "\sscore: $s -> $#texts_in_score\n"
    #}
    my $texts_in_scores = scalar keys %{$hash_results{$scores[$s]}};
    #print "\tscore_C: $scores[$s] -> $texts_in_scores\n\n";
    print OUT_STAT "$texts_in_scores";
    print OUT_STAT ", " if ($s < $#scores);
  }
    print OUT_STAT "],
}]
},
options: {
  legend: {
        display: false
    },
    tooltips: {
        callbacks: {
           label: function(tooltipItem) {
                  return tooltipItem.yLabel;
           }
        }
    },
scales: {
  xAxes: [{
      ticks: {
          beginAtZero: true
      },
      scaleLabel: {
        display: true,
        labelString: 'text rank (based on # of matches)'
      }
  }],
    yAxes: [{
        ticks: {
            beginAtZero: true,
            callback: function(value) {if (value % 1 === 0) {return value;}}
        },
        scaleLabel: {
          display: true,
          labelString: '# of texts'
        }
    }]
}
}
});
<\/script>";
print OUT_STAT "</body>\n</html>";

close DATA1;
close DATA2;
close OUT_HTML;
close OUT_INDEX;
close OUT_MENU;
close OUT_STAT;
close LEMMAS;
print "DONE!\n";
print "Check files in $project_directory\n";

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub makeHTMLpage {

  my ($Pnum, $text) = @_;
  my $pageName = $Pnum.'.html';
  open(OUT_PAGE, ">$pageName" ) || die "Error creating the $pageName file!:$!\n\n";

  my $page_template_final = $page_template;

  $page_template_final =~ s/_PNUM_/$Pnum/;
  $page_template_final =~ s/_TEXT_/$text/;
  print OUT_PAGE $page_template_final;
  close OUT_PAGE;
}

sub makeHTMLcataloguePage {
    my ($Pnum) = @_;
    my $pageName = $Pnum.'_cat.html';
    print "... generating $pageName\n";
    open(OUT_PAGE_CAT, ">$pageName" ) || die "Error creating the $pageName file!:$!\n\n";
    print OUT_PAGE_CAT "<!DOCTYPE html>
    <html lang=\"eng\">
    <head>
    <meta charset=\"utf-8\"/>
    <STYLE>
    body {
      font-family: \"Times New Roman\";
      font-size: 10.5pt;
      line-height: 12pt;
    }
    <\/STYLE>
    <title>WritEMe database -- $Pnum catalogue data</title>
    <\/head>
    <body>\n";
    print OUT_PAGE_CAT "period: ".$hash_catalogue{$Pnum}{'period'}."<br>\n";
    print OUT_PAGE_CAT "period_remarks: ".$hash_catalogue{$Pnum}{'period_remarks'}."<br>\n";
    print OUT_PAGE_CAT "primary_publication: ".$hash_catalogue{$Pnum}{'primary_publication'}."<br>\n";
    print OUT_PAGE_CAT "genre: ".$hash_catalogue{$Pnum}{'genre'}."<br>\n";
    print OUT_PAGE_CAT "subgenre: ".$hash_catalogue{$Pnum}{'subgenre'}."<br>\n";
    print OUT_PAGE_CAT "subgenre_remarks: ".$hash_catalogue{$Pnum}{'subgenre_remarks'}."<br>\n";
    print OUT_PAGE_CAT "language: ".$hash_catalogue{$Pnum}{'language'}."<br>\n";
    print OUT_PAGE_CAT "material: ".$hash_catalogue{$Pnum}{'material'}."<br>\n";
    print OUT_PAGE_CAT "accession_no: ".$hash_catalogue{$Pnum}{'accession_no'}."<br>\n";
    print OUT_PAGE_CAT "collection: ".$hash_catalogue{$Pnum}{'collection'}."<br>\n";
    print OUT_PAGE_CAT "excavation_no: ".$hash_catalogue{$Pnum}{'excavation_no'}."<br>\n";
    print OUT_PAGE_CAT "museum_no: ".$hash_catalogue{$Pnum}{'museum_no'}."<br>\n";
    print OUT_PAGE_CAT "object_type: ".$hash_catalogue{$Pnum}{'object_type'}."<br>\n";
    print OUT_PAGE_CAT "primary_publication: ".$hash_catalogue{$Pnum}{'primary_publication'}."<br>\n";
    print OUT_PAGE_CAT "provenience: ".$hash_catalogue{$Pnum}{'provenience'}."<br>\n";
    print OUT_PAGE_CAT "publication_date: ".$hash_catalogue{$Pnum}{'publication_date'}."<br>\n";
    print OUT_PAGE_CAT "publication_history: ".$hash_catalogue{$Pnum}{'publication_history'}."<br>\n";
    print OUT_PAGE_CAT "published_collation: ".$hash_catalogue{$Pnum}{'published_collation'}."<br>\n";
    print OUT_PAGE_CAT "seal_id: ".$hash_catalogue{$Pnum}{'seal_id'}."<br>\n";
    print OUT_PAGE_CAT "seal_information: ".$hash_catalogue{$Pnum}{'seal_information'}."<br>\n";
    print OUT_PAGE_CAT "stratigraphic_level: ".$hash_catalogue{$Pnum}{'stratigraphic_level'}."<br>\n";

    print OUT_PAGE_CAT "<\/body>\n<\/html>";

    close OUT_PAGE_CAT;
}



sub process_catalogue_data {
    my ($line) = @_;

    chomp $line;
    $line =~ s/^\s+|\s+$//g;
    next if ( !$line );

    if ( $csv->parse($line) ) {

        my @columns = $csv->fields();

        my $accounting_period = '-';
         if ($columns[1]) {$accounting_period = $columns[1]};
        my $accession_no = '-';
         if ($columns[0]) {$accession_no = $columns[0]};
        my $acquisition_history = '-';
         if ($columns[2]) {$acquisition_history = $columns[2]};
        my $alternative_years = '-';
         if ($columns[3]) {$alternative_years = $columns[3]};
        my $ark_number = '-';
         if ($columns[4]) {$ark_number = $columns[4]};
        my $atf_source = '-';
         if ($columns[5]) {$atf_source = $columns[5]};
        my $atf_up = '-';
         if ($columns[6]) {$atf_up = $columns[6]};
        my $author = '-';
         if ($columns[7]) {$author = $columns[7]};
        my $author_remarks = '-';
         if ($columns[8]) {$author_remarks = $columns[8]};
        my $cdli_collation = '-';
         if ($columns[9]) {$cdli_collation = $columns[9]};
        my $cdli_comments = '-';
         if ($columns[10]) {$cdli_comments = $columns[10]};
        my $citation = '-';
         if ($columns[11]) {$citation = $columns[11]};
        my $collection = '-';
         if ($columns[12]) {$collection = $columns[12]};
        my $composite_id = '-';
         if ($columns[13]) {$composite_id = $columns[13]};
        my $condition_description = '-';
         if ($columns[14]) {$condition_description = $columns[14]};
        my $date_entered = '-';
         if ($columns[15]) {$date_entered = $columns[15]};
        my $date_of_origin = '-';
         if ($columns[16]) {$date_of_origin = $columns[16]};
        my $date_remarks = '-';
         if ($columns[17]) {$date_remarks = $columns[17]};
        my $date_updated = '-';
         if ($columns[18]) {$date_updated = $columns[18]};
        my $dates_referenced = '-';
         if ($columns[19]) {$dates_referenced = $columns[19]};
        my $db_source = '-';
         if ($columns[20]) {$db_source = $columns[20]};
        my $dumb = '-';
         if ($columns[22]) {$dumb = $columns[22]};
        my $designation = '-';
         if ($columns[21]) {$designation = $columns[21]};
        my $dumb2 = '-';
         if ($columns[23]) {$dumb2 = $columns[23]};
        my $electronic_publication = '-';
         if ($columns[24]) {$electronic_publication = $columns[24]};
        my $elevation = '-';
         if ($columns[25]) {$elevation = $columns[25]};
        my $excavation_no = '-';
         if ($columns[26]) {$excavation_no = $columns[26]};
        my $external_id = '-';
         if ($columns[27]) {$external_id = $columns[27]};
        my $findspot_remarks = '-';
         if ($columns[28]) {$findspot_remarks = $columns[28]};
        my $findspot_square = '-';
         if ($columns[29]) {$findspot_square = $columns[29]};
        my $genre = '-';
         if ($columns[30]) {$genre = $columns[30]};
         $genre =~ s/\s*\(.+\)//;
         $genre =~ s/Lexical/lex/;
         $genre =~ s/Administrative/adm/;
         $genre =~ s/School/schl/;
         $genre =~ s/uncertain/unc/;
         $genre =~ s/Legal/leg/;
         $genre =~ s/Royal\/Monumental/roy/;
         $genre =~ s/Literary/lit/;
         $genre =~ s/Mathematical/math/;
         $genre =~ s/Prayer\/Incantation/pray/;
         $genre =~ s/Letter/lett/;
         $genre =~ s/Ritual/rit/;
         $genre =~ s/Private\/Votive/priv/;
         $genre =~ s/Other/oth/;
         $genre =~ s/Scientific/scie/;
         $genre =~ s/Omen/omen/;
         $genre =~ s/Literary; Mathematical/lit-mat/;
         $genre =~ s/Lexical; Literary/lex-lit/;
         $genre =~ s/Lexical; Mathematical/lex-math/;
         $genre =~ s/Lexical; School/lex-schl/;
         $genre =~ s/Lexical; Literary; Mathematical/lex-math/;
         $genre =~ s/Literary; Lexical/lex-lit/;
         $genre =~ s/Literary; Letter/lit-lett/;
         $genre =~ s/Astronomical/astr/;
         $genre =~ s/Literary; Administrative/lit-adm/;
         $genre =~ s/Royal\/Monumental; Literary/roy/;
         $genre =~ s/Historical/hist/;
         $genre =~ s/Astronomical, Omen/astr-omen/;
         $genre =~ s/Pottery (seal)/seal/;
         $genre =~ s/Votive/vot/;
         $genre =~ s/Royal\/Votive/roy/;

        my $google_earth_collection = '-';
         if ($columns[31]) {$google_earth_collection = $columns[31]};
        my $google_earth_provenience = '-';
         if ($columns[32]) {$google_earth_provenience = $columns[32]};
        my $height = '-';
         if ($columns[33]) {$height = $columns[33]};
        my $id = '-';
         if ($columns[34]) {$id = $columns[34]};
        my $id_text2 = '-';
         if ($columns[35]) {$id_text2 = $columns[35]};
        my $id_text = '-';
         if ($columns[36]) {$id_text = $columns[36]};
        my $join_information = '-';
         if ($columns[37]) {$join_information = $columns[37]};
        my $language = '-';
         if ($columns[38]) {$language = $columns[38]};
        my $lineart_up = '-';
         if ($columns[39]) {$lineart_up = $columns[39]};
        my $material = '-';
         if ($columns[40]) {$material = $columns[40]};
        my $museum_no = '-';
         if ($columns[41]) {$museum_no = $columns[41]};
        my $object_preservation = '-';
         if ($columns[42]) {$object_preservation = $columns[42]};
        my $object_type = '-';
         if ($columns[43]) {$object_type = $columns[43]};
        my $period = '-';
         if ($columns[44]) {$period = $columns[44]};
         $period =~ s/\(.+\)//;
         $period =~ s/Early Dynastic/ED/;
         $period =~ s/Old Akkadian/OAkk/;
         $period =~ s/Ur III/UrIII/;
         $period =~ s/Old Assyrian/OA/;
         $period =~ s/Middle Assyrian/MA/;
         $period =~ s/Neo-Assyrian/NA/;
         $period =~ s/Early Old Babylonian/EOB/;
         $period =~ s/Old Babylonian/OB/;
         $period =~ s/Middle Babylonian/MB/;
         $period =~ s/Neo-Babylonian/NB/;
         $period =~ s/Achaemenid/Ach/;
         $period =~ s/Hellenistic/Hel/;
         $period =~ s/Middle Hittite/MH/;
         $period =~ s/Egyptian/Egy/;
         $period =~ s/Harappan/Har/;
         $period =~ s/Lagash II/LgII/;
         $period =~ s/Linear Elamite/LE/;
         $period =~ s/Proto-Elamite/PE/;
         $period =~ s/Middle Elamite/ME/;
         $period =~ s/Neo-Elamite/NE/;
         $period =~ s/Old Elamite/OE/;
         $period =~ s/Parthian/Par/;
         $period =~ s/Pre-Uruk/<Uruk/;
         $period =~ s/uncertain/unc/;
         $period =~ s/Sassanian/Sas/;
         $period =~ s/\s//g;

        my $period_remarks = '-';
         if ($columns[45]) {$period_remarks = $columns[45]};
        my $photo_up = '-';
         if ($columns[46]) {$photo_up = $columns[46]};
        my $primary_publication = '-';
         if ($columns[47]) {$primary_publication = $columns[47]};
        my $provenience = '-';
         if ($columns[48]) {$provenience = $columns[48]};
         $provenience =~ s/\(.+\)//;
        my $provenience_remarks = '-';
         if ($columns[49]) {$provenience_remarks = $columns[49]};
        my $publication_date = '-';
         if ($columns[50]) {$publication_date = $columns[50]};
        my $publication_history = '-';
         if ($columns[51]) {$publication_history = $columns[51]};
        my $published_collation = '-';
         if ($columns[52]) {$published_collation = $columns[52]};
        my $seal_id = '-';
         if ($columns[53]) {$seal_id = $columns[53]};
        my $seal_information = '-';
         if ($columns[54]) {$seal_information = $columns[54]};
        my $stratigraphic_level = '-';
         if ($columns[55]) {$stratigraphic_level = $columns[55]};
        my $subgenre = '-';
         if ($columns[56]) {$subgenre = $columns[56]};
        my $subgenre_remarks = '-';
         if ($columns[57]) {$subgenre_remarks = $columns[57]};
        my $surface_preservation = '-';
         if ($columns[58]) {$surface_preservation = $columns[58]};
        my $text_remarks = '-';
         if ($columns[59]) {$text_remarks = $columns[59]};
        my $thickness = '-';
         if ($columns[60]) {$thickness = $columns[60]};
        my $translation_source = '-';
         if ($columns[61]) {$translation_source = $columns[61]};
        my $width = '-';
         if ($columns[62]) {$width = $columns[62]};
        my $object_remarks = '-';
         if ($columns[63]) {$object_remarks = $columns[63]};

        if ($id) {
            $id = 'P'.sprintf("%06d", $id); #ex.: P011091
            print "processing catalogue $id\n";
            $hash_catalogue{$id}{'accession_no'}        = $accession_no;
            $hash_catalogue{$id}{'accounting_period'}   = $accounting_period;
            $hash_catalogue{$id}{'acquisition_history'} = $acquisition_history;
            $hash_catalogue{$id}{'alternative_years'}   = $alternative_years;
            $hash_catalogue{$id}{'ark_number'}          = $ark_number;
            $hash_catalogue{$id}{'atf_source'}          = $atf_source;
            $hash_catalogue{$id}{'atf_up'}              = $atf_up;
            $hash_catalogue{$id}{'author'}              = $author;
            $hash_catalogue{$id}{'author_remarks'}      = $author_remarks;
            $hash_catalogue{$id}{'cdli_collation'}      = $cdli_collation;
            $hash_catalogue{$id}{'cdli_comments'}       = $cdli_comments;
            $hash_catalogue{$id}{'citation'}            = $citation;
            $hash_catalogue{$id}{'collection'}          = $collection;
            $hash_catalogue{$id}{'composite_id'}        = $composite_id;
            $hash_catalogue{$id}{'condition_description'} = $condition_description;
            $hash_catalogue{$id}{'date_entered'}     = $date_entered;
            $hash_catalogue{$id}{'date_of_origin'}   = $date_of_origin;
            $hash_catalogue{$id}{'date_remarks'}     = $date_remarks;
            $hash_catalogue{$id}{'date_updated'}     = $date_updated;
            $hash_catalogue{$id}{'dates_referenced'} = $dates_referenced;
            $hash_catalogue{$id}{'db_source'}        = $db_source;
            $hash_catalogue{$id}{'dumb'}             = $dumb;
            $hash_catalogue{$id}{'designation'}      = $designation;
            $hash_catalogue{$id}{'dumb2'}            = $dumb2;
            $hash_catalogue{$id}{'electronic_publication'} = $electronic_publication;
            $hash_catalogue{$id}{'elevation'}        = $elevation;
            $hash_catalogue{$id}{'excavation_no'}    = $excavation_no;
            $hash_catalogue{$id}{'external_id'}      = $external_id;
            $hash_catalogue{$id}{'findspot_remarks'} = $findspot_remarks;
            $hash_catalogue{$id}{'findspot_square'}  = $findspot_square;
            $hash_catalogue{$id}{'genre'}            = $genre;
            $hash_catalogue{$id}{'google_earth_collection'} = $google_earth_collection;
            $hash_catalogue{$id}{'google_earth_provenience'} = $google_earth_provenience;
            $hash_catalogue{$id}{'height'}              = $height;
            $hash_catalogue{$id}{'id'}                  = $id;
            $hash_catalogue{$id}{'id_text2'}            = $id_text2;
            $hash_catalogue{$id}{'id_text'}             = $id_text;
            $hash_catalogue{$id}{'join_information'}    = $join_information;
            $hash_catalogue{$id}{'language'}            = $language;
            $hash_catalogue{$id}{'lineart_up'}          = $lineart_up;
            $hash_catalogue{$id}{'material'}            = $material;
            $hash_catalogue{$id}{'museum_no'}           = $museum_no;
            $hash_catalogue{$id}{'object_preservation'} = $object_preservation;
            $hash_catalogue{$id}{'object_type'}         = $object_type;
            $hash_catalogue{$id}{'period'}              = $period;
            $hash_catalogue{$id}{'period_remarks'}      = $period_remarks;
            $hash_catalogue{$id}{'photo_up'}            = $photo_up;
            $hash_catalogue{$id}{'primary_publication'} = $primary_publication;
            $hash_catalogue{$id}{'provenience'}         = $provenience;
            $hash_catalogue{$id}{'provenience_remarks'} = $provenience_remarks;
            $hash_catalogue{$id}{'publication_date'}    = $publication_date;
            $hash_catalogue{$id}{'publication_history'} = $publication_history;
            $hash_catalogue{$id}{'published_collation'} = $published_collation;
            $hash_catalogue{$id}{'seal_id'}             = $seal_id;
            $hash_catalogue{$id}{'seal_information'}    = $seal_information;
            $hash_catalogue{$id}{'stratigraphic_level'} = $stratigraphic_level;
            $hash_catalogue{$id}{'subgenre'}            = $subgenre;
            $hash_catalogue{$id}{'subgenre_remarks'}    = $subgenre_remarks;
            $hash_catalogue{$id}{'surface_preservation'} = $surface_preservation;
            $hash_catalogue{$id}{'text_remarks'}       = $text_remarks;
            $hash_catalogue{$id}{'thickness'}          = $thickness;
            $hash_catalogue{$id}{'translation_source'} = $translation_source;
            $hash_catalogue{$id}{'width'}              = $width;
            $hash_catalogue{$id}{'object_remarks'}     = $object_remarks;
        }
    }

}
