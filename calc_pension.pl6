use v6.c;
#use DB::SQLite;
use Date::Util;
# 社会平均工资
class AverageWage { has Int     $.year; has Date    $.begin_date; has Date    $.end_date; has Numeric $.avg_salary; has Numeric $.floor_salary; has Numeric $.ceil_salary; 
    my %avg_wages;
    submethod TWEAK {
        %avg_wages{$!year.Str} = self;
    }
    
    method fetch(Int $year --> AverageWage) {
        my $avg_wage = %avg_wages{$year.Str};
    }
}

# 个人缴费工资
class IndividualPaymentWage {
    
    has Str     $.sn;
    has Int     $.year;
    has Date    $.begin_date;
    has Date    $.end_date;
    has Numeric $.salary;
    my %individual_wages;
    
    submethod TWEAK {
        %individual_wages{$!sn}{$!year.Str}= self;
    }

    method months() {
        my $date_1 = $!begin_date;
        my $date_2 = $!end_date;
        my $months = date_diff($date_1,$date_2,'M');

    }

    method fetch_all_of(Str $sn ) {
        #say $!sn;
        my %indiv_wage_of_insured = %individual_wages{$sn};
    }

    method fetch(Str $sn, Num $year --> IndividualPaymentWage:D) {
        my $indiv_wage = %individual_wages{$sn}{$year.Str};
    }

}

# 个人账户
class IndividualAccount {
    has Str $.sn;
    has Date $.paying_date; # 征集日期
    has Date $.accounting_date; # 账户日期
    has Numeric $.credit; # 入账

    

}

# 征缴比例
class CollectionRatio { 
    has Str $.type;
    has Date $.begin_date;
    has Date $.end_date;
    has Numeric $.enterprise_rate;
    has Numeric $.individual_tate;
    
}

# 个人基础信息
class PersonalBasicInfo {
    has Str $.sn;
    has Str $.id;
    has Str $.name;
    has Str $.sex;
    has Str $.nation;
    has Date $.birth_date;
    has Str $.address = '';
    has Str $.zipcode = '';
    has Str $.phone = '';
    my %person_infos ;
    
    
    
    submethod TWEAK {
        %person_infos{$!sn} = self;
    }
    
    method age {
        my $now = Date.today;
        my $age = date_diff(self.birth_date,$now,'Y');
    }

    method fetch(Str $sn --> PersonalBasicInfo) {
        my $perosn_info = %person_infos{$sn};
    }

};

# 参保人信息
class InsuredDetails {
    has Str $.sn;
    has Date $.work_date;
    has Str $.insure_status;
    has Date $.insuring_begin_date;
    has Date $.accounting_begin_date ;
    my %insured_details;
    
    submethod TWEAK {
        %insured_details{$!sn} = self;
    }

    method fetch(Str $sn --> InsuredDetails) {
        my $insured_detail = %insured_details{$sn};
    }


}


# 退休信息
class RetirementDetails {
    has Str $.sn;
    has Date $.retired_date;
    has Int $.service_length_deduction_monthly = 0 ; # 扣减工龄
    has Numeric $.account_balance; # 账户储存额
    my %retire_details;
    submethod TWEAK {
        %retire_details{$!sn} = self;
    }

    method fetch(Str $sn --> RetirementDetails) {
        my $retire_detail = %retire_details{$sn};
    }
}

# 养老金
class Pension {

  has Str $.sn;
#has Numeric $.initial_pension;
#has Numeric $.current_pension;
=pod
   submethod BUILD($!sn) {
       die "$!sn has not retired!" \
           unless RetirementDetails.fetch($!sn);
       die "Can not fetch person which sn is : $!sn." \
           unless PersonalBasicInfo.fetch($!sn);
   }
=cut   
    # 历年增资计算subroutine引用
    my $subs_of_increasing_pension_href  := {  
      2010 => sub {...} ,
      2011 => sub {...} ,
      2012 => sub {...},
    }; 
          
    # 与退休年龄对应的账户养老金计发月数
    my $retire_age__months_href := {
        40 => 233, 41 => 230, 42 => 226,
        43 => 223, 44 => 220, 45 => 216,
        47 => 208, 48 => 204, 49 => 199,
        50 => 195, 51 => 190, 52 => 185,

    };

    method !personal_info {
        return PersonalBasicInfo.fetch($!sn);
    }

