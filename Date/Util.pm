use v6.c;

unit module Date::Util;

subset DurType of Str where { $_ eq < Y M D YMD >.one};

sub date_diff(Date:D $dt_start, Date:D $dt_end, DurType $pattern ) is export {
    my Int $dur_day = $dt_end - $dt_start ; 

    if $dur_day  < 0 {
        X::AdHoc.new(payload => "First Argument Should BE EARLIER THAN Second Argument!").throw;
    }

    my Int $dur_year; 
    my Int $dur_month; 
    my Int $year_dval = $dt_end.year - $dt_start.year; 
    my Int $month_dval = ($dt_end.year * 12 + $dt_end.month) - ($dt_start.year * 12 + $dt_start.month); 

    my $dt_later_mons =$dt_start.later(month => $month_dval);
    
        if $dt_later_mons.daycount > $dt_end.daycount  {
            $dur_month = $month_dval -1;
            $dur_year = floor($dur_month/12);
        } else {
            $dur_month = $month_dval;
            $dur_year = floor($dur_month/12);
        }
    my %dur = :year($dur_year),
              :month($dur_month - $dur_year * 12),
              :day($dt_end - $dt_start.later(month=>$dur_month) );

    my %result = (
        Y => $dur_year,
        M => $dur_month,
        D => $dur_day,
        YMD => %dur,
    );

    return %result{$pattern};
}

`#(
sub date_cmp(Date:D $dt1, Date:D $dt2) is export {
	given $dt1 - $dt2 {
		when 0 { return 0}
		when * < 0 { return -1}
		when * > 0 { return 1 }
	}
}
)

