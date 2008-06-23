# basic format for stomp messages
require 'rexml/document'
#require 'xml_helper.rb'
#require 'rubygems'
#gem 'stomp_message'
#require 'stomp_message'
require 'optparse'
require 'rdoc/usage'


module StompMessage
  class Options
    def self.parse_options(params)
       opts = OptionParser.new
    #   puts "argv are #{params}"
       temp_hash = {}
       temp_hash[:ack]= 'false'   # no ack by default
       temp_hash[:msisdn] = 'not_defined'
       email_flag=false
        opts.on("-h","--host VAL", String) {|val|  temp_hash[:host ] = val
                                              #  puts "host is #{val}"
                                                }
      # takes ruby hash code and converts to yaml
       opts.on("-H","--body_hash VAL", String) {|val|   temp=eval(val)
                                                 temp_hash[:body ] = temp.to_yaml
                                                                                        #  puts "host is #{val}"
                                                                                          }                                          
        opts.on("-D","--email VAL", String) {|val|  temp_hash[:email ] = val
                                                     temp_hash[:destination]=val }

      opts.on("-p","--port VAL", String) {|val|  temp_hash[:port ] = val      }
      opts.on("-c","--count VAL", String) {|val|  temp_hash[:count ] = val      }
      opts.on("-r","--repeat VAL", String) {|val|  temp_hash[:repeat ] = val      }
          opts.on("-S","--subject VAL", String) {|val|  temp_hash[:subject ] = val }
        opts.on("-s","--source VAL", String) {|val|  temp_hash[:source ] = val  }
          opts.on("-A","--ack VAL", String) {|val|  temp_hash[:ack ] = val
                                                    temp_hash[:action]=val
                                              #     puts "ack is #{val}"
                                                              }                                                  

       opts.on("-u","--user VAL", String) {|val|  temp_hash[:user ] = val }
                                            #   puts "user is #{val}"
         opts.on("-T","--topic VAL", String) {|val|  temp_hash[:topic ] = val }                                      
       opts.on("-t","--text VAL", String) {|val|  temp_hash[:text ] = val }
                                        
      opts.on("-M","--msg_command VAL", String) {|val|  temp_hash[:command ] = val }
                                             
       opts.on("-b","--body VAL", String) {|val|  temp_hash[:body ] = val }
        opts.on("-k","--keyword VAL", String) {|val|  temp_hash[:keyword ] = val
                                                puts "keyword is #{val}"
                                                keyword_flag=false }
        opts.on("-m","--msisdn VAL", String) {|val|  temp_hash[:msisdn ] = val }
       opts.on("-U","--url VAL", String) {|val|  temp_hash[:url ] = val }
  #oops couldnot thinkof another acronym for a
       opts.on("-a","--account VAL", String) {|val|      temp_hash[:account ] = val }

      opts.on("-B","--broadcast VAL", String) {|val|  temp_hash[:broadcast ] = val        }
         opts.on("-x","--help", "get help") { |val|  temp_hash[:help]=true  }  
       opts.on("-v","--value VAL", String) {|val|  temp_hash[:value ] = val }
                                                                                                                                                      
       opts.on("-d","--debug", "turn on debug") { |val| temp_hash[:debug ] = true              }                          
                                             
                                       
       opts.parse(params)
                     # puts " in HTTP #{hostname} port #{port} url: #{url}"
      
      return temp_hash

     end # parse options
  end
  # help build xml commands from messages
  module XmlHelper
	  # create elements from instance variables... (instance variablesneed to be set)
	  #array variables need to end in s (eg mssidns) and are handled recurvisely
	  def xml_instance_variable(iv_input)
	    iv=iv_input.delete('@')
	    class_var=eval("self.#{iv}.class")
	  #  puts "class is #{class_var} "
	    iv_xml=[]
	    case 
      when class_var==Array
        #puts "in array with #{iv}"
        len=iv.size
        check_for_s=iv[len-1]
        # puts "iv #{iv}: len is #{len} last digit is #{check_for_s}"     
        raise "not terminate in s or too short" if len <=1 or check_for_s!=115
        the_array = eval("self.#{iv}")
        iv_short = iv[0..len-2]
        #puts "iv short is #{iv_short}"     
        the_array.each {|e| 
               iv_xml << create_element(iv_short,e) }
        
      else
        val= eval "self.#{iv}"
	      iv_xml[0]= create_element(iv.to_s,val)
      end
	    return iv_xml
    end
    def create_element(element_name, element_value)
        # puts "in create element #{element_name}: #{element_value}"
        element_xml= REXML::Element.new element_name
        element_xml.text=element_value
        element_xml
    end     
     def load_iv(iv_input,doc)
        iv=iv_input.delete('@')
       val = REXML::XPath.first(doc, "//#{iv}").text
       puts "in load iv #{iv} and val: #{val}"
        eval "self.#{iv}=#{val}"
     end
     def load_instance_variables(xml_string)
              xml_doc=REXML::Document.new(xml_string)
              self.instance_variables.each {|iv| load_iv(iv,xml_doc)        }
             
     end
    # add all elements to top variable
    def add_elements(top)
       elements = []
        self.instance_variables.each {|iv| xml_instance_variable(iv).each {|x| elements << x} 
                   
      
                  }
        elements.each {|e| top.add_element e}
        top
    end
  
	end
	# basic stomp message class
	# sent between clients and servers... subclasss and add instance variables.
	class Message
	  include StompMessage::XmlHelper
	  attr_accessor :__stomp_msg_command, :__stomp_msg_body
	  def initialize(cmd, bdy=nil)
	      raise 'command nil' if cmd==nil
	      self.__stomp_msg_command =   cmd==nil ? '' : cmd.to_s
	      self.__stomp_msg_body =   bdy==nil ? '' : bdy.to_s
	     
	  end
	  def body
	    self.__stomp_msg_body
    end
     def command
  	    self.__stomp_msg_command
      end
	     
    def to_xml
      doc=REXML::Document.new()
      msg_xml = REXML::Element.new "stomp_msg_message"   
      doc.add_element(msg_xml)   
       msg3 = self.add_elements(REXML::Element.new("__instance_variables"))
       doc.root.add_element(msg3)
      output =""
      doc.write output
      output
     # doc= REXML::Document.new sms_xml.to_s
     # doc.to_s
    end
	
    def self.load_xml(xml_string)
      begin
      doc=REXML::Document.new(xml_string)
      command=REXML::XPath.first(doc, "//__stomp_msg_command").text
    #  puts "load_xml command is #{command}"
      body=REXML::XPath.first(doc, "//__stomp_msg_body").text
    #     puts "load_xml body is #{body}"
      tt_sms=StompMessage::Message.new(command, body)
      rescue Exception => e
        puts "Exception in load xml:#{xml_string}"
        puts "message #{e.message}"
      end
      tt_sms
    end
     def self.load_xml_new(xml_string)
        begin
       # doc=REXML::Document.new(xml_string)
        test= self.new('temp', 'temp')
        test.load_instance_variables(xml_string)
        #sms=StompMessage::Message.new(test.command, test.body)
        rescue Exception => e
          puts "Exception in load xml:#{xml_string}"
          puts "message #{e.message}"
        end
       test
      end
	end
end
# if a ruby gem file then you need to grab second in caller array
def RDoc.usage_no_exit(*args)
    # main_program_file = caller[1].sub(/:\d+$/, '')
      main_program_file = caller[1].split(':')[0]
    #puts "main program is #{main_program_file}"
   # puts " caller is #{caller.inspect}"
    comment = File.open(main_program_file) do |file|
      find_comment(file)
    end

    comment = comment.gsub(/^\s*#/, '')

    markup = SM::SimpleMarkup.new
    flow_convertor = SM::ToFlow.new
    
    flow = markup.convert(comment, flow_convertor)

    format = "plain"

    unless args.empty?
      flow = extract_sections(flow, args)
    end

    options = RI::Options.instance
    if args = ENV["RI"]
      options.parse(args.split)
    end
    formatter = options.formatter.new(options, "")
    formatter.display_flow(flow)
  end