    method !retire_details {
        return RetirementDetails.fetch($!sn);
    }

    method !insured_details {
        return InsuredDetails.fetch($!sn);
    }
    
    method fetch {...}

    # 退休上年度社会平均工资
    method last_avg_wage {
        my $retired_date = self!retire_details.retired_date;
        return my $last_avg_salary = AverageWage.fetch($retired_date.year) || die "Can not get last_avg_wage.";
    }

    # 个人实际缴费年限
    method actual_payment_years()  {
        my $months = 0;
        my %individual_wage = IndividualPaymentWage.fetch_all_of($!sn);
        for %individual_wage.values -> $wage {
            $months += $wage.months;
        }
        my $years = $months/12;
        return $years.round(0.01);
    }

    # 个人视同缴费年限
    method same_as_payment_years() {
        
        my $work_date = self!insured_details.work_date;
        my $account_date = self!insured_details.accounting_begin_date;
        my $reduce_months = self!retire_details.service_length_deduction_monthly;
        my $as_same_payment_months = date_diff($work_date,$account_date,'M');
        $as_same_payment_months = $as_same_payment_months - $reduce_months;
        return my $as_same_payment_years = ($as_same_payment_months / 12).round(0.01);
        
    
    
    }

    # 个人基础养老金指数
    method basic_ratio() {
        
    }

    # 个人过渡养老金指数
    method transitional_ratio {...}

    # 基础养老金
    method basic_pension() of Numeric {
        my $person = PersonalBasicInfo.fetch($!sn);
        my $retire = RetirementDetails.fetch($!sn);
        my $insure = InsuredDetails.fetch($!sn);


    }
    
    # 过渡性养老金
    method transitional_pension() of Numeric {...}
    
    # 账户养老金
    method account_pension() of Numeric {
        my $person = self.personal_info;
    }
    
    # 初始养老金月标准
    method initial_pension_monthly() of Numeric {...}

    # 当前养老金月标准
    multi method current_pension_monthly() of Numeric {...}
    
    multi method current_pension_monthly(Int $year) of Numeric {...};
  
}


