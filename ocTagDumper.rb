# Usage: ruby ocTagDumper.rb /path/to/file_to_be_processing.ext

require 'dover_to_calais'
require 'em/throttled_queue'

# -----------------------------------------------------------------------------
## Currently unused - repackaging as Jekyll plugin shortly
entities = ["Anniversary", "City", "Company", "Continent", "Country", "Currency", "EmailAddress",
            "EntertainmentAwardEvent", "Facility", "FaxNumber", "Holiday", "IndustryTerm", "MarketIndex",
            "MedicalCondition", "MedicalTreatment", "Movie", "MusicAlbum", "MusicGroup", "NaturalFeature",
            "OperatingSystem", "Organization", "Person", "PhoneNumber", "PoliticalEvent", "Product",
            "ProgrammingLanguage", "ProvinceOrState", "PublishedMedium", "RadioProgram", "RadioStation",
            "Region", "SportsEvent", "SportsGame", "SportsLeague", "TVShow", "TVStation", "Technology",
            "SocialTags", "originalValue"]
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
## Currently unused - repackaging as Jekyll plugin shortly
events = ["Acquisition", "Alliance", "AnalystEarningsEstimate", "AnalystRecommendation", "ArmedAttack",
          "ArmsPurchaseSale", "Arrest", "Bankruptcy", "BonusSharesIssuance", "BusinessRelation",
          "Buybacks", "CandidatePosition", "CompanyAccountingChange", "CompanyAffiliates", "CompanyCompetitor",
          "CompanyCustomer", "CompanyEarningsAnnouncement", "CompanyEarningsGuidance", "CompanyEmployeesNumber",
          "CompanyExpansion", "CompanyForceMajeure", "CompanyFounded", "CompanyInvestment", "CompanyLaborIssues",
          "CompanyLayoffs", "CompanyLegalIssues", "CompanyLocation", "CompanyListingChange", "CompanyMeeting",
          "CompanyNameChange", "CompanyProduct", "CompanyReorganization", "CompanyRestatement", "CompanyTechnology",
          "CompanyUsingProduct", "CompanyTicker", "ConferenceCall", "Conviction", "CreditRating", "DebtFinancing",
          "DelayedFiling",  "DiplomaticRelations", "Dividend", "EmploymentChange", "EmploymentRelation",
          "EnvironmentalIssue", "EquityFinancing", "Extinction", "FamilyRelation", "FDAPhase", "Indictment",
          "IndicesChanges", "IPO", "JointVenture", "ManMadeDisaster", "Merger", "MilitaryAction", "MovieRelease",
          "MusicAlbumRelease", "NaturalDisaster", "PatentFiling", "PatentIssuance", "PersonAttributes", "PersonCareer",
          "PersonCommunication", "PersonEducation", "PersonEmailAddress", "PersonLocation", "PersonParty",
          "PersonRelation", "PersonTravel", "PoliticalEndorsement", "PoliticalRelationship", "PollsResult",
          "ProductIssues", "ProductRecall", "ProductRelease", "Quotation", "SecondaryIssuance", "StockSplit",
          "Trial", "VotingResult"]
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Currently unused - repackaging as Jekyll plugin shortly
topics = ["Business_Finance", "Disaster_Accident", "Education", "Entertainment_Culture", "Environment",
          "Health_Medical_Pharma", "Hospitality_Recreation", "Human_Interest", "Labor", "Law_Crime", "Politics",
          "Religion_Belief", "Social_Issues", "Sports", "Technology_Internet", "Weather", "War_Conflict", "Other"]
# -----------------------------------------------------------------------------

EM.run do
  # Ctrl+C to stop EventMachine
  Signal.trap('INT')  { EventMachine.stop }
  Signal.trap('TERM') { EventMachine.stop }

  DoverToCalais::API_KEY =  'your_Open_Calais_API_key'
  data_dir = ARGV[0] + '/'
  puts "Searching in: " + data_dir

  # 2 queries per second
  # this is to not exceed the OpenCalais concurrency limit
  queue = EM::ThrottledQueue.new(2, 1)

  dovers = []
  Dir.foreach(data_dir) do |filename|
    next if filename == '.' or filename == '..' or filename == '.DS_Store'
    puts "Searching text in: " + filename
    dover = DoverToCalais::Dover.new(data_dir + filename)
    dovers << dover

    # push to throttled queue
    queue.push(dover)
  end

  dovers.each do |dover|
    dover.to_calais do |response|
      if response.error
        puts "*** Data source #{dover.data_src} error: #{response}" #
      else

        puts "Data Source: #{dover.data_src}"
        puts "-----------------------------------------------------------------------------"
        puts "-----------------------------------------------------------------------------"

        technology = response.filter( {:entity => 'Technology'} )
        puts "TECH: #{technology}"
        puts "-----------------------------------------------------------------------------"
        puts "#{technology.map{|x| x.value}.join("\n")}"
        puts "-----------------------------------------------------------------------------"

        industry_term = response.filter( {:entity => 'IndustryTerm'} )
        puts "IT: #{industry_term}"
        puts "-----------------------------------------------------------------------------"
        puts "#{industry_term.map{|x| x.value}.join("\n")}"
        puts "-----------------------------------------------------------------------------"

        operating_system = response.filter( {:entity => 'OperatingSystem'} )
        puts "OS: #{operating_system}"
        puts "-----------------------------------------------------------------------------"
        puts "#{operating_system.map{|x| x.value}.join("\n")}"
        puts "-----------------------------------------------------------------------------"

        social_tags = response.filter( {:entity => 'originalValue'} )
        puts "ST: #{social_tags}"
        puts "-----------------------------------------------------------------------------"
        puts "#{social_tags.map{|x| x.value}.join("\n").gsub(/[()]/, "")}"
        puts "-----------------------------------------------------------------------------"
      end #if response
    end #dovers.to_calais
    dovers.length.times { queue.pop  { |dover| dover.analyze_this } }
  end #dovers.each block
end
