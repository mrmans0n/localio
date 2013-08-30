require 'erb'

class TemplateHandler
  def self.process_template(template_name, target_directory, generated_file_name)
    full_template_path = File.join(File.dirname(File.expand_path(__FILE__)), "templates/#{template_name}")
    input_file = File.open(full_template_path, 'rb')
    template = input_file.read
    input_file.close
    renderer = ERB.new(template)
    output = renderer.result()
    output_file = File.new(generated_file_name, 'w')
    output_file.write(output)
    output_file.close

    destination_path = target_directory+generated_file_name
    FileUtils.mkdir_p(File.dirname(destination_path))
    FileUtils.cp(generated_file_name, destination_path)
    FileUtils.rm(generated_file_name)
  end
end