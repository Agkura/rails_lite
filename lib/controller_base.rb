require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, params)
    @req = req
    @res = res
    @params = req.params.merge(params)
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response ||= false
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "Double Render, Mother Lover" if already_built_response?
    @already_built_response = true
    res.set_header('Location', url)
    res.status = 302
    @session.store_session(@res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise "Double Render, Mother Lover" if already_built_response?
    @already_built_response = true
    res.write(content)
    res['Content-Type'] = content_type
    @session.store_session(@res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    filename = self.class.to_s.underscore
    file = File.read("views/#{filename}/#{template_name}.html.erb")
    file = ERB.new("#{file}").result(binding)
    render_content(file, 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render(name) unless already_built_response?
  end
end
