#Call this file to start the analysis. You must input amino acide sequence with at least two cysteine and specify data file (.txt). The data file must list
#the data like mz&intentsity mz$intensity... 
$LOAD_PATH << (File.dirname(__FILE__) + '/../bin')
$LOAD_PATH << (File.dirname(__FILE__) + '/../lib')
require "command"
require "tools"
module DisulfideSearcher
  CMDLineDefaults = "--sequence FCGLCVCPCNK --run-file somefile.txt".split(/ /)
  RunDefaults = {:sequence=>"AASCFCADFSCFCA", :run_file=>"C:/Ruby192/myproject/exp_data/extracted_mzml/Dependent_specific_ms2.mzML/591.73-77.9.txt", :output_file=>nil,:mass_tolerance=>0.3, :Qvalue=>15, :single_disulfide_mode=>false,:disulifde_pattern_analysis=>true,:lower_mz_limit=>200, :output_percent_coverage=>false, :optimizeQ=>false, :help=>false, :sequence_given=>true, :run_file_given=>true}
  class CMDline
    def self.run(argv)
      require 'trollop'
      parser = Trollop::Parser.new do 
        opt :sequence, "Input the peptide sequence", required: true, type: :string
        opt :run_file, "Input file, files need to be in this format m/z&intensity, m/z&intensity...", :required => true, type: :string
        opt :output_file, "Output file --suitable automatic name will be used if not specified", type: :string
        opt :mass_tolerance, "Mass tolerance for MS/MS matching", type: :float, default: 0.3
        opt :lower_mz_limit, "Lower mass limit for searching", type: :int, default: 200
        opt :output_percent_coverage, "Output the percent coverage of each fraggment ion type"
        opt :optimizeQ, "Optimize for best Q value within Andromeda type algorithm"
		opt :Qvalue, "sample top q number of peaks from every 100 thompson unit", type: :int, default: 6
		opt :single_disulfide_mode, "When you have more four cysteines but want to analyze peptide with single disulifde bond"
		opt :disulifde_pattern_analysis, "Give score for each pattern of different possible disulifde patterns", default: true 
        opt :Decoy, "Create 1000 random peptide and give hypergeometric distribution score"
	end
      opts = Trollop::with_standard_exception_handling parser do 
        #raise Trollop::HelpNeeded if argv.empty? # show help if empty
        parser.parse(argv)
      end
      p opts	  
    end
  end
end

if $0 == __FILE__
  ARGV = DisulfideSearcher::CMDLineDefaults if ARGV.empty? 
   ARGV
  input = DisulfideSearcher::CMDline.run(ARGV)
end
#optimum level of data extraction is determined by caculating the common score up to Q= 70 by 2Q. 
if input[:optimizeQ] == true
	array_of_q = (1..10).map do |i|
	[interface(input[:sequence],input[:mass_tolerance],i,input[:single_disulfide_mode],input[:disulifde_pattern_analysis],input[:lower_mz_limit],input[:output_percent_coverage],input[:run_file]),i]
	end
	p array_of_q.sort

elsif input[:Decoy] == true

pool = (0..10).collect do |i|
 input[:sequence].split("").shuffle.join
end
pool.delete_if {|d| d == input[:sequence]}

output = pool.map do |e|
 interface(e,input[:mass_tolerance],input[:Qvalue],input[:single_disulfide_mode],input[:disulifde_pattern_analysis],input[:lower_mz_limit],input[:output_percent_coverage],input[:run_file])
end

#outputfile ==> indicate where you want file to be saved. 
name = "C:/Ruby192/myproject/decoy/f_decoy#{input[:run_file][-10,10]}.txt"
File.open(name, "w+") do |f| 
	  f.puts frequency_analyzer(output.flatten.map {|f| f.round}.sort, name)
     end

else
 interface(input[:sequence],input[:mass_tolerance],input[:Qvalue],input[:single_disulfide_mode],input[:disulifde_pattern_analysis],input[:lower_mz_limit],input[:output_percent_coverage],input[:run_file])
end