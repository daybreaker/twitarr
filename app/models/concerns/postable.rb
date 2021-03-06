module Postable
  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
  end

  module InstanceMethods
    include Twitter::Extractor
    def validate_author
      return if author.blank?
      unless User.exist? author
        errors[:base] << "#{author} is not a valid username"
      end
    end

    def validate_original_author
      return if original_author.blank?
      unless User.exist? original_author
        errors[:base] << "#{original_author} is not a valid username"
      end
    end

    def author=(username)
      super User.format_username username
    end

    def original_author=(username)
      super User.format_username username
    end

    def location=(loc)
      super loc
    end

    # noinspection RubyResolve
    def parse_hash_tags
      self.entities = extract_entities_with_indices text
      self.hash_tags = []
      self.mentions = []
      entities.each do |entity|
        entity = entity.inject({}) {|x, (k,v)| x[k.to_sym] = v; x }
        if entity.has_key? :hashtag
          self.hash_tags << entity[:hashtag].downcase
        elsif entity.has_key? :screen_name
          self.mentions << entity[:screen_name].downcase
        end
      end
    end

    def post_create_operations
      record_hashtags
    end

    def record_hashtags
      self.hash_tags.each do |ht|
        Hashtag.add_tag ht
      end
    end

    def validate_location
      post_location = self[:location]
      result = Location.valid_location? post_location
      unless result
        errors[:base] << "Invalid location: #{post_location}"
      end
      result
    end

    def add_reaction(username, reaction)
      begin 
        doc = reactions.find_by({:reaction => reaction, :username => username})
        logger.info "Duplicate reaction on post: #{username}, #{reaction}"
      rescue Mongoid::Errors::DocumentNotFound => e
        reactions.create reaction: reaction, username: username
      end
    end
  
    def remove_reaction(username, reaction)
      begin 
        doc = reactions.find_by({:reaction => reaction, :username => username})
        doc.remove
      rescue Mongoid::Errors::DocumentNotFound => e
        logger.info "Could not find reaction to remove: #{username}, #{reaction}"
      end
    end
  end

  module ClassMethods
    def view_mentions(params = {})
      query_string = params[:query]
      start_loc = params[:page] || 0
      limit = params[:limit] || 20
      query = if params[:mentions_only]
                where({mentions: query_string})
              else
                self.or({mentions: query_string}, {author: query_string})
              end
      if params[:after]
        val = Time.from_param(params[:after])
        if val
          query = query.where(:timestamp.gt => val)
        end
      end
      query.order_by(id: :desc).skip(start_loc*limit).limit(limit)
    end

    def view_hashtags(params = {})
      query_string = params[:query]
      start_loc = params[:page] || 0
      limit = params[:limit] || 20
      query = where({hash_tags: query_string})
      if params[:after]
        val = Time.from_param(params[:after])
        if val
          query = query.where(:timestamp.gt => params[:after])
        end
      end
      query.order_by(id: :desc).skip(start_loc*limit).limit(limit)
    end
  end
end
