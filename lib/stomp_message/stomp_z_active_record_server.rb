require 'yaml'
require 'erb'
require 'socket'

#require 'stomp_server'
module StompMessage
  # statistics listening class.  Updates the statistics at every message/event
  # had to name it Z due to order problems. not sure why.
  class StompZActiveRecordServer   < StompMessage::StompServer
   attr_accessor :model_list
   attr_reader :database_env
def initialize(options={})
   super(options)
   puts "root_path: #{options[:root_path]} rails_environment #{options[:env]}"
   setup_active_record(options[:root_path], options[:env])
   puts "#{self.class}: finished Active Record initializing"
  # self.model_list = []
 end
#check the active record connection and reestablish... wierd stuff happening at cure.
#note this is specific tomysql... need to fix later
	def check_active_record_connection(my_class)
	 begin
	   ar_conn=my_class.new.connection
     puts " checking AR connection status: #{ar_conn.active?}"
     puts " AR down... reconnecting"  if !ar_conn.active?
   #  puts "after first check"
     ar_conn.reconnect! if !ar_conn.active?
   # puts "after reconnect"
  rescue Mysql::Error
     puts "reconnecting due to Mysql:Error"
     ar_conn.reconnect
  rescue Exception => e
    puts "ActiveRecord found exception that should not be here #{e.message}"
  end
end
def monitor_ar_status(connection)
  puts "starting up active record monitor status"
  self.mythreads << Thread.new { while true
                 begin
                   sleep(1000)
                   check_active_record_connection(connection)
                 rescue Exception => e
                          handle_exception(e)
                 end
               end  # while
                }              
end
#RAILS_ENV= 'production' if RUBY_PLATFORM =~ /java/ 
# the model path needs to include the models for active record...  can be inferred from
# table names if needed but easiest and simplest is to give path to to the rails application
def setup_active_record(root_path,tenv)
  require 'rubygems'
   if self.java?
     env = 'development'
     env = 'production' if Socket.gethostname=='svbalance.cure.com.ph'
     env = tenv if tenv!=nil
   end
  # env = 'production'  #now using connection pools so always production
  #ENV['RAILS_ENV'] ||= env
  #RAILS_ENV=env
  gem 'activerecord'
  require 'active_record'
  
  # ENV['RAILS_ENV'] ||= env
  # RAILS_ENV=env
   path= root_path + "config/database.yml"
   puts "path is #{path}" if @debug
   data=File.open(path).readlines.join
  # puts "file open"
   result=ERB.new(data).result
  # puts "after erb #{result}"
   parsed=YAML.load(result)
 #  puts " values are: #{parsed.to_s}" # if @debug
   puts "env is #{env} values are: #{parsed[env]}"  if @debug
  
   @database_env=parsed[env]
    # puts "db temp #{self.database_env.to_s}"
    puts "Database settings: #{self.database_env.inspect} from environment #{env} in database.yml"
    puts "JNDI Needed: #{self.database_env['jndi']} please ensure configured!" if self.database_env['jndi'] !=nil
   ActiveRecord::Base.allow_concurrency = true
   establish_ar_jdbc_pool
   ActiveRecord::Base.logger = Logger.new(STDOUT)  #RAILS_DEFAULT_LOGGER
   # grab all the models
 #   model_path = root_path + "app/models/*.rb"
   load_models(root_path)
   #puts "after DIR"
 end
 #load the AR models... override if necessary
 # model list is an array of models to load
 def onMessage(msg_body,msg_hash)
     puts "----> Stomp Z AR on Message"
     if check_origin(msg_hash)
        establish_ar_jdbc_pool
        super(msg_body,msg_hash)
        free_ar_jdbc_pool
      end
      msg_body=msg_hash=nil
       puts "<---- Stomp Z AR on Message exit"
       
 end
 def establish_ar_jdbc_pool
    puts "----- establish jdbc pool" 
    ActiveRecord::Base.establish_connection(self.database_env)    if !ActiveRecord::Base.connected?
 end
 def free_ar_jdbc_pool
   puts "---- free pool"
  # ActiveRecord::Base.connection.disconnect!
 #  ActiveRecord::Base.remove_connection
 end
 def load_models(root_path)
      model_path = root_path  + "app/models/"
   # puts "model path is #{model_path}"
   last_model=""
   self.model_list.each { |model_file|
       lib = model_path + model_file
       last_model = require lib 
      puts "loading required model: is #{lib}" if @debug
      # last_model=lib  #last one needs to be active_record  (need to fix)
       }
       puts "last model is #{last_model}"
      monitor_ar_status(eval("#{last_model[0]}")) if !self.java?
 end
   def server_shutdown
      puts "---->shutting down AR"
      free_ar_jdbc_pool
      super
       puts "<----shut down AR"
      
    end
end   # class
end  #module