require 'erb'
require 'zucchini/report/view'
require 'yaml'
require 'nokogiri'
require 'json'

class Zucchini::Report

  def initialize(features, ci = false, html_path = '/tmp/zucchini_report.html', junit_path = '/tmp/zucchini_report.xml')
    @features, @ci, @html_path, @junit_path = [features, ci, html_path, junit_path]

    generate!
  end

  def text
    @features.map do |f|
      failed_list = f.stats[:failed].empty? ? '' : "\n\nFailed:\n" + f.stats[:failed].map { |s| "   #{s.file_name}: #{s.diff[1]}" }.join
      if f.succeeded
        summary = f.stats.map { |key, set| "#{set.length.to_s} #{key}" }.join(', ')
      else
        summary = "\nFeature execution failed with Javascript Exception\n\n"
      end

      "#{f.name}:\n#{summary}#{failed_list}"
    end.join("\n\n")
  end

  def html
    @html ||= begin
      template_path = File.expand_path("#{File.dirname(__FILE__)}/report/template.erb.html")

      view = Zucchini::ReportView.new(@features, @ci)
      compiled = (ERB.new(File.open(template_path).read)).result(view.get_binding)

      File.open(@html_path, 'w+') { |f| f.write(compiled) }
      compiled
    end
  end

  def junit

    doc = Nokogiri::XML::Document.new()

    root = Nokogiri::XML::Element.new('testsuites', doc)

    doc.add_child(root)

    suite_id = 0
    @features.each do |f|
      suite = Nokogiri::XML::Element.new('testsuite', doc)
      suite['id'] = suite_id
      suite['package'] = f.name
      suite['hostname'] = ENV['ZUCCHINI_DEVICE']
      suite['name'] = f.name
      suite['tests'] = 1 + f.stats[:failed].length + f.stats[:passed].length
      suite['failures'] = f.stats[:failed].length
      suite['errors'] = (f.succeeded ? 0 : 1)
      suite['time'] = 0
      suite['timestamp'] = Time.now.utc.iso8601.gsub!(/Z$/, '')

      suite_props = Nokogiri::XML::Element.new('properties', doc)
      suite.add_child(suite_props)


      # Report a single test case for whether or not the suite execution passed
      test_case = Nokogiri::XML::Element.new('testcase', doc)
      test_case['name'] = 'Feature Execution'
      test_case['classname'] = f.name
      test_case['time'] = 0

      unless f.succeeded
        error = Nokogiri::XML::Element.new('error', doc)
        error['type'] = 'Uncaught Javascript Exception'
        test_case.add_child(error)
      end

      suite.add_child(test_case)


      # Report test cases for failed tests
      f.stats[:failed].each do |stat|
        test_case = Nokogiri::XML::Element.new('testcase', doc)
        test_case['name'] = stat.original_file_path
        test_case['classname'] = stat.file_path
        test_case['time'] = 0

        error = Nokogiri::XML::Element.new('failure', doc)
        error['message'] = stat.diff[1]
        error['type'] = 'Screenshot not matching'
        test_case.add_child(error)

        suite.add_child(test_case)
      end

      # Report test cases for passed tests
      f.stats[:passed].each do |stat|
        test_case = Nokogiri::XML::Element.new('testcase', doc)
        test_case['name'] = stat.original_file_path
        test_case['classname'] = stat.file_path
        test_case['time'] = 0
        suite.add_child(test_case)
      end


      stdout = (f.succeeded ? f.js_stdout : '')
      stderr = (!f.succeeded ? f.js_stdout : '')

      suite.add_child("<system-out>#{doc.create_cdata(stdout)}</system-out>")
      suite.add_child("<system-err>#{doc.create_cdata(stderr)}</system-err>")

      root.add_child(suite)

      suite_id += 1
    end

    File.open(@junit_path, 'w+') { |f| f.write(doc.to_xml) }

  end

  def generate!
    html
    log text
    junit
  end

  def open
    system "open #{@html_path}"
  end

  def log(buf)
    puts buf
  end
end
