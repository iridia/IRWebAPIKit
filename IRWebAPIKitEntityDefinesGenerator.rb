#!/usr/bin/env ruby

# IRWebAPIKit Entity Defines Generator
# 
# Evadne Wu at Iridia, 2010
# 
# This script downloads DTDs from w3.org, then parses them, then makes a special header for inclusion into IRWebAPIKit for the entity replacing helper method to consume.

require 'open-uri'





# Retrieve definitions

	retrievedDefinitions = {}

	EntityDefinitionURIPrefix = "http://www.w3.org/TR/xhtml1/DTD"	# replace this with localhost to use predownloaded copies
#	EntityDefinitionURIPrefix = "http://localhost/~evadne/"
	
	LineDefinition = /\<!ENTITY ([^\s]+)\s+\"(&)(#\d+;)(#\d+;)*\"/ 	# <!ENTITY agrave "&#224;"> or <!ENTITY lt "&#38;#60;">

	([

		"#{EntityDefinitionURIPrefix}xhtml-lat1.ent",
		"#{EntityDefinitionURIPrefix}xhtml-symbol.ent",
		"#{EntityDefinitionURIPrefix}xhtml-special.ent"

	]).each { | remoteURI | 
	
		puts "Downloading DTD from #{remoteURI}"
	
		open (remoteURI) { | contents | contents.each_line { |line|
		
			next unless (matches = LineDefinition.match line)
		
			entityName = "&#{matches[1]};"
			entityNumber = matches[2] + ((matches[4]) ? matches[4] : matches[3])	# amp, lt are culprits 
			
			puts "Adding #{entityName} => #{entityNumber}"		
			retrievedDefinitions[entityName] = entityNumber
	
		}}

		puts "\n"

	}





# Dump everything out

	HeaderHeaderFilename = "IRWebAPIKitEntityDefinesHeader.h"
	HeaderFilename = "IRWebAPIKitEntityDefines.h"
	HeaderFooterFilename = "IRWebAPIKitEntityDefinesFooter.h"

	headerHeader = File.open(HeaderHeaderFilename, 'r')
	headerFile = File.open(HeaderFilename, 'w')
	headerFooter = File.open(HeaderFooterFilename, 'r')
	now = Time.new

	headerHeader.each_line { |line|

		headerFile.write line
		.gsub("#YEAR", "#{now.year}")
		.gsub("#DATE", "#{now.year}/#{now.month}/#{now.day}")
		.gsub("#AUTHOR", "Iridia Automata")

	}
	
	headerHeader.close
	
	def makeDictionary (methodName, hash, keysToValues)
		
		returnedString = <<-END

			NSDictionary* #{methodName} () {

				return [NSDictionary dictionaryWithObjectsAndKeys:

		END

		hash.each { | key, value | returnedString << <<-END
					@"#{keysToValues ? value : key}", @"#{keysToValues ? key : value}",
		END
		}

		returnedString << <<-END

				nil];

			}

		END
		
		return returnedString.gsub(/^\t\t\t/, "")
		
	end
	
	headerFile.write makeDictionary("IRWebAPIKitXMLEntityNumbersFromNames", retrievedDefinitions, true)

	2.times { headerFile.write "\n" }
	
	headerFile.write makeDictionary("IRWebAPIKitXMLEntityNamesFromNumbers", retrievedDefinitions, false)
	
	headerFooter.each_line { |line| headerFile.write line }
	
	headerFooter.close
	headerFile.close
	