sub MAIN() {
    my $ljw = PersonalBasicInfo.new(
        sn => '10000000001',
        id => '650104196907295011',
        name => 'LiJianWei',
        sex => 'Male',
        nation => '01',
        birth_date => Date.new(1969,7,29),

    );

    my $ljw_retired = RetirementDetails.new(
        sn => '10000000001',
        retired_date => Date.new(2019,9,30),
        account_balance => 65233.3,
        );

    my $ljw_insured = InsuredDetails.new(
        sn => '10000000001',
        work_date => Date.new(1994,10,1),
        insure_status => 'insuring',
        insuring_begin_date => Date.new(1996,1,1),
        accounting_begin_date => Date.new(1996,1,1),

    );

    my $ljw_pension = Pension.new(sn=>'10000000001');

    my $collection_ratio = CollectionRatio.new(
        type => '职工养老保险',
        begin_date => Date.new(1996,1,1),
        end_date => Date.new(2099,12,31),
        enterprise_rate => 0.2,
        individual_rate => 0.08,
        );
    my @wages = (
        {year=>1996,begin_date=>Date.new(1996,1,1),end_date=>Date.new(1996,12,31),avg_salary=>362,floor_salary=>199,ceil_salary=>993},
        {year=>1997,begin_date=>Date.new(1997,1,1),end_date=>Date.new(1997,12,31),avg_salary=>410,floor_salary=>199,ceil_salary=>993},
        {year=>1998,begin_date=>Date.new(1998,1,1),end_date=>Date.new(1998,12,31),avg_salary=>435,floor_salary=>199,ceil_salary=>993},
        {year=>1999,begin_date=>Date.new(1999,1,1),end_date=>Date.new(2000,6,30),avg_salary=>440,floor_salary=>199,ceil_salary=>993},
        {year=>2000,begin_date=>Date.new(2000,7,1),end_date=>Date.new(2000,12,31),avg_salary=>516,floor_salary=>199,ceil_salary=>993},
        {year=>2001,begin_date=>Date.new(2001,1,1),end_date=>Date.new(2002,6,30),avg_salary=>578,floor_salary=>199,ceil_salary=>993},
        {year=>2002,begin_date=>Date.new(2002,7,1),end_date=>Date.new(2003,6,30),avg_salary=>660,floor_salary=>199,ceil_salary=>993},
        {year=>2003,begin_date=>Date.new(2003,7,1),end_date=>Date.new(2004,6,30),avg_salary=>765,floor_salary=>199,ceil_salary=>993},
        {year=>2004,begin_date=>Date.new(2004,7,1),end_date=>Date.new(2005,6,30),avg_salary=>896,floor_salary=>199,ceil_salary=>993},
        {year=>2005,begin_date=>Date.new(2005,7,1),end_date=>Date.new(2006,6,30),avg_salary=>1010,floor_salary=>199,ceil_salary=>993},
        {year=>2006,begin_date=>Date.new(2006,7,1),end_date=>Date.new(2007,6,30),avg_salary=>1190,floor_salary=>199,ceil_salary=>993},
        {year=>2007,begin_date=>Date.new(2007,7,1),end_date=>Date.new(2008,6,30),avg_salary=>1415,floor_salary=>199,ceil_salary=>993},
        {year=>2008,begin_date=>Date.new(2008,7,1),end_date=>Date.new(2009,6,30),avg_salary=>1745,floor_salary=>199,ceil_salary=>993},
        {year=>2009,begin_date=>Date.new(2009,7,1),end_date=>Date.new(2010,6,30),avg_salary=>2068,floor_salary=>199,ceil_salary=>993},
        {year=>2010,begin_date=>Date.new(2010,7,1),end_date=>Date.new(2011,6,30),avg_salary=>2208,floor_salary=>199,ceil_salary=>993},
        {year=>2011,begin_date=>Date.new(2011,7,1),end_date=>Date.new(2012,6,30),avg_salary=>2525,floor_salary=>199,ceil_salary=>993},
        {year=>2012,begin_date=>Date.new(2012,7,1),end_date=>Date.new(2013,6,30),avg_salary=>2850,floor_salary=>199,ceil_salary=>993},
        {year=>2013,begin_date=>Date.new(2013,7,1),end_date=>Date.new(2014,6,30),avg_salary=>3163,floor_salary=>199,ceil_salary=>993},
        {year=>2014,begin_date=>Date.new(2014,7,1),end_date=>Date.new(2015,6,30),avg_salary=>3234,floor_salary=>199,ceil_salary=>993},
        {year=>2015,begin_date=>Date.new(2015,7,1),end_date=>Date.new(2016,6,30),avg_salary=>3514,floor_salary=>199,ceil_salary=>993},
        {year=>2016,begin_date=>Date.new(2016,7,1),end_date=>Date.new(2017,6,30),avg_salary=>3784,floor_salary=>199,ceil_salary=>993},
        {year=>2017,begin_date=>Date.new(2017,7,1),end_date=>Date.new(2018,6,30),avg_salary=>4125,floor_salary=>199,ceil_salary=>993},
        {year=>2018,begin_date=>Date.new(2018,7,1),end_date=>Date.new(2019,6,30),avg_salary=>4666,floor_salary=>199,ceil_salary=>993},
        {year=>2019,begin_date=>Date.new(2019,7,1),end_date=>Date.new(2020,6,30),avg_salary=>5346,floor_salary=>199,ceil_salary=>993},
        ); 
    my @individual_wages = (
        {sn=>'10000000001',year=>1994,begin_date=>Date.new(1994,10,1),end_date=>Date.new(1995,3,30),salary=>(2196/6).round},
        {sn=>'10000000001',year=>1995,begin_date=>Date.new(1995,4,1),end_date=>Date.new(1996,3,30),salary=>3168/12.round},
        {sn=>'10000000001',year=>1996,begin_date=>Date.new(1996,4,1),end_date=>Date.new(1997,3,30),salary=>3936/12.round},
        {sn=>'10000000001',year=>1997,begin_date=>Date.new(1997,4,1),end_date=>Date.new(1998,3,30),salary=>4392/12.round},
        {sn=>'10000000001',year=>1998,begin_date=>Date.new(1998,4,1),end_date=>Date.new(1999,3,30),salary=>4620/12.round},
        {sn=>'10000000001',year=>1999,begin_date=>Date.new(1999,4,1),end_date=>Date.new(2000,3,30),salary=>5040/12.round},
        {sn=>'10000000001',year=>2000,begin_date=>Date.new(2000,4,1),end_date=>Date.new(2001,3,30),salary=>7713/12.round},
        {sn=>'10000000001',year=>2001,begin_date=>Date.new(2001,4,1),end_date=>Date.new(2002,3,30),salary=>6360/12.round},
        {sn=>'10000000001',year=>2002,begin_date=>Date.new(2002,4,1),end_date=>Date.new(2003,3,30),salary=>6519/12.round},
        {sn=>'10000000001',year=>2003,begin_date=>Date.new(2003,4,1),end_date=>Date.new(2004,3,30),salary=>6996/12.round},
        {sn=>'10000000001',year=>2004,begin_date=>Date.new(2004,4,1),end_date=>Date.new(2005,3,30),salary=>7920/12.round},
        {sn=>'10000000001',year=>2005,begin_date=>Date.new(2005,4,1),end_date=>Date.new(2005,12,31),salary=>6516/12.round},
        {sn=>'10000000001',year=>2006,begin_date=>Date.new(2006,1,1),end_date=>Date.new(2006,12,31),salary=>9336/12.round},
        {sn=>'10000000001',year=>2007,begin_date=>Date.new(2007,1,1),end_date=>Date.new(2007,12,31),salary=>10692/12.round},
        {sn=>'10000000001',year=>2008,begin_date=>Date.new(2008,1,1),end_date=>Date.new(2008,12,31),salary=>12864/12.round},
        {sn=>'10000000001',year=>2009,begin_date=>Date.new(2009,1,1),end_date=>Date.new(2009,12,31),salary=>14808/12.round},
        {sn=>'10000000001',year=>2010,begin_date=>Date.new(2010,1,1),end_date=>Date.new(2010,12,31),salary=>15456/12.round},
        {sn=>'10000000001',year=>2011,begin_date=>Date.new(2011,1,1),end_date=>Date.new(2011,12,31),salary=>17800/12.round},
        {sn=>'10000000001',year=>2012,begin_date=>Date.new(2012,1,1),end_date=>Date.new(2012,12,31),salary=>20416/12.round},
        {sn=>'10000000001',year=>2013,begin_date=>Date.new(2013,1,1),end_date=>Date.new(2013,12,31),salary=>24984/12.round},
        {sn=>'10000000001',year=>2014,begin_date=>Date.new(2014,1,1),end_date=>Date.new(2014,12,31),salary=>36000/12.round},
        {sn=>'10000000001',year=>2015,begin_date=>Date.new(2015,1,1),end_date=>Date.new(2016,6,30),salary=>2256},
        {sn=>'10000000001',year=>2016,begin_date=>Date.new(2016,7,1),end_date=>Date.new(2017,6,30),salary=>6878},
        {sn=>'10000000001',year=>2017,begin_date=>Date.new(2017,7,1),end_date=>Date.new(2018,6,30),salary=>7508},
        {sn=>'10000000001',year=>2018,begin_date=>Date.new(2018,7,1),end_date=>Date.new(2019,6,30),salary=>8471},
        {sn=>'10000000001',year=>2019,begin_date=>Date.new(2019,7,1),end_date=>Date.new(2020,6,30),salary=>10429},
    );
    #my @individual_wages;
    for @individual_wages -> $ind_wage {
        my $individual_wage = IndividualPaymentWage.new(
            :sn($ind_wage<sn>),
            :year($ind_wage<year>),
            :begin_date($ind_wage<begin_date>),
            :end_date($ind_wage<end_date>),
            :salary($ind_wage<salary>),
        );
        #%individual_wages{$ind_wage<year>} = $individual_wage;
    }

    my %avg_wages ;
    for @wages -> $wage {
        #say $wage.perl;
        my $avg_wage = AverageWage.new(
            :year($wage<year>),
            :begin_date($wage<begin_date>),
            :end_date($wage<end_date>),
            :avg_salary($wage<avg_salary>),
            :floor_salary($wage<floor_salary>),
            :ceil_salary($wage<ceil_salary>),
            );
        %avg_wages{$wage<year>} = $avg_wage;
    }
    say %avg_wages{2016}.perl;
    my $person_ljw = PersonalBasicInfo.fetch('10000000001');
    say $person_ljw.perl;
    say $person_ljw.age.perl;
    
    my $pension_ljw =  Pension.new(sn=>'10000000001'); 
    say $pension_ljw.same_as_payment_years.perl;
    say $pension_ljw.actual_payment_years;
    say $pension_ljw.last_avg_wage;
    say IndividualPaymentWage.fetch_all_of('10000000001').perl;

}
