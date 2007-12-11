module Seldon
  module MetricParser
    # this exception is thrown if the caller inspects a metric
    # improperly (for example, if a metric that measures database
    # activity is called with :controller_name, a MetricException is thrown)
    class MetricException < Exception; end
      
    # FIXME revisit this design - centralizing this stuff decouples metric name
    # knowledge from the metrics themselves.
    SEPARATOR = '/'
    
    @segments = nil

    def is_web_service?
      segments[0] == "WebService" && segments[1] != 'Soap' && segments[1] != 'Xml Rpc'
    end
    
    def is_controller?
      segments[0] == "Controller"  && segments.length > 1
    end
    
    def is_render?
      segments.last == "Rendering"
    end
    
    def is_database?
      segments[0] == "ActiveRecord"
    end
    alias is_active_record? is_database?
    
    def is_database_read?
      is_database? && segments[-1] == "find" && segments.length > 2
    end
    
    def is_database_write?
      is_database? && segments[-1] == "save" && segments.length > 2
    end
    
    def model_class
      raise MetricException.new unless is_active_record?
      return segments[1]
    end
    
    def is_error?
      segments[0] == 'Errors'
    end
    
    def controller_name
      raise MetricException.new unless is_controller?
      name = ''
      segments[1..-2].each do |s| 
        name << s.camelize
        name << '::' unless s == segments[-2]
      end
      name + "Controller"
    end
    
    def action_name
      raise MetricException.new unless is_controller?
      segments[-1]
    end
    
    def url
      raise MetricException.new("Not a URL: #{name}") unless is_controller?
      '/'+short_name
    end
    
    def short_name
      segments[begin_short_name_segment..end_short_name_segment].join(SEPARATOR)
    end
    
    def category
      segments[0]
    end
    
    def segments
      @segments ||= name.split(SEPARATOR).freeze
      @segments
    end
    
  private
    def begin_short_name_segment
      return 2 if is_error?
      return 1
    end
    
    def end_short_name_segment
      return -1
    end
  end
end