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
      failed_list = f.stats[:failed].empty? ? "" : "\n\nFailed:\n" + f.stats[:failed].map { |s| "   #{s.file_name}: #{s.diff[1]}" }.join
      summary = f.stats.map { |key, set| "#{set.length.to_s} #{key}" }.join(", ")

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
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.result {
        xml.suites {
        }
        xml.duration 0
        xml.keepLongStdio false
      }
    end

    doc = builder.doc
    suites = doc.search('//suites')[0]

    @features.each do |f|
      suite = Nokogiri::XML::Element.new('suite', doc)
      suite.add_child("<file>#{@junit_path}</file>")
      suite.add_child("<name>#{f.name}</name>")
      suite.add_child("<duration>0</duration>")
      suite.add_child("<timestamp>#{DateTime.now.iso8601}</timestamp>")

      feature_failed = !f.succeeded
      feature_stdout = f.js_stdout

      test_case = Nokogiri::XML::Element.new('case', doc)
      test_case.add_child('<duration>0</duration>')
      test_case.add_child("<className>#{doc.create_cdata(f.path)}</className>")
      test_case.add_child("<testName>#{doc.create_cdata(f.name)}</testName>")
      test_case.add_child('<skipped>false</skipped>')
      test_case.add_child("<failedSince>#{feature_failed ? 2 : 0}</failedSince>")
      test_case.add_child("<stdout>#{doc.create_cdata(feature_stdout)}</stdout>")
      suite.add_child(test_case)

      f.stats[:failed].each do |stat|
        test_case = Nokogiri::XML::Element.new('case', doc)
        test_case.add_child('<duration>0</duration>')
        test_case.add_child("<className>#{doc.create_cdata(stat.original_file_path)}</className>")
        test_case.add_child("<testName>#{doc.create_cdata(stat.file_path)}</testName>")
        test_case.add_child('<skipped>false</skipped>')
        test_case.add_child('<failedSince>2</failedSince>')
        test_case.add_child("<stdout>#{doc.create_cdata(stat.diff[1])}</stdout>")
        suite.add_child(test_case)
      end

      f.stats[:passed].each do |stat|
        test_case = Nokogiri::XML::Element.new('case', doc)
        test_case.add_child('<duration>0</duration>')
        test_case.add_child("<className>#{doc.create_cdata(stat.original_file_path)}</className>")
        test_case.add_child("<testName>#{doc.create_cdata(stat.file_path)}</testName>")
        test_case.add_child('<skipped>false</skipped>')
        test_case.add_child('<failedSince>0</failedSince>')
        test_case.add_child("<stdout>#{doc.create_cdata(stat.diff[1])}</stdout>")
        suite.add_child(test_case)
      end

      suites << suite
    end

    File.open(@junit_path, 'w+') { |f| f.write(doc.to_xml) }

  end

  def generate!
    log text
    html
    junit
  end

  def open
    system "open #{@html_path}"
  end

  def log(buf)
    puts buf
  end
end
