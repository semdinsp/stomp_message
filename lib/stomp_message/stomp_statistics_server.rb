# basic format for stomp messages
require 'rexml/document'
# basic statistics class for listening to topics
module StompMessage
  # statistics listening class.  Updates the statistics at every message/event
	class StompStatisticsServer < StompMessage::StompServer
	  attr_accessor  :tags, :statistics
	  def setup_var
	    self.tags = %w(hour day week  month)
	    self.statistics = Hash.new
	    self.tags.each { |tagv| statistics[tagv] = Hash.new(0)    }
	    @old_exception_count=0
    end
	  def initialize(options={})
      super(options)
      setup_var
    end
    # update the statistics by tag value  (eg hour)
    def increment_stats(tag, element)
       self.statistics[tag][element]+=1
    end
    # reset element to zero (eg reset hour to zero)
    def reset_element(tag, element)
       self.statistics[tag][element]=0
    end
    # increment all the tags with a new element value  .  Hash is zero if not found
    def tag_increment(element)
      self.tags.each {|tagv|  puts "incrementing #{tagv}  element: #{element}" if @debug
                            increment_stats(tagv,element)}
      
    end
    
     def handle_message(msg)
        puts "in handle message stomp stat server" if @debug
         m=StompMessage::Message.load_xml(msg.body)
        tag_increment(m.command)
        super(msg)
        tag_increment('msg_count')
        tag_increment('exception_count') if @old_exception_count!= self.exception_count
         @old_exception_count= self.exception_count
         
	  end
	   def stomp_PING(msg, stomp_msg)
          puts "stomp PING: #{msg.body}" if @debug
          [false,'']
          #do not reply as statistic servers do no respond to pings.  they respond to stomp_REPORT    
    end
    #def create_statistics(msg)  # k[it]=0 if !k.key?(it)
     # self.tags.each { |tagv| self.statistics[tagv].each {|k| 
    #                             internal_tags = %w(msg_count, exception_count ) 
    #                             internal_tags.each { |it| 
    #                                                       data= eval("self.#{it}")
    #                                                        k[it]= data-k[it]
    #                                                       puts "it is #{it}: data is #{data} k[it] is #{k[it]}"
     #                                                                               }
    #                                                    }
    #                          }
    # 
    #end
    def stomp_REPORT(msg, stomp_msg)
      
       result= " Stomp Report #{Time.now}\n"
       result << " Messages processed: #{self.msg_count} \n"
       flag =   self.exception_count!=nil ? '' : 'IMPORTANT'
       result << "#{flag} Exceptions processed: #{self.exception_count}\n "
       self.tags.each { |tagv|  # run through each tag  (hour, day etc)  
           result << "#{tagv} Latests Statistics\n"
           self.statistics[tagv].each {|k,v| result <<  " ----- #{k}: #{v}\n"}
          }
       puts result if @debug
       reply_msg = StompMessage::Message.new('stomp_REPLY', "#{result}")
       [true, reply_msg]
    end
    def stomp_RESET(msg, stomp_msg)
        puts "stomp reset: #{msg.body}" if @debug
        reset_tag = msg.body.to_s if self.tags.include?(msg.body.to_s)
        puts " --- RESET TAG: #{reset_tag}"
        self.statistics[reset_tag].each { |k,v| self.statistics[reset_tag][k]=0
                                       puts "RESET: tag #{k} value is zero"
                                        } if self.tags.include?(msg.body.to_s)
        [false,'']
    end
  end
end