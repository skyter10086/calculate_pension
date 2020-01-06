enum DurType is export <Y M D YMD>;

#subset Sex of Str where  /^Male||Female$/;

enum Sex  is export < Male Female>;

#subset Nation of Str where { my @arr = ~ Range.new(1,56); $_ ∈ @arr;}
enum Nation  <<汉族 回族 藏族 维族 蒙古族 朝鲜族 土家族 布依族 傣族>>;

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

subset YM of Str where { $_ ~~ /^(\d ** 4)(\d ** 2)$/; my $d = $0~'-'~$1~'-'~'01'; Date.new: $d;}

#subset YM of Str where { $_ ~~ rx/^\d ** 6$/; Date.new($_.substr(0,4)~'-'~$_.substr(4,2)~'-01'); }

subset Y-M-D of Str where { Date.new: $_ };

subset YM-YM  of Str  where {                      
                      $_ ~~ rx/^(\d+)\-(\d+)$/;
                      my $a = $_.substr(0,6);
                      my $b = $_.substr(7,6);
                      ($a ~~ YM) and ($b ~~ YM);
}
class Person {

    
    has Str $.name;
    has Str $.id;
    has Nation $.nation;
    has Sex $.sex;
    has Y-M-D $.birth;

    multi method age() {
	    my $today = Date.today;
	    my $birth_day = Date.new(self.birth);
            my $age = date_diff($birth_day, $today, Y);
	    return $age;
    }

    multi method age(Y-M-D $date -->Int) {
	    my $birth_day = Date.new(self.birth);
	    my $age = date_diff($birth_day, Date.new($date), Y);
	    return $age;
    }

}

class DurationMonthly {
   #has Date $.start;
   #has Date $.end;
    has YM-YM $.duration;

    method start() {
        my $dur = self.duration;
        my $start = $dur.substr(0,6);
        my $end = $dur.substr(7,6);
        ($start, $end) = ($end, $start) if $start > $end;
        return Date.new($start.substr(0,4)~'-'~$start.substr(4,2)~'-01');
    }

    method end() {
        my $dur = self.duration;
        my $start = $dur.substr(0,6);
        my $end = $dur.substr(7,6);
        ($start, $end) = ($end, $start) if $start > $end;
        return Date.new($end.substr(0,4)~'-'~$end.substr(4,2)~'-01');
    }



   method MonthSet() {
     my $start = self.start;
     my $end = self.end;
     my @months = [];
     my $fmt = { sprintf "%04d%02d", .year, .month };
     
     while $start < $end {
         my $str = Date.new($start.Str, formatter=> $fmt).Str;
         @months.push($str);
         $start = $start.later(month=>1);
     }
     @months.push(Date.new($end.Str, formatter=> $fmt).Str)  ;
     return @months;
   }
   
   

 }
 
class DurationHash is DurationMonthly {
    has $.value;
    
    method HashSet {
        my $val = self.value;
        my @arr = self.MonthSet;
        my %hash ;
        for @arr -> $key {
            %hash{$key} = $val;
        }
        return %hash;
    }
}

my $d = DurationMonthly.new(duration=>'201905-201905');
           
my @mons = $d.MonthSet;

@mons.perl.say;

my $h_1 = DurationHash.new(
            duration => '199601-199606',
            value => 139
 );
 $h_1.HashSet.perl.say;

 role Insured {

    has Y-M-D $.insure_date;
    has Str $.sn;
    has Int %.base-salary;
    
    method pay-age() {
        
    }

 }

 class InsuredMan is Person does Insured {
     
     method pay-age() {
         my %salaries = self.base-salary;
         #say %salaries.perl;
        my @pay-age = self.base-salary.keys;
        #say @pay-age;
        my  @months;
        for @pay-age -> $age {
            @months.append(DurationMonthly.new(duration=>$age).MonthSet);
            #say DurationMonthly.new(duration=>$age).MonthSet;
            #say @months;
        }
        #say @months.elems;
        return @months.elems;
        
    }

    method intro {
      say self.name~" is " ~ self.age ~ ' years old.';
      say self.name~" has paid for "~self.pay-age~ " months";
    }

 }

 my InsuredMan $david = InsuredMan.new(:sn<08238933168>,
                                       :id<411302198310203835>,
                                       :name<曾理>,
                                       :nation(Nation::汉族),
                                       :sex(Sex::Male),
                                       :birth<1983-10-25>,
                                       :insure_date<2006-07-15>,
                                       :base-salary('200607-200706'=>1500,'200707-200806'=>2200,'200807-200906'=>2700));

$david.intro;

say $david.nation;