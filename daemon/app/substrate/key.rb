SUBSTRATE_SUBKEY_EXECUTIVE = ENV['SUBSTRATE_SUBKEY_EXECUTIVE'] || 'subkey'

class Substrate::Child
  def initialize(*args, **options)
    # Setup a cross-thread notification pipe - nio4r can't monitor pids unfortunately:
    pipe = ::IO.pipe
    @forward_pipe = ::IO.pipe

    @input = Async::IO::Generic.new(pipe.first)
    @output = pipe.last

    @output_string = nil

    @exit_status = nil

    @pid = ::Process.spawn(*args, **options, out: @forward_pipe.last, err: [:child, :out], pgroup: true)

    @thread = Thread.new do
      _, @exit_status = ::Process.wait2(@pid)
      @output.close
    end
  end

  attr :pid

  def running?
    @exit_status.nil?
  end

  def kill(signal = :TERM)
    ::Process.kill(signal, -@pid)
  end

  def wait
    if @exit_status.nil?
      wait_thread
    end

    @exit_status
  end

  def output
    return @output_string if @output_string

    wait
    @forward_pipe.last.close
    @output_string = @forward_pipe.first.read
    @forward_pipe.first.close

    @output_string
  end

  private

  def wait_thread
    @input.read(1)

  ensure
    # If the user stops this task, we kill the process:
    if @exit_status.nil?
      ::Process.kill(:KILL, -@pid)
    end

    @thread.join
    @forward_pipe.last.close

    # We are done with the notification pipe:
    @input.close
    @output.close
  end
end

module Substrate::Key
  def self.generate
    (Async { Substrate::Key.spawn_json 'generate', '-n', 'phala' }).wait
  end

  def self.spawn(subcommand, *args)
    child = Substrate::Child.new SUBSTRATE_SUBKEY_EXECUTIVE, subcommand, *args
    output = child.output

    raise StandardError.new output if output.start_with? 'Error:'
    raise StandardError.new output if output.start_with? 'error:'

    output
  end

  def self.spawn_json(subcommand, *args)
    child = Substrate::Child.new SUBSTRATE_SUBKEY_EXECUTIVE, subcommand, '--output-type', 'Json', *args
    output = nil
    begin
      output = child.output
      ret = JSON.parse output
      raise StandardError.new output unless ret.instance_of? Hash

      return ret
    rescue JSON::ParserError
      raise StandardError.new output
    rescue => e
      raise e
    end
  end
end
