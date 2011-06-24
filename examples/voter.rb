require 'blocker'

class Voter < BinaryBlocker::Blocker
  has_one :last_name,             :sstring, :length => 35
  has_one :first_name,            :sstring, :length => 20
  has_one :middle_name,           :sstring, :length => 20
  has_one :name_suffix,           :sstring, :length => 3
  # a post filter could convert this to an Fixnum
  has_one :birthyear,             :sstring, :length => 4  
  has_one :gender,                :sstring, :length => 1
  # a post filter could convert this to a date (but that is pretty slow)
  has_one :registration,          :sstring, :length => 8
  has_one :addr_prefix,           :sstring, :length => 1
  has_one :addr_num,              :sstring, :length => 7
  has_one :addr_suffix,           :sstring, :length => 4
  has_one :addr_prefix_direction, :sstring, :length => 2
  has_one :addr_street,           :sstring, :length => 30
  has_one :addr_street_type,      :sstring, :length => 6
  has_one :addr_suffix_direction, :sstring, :length => 2
  has_one :addr_ext,              :sstring, :length => 13
  has_one :city,                  :sstring, :length => 35
  has_one :state,                 :sstring, :length => 2
  has_one :zip,                   :sstring, :length => 5
  has_one :maddr1,                :sstring, :length => 50   
  has_one :maddr2,                :sstring, :length => 50   
  has_one :maddr3,                :sstring, :length => 50   
  has_one :maddr4,                :sstring, :length => 50   
  has_one :maddr5,                :sstring, :length => 50   
  has_one :voter_id,              :sstring, :length => 13
  has_one :county_code,           :sstring, :length => 2
  has_one :jurisdiction,          :sstring, :length => 5
  has_one :ward,                  :sstring, :length => 6
  has_one :school,                :sstring, :length => 5
  has_one :state_house,           :sstring, :length => 5
  has_one :state_senate,          :sstring, :length => 5
  has_one :congress,              :sstring, :length => 5
  has_one :country_commissioner,  :sstring, :length => 5
  has_one :village_code,          :sstring, :length => 5
  has_one :village_precinct,      :sstring, :length => 6 
  has_one :school_precinct,       :sstring, :length => 6
  has_one :perm_absentee_ind,     :sstring, :length => 1
  has_one :status,                :sstring, :length => 2
end


voter = Voter.new
voter.last_name = 'Hurley'
voter.first_name = 'Patrick'
voter.county_code = '82'
File.open("voter1.txt", "wb") do |vinfo|
  vinfo.print voter.block
  vinfo.print "Hurley                             Susan                                                                                                                                                                                                                                                                                                                                                                                                                                     82                                                        "
end

start = Time.new
count = 0
File.open("v.txt") do |vinfo|
  until vinfo.eof
    voter = Voter.new(vinfo)
    count += 1
    # You might want to do something more interesting here...
    #puts voter.last_name
    #puts voter.first_name
  end
end
stop = Time.new
puts "Processed #{count} records in #{stop - start} seconds"