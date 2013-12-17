require 'csv'
require 'fuzzystringmatch'
require 'fast-stemmer'
require 'set'

class Reconciler
	@@iptc_data = Hash.new
	@@stop_words = Set["a", "about", "across", "after", "all", "also", "an", "and", "as", "at", "be", "been", "by", "can", "for", "from", "have", "in", "into", "its", "of", "off", "on", "or", "since", "that", "the", "their", "to", "were", "where", "which", "while", "who", "with"]
	
	def self.iptc_load
		CSV.foreach('iptc_sample.csv') do |row|
			dump = Array.new(row)
			iptc_term = dump[7].downcase
			Reconciler.strip_term(iptc_term)
			@@iptc_data[iptc_term] = @@term_stripped
		end
	end

	def self.strip_term(term)
		split_term = term.split(' ')
		@@split_term_stemmed = []
		split_term.each do |word|
			if @@stop_words.include?(word)
				next
			end
			if word.include?('-')
				word.delete!('-')
			end
			@@split_term_stemmed.push(word.stem)
		end
		@@term_stripped = @@split_term_stemmed.join(' ')
	end

	def self.iptc_compare(dbp_term)
		if @@iptc_data.has_key?(dbp_term)
			puts "#{dbp_term} matched!"
			CSV.open('matches2.csv', mode = "a+") { |file| file << [dbp_term] }
		else
			Reconciler.strip_term(dbp_term)
			dbp_term_stripped = @@term_stripped
			jarrow = FuzzyStringMatch::JaroWinkler.create( :native )
			@@iptc_data.each do |iptc_term, iptc_term_stripped|
				distance = jarrow.getDistance(iptc_term_stripped, dbp_term_stripped)
				if distance > 0.9
					if dbp_term_stripped.split(' ').all? {|word| iptc_term_stripped.split(' ').include?(word)} == true && iptc_term_stripped.split(' ').all? {|word| dbp_term_stripped.split(' ').include?(word)}
						puts "IPTC: #{iptc_term} (#{iptc_term_stripped}), DBPEDIA: #{dbp_term} (#{dbp_term_stripped}): #{distance}"
						CSV.open('matches2.csv', mode = "a+") { |file| file << [dbp_term, iptc_term] }
					else
						puts "POSSIBLE MATCH - IPTC: #{iptc_term} (#{iptc_term_stripped}), DBPEDIA: #{dbp_term} (#{dbp_term_stripped}): #{distance}"
						CSV.open('possible_matches.csv', mode = "a+") { |file| file << [dbp_term, iptc_term] }
					end
				end
			end
		end
	end
end

Reconciler.iptc_load

start_time = Time.now

CSV.foreach('dbpedia_sample.csv') do |row|
	dbp_row = Array.new(row)
	dbp_term = dbp_row[1].downcase
	Reconciler.iptc_compare(dbp_term)
end

end_time = Time.now

duration = end_time - start_time
puts "Program Duration: #{duration}" # Takes about 38 minutes right now


# non fiction vs non fiction books?
# police vs policemen?
# can deal with plurals, but what about more specific categories of the same thing?


# you'll want to add DBPedia url and IPTC url at some point to matches.csv


# this will check to see if one of the strings contains words not in the other one
# dbp_term_stripped.split(' ').all? {|word| iptc_term_stripped.split(' ').include?(word)} == false || iptc_term_stripped.split(' ').all? {|word| dbp_term_stripped.split(' ').include?(word)} == false


# put each term in a set and then check if they include stop words, if included then delete


