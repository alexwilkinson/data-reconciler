require 'csv'
require 'fast-stemmer'
require 'set'

class Reconciler
	@@dbp_data = Hash.new
	@@stop_words = Set["a", "about", "across", "after", "all", "also", "an", "and", "as", "at", "be", "been", "by", "can", "for", "from", "have", "in", "into", "its", "of", "off", "on", "or", "since", "that", "the", "their", "to", "were", "where", "which", "while", "who", "with"]
	@@iptc_data = Hash.new
	def self.iptc_load
		CSV.foreach('iptc.csv') do |row|
			dump = Array.new(row)
			iptc_term = dump[7].downcase
			Reconciler.strip_term(iptc_term)
			@@iptc_data[iptc_term] = @@term_stripped
		end
	end

	def self.dbp_load
		CSV.foreach('dbpedia_category_labels.csv') do |row|
			dump = Array.new(row)
			dbp_term = dump[1].downcase
			Reconciler.strip_term(dbp_term)
			@@dbp_data[dbp_term] = @@term_stripped
		end
	end

	def self.strip_term(term)
		@@special_characters_delete = ["-", ",", "(", ")", ":"]
		split_term = term.split(' ')
		@@split_term_stemmed = []
		split_term.each do |word|
			if @@stop_words.include?(word)
				next
			end
			@@special_characters_delete.each do |char|
				if word.include?(char)
					word.delete!(char)
				end
			end
			@@split_term_stemmed.push(word.stem)
		end
		@@term_stripped = @@split_term_stemmed.join(' ')
	end

	def self.char_test
		@@dbp_data.each do |dbp_term, dbp_stripped|
			if dbp_term.include?('*')
				puts "#{dbp_term}"
			end
		end
	end

end

start_time = Time.now
Reconciler.dbp_load
Reconciler.char_test
end_time = Time.now
duration_as_hash = end_time - start_time
puts "AS HASH: #{duration_as_hash}"

start_time = Time.now




