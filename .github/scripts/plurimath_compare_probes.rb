# frozen_string_literal: true

# Focused consumer-boundary assertions. The separate CLI-suite and corpus cases
# exercise the CLI itself; these probes establish independent operand semantics.
require "json"
require "optparse"
require "fileutils"
require "asciidoctor"
require "metanorma-standoc"
require "html2doc"
require "nokogiri"

module PlurimathComparisonProbes
  module_function

  SIGNED = {
    "a^-2" => ["pow", "a", ["neg", "2"]],
    "a_-2" => ["sub", "a", ["neg", "2"]],
    "7 mod -3" => ["mod", "7", ["neg", "3"]],
    "7 mod -3^2" => ["mod", "7", ["neg", ["pow", "3", "2"]]],
    "7 mod -3/2" => ["mod", "7", ["neg", ["div", "3", "2"]]],
    "7 mod -3 mod 2" => ["mod", "7", ["neg", ["mod", "3", "2"]]],
  }.freeze

  WORD = {
    "mover" => '<mover><mi>x</mi><mi>y</mi></mover>',
    "munder" => '<munder><mi>x</mi><mi>y</mi></munder>',
    "munderover" => '<munderover><mi>x</mi><mi>u</mi><mi>v</mi></munderover>',
    "nested-mover" => '<mover><mover><mi>x</mi><mi>y</mi></mover><mi>z</mi></mover>',
    "inline-mover" => '<mstyle displaystyle="false"><mover><mi>x</mi><mi>y</mi></mover></mstyle>',
    "inline-munder" => '<mstyle displaystyle="false"><munder><mi>x</mi><mi>y</mi></munder></mstyle>',
    "label-min" => '<mover><mi>x</mi><mi>min</mi></mover>',
    "line-break" => '<mstyle displaystyle="true"><mover><mi>x</mi><mi>y</mi></mover><mo linebreak="newline"/><mi>z</mi></mstyle>',
  }.freeze

  def compact(values)
    values = values.reject { |value| value.nil? || value == "" || value == [] }
    values.length == 1 ? values.first : values
  end

  def mathml(node)
    children = node.element_children
    case node.name
    when "mn"
      value = node.text.tr("−", "-").strip
      value.start_with?("-") ? ["neg", value[1..]] : value
    when "mi", "mo", "mtext"
      node.text.tr("−", "-").strip
    when "msup", "msub", "mfrac", "mover", "munder"
      kind = { "msup" => "pow", "msub" => "sub", "mfrac" => "div",
               "mover" => "over", "munder" => "under" }.fetch(node.name)
      [kind, *children.map { |child| mathml(child) }]
    when "munderover"
      ["under", ["over", mathml(children[0]), mathml(children[2])], mathml(children[1])]
    when "semantics"
      presentation = children.reject { |child| %w[annotation annotation-xml].include?(child.name) }
      raise "Unexpected semantics shape" unless presentation.length == 1

      mathml(presentation.first)
    when "math", "mstyle", "mrow"
      values = children.map { |child| mathml(child) }
      return ["neg", values.last] if values.length == 2 && values.first == "-"
      return ["mod", values.first, values.last] if values.length == 3 && values[1] == "mod"

      compact(values)
    else
      raise "Unsupported MathML element #{node.name}"
    end
  end

  def omml(node)
    return nil if node.name.end_with?("Pr") || node.name == "br"
    return node.text.strip if node.name == "r"

    if %w[limUpp limLow sSup sSub].include?(node.name)
      fields = node.element_children.to_h { |child| [child.name, child] }
      script = %w[limUpp limLow].include?(node.name) ? "lim" : (node.name == "sSup" ? "sup" : "sub")
      kind = %w[limUpp sSup].include?(node.name) ? "over" : "under"
      return [kind, omml(fields.fetch("e")), omml(fields.fetch(script))]
    end
    allowed = %w[html body p div span oMathPara oMath e lim sup sub]
    raise "Unsupported OMML container #{node.name}" unless allowed.include?(node.name)

    compact(node.element_children.map { |child| omml(child) })
  end

  def checked_row(id, group, expected)
    actual = yield
    { id: id, group: group, expected: expected, actual: actual, passed: actual == expected }
  rescue StandardError => error
    { id: id, group: group, expected: expected, passed: false,
      error: "#{error.class}: #{error.message}" }
  end

  def run(output)
    directory = File.dirname(File.expand_path(output))
    FileUtils.mkdir_p(directory)
    rows = SIGNED.map do |expression, expected|
      checked_row("signed-#{expression}", "pr486", expected) do
        input = "= Document title\nAuthor\n:docfile: probe.adoc\n:nodoc:\n:novalid:\n:no-isobib:\n\nstem:[#{expression}]\n"
        result = Asciidoctor.convert(input, backend: :standoc, header_footer: true, agree_to_terms: true)
        document = Nokogiri::XML(result) { |config| config.strict.nonet }
        node = document.at_xpath('//*[local-name()="math"]')
        raise "No generated MathML" unless node

        File.write(File.join(directory, "signed-#{expression.unpack1('H*')}.xml"), result)
        mathml(node)
      end
    end
    # Use the actual Html2Doc converter method with its normal constructor.
    # The outer namespaces are Word's actual fragment context, not normalization.
    word = Html2Doc.new(filename: File.join(directory, "word-probe"))
    WORD.each do |id, body|
      source = '<math xmlns="http://www.w3.org/1998/Math/MathML" displaystyle="true">' + body + '</math>'
      expected = mathml(Nokogiri::XML(source) { |config| config.strict.nonet }.root)
      rows << checked_row("word-#{id}", "pr487", expected) do
        wrapper = '<html xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" ' \
                  'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><body><p>' + source + '</p></body></html>'
        document = Nokogiri::XML(wrapper) { |config| config.strict.nonet }
        word.mathml_to_ooml1(document.at_xpath('//*[local-name()="math"]'), document.collect_namespaces)
        result = document.to_xml
        File.write(File.join(directory, "word-#{id}.xml"), result)
        parsed = Nokogiri::XML(result) { |config| config.strict.nonet }
        raise "No generated OMML" if parsed.xpath('//*[local-name()="oMath"]').empty?

        omml(parsed.root)
      end
    end
    result = { rows: rows, failures: rows.reject { |row| row[:passed] }.map { |row| row[:id] },
               scope: "Native Standoc Asciidoctor conversion and Html2Doc MathML-to-OMML boundary; no Word visual assertion",
               provenance: { standoc: Metanorma::Standoc::Maths.instance_method(:asciimath_parse).source_location,
                             html2doc: Html2Doc.instance_method(:mathml_to_ooml1).source_location } }
    File.write(output, JSON.pretty_generate(result) + "\n")
    puts JSON.generate(result.reject { |key| key == :rows })
    result[:failures].empty? ? 0 : 1
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}
  OptionParser.new { |parser| parser.on("--output PATH") { |path| options[:output] = path } }.parse!
  exit PlurimathComparisonProbes.run(options.fetch(:output))
end
