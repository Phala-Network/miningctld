require 'io/console'
PHOST_STATUS_CHECK_INTERVAL = ENV['PHOST_STATUS_CHECK_INTERVAL'] ? ENV['PHOST_STATUS_CHECK_INTERVAL'].to_i : 21

class Daemon::Worker
  attr_reader :parent
  attr_reader :status

  attr_reader :process
  attr_accessor :intention_set

  def initialize(parent)
    @parent = parent
    @redis_client = async_redis_client
    @redis_listener_id = SecureRandom.uuid

    @status = :IDLE
    @dead = false
    @process = nil
    @intention_set = false
    @pending_set_intention = false
    @synched = false

    @header_num = 0
    @block_num = 0

    condition = Async::Condition.new
    @redis_subscribe = Async do |task|
      $logger.info "Listening pHost status on channel #{@redis_listener_id}"
      @redis_client.subscribe @redis_listener_id do |context|
        (Enumerator.new do |yielder|
          condition.signal
          while (type, name, message = context.listen)
            yielder << message
          end
        end).each do |message|
          handle_phost_callback message
        end
      rescue IOError
      rescue Async::Wrapper::Cancelled
      rescue => err
        $logger.error err
      end
    end

    check_status_cycle
  end

  def run!(controller_uri:, ws_url:)
    s = check_status false
    if s === :IDLE || s === :ERROR
      @intention_set = false
      @pending_set_intention = false
      @synched = false
      @header_num = 0
      @block_num = 0

      @process = Daemon::Worker::Process.new(
        'phost',
        '--pruntime-endpoint',
        'http://pruntime:8000/',
        '--substrate-ws-endpoint',
        ws_url,
        '--mnemonic',
        controller_uri,
        '-r',
        '--notify-endpoint',
        "http://daemon:9292/phost_callback/#{@redis_listener_id}"
      )
      Async { @process.wait }
    end

    @process
  end

  def check_status(should_report = true)
    if @process
      if !@process.running?
        @status = :ERROR
        @intention_set = false
      elsif !@synched
        @status = :SYNCING
      else
        @status = @intention_set ? :INTENTION_SET : :WAITING
      end
    else
      @status = :IDLE
      @intention_set = false
    end

    report_status if should_report
    
    @status
  end

  def report_status
    tunnel_connection.write tunnel_session.encode({
      report_worker_info: {
        status: @status
      }
    })
    tunnel_connection.flush
  end

  def io_task
    @parent.external_tunnel_session.io_task
  end

  def tunnel_session
    @parent.external_tunnel_session
  end

  def tunnel_connection
    @parent.external_tunnel_session.connection
  end

  private

  def handle_phost_callback(message)
    begin
      info = JSON.parse message
      $logger.info "pHost: #{info}"
      @synched = info["initial_sync_finished"]
      @header_num = info["headernum"]
      @block_num = info["blocknum"]
    rescue => e
      $logger.error "Error while processing pHost callback"
      $logger.error e
    end
  end

  def check_status_cycle
    io_task.async do |task|
      while true
        is_dead = @dead || @status === :ERROR
        check_status

        task.sleep PHOST_STATUS_CHECK_INTERVAL
      end
    end
  end
end

class Daemon::Worker::Process
  def initialize(*args, **options)
    # Setup a cross-thread notification pipe - nio4r can't monitor pids unfortunately:
    pipe = ::IO.pipe

    @input = Async::IO::Generic.new(pipe.first)
    @output = pipe.last

    @exit_status = nil

    @pid = ::Process.spawn(*args, **options, pgroup: true)

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

  private

  def wait_thread
    @input.read(1)

  ensure
    # If the user stops this task, we kill the process:
    if @exit_status.nil?
      ::Process.kill(:KILL, -@pid)
    end

    @thread.join

    # We are done with the notification pipe:
    @input.close
    @output.close
  end
end
