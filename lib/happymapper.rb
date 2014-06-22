require 'date'
require 'time'
require 'rubygems'
require 'nokogiri'

class Boolean; end
class XmlContent; end

module HappyMapper

  DEFAULT_NS = "happymapper"

  def self.included(base)
    base.instance_variable_set("@attributes", {})
    base.instance_variable_set("@elements", {})
    base.extend ClassMethods
  end

  module ClassMethods
    def attribute(name, type, options={})
      attribute = Attribute.new(name, type, options)
      @attributes[to_s] ||= []
      @attributes[to_s] << attribute
      attr_accessor attribute.method_name.intern
    end

    def attributes
      @attributes[to_s] || []
    end

    def element(name, type, options={})
      element = Element.new(name, type, options)
      @elements[to_s] ||= []
      @elements[to_s] << element
      attr_accessor element.method_name.intern
    end

    def content(name)
      @content = name
      attr_accessor name
    end

    def after_parse_callbacks
      @after_parse_callbacks ||= []
    end

    def after_parse(&block)
      after_parse_callbacks.push(block)
    end

    def elements
      @elements[to_s] || []
    end

    def text_node(name, type, options={})
      @text_node = TextNode.new(name, type, options)
      attr_accessor @text_node.method_name.intern
    end

    def has_xml_content
      attr_accessor :xml_content
    end
    
    def has_one(name, type, options={})
      element name, type, {:single => true}.merge(options)
    end

    def has_many(name, type, options={})
      element name, type, {:single => false}.merge(options)
    end

    # Specify a namespace if a node and all its children are all namespaced
    # elements. This is simpler than passing the :namespace option to each
    # defined element.
    def namespace(namespace = nil)
      @namespace = namespace if namespace
      @namespace
    end

    def tag(new_tag_name)
      @tag_name = new_tag_name.to_s unless new_tag_name.nil? || new_tag_name.to_s.empty?
    end

    def tag_name
      @tag_name ||= to_s.split('::')[-1].downcase
    end

    def parse(xml, options = {})
      # locally scoped copy of namespace for this parse run
      namespace = @namespace

      if xml.is_a?(Nokogiri::XML::Node)
        node = xml
      else
        if xml.is_a?(Nokogiri::XML::Document)
          node = xml.root
        else
          xml = Nokogiri::XML(xml)
          node = xml.root
        end

        root = node.name == tag_name
      end

      # This is the entry point into the parsing pipeline, so the default
      # namespace prefix registered here will propagate down
      namespaces   = options[:namespaces]
      namespaces ||= {}
      namespaces   = namespaces.merge(xml.collect_namespaces) if xml.respond_to?(:collect_namespaces)
      namespaces   = namespaces.merge(xml.namespaces)
      
      # Remove any prefix (like xmlns:)
      new_namespaces = Hash.new
      namespaces.to_a.each do |(key,val)|
        new_namespaces[key.to_s.split(":").last] = val
      end
      
      namespaces = new_namespaces
      namespace ||= "xmlns" if namespaces.has_key?("xmlns")
      
      # If the namespace is a URL, convert into the namespace key name.
      namespace = (namespaces.to_a.detect { |(key,url)| url == namespace }.first rescue nil) if namespace =~ /http[s]?\:/
      namespace = namespace.split(":").last rescue nil
      
      nodes = options.fetch(:nodes) do
        xpath  = (root ? '/' : node.path + "/")
        xpath += "/" if options[:deep]
        xpath  = options[:xpath].to_s.sub(/([^\/])$/, '\1/') if options[:xpath]
        xpath += "#{namespace}:" if namespace

        nodes = []

        # when finding nodes, do it in this order:
        # 1. specified tag
        # 2. name of element
        # 3. tag_name (derived from class name by default)
        [options[:tag], options[:name], tag_name].compact.each do |xpath_ext|
          # puts xpath + xpath_ext.to_s + ", " + namespaces.inspect
          nodes = node.xpath(xpath + xpath_ext.to_s, namespaces)
          break if nodes && !nodes.empty?
        end
        
        puts "Found #{nodes.length} nodes within #{name}"
        
        nodes
      end

      collection = nodes.collect do |n|
        obj = new
        
        puts "Created instance #{obj.inspect}"

        attributes.each do |attr|
          obj.send("#{attr.method_name}=",
                    attr.from_xml_node(n, namespace, namespaces))
        end
        
        elements.each do |elem|
          element_namespace = elem.options[:namespace] == false ? nil : elem.options[:namespace] || namespace
          
          # Convert the namespace into something Nokogiri can handle.
          if element_namespace =~ /http[s]?\:/
            element_namespace = (namespaces.to_a.detect { |(key,url)| url == element_namespace }.first rescue nil)
            element_namespace = element_namespace.split(":").last rescue nil
          elsif element_namespace && !namespaces.keys.include?(element_namespace)
            # Namespace required but not present in XML, skip it.
            next
          end
          
          obj.send("#{elem.method_name}=", 
                  elem.from_xml_node(n, element_namespace, namespaces))
        end

        obj.send("#{@text_node.method_name}=", 
                  @text_node.from_xml_node(n, namespace, namespaces)) if @text_node

        if obj.respond_to?('xml_content=')
          n = n.children if n.respond_to?(:children)
          obj.xml_content = n.to_xml 
        end

        obj.send("#{@content}=", n.content) if @content

        obj.class.after_parse_callbacks.each { |callback| callback.call(obj) }

        obj
      end

      # per http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000354
      nodes = nil

      if options[:single] || root
        collection.first
      else
        collection
      end
    end
  end
end

require 'happymapper/item'
require 'happymapper/attribute'
require 'happymapper/element'
require 'happymapper/item'
require 'happymapper/attribute'
require 'happymapper/element'
require 'happymapper/text_node'
